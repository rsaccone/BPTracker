//
//  BPImportOrchestrator.m
//  BPTracker
//
//  Created by Robert Saccone on 12/27/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BPImportOrchestrator.h"

#import <SLexUtil/CHCSVParser.h>
#import <SLexUtil/ErrorMsgBuilder.h>
#import <SLexUtil/NSErrorHelper.h>
#import <SlexUtil/NumericUtil.h>
#import "BPDataImporterFactory.h"
#import "BPDataImportError.h"
#import "BloodPressureDataAnalyzer.h"
#import "BloodPressureReading.h"
#import "ManagedObjFieldInfo.h"

typedef enum
{
    OrchStateNone,
    OrchStateCheckForColumnHeadings,
    OrchStateCaptureColumnMappings,
    OrchStateCaptureReadingComponent,
    OrchStateFinSuccess,
    OrchStateFinError,
    OrchStateFinCanceled
} OrchestratorState;

// The number of readings to process before issuing a commit.
static const NSUInteger BatchSize = 100;

// Column names that can be in CSV file.
static NSString *const DateCol      = @"DATE";
static NSString *const TimeCol      = @"TIME";
static NSString *const PulseCol     = @"PULSE";
static NSString *const SystolicCol  = @"SYSTOLIC";
static NSString *const DiastolicCol = @"DIASTOLIC";
static NSString *const WeightCol    = @"WEIGHT";
static NSString *const NoteCol      = @"NOTE";

// Field names in a BPReading.
static NSString *const DateField        = @"readingDate";
static NSString *const PulseField       = @"pulse";
static NSString *const SystolicField    = @"systolic";
static NSString *const DiastolicField   = @"diastolic";
static NSString *const WeightField      = @"weight";
static NSString *const NoteField        = @"note";


static NSArray *defaultColumnHeaderOrdering = nil;
static NSDictionary *columnNamesToFieldInfoMap = nil;
static NSDictionary *fieldNameToBPComponent = nil;

NSString *const BPDataImportErrorDomain = @"com.softlexsystems.bptracker.DataImportErrorDomain";

@interface BPImportOrchestrator () <CHCSVParserDelegate>

- (void)setupColumnOrderingFromDefaults;
- (void)parsingErrorHandler:(NSError *)error;
- (BOOL)captureColumnDefinition:(NSString *)colNameCandidate error:(NSError * __autoreleasing *)error;
- (BOOL)checkForAllRequiredColumnDefinitions:(NSError * __autoreleasing *)error;
- (BOOL)populateCurrReadingWithFieldData:(NSString *)field error:(NSError * __autoreleasing *)error;
- (BOOL)orchestrationCanceled;
- (BOOL)commitImportedRecords;
- (NSDate *)parseDateComponentFromDataField:(NSString *)field error:(NSError* __autoreleasing *)error;
- (NSError *)makeConversionErrorFromFieldInfo:(ManagedObjFieldInfo *)fieldInfo fieldData:(NSString *)fieldData;

@property(nonatomic, weak) id<BPImportOrchestratorDelegate> delegate;
@property(nonatomic, strong) id<BPDataImporter> dataImporter;
@property(nonatomic, strong) NSMutableArray *colDefs;
@property(nonatomic, strong) NSMutableArray *colNameOrdering;
@property(nonatomic, strong) NSMutableDictionary *colNameToColNumber;
@property(nonatomic, strong) NSManagedObjectContext *privateImportManagedContext;
@property(nonatomic, strong) NSManagedObjectContext *scratchImportContext;
@property(nonatomic, strong) BloodPressureReading *currBPReading;
@property(nonatomic, strong) CHCSVParser *csvParser;
@property(nonatomic, strong) NSMutableDictionary *dataCache;
@property(atomic, assign) OrchestratorState currState;
@property(nonatomic, strong) NSString *dateStr;
@property(nonatomic, strong) NSString *timeStr;
@property(atomic, assign) NSUInteger numRecordsImported;
@property(atomic, assign) NSUInteger numRecordsUpdated;


@end

