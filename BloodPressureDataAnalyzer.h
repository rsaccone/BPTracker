//
//  BPValidator.h
//  BPTracker
//
//  Created by Robert Saccone on 4/8/11.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BloodPressureReading;

enum BloodPressureCategory
{
    Low = 0,
    Low_Normal,
    Normal,
    Prehypertension_Borderline,
    Stage1_Mild_Hypertension,
    Stage2_Moderate_Hypertension,
    Stage3_Severe_Hypertension,
    Stage4_Very_Severe_Hypertension
};

typedef enum BPComponent : uint32_t
{
    NoComponent         = 0x00000000,
    SystolicComponent   = 0x00000001,
    DiastolicComponent  = 0x00000002,
    PulseComponent      = 0x00000004,
    WeightComponent     = 0x00000008,
    DateComponent       = 0x00000010
} BPComponent;

typedef enum BPValidationResult : uint32_t
{
    BPValSuccess            = 0UL,
    BPValSystolicMissing    = 1UL << 0,
    BPValDiastolicMissing   = 1UL << 1,
    BPValPulseMissing       = 1UL << 2,
    BPValWeightMissing      = 1UL << 3,
    BPValDateMissing        = 1UL << 4,
    BPValSystolicInvalid    = 1UL << 5,
    BPValDiastolicInvalid   = 1UL << 6,
    BPValPulseInvalid       = 1UL << 7,
    BPValWeightInvalid      = 1UL << 8,
    BPValDateInvalid        = 1UL << 9,
    BPComponentsMissing     = (BPValSystolicMissing | BPValDiastolicMissing | BPValPulseMissing | BPValWeightMissing | BPValDateMissing),
    BPComponentsInvalid     = (BPValSystolicInvalid | BPValDiastolicInvalid | BPValPulseInvalid | BPValWeightInvalid | BPValDateInvalid)
} BPValidationResult;


@interface BloodPressureDataAnalyzer : NSObject 

+ (BloodPressureDataAnalyzer *)instance;
- (id)init;
- (BOOL)isSystolicInRange:(short)systolic;
- (BOOL)isDiastolicInRange:(short)diastolic;
- (BOOL)isPulseInRange:(short)pulse;
- (BOOL)isWeightInRange:(short)weight;
- (BPValidationResult)validateComponents:(BloodPressureReading *)bpReading;

//TODO: Revisit the names of the following methods. Should these even belong to this class?
- (NSString *)localizedNameForBPComponent:(BPComponent)component;
- (NSString *)buildMsgFromValidationResults:(BPValidationResult)bpValResult;
- (NSString *)validValuesDescriptionForComponent:(BPComponent)component;

- (double)meanArterialPressureFromSystolicReading:(short)systolic diastolicReading:(short)diastolic;
- (double)meanArterialPressureFromBloodPressureReading:(BloodPressureReading *)bpReading;
- (enum BloodPressureCategory)systolicCategory:(short) systolic;
- (enum BloodPressureCategory)diastolicCategory:(short) diastolic;
- (enum BloodPressureCategory)systolicComponent:(short) systolic diastolicComponent:(short)diastolic;
- (enum BloodPressureCategory)bloodPressureReadingCategory:(BloodPressureReading *)bpReading;

@property(nonatomic, readonly) short minSystolic;
@property(nonatomic, readonly) short minDiastolic;
@property(nonatomic, readonly) short maxSystolic;
@property(nonatomic, readonly) short maxDiastolic;
@property(nonatomic, readonly) short minPulse;
@property(nonatomic, readonly) short maxPulse;
@property(nonatomic, readonly) short minWeight;
@property(nonatomic, readonly) short maxWeight;

@end
