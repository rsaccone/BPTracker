//
//  BPDataImportError.h
//  BPTracker
//
//  Created by Robert Saccone on 12/28/12.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

extern NSString *const BPDataImportErrorDomain;

enum BPDataImportErrors
{
    BPIUnknownError                     = -1,
    BPIDuplicateReadingDateInSource     = -2,
    BPIDuplicateReadingDetectionFailed  = -3,
    BPIInvalidManagedObjectContext      = -4,
    BPIFileDoesNotExist                 = -5,
    BPIInvalidFileFormat                = -6,
    BPIImportFileMissingColumn          = -7,
    BPIInvalidDataInColumn              = -8,
    BPImportFileContainsTooManyColumns  = -9,
    BPInvalidDataInReading              = -10,
    BPInvalidColumnName                 = -11,
    BPInvalidDateTimeData               = -12,
    BPInvalidColumnNameInternal         = -13
};