@implementation BPImportOrchestrator
{
@private
    id<BPImportOrchestratorDelegate> __weak delegate_;
    id<BPDataImporter> dataImporter_;
    NSMutableArray *colDefs_;
    NSMutableArray *colNameOrdering_;
    NSMutableDictionary *colNameToColNumber_;
    NSManagedObjectContext *privateImportManagedContext_;
    NSManagedObjectContext *scratchImportContext_;
    CHCSVParser *csvParser_;
    NSMutableDictionary *dataCache_;
    OrchestratorState currState_;
    NSString *dateStr_;
    NSString *timeStr_;
    NSUInteger currLine_;
    NSUInteger currCol_;
    NSUInteger importsInBatchCount_;
    NSUInteger numRecordsImported_;
    NSUInteger numRecordsUpdated_;
    volatile BOOL cancelRequest_;
}

@synthesize delegate = delegate_;
@synthesize dataImporter = dataImporter_;
@synthesize colDefs = colDefs_;
@synthesize colNameOrdering = colNameOrdering_;
@synthesize colNameToColNumber = colNameToColNumber_;
@synthesize privateImportManagedContext = privateImportManagedContext_;
@synthesize scratchImportContext = scratchImportContext_;
@synthesize currBPReading;
@synthesize csvParser = csvParser_;
@synthesize dataCache = dataCache_;
@synthesize currState = currState_;
@synthesize dateStr = dateStr_;
@synthesize timeStr = timeStr_;
@synthesize numRecordsImported = numRecordsImported_;
@synthesize numRecordsUpdated = numRecordsUpdated_;

#pragma mark - Column Name and Field Helper functions

static NSString *normalizeColunName(NSString *columnName)
{
    ZCAssert(columnName != nil, @"columnName is nil!");
    
    columnName = [columnName stringByTrimmingCharactersInSet:
                  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    columnName = [columnName uppercaseString];
    
    return columnName;
}

#if defined(NOT_NEED_FOR_IMPORT)

static ManagedObjFieldInfo *findFieldInfo(NSString *columnName)
{
    ZCAssert(columnName != nil, @"columnName is nil!");

    columnName = normalizeColunName(columnName);
    
    return [columnNamesToFieldInfoMap objectForKey:columnName];
}

#endif

#pragma mark - Initialization

- (id)initWithCSVFile:(NSString *)filename parentManagedObjectContext:(NSManagedObjectContext *) parentManagedObjectContext notificationDelegate:(id<BPImportOrchestratorDelegate>)delegate error:(NSError **)anError
{
    static dispatch_once_t initOnce;
    
    dispatch_once(&initOnce, ^{
        defaultColumnHeaderOrdering =
          @[
            DateCol,
            TimeCol,
            PulseCol,
            SystolicCol,
            DiastolicCol,
            WeightCol,
            NoteCol
            ];
        
        ManagedObjFieldInfo *readingDateFieldInfo = [[ManagedObjFieldInfo alloc] initWithFieldName:DateField fieldType:DateFieldType];
        
        columnNamesToFieldInfoMap =
        @{ DateCol : readingDateFieldInfo,
           TimeCol : readingDateFieldInfo,
           PulseCol : [[ManagedObjFieldInfo alloc] initWithFieldName:PulseField fieldType:ShortFieldType],
           SystolicCol : [[ManagedObjFieldInfo alloc] initWithFieldName:SystolicField fieldType:ShortFieldType],
           DiastolicCol :[[ManagedObjFieldInfo alloc] initWithFieldName:DiastolicField fieldType:ShortFieldType],
           WeightCol : [[ManagedObjFieldInfo alloc] initWithFieldName:WeightField fieldType:ShortFieldType],
           NoteCol : [[ManagedObjFieldInfo alloc] initWithFieldName:NoteField fieldType:StringFieldType]
        };
        
        fieldNameToBPComponent =
        @{ DateField : @(DateComponent),
           PulseField : @(PulseComponent),
           SystolicField : @(SystolicComponent),
           DiastolicField : @(DiastolicComponent),
           WeightField : @(WeightComponent)
           };
    });
    
    if (anError == nil)
    {
        NSException* myException = [NSException
                                    exceptionWithName:NSInvalidArgumentException
                                    reason:@"anError is nil!"
                                    userInfo:nil];
        @throw myException;
    }

    if (filename == nil)
    {
        ZAssert(filename != nil, @"filename is nil!");
        
        *anError = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPIFileDoesNotExist,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          @"IMPORT_READINGS_INVALID_IMPORT_FILENAME_REASON",
                                          @"IMPORT_READINGS_RESTART_APPLICATION_RECOVERY_SUGGESTION",
                                          nil,
                                          nil,
                                          nil,
                                          NoStringOverrides);
        
        
        return nil;
    }
    
    if (parentManagedObjectContext == nil)
    {
        ZAssert(parentManagedObjectContext != nil, @"parentManagedObjectContext is nil!");
        
        *anError = makeNSErrorFromResources(BPDataImportErrorDomain,
                                            BPIFileDoesNotExist,
                                            @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                            @"IMPORT_READINGS_INVALID_DATABASE_CONTEXT_REASON",
                                            @"IMPORT_READINGS_RESTART_APPLICATION_RECOVERY_SUGGESTION",
                                            nil,
                                            nil,
                                            nil,
                                            NoStringOverrides);
        
        return nil;
    }
    
    self = [super init];
    
    if (self != nil)
    {
        delegate_ = delegate;
        dataCache_ = [[NSMutableDictionary alloc] init];
        colNameOrdering_ = [[NSMutableArray alloc] initWithCapacity:defaultColumnHeaderOrdering.count];
        colNameToColNumber_ = [[NSMutableDictionary alloc] initWithCapacity:defaultColumnHeaderOrdering.count];
        
        // create writer MOC
        privateImportManagedContext_ = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        
        [privateImportManagedContext_ setParentContext:parentManagedObjectContext];
        
        NSStringEncoding usedEncoding = 0;
        
        csvParser_ = [[CHCSVParser alloc] initWithContentsOfCSVFile:filename
                                                       usedEncoding:&usedEncoding
                                                              error:anError];
        
        if (!csvParser_)
        {
            if (*anError != nil)
            {
                ALog(@"Couldn't create csvParser: %@", [ErrorMsgBuilder build:nil error:*anError]);
            }
            else
            {
                ALog(@"Couldn't create csvParser");
            }
            
            return nil;
        }
        else
        {
            DLog(@"Created CSV Parser, encoding used = %lu", (unsigned long)usedEncoding);
        }
        
        csvParser_.parserDelegate = self;
    }
    
    return self;
}

