//
//  BPValidator.m
//  BPTracker
//
//  Created by Robert Saccone on 4/8/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "BloodPressureDataAnalyzer.h"

#import <SLexUtil/NumericUtil.h>
#import "BloodPressureReading.h"

#define MIN_SYSTOLIC      1
#define MIN_DIASTOLIC     1
#define MAX_SYSTOLIC    250
#define MAX_DIASTOLIC   160
#define MIN_PULSE       0
#define MAX_PULSE       220
#define MIN_WEIGHT      1
#define MAX_WEIGHT      3000
    
#define NORMAL_SYSTOLIC     120
#define NORMAL_DIASTOLIC    80

@interface BloodPressureDataAnalyzer ()

- (NSString *)rangeDescriptionForComponent:(BPComponent)component;

@end

@implementation BloodPressureDataAnalyzer
{
@private
    short minSystolic_;
    short minDiastolic_;
    short maxSystolic_;
    short maxDiastolic_;
    short minPulse_;
    short maxPulse_;
    short minWeight_;
    short maxWeight_;
}

@synthesize minSystolic = minSystolic_;
@synthesize minDiastolic = minDiastolic_;
@synthesize maxSystolic = maxSystolic_;
@synthesize maxDiastolic =maxDiastolic_;
@synthesize minPulse = minPulse_;
@synthesize maxPulse = maxPulse_;
@synthesize minWeight = minWeight_;
@synthesize maxWeight = maxWeight_;

static BloodPressureDataAnalyzer *theInstance = nil;
static NSDictionary *valErrorToErrantComponent = nil;
static NSDictionary *bpComponentToLocalizedNameStrKey = nil;
static NSArray *missingComponentNames = nil;

struct BPComponentCategoryPair
{
    short limit;
    enum BloodPressureCategory category;
};

static const struct BPComponentCategoryPair systolicComponentCategories[] =
{
    { 90,  Low },
    { 100, Low_Normal },
    { 119, Normal },
    { 139, Prehypertension_Borderline },
    { 159, Stage1_Mild_Hypertension },
    { 179, Stage2_Moderate_Hypertension },
    { 209, Stage3_Severe_Hypertension },
    { 229, Stage4_Very_Severe_Hypertension }
};

static const struct BPComponentCategoryPair diastolicComponentCategories[] =
{
    { 59,  Low },
    { 74,  Low_Normal },
    { 79,  Normal },
    { 89,  Prehypertension_Borderline },
    { 99, Stage1_Mild_Hypertension },
    { 109, Stage2_Moderate_Hypertension },
    { 119, Stage3_Severe_Hypertension },
    { 139, Stage4_Very_Severe_Hypertension }
};

static BPValidationResult missingComponentChecks[] =
{
    BPValDateMissing,
    BPValSystolicMissing,
    BPValDiastolicMissing,
    BPValPulseMissing,
    BPValWeightMissing
};

static BPValidationResult invalidComponentChecks[] =
{
    BPValSystolicInvalid,
    BPValDiastolicInvalid,
    BPValPulseInvalid,
    BPValWeightInvalid,
    BPValDateInvalid
};

