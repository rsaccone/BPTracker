//
//  ManagedObjFieldInfo.m
//  BPTracker
//
//  Created by Robert Saccone on 1/4/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import "ManagedObjFieldInfo.h"

@implementation ManagedObjFieldInfo
{
@private
    NSString *fieldName_;
    FieldType fieldType_;
    BOOL optional_;
}

@synthesize fieldName = fieldName_;
@synthesize fieldType = fieldType_;
@synthesize optional = optional_;

- (id)initWithFieldName:(NSString *)name fieldType:(FieldType)type optional:(BOOL)optionalFlag
{
    ZAssert(name != nil, @"name == nil");
    
    self = [super init];
    
    if (self != nil)
    {
        fieldName_ = name;
        fieldType_ = type;
        optional_ = optionalFlag;
    }
    
    return self;
}

- (id) initWithFieldName:(NSString *)name fieldType:(FieldType)type
{
    return [self initWithFieldName:name fieldType:type optional:NO];
}

@end