- (id)init
{
    return [self initWithCSVFile:nil parentManagedObjectContext:nil notificationDelegate:nil error:nil];
}

#pragma mark - Parsing error handling

- (void)parsingErrorHandler:(NSError *)error
{
    [self.csvParser cancelParsing];
    self.currState = OrchStateFinError;
    
    if (self.delegate != nil)
    {
        [self.delegate importOrchestrator:self
                          failedWithError:error
                     totalRecordsImported:self.numRecordsImported
                      totalRecordsUpdated:self.numRecordsUpdated];
    }
}

- (BOOL)orchestrationCanceled
{
    if (self->cancelRequest_)
    {
        [self.csvParser cancelParsing];
        self.currState = OrchStateFinCanceled;
        [self.delegate importOrchestrator:self
                     totalRecordsImported:self.numRecordsImported
                      totalRecordsUpdated:self.numRecordsUpdated
                              wasCanceled:YES];
        
        return YES;
    }
    
    return NO;
}

- (BOOL)commitImportedRecords
{
    NSError * __autoreleasing error = nil;
    
    if ([self.dataImporter commit:&error])
    {
        importsInBatchCount_ = 0;
        self.numRecordsImported = self.dataImporter.newReadingsImportedCount;
        self.numRecordsUpdated = self.dataImporter.readingsUpdatedCount;
        
        [self.delegate importOrchestrator:self
                       numRecordsImported:self.numRecordsImported
                        numRecordsUpdated:self.numRecordsUpdated];
        
        return YES;
    }

    // Error committing.
    [self parsingErrorHandler:error];
    
    return NO;
}