+ (BloodPressureDataAnalyzer *)instance
{
    if (theInstance == nil)
        theInstance = [[BloodPressureDataAnalyzer alloc] init];
    
    return theInstance;
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
    static dispatch_once_t initOnce;
    
    dispatch_once(&initOnce, ^{
        missingComponentNames =
        @[
          @"DATE_COMPONENT_NAME",
          @"SYSTOLIC_COMPONENT_NAME",
          @"DIASTOLIC_COMPONENT_NAME",
          @"PULSE_COMPONENT_NAME",
          @"WEIGHT_COMPONENT_NAME"
          ];
        
        valErrorToErrantComponent =
        @{
          @(BPValSystolicMissing) : @(SystolicComponent),
          @(BPValDiastolicMissing) : @(DiastolicComponent),
          @(BPValPulseMissing) : @(PulseComponent),
          @(BPValWeightMissing) : @(WeightComponent),
          @(BPValDateMissing) : @(DateComponent),
          @(BPValSystolicInvalid) : @(SystolicComponent),
          @(BPValDiastolicInvalid) : @(DiastolicComponent),
          @(BPValPulseInvalid) : @(PulseComponent),
          @(BPValWeightInvalid) : @(WeightComponent),
          @(BPValDateInvalid) : @(DateComponent)
          };
        
        bpComponentToLocalizedNameStrKey =
        @{
          @(SystolicComponent) : @"SYSTOLIC_COMPONENT_NAME",
          @(DiastolicComponent) : @"DIASTOLIC_COMPONENT_NAME",
          @(DateComponent) : @"DATE_COMPONENT_NAME",
          @(WeightComponent) : @"WEIGHT_COMPONENT_NAME",
          @(PulseComponent) : @"PULSE_COMPONENT_NAME"
        };
    });
    
    self = [super init];
    
    if (self)
    {
        minSystolic_    = MIN_SYSTOLIC;
        minDiastolic_   = MIN_DIASTOLIC;
        maxSystolic_    = MAX_SYSTOLIC;
        maxDiastolic_   = MAX_DIASTOLIC;
        minPulse_       = MIN_PULSE;
        maxPulse_       = MAX_PULSE;
        minWeight_      = MIN_WEIGHT;
        maxWeight_      = MAX_WEIGHT;
    }
    
    return self;
}

#pragma mark -
#pragma mark Interface Methods

- (BOOL)isSystolicInRange:(short)systolic
{
    if ((systolic >= minSystolic_) && (systolic <= maxSystolic_))
        return YES;
        
    return NO;
}

- (BOOL)isDiastolicInRange:(short)diastolic
{
    if ((diastolic >= minDiastolic_) && (diastolic <= maxDiastolic_))
        return YES;
    
    return NO;
}

- (BOOL)isPulseInRange:(short)pulse
{
    if ((pulse >= minPulse_) && (pulse <= maxPulse_))
        return YES;
    
    return NO;
}

- (BOOL)isWeightInRange:(short)weight
{
    if (weight >= minWeight_)
        return YES;
          
    return NO;
}

- (BPValidationResult)validateComponents:(BloodPressureReading *)bpReading
{
    ZAssert(bpReading != nil, @"bpReading == nil");
    
    BPValidationResult result = BPValSuccess;
    
    if (bpReading.readingDate == nil)
    {
        result |= BPValDateMissing;
    }
    
    if (bpReading.systolic != nil)
    {
        if (![self isSystolicInRange:[bpReading.systolic shortValue]])
        {
            result |= BPValSystolicInvalid;
        }
    }
    else
    {
        result |= BPValSystolicMissing;
    }
    
    if (bpReading.diastolic != nil)
    {
        if (![self isDiastolicInRange:[bpReading.diastolic shortValue]])
        {
            result |= BPValDiastolicInvalid;
        }
    }
    else
    {
        result |= BPValDateMissing;
    }
    
    if (bpReading.pulse != nil)
    {
        if (![self isPulseInRange:[bpReading.pulse shortValue]])
        {
            result |= BPValPulseInvalid;
        }
    }
    else
    {
        result |= BPValPulseMissing;
    }

    if (bpReading.weight != nil)
    {
        if (![self isWeightInRange:[bpReading.weight shortValue]])
        {
            result |= BPValWeightInvalid;
        }
    }
    else
    {
        result |= BPValWeightMissing;
    }
    
    return result;
}