#pragma mark - Public interface methods
- (void)beginImport
{
    BPImportOrchestrator * __weak weakSelf = self;
    
    [self.privateImportManagedContext performBlock:^{
        // Create the context that will be used by the import to persist the data.
        NSManagedObjectContext *importerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        
        [importerContext setParentContext:self.privateImportManagedContext.parentContext];
        
        weakSelf.dataImporter
            = [[BPDataImporterFactory instance] makeDataImporter:importerContext
                                               mergeImportedData:YES
                                                   batchSizeHint:0];
        
        [weakSelf.dataImporter begin];
        

        [weakSelf.csvParser parse];
    }];
}

- (void)cancelImportRequest
{
    self->cancelRequest_ = YES;
}


#pragma mark - Column Name Header Related Methods

- (void)setupColumnOrderingFromDefaults
{
    NSUInteger index = 0;
    for (NSString *currCol in defaultColumnHeaderOrdering)
    {
        self.colDefs[index] = columnNamesToFieldInfoMap[currCol];
        self.colNameToColNumber[currCol] = [NSNumber numberWithUnsignedLong:index];
        self.colNameOrdering[index++] = currCol;
    }
}

- (BOOL)captureColumnDefinition:(NSString *)colNameCandidate error:(NSError * __autoreleasing *)error
{
    ZAssert(error != nil, @"error == nil");
    
    if (currCol_ < defaultColumnHeaderOrdering.count)
    {
        NSString *colNameNormalized = normalizeColunName(colNameCandidate);
        
        ManagedObjFieldInfo *moFieldInfo = [columnNamesToFieldInfoMap objectForKey:colNameNormalized];
        
        // if the colNameCandidate matches one of the column headers than the csv file has headers
        // and they must be captured because the ordering is dependent upon the csv column
        // header order otherwise use the assumed ordering.  Note that the assumed ordering.
        // means that every column is present, none are optional.
        if (moFieldInfo != nil)
        {
            self.colDefs[currCol_] = moFieldInfo;
            self.colNameOrdering[currCol_] = colNameNormalized;
            self.colNameToColNumber[colNameNormalized] = [NSNumber numberWithUnsignedLong:currCol_++];
            return YES;
        }
    }
    else
    {
        // More columns than expected.
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READINGS_TOO_MANY_COLUMNS_REASON", nil), self->currLine_, self->currCol_];
        
        *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPImportFileContainsTooManyColumns,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          reason,
                                          @"IMPORT_READINGS_INVALID_COLUMN_NAME_SUGGESTION",
                                          nil,
                                          nil,
                                          nil,
                                          FailureReasonIsAString);
    }
    
    return NO;
}

// TODO: Create an NSError for missing column definition.
- (BOOL)checkForAllRequiredColumnDefinitions:(NSError * __autoreleasing *)error
{
    ZAssert(error != nil, @"error == nil!");
    
    *error = nil;
    
    BPImportOrchestrator * __weak weakSelf = self;

    [columnNamesToFieldInfoMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
        // See if the key, which is the column name, is in the column definitions
        // that have been captured.
        if ((weakSelf.colNameToColNumber[key] == nil) && (!((ManagedObjFieldInfo *)obj).optional))
        {
            // TODO: Create an NSError to describe the missing column.
            *stop = YES;
        }
    }];
    
    return (*error == nil) ? YES : NO;
}

#pragma mark - Populate BPReading with data

- (NSDate *)parseDateComponentFromDataField:(NSString *)field error:(NSError* __autoreleasing *)error
{
    ZAssert(error != nil, @"error == nil");
    
    NSString *dateColValue = nil;
    NSString *timeColValue = nil;
    
    NSString *colName = colNameOrdering_[currCol_];
    
    if ([colName compare:DateCol] == NSOrderedSame)
    {
        timeColValue = dataCache_[TimeCol];
        
        if (timeColValue == nil)
        {
            // Save the date until the time comes in.
            dataCache_[DateCol] = field;
        }
        else
        {
            dateColValue = field;
        }
    }
    else if ([colName compare:TimeCol] == NSOrderedSame)
    {
        dateColValue = dataCache_[DateCol];
        
        if (dateColValue == nil)
        {
            dataCache_[TimeCol] = field;
        }
        else
        {
            timeColValue = field;
        }
    }
    else
    {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READINGS_INVALID_COLUMN_INTERNAL_REASON", nil), colName];
        
        *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPInvalidColumnNameInternal,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          reason,
                                          @"MPORT_READINGS_RESTART_APPLICATION_RECOVERY_SUGGESTION",
                                          *error,
                                          nil,
                                          nil,
                                          FailureReasonIsAString);
        
        return nil;
    }
    
    NSDate *parsedDate = nil;
    
    if (dateColValue && timeColValue)
    {
        NSError *parsingError = nil;
        NSString *tmp = [NSString stringWithFormat:@"%@ %@", dateColValue, timeColValue];
        
        NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeDate error:error];
        
        if (detector != nil)
        {
            NSArray *matches = [detector matchesInString:tmp
                                                 options:0
                                                   range:NSMakeRange(0, [tmp length])];
            
            // Use the first entry that has a date.
            for (NSTextCheckingResult *match in matches)
            {
                if (match.date != nil)
                {
                    parsedDate = match.date;
                    break;
                }
            }
            
            if (parsedDate != nil)
            {
                ++currCol_;
            }
            else
            {
                NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READINGS_DATE_TIME_STAMP_DATA_INVALID_REASON", nil),
                                    self->currLine_];
                
                *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                                  BPInvalidDateTimeData,
                                                  @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                                  reason,
                                                  @"IMPORT_READINGS_DATE_TIME_STAMP_DATA_INVALID_RECOVERY_SUGGESTION",
                                                  parsingError,
                                                  nil,
                                                  nil,
                                                  FailureReasonIsAString);
            }
        }
    }
    else
    {
        ++currCol_;
    }
    
    return parsedDate;
}

- (NSError *)makeConversionErrorFromFieldInfo:(ManagedObjFieldInfo *)fieldInfo fieldData:(NSString *)fieldData
{
    ZAssert(fieldInfo != nil, @"fieldInfo == nil");
    
    NSNumber *num = fieldNameToBPComponent[fieldInfo.fieldName];
    
    ZAssert(num != nil, @"num == nil");
    
    BPComponent bpComponent = (BPComponent)num.unsignedIntValue;
    
    BloodPressureDataAnalyzer *bpDataAnalyzer = [BloodPressureDataAnalyzer instance];
    
    NSString *compDesc = [bpDataAnalyzer validValuesDescriptionForComponent:bpComponent];
    NSString *componentName = [bpDataAnalyzer localizedNameForBPComponent:bpComponent];
    NSString *dataTypeStr = nil;
    
    switch (fieldInfo.fieldType)
    {
        case DateFieldType:
            dataTypeStr = NSLocalizedString(@"DATE_TYPE", nil);
            break;
            
        case StringFieldType:
            dataTypeStr = NSLocalizedString(@"TEXT_TYPE", nil);
            break;
            
        case ShortFieldType:
        case IntFieldType:
            dataTypeStr = NSLocalizedString(@"NUMERIC_TYPE", nil);
            break;
            
        default:
            dataTypeStr = [NSString stringWithFormat:NSLocalizedString(@"UNKNOWN_TYPE", nil), fieldInfo.fieldType];
            ZAssert(NO, @"Field name %@ has an unexpected type value %u", fieldInfo.fieldName, fieldInfo.fieldType);
            break;
    }
    
    NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READINGS_INVALID_DATA_IN_COLUMN_REASON", nil),
                        self->currLine_, self->currCol_ + 1, componentName, dataTypeStr];
    
    if (compDesc != nil)
    {
        reason = [NSString stringWithFormat:@"%@\n%@", reason, compDesc];
    }
    
    NSString *recovery = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READINGS_INVALID_READING_DATA_RECOVERY_SUGGESTION", nil), self->currLine_];
    
    
    NSError *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                              BPInvalidDataInReading,
                                              @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                              reason,
                                              recovery,
                                              nil,
                                              nil,
                                              nil,
                                              FailureReasonIsAString | RecoverySuggestionIsAString);
    
    return error;
    
}