- (NSString *)rangeDescriptionForComponent:(BPComponent)component
{
    short min = 0;
    short max = 0;
    
    NSString *formatString = nil;
    
    switch (component)
    {
        case SystolicComponent:
            min = self.minSystolic;
            max = self.maxSystolic;
            formatString = NSLocalizedString(@"RANGE_OF_READING", nil);
            break;
            
        case DiastolicComponent:
            min = self.minDiastolic;
            max = self.maxDiastolic;
            formatString = NSLocalizedString(@"RANGE_OF_READING", nil);
            break;
            
        case PulseComponent:
            min = self.minPulse;
            max = self.maxPulse;
            formatString = NSLocalizedString(@"RANGE_OF_READING", nil);
            break;
            
        case WeightComponent:
            min = self.minWeight;
            max = self.maxWeight;
            formatString = NSLocalizedString(@"RANGE_OF_READING", nil);
            break;
            
        default:
            ZAssert(NO, @"Component (%u) doesn't have a range of valid of values.", component);
            return nil;
    }
    
    NSString *componentName = NSLocalizedString(bpComponentToLocalizedNameStrKey[[NSNumber numberWithUnsignedInt:component]], nil);
    
    return [NSString stringWithFormat:formatString, componentName, min, max];
}

- (NSString *)localizedNameForBPComponent:(BPComponent)component;
{
    switch (component)
    {
        case SystolicComponent:
            return NSLocalizedString(@"SYSTOLIC_COMPONENT_NAME", nil);
            
        case DiastolicComponent:
            return NSLocalizedString(@"DIASTOLIC_COMPONENT_NAME", nil);
            
        case PulseComponent:
            return NSLocalizedString(@"PULSE_COMPONENT_NAME", nil);

        case WeightComponent:
            return NSLocalizedString(@"WEIGHT_COMPONENT_NAME", nil);
            
        case DateComponent:
           return NSLocalizedString(@"DATE_COMPONENT_NAME", nil);
            
        default:
            return nil;
    }
}

- (NSString *)validValuesDescriptionForComponent:(BPComponent)component
{
    NSString *desc = nil;
    
    switch (component)
    {
        case SystolicComponent:
        case DiastolicComponent:
        case PulseComponent:
        case WeightComponent:
            desc = [self rangeDescriptionForComponent:component];
            break;

        case DateComponent:
            desc = NSLocalizedString(@"DATE_COMPONENT_DESCRIPTION", nil);
            break;
            
        default:
            ALog(@"Unexpected component %u", component);
            break;
    }
    
    return desc;
}

- (NSString *)buildMsgFromValidationResults:(BPValidationResult)bpValResult
{
    NSMutableString *msg = nil;
    
    if (bpValResult)
    {
        msg = [[NSMutableString alloc] init];
        
        size_t count;
        
        if (bpValResult & BPComponentsMissing)
        {
            // Create messages for missing components
            count = COUNT_OF(missingComponentChecks);
            
            for (size_t i = 0; i < count; ++i)
            {
                if (bpValResult & missingComponentChecks[i])
                {
                    if (msg.length != 0)
                    {
                        [msg appendString:@"\n"];
                    }
                    
                    [msg appendFormat:NSLocalizedString(@"BP_READING_COMPONENT_MISSING", nil), NSLocalizedString(missingComponentNames[i], nil)];
                }
            }
        }
        
        if (bpValResult & BPComponentsInvalid)
        {
            count = COUNT_OF(invalidComponentChecks);
            
            for (size_t i = 0; i < count; ++i)
            {
                short min;
                short max;

                if (bpValResult & invalidComponentChecks[i])
                {
                    NSString *formatString = nil;
                    
                    switch (invalidComponentChecks[i])
                    {
                    case BPValDiastolicInvalid:
                            min = self.minDiastolic;
                            max = self.maxDiastolic;
                            formatString = NSLocalizedString(@"BP_READING_COMPONENT_OUT_OF_RANGE", nil);
                            break;

                    case BPValSystolicInvalid:
                            min = self.minSystolic;
                            max = self.maxSystolic;
                            formatString = NSLocalizedString(@"BP_READING_COMPONENT_OUT_OF_RANGE", nil);
                            break;
                            
                    case BPValPulseInvalid:
                            min = self.minPulse;
                            max = self.maxPulse;
                            formatString = NSLocalizedString(@"PULSE_READING_OUT_OF_RANGE", nil);
                            break;
                            
                    case BPValWeightInvalid:
                            min = self.minWeight;
                            max = self.maxWeight;
                            formatString = NSLocalizedString(@"WEIGHT_OUT_OF_RANGE", nil);
                            break;
                            
                    default:
                            ALog(@"Unexpected invalid component check %u", invalidComponentChecks[i]);
                            formatString = nil;
                            break;
                    }
                    
                    if (formatString != nil)
                    {
                        NSNumber* errComponent = valErrorToErrantComponent[[NSNumber numberWithUnsignedInt:invalidComponentChecks[i]]];
                        
                        NSString *compStringKey = bpComponentToLocalizedNameStrKey[errComponent];
                        NSString *componentName = NSLocalizedString(compStringKey, nil);
                        
                        if (msg.length != 0)
                        {
                            [msg appendString:@"\n"];
                        }
                        
                        [msg appendFormat:formatString, componentName, min, max];
                    }
                }
            }
        }
    }
    
    return msg;
}