- (BOOL)populateCurrReadingWithFieldData:(NSString *)field error:(NSError * __autoreleasing *)error
{
    ZAssert(error != nil, @"error == nil");
    
    if (field.length == 0)
    {
        return NO;
    }
    
    if (currCol_ >= self.colDefs.count)
    {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READING_TOO_MANY_COLUMNS_REASON", nil),
                            self->currLine_, self->currCol_];

        *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                          BPImportFileContainsTooManyColumns,
                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                          reason,
                                          @"IMPORT_READINGS_TOO_MANY_COLUMNS_RECOVERY_SUGGESTION",
                                          nil,
                                          nil,
                                          nil,
                                          FailureReasonIsAString);
        
        return NO;
    }
    
    ManagedObjFieldInfo *fieldInfo = self.colDefs[currCol_];
    
    id value = nil;
    
    FieldType fieldType = fieldInfo.fieldType;
    
    switch (fieldType)
    {
        case DateFieldType:
            value = [self parseDateComponentFromDataField:field error:error];
            break;
            
        case StringFieldType:
            value = field;
            ++currCol_;
            break;
            
        case IntFieldType:
        case ShortFieldType:
            if (fieldInfo.fieldType == IntFieldType)
            {
                value = [NumericUtil convertStringToNSNumber:field expectedType:IntNumberType];
            }
            else
            {
                value = [NumericUtil convertStringToNSNumber:field expectedType:ShortNumberType];
            }
            
            if (value != nil)
            {
                ++currCol_;
            }
            else
            {
                *error = [self makeConversionErrorFromFieldInfo:fieldInfo fieldData:field];
            }
            break;
            
        default:
            // TODO: - Unexpected type - What to do about this?
            break;
    }
    
    if (value != nil)
    {
        ZAssert(*error == nil, @"value != nil and *error != nil");
        NSString *fieldName = fieldInfo.fieldName;
        [self.currBPReading setValue:value forKey:fieldName];
    }
    
    return ((value != nil) || ((value == nil) && (*error == nil))) ? YES : NO;
}

#pragma mark - CHCVSParserDelegate Implementation

- (void)parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile
{
    DLog(@"BPImportOrchestrator: didStartDocument called, filename = %@", csvFile);
    ZAssert(self.currState == OrchStateNone, @"Unexpected state %d", self.currState);
    
    if ([self orchestrationCanceled])
    {
        return;
    }
    
    self.currState = OrchStateCheckForColumnHeadings;
    self.scratchImportContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    [self.scratchImportContext setParentContext:self.privateImportManagedContext.parentContext];
}

- (void)parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber
{
    DLog(@"BPImportOrchestrator: didStartLine called, lineNumber = %lu", (unsigned long)lineNumber);
    
    if ([self orchestrationCanceled])
    {
        return;
    }
    
    currLine_ = lineNumber;
    currCol_ = 0;
    self.dateStr = nil;
    self.timeStr = nil;
    [self.dataCache removeAllObjects];
    
    if (self.currState == OrchStateCheckForColumnHeadings)
    {
        ZAssert(lineNumber == 1, @"Looking for column headings but lineNumber (%lu) != 0", (unsigned long)lineNumber);
        self.colDefs = [[NSMutableArray alloc] initWithCapacity:defaultColumnHeaderOrdering.count];
    }
    else if (self.currState == OrchStateCaptureReadingComponent)
    {
        ZAssert(self.currBPReading == nil, @"self.currBPReading != nil");
        
        self.currBPReading =
        [NSEntityDescription insertNewObjectForEntityForName:@"BloodPressureReading"inManagedObjectContext:self.scratchImportContext];
    }
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber
{
    DLog(@"BPImportOrchestrator: didEndLine called, lineNumber = %lu", (unsigned long)lineNumber);
    
    NSAssert(currLine_ == lineNumber, @"didEndLine: lineNumber (%lu) != currLine_ (%lu)", (unsigned long)lineNumber, (unsigned long)currLine_);
    
    if ([self orchestrationCanceled])
    {
        return;
    }

    NSError * __autoreleasing error = nil;
    
    if (self.currState == OrchStateCaptureColumnMappings)
    {
        if ([self checkForAllRequiredColumnDefinitions:&error])
        {
            // All columns captured successfully switch to
            // importing blood pressure readings.
            self.currState = OrchStateCaptureReadingComponent;
        }
        else
        {
            [self parsingErrorHandler:error];
        }
    }
    else if (self.currState == OrchStateCaptureReadingComponent)
    {
        // currCol_ will be 0 if a blank line is encountered. Make the
        // best effort to skip it so it doesn't come up as an error. A
        // blank line will likely occur at the end of the file.
        if (self->currCol_ > 0)
        {
            NSAssert(self.currBPReading != nil, @"self.currBPReading == nil!");
            
            NSError * __autoreleasing error = nil;
            
            BPValidationResult valResult = [[BloodPressureDataAnalyzer instance] validateComponents:self.currBPReading];
            
            if (!valResult)
            {
                if ([self.dataImporter import:self.currBPReading error:&error])
                {
                    self.currBPReading = nil;
                    ++importsInBatchCount_;
                    
                    if ((importsInBatchCount_ % BatchSize) == 0)
                    {
                        [self commitImportedRecords];
                    }
                }
                else
                {
                    [self parsingErrorHandler:error];
                }
            }
            else
            {
                NSString *reason = [[BloodPressureDataAnalyzer instance] buildMsgFromValidationResults:valResult];
                
                NSString *recovery = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READINGS_INVALID_READING_DATA_RECOVERY_SUGGESTION", nil), self->currLine_];
                
                
                NSError *error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                                          BPInvalidDataInReading,
                                                          @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                                          reason,
                                                          recovery,
                                                          nil,
                                                          nil,
                                                          nil,
                                                          FailureReasonIsAString | RecoverySuggestionIsAString);
                
                [self parsingErrorHandler:error];
            }
        }
    }
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field
{
    DLog(@"BPImportOrchestrator: didReadField called, field = %@", field);

    if ([self orchestrationCanceled])
    {
        return;
    }

    NSError * __autoreleasing error = nil;
    
    if (self.currState == OrchStateCheckForColumnHeadings)
    {
        ZAssert(currCol_ == 0, @"Expected currCol_ to be 0, currCol_ = %lu", (unsigned long)currCol_);
        
        if ([self captureColumnDefinition:field error:&error])
        {
            self.currState = OrchStateCaptureColumnMappings;
            
            return;
        }
        
        // No column definition, attempt to treat this as a value.
        [self setupColumnOrderingFromDefaults];

        self.currState = OrchStateCaptureReadingComponent;
    }
    
    BOOL fieldProcessed = NO;
    
    if (self.currState == OrchStateCaptureColumnMappings)
    {
        fieldProcessed = [self captureColumnDefinition:field error:&error];
    }
    else if (self.currState == OrchStateCaptureReadingComponent)
    {
        fieldProcessed = [self populateCurrReadingWithFieldData:field error:&error];
    }
    else
    {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"IMPORT_READINGS_UNEXPECTED_ERROR_REASON", nil), self->currLine_];
        
        error = makeNSErrorFromResources(BPDataImportErrorDomain,
                                         BPIUnknownError,
                                         @"IMPORT_READINGS_FAILURE_DESCRIPTION",
                                         reason,
                                         @"IMPORT_READINGS_RESTART_APPLICATION_RECOVERY_SUGGESTION",
                                         nil,
                                         nil,
                                         nil,
                                         FailureReasonIsAString);
    }
    
    if (!fieldProcessed && (error != nil))
    {
        [self parsingErrorHandler:error];
    }
}

- (void)parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile
{
    DLog(@"BPImportOrchestrator: didEndDocument called, filename = %@", csvFile);

    if ([self orchestrationCanceled])
    {
        return;
    }
    
    if (self.currState == OrchStateCaptureReadingComponent)
    {
        if (importsInBatchCount_ !=0)
        {
            if ([self commitImportedRecords])
            {
                // Notify the delegate that the import is completed.
                [self.delegate importOrchestrator:self
                 totalRecordsImported:self.numRecordsImported
                              totalRecordsUpdated:self.numRecordsUpdated
                                      wasCanceled:NO];
            }
        }
    }
    
    self.currState = OrchStateFinSuccess;
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error
{
    DLog(@"BPImportOrchestrator: didFailWithError called, description = %@", error.localizedDescription);
}

@end