static const struct BPComponentCategoryPair *mapBloodPressure(short compReading,
                                                              const struct BPComponentCategoryPair *compCat,
                                                              size_t compCatSize)
{
    const struct BPComponentCategoryPair *compCatEnd = compCat + compCatSize;
    
    while (compCat < compCatEnd)
    {
        if (compReading <= compCat->limit)
        {
            return compCat;
        }
        
        ++compCat;
    }
    
    return --compCatEnd;
}

- (enum BloodPressureCategory)systolicCategory:(short)systolic
{
    const struct BPComponentCategoryPair *compCat = mapBloodPressure(systolic,
                                                                     systolicComponentCategories,
                                                                     COUNT_OF(systolicComponentCategories));
    
    NSAssert(compCat != 0, @"Systolic component category not found!");
    
    return compCat->category;
}

- (enum BloodPressureCategory)diastolicCategory:(short)diastolic
{
    const struct BPComponentCategoryPair *compCat = mapBloodPressure(diastolic,
                                                                     diastolicComponentCategories,
                                                                     COUNT_OF(diastolicComponentCategories));
    
    NSAssert(compCat != 0, @"Diastolic component category not found!");
    
    return compCat->category;
}

- (enum BloodPressureCategory)systolicComponent:(short)systolic diastolicComponent:(short)diastolic
{
    enum BloodPressureCategory systolicCat = [self systolicCategory:systolic];
    enum BloodPressureCategory diastolicCat = [self diastolicCategory:diastolic];
    
    // Category is the higher of the two component readings.
    return (systolicCat > diastolicCat) ? systolicCat : diastolicCat;
}

- (enum BloodPressureCategory)bloodPressureReadingCategory:(BloodPressureReading *)bpReading
{
    return [self systolicComponent:[[bpReading systolic] shortValue] 
                diastolicComponent:[[bpReading diastolic] shortValue]];
}

- (double)meanArterialPressureFromSystolicReading:(short)systolic diastolicReading:(short)diastolic
{
    return (double)diastolic + (((double)(systolic - diastolic)) / 3.0);
}

- (double)meanArterialPressureFromBloodPressureReading:(BloodPressureReading *)bpReading;
{
    return [self meanArterialPressureFromSystolicReading:[bpReading.systolic shortValue] 
                                        diastolicReading:[bpReading.diastolic shortValue]];
}

// Top number (systolic) in mm Hg	 	Bottom number (diastolic) in mm Hg	Your category*	What to do**
// Below 120	and	Below 80	Normal blood pressure	Maintain or adopt a healthy lifestyle.
// 120-139	or	80-89	Prehypertension	Maintain or adopt a healthy lifestyle.
// 140-159	or	90-99	Stage 1 hypertension	Maintain or adopt a healthy lifestyle. If blood pressure goal isn't reached in about six months, talk to your doctor about taking one or more medications.
// 160 or more	or	100 or more	Stage 2 hypertension	Maintain or adopt a healthy lifestyle. Talk to your doctor about taking more than one medication.
// Category is the higher of systolic / diastolic


@end
