//
//  ManagedObjFieldInfo.h
//  BPTracker
//
//  Created by Robert Saccone on 1/4/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum FieldType : uint32_t
{
    DateFieldType,
    StringFieldType,
    ShortFieldType,
    IntFieldType
} FieldType;

@interface ManagedObjFieldInfo : NSObject


- (id)initWithFieldName:(NSString *)name fieldType:(FieldType)type;

- (id)initWithFieldName:(NSString *)name fieldType:(FieldType)type optional:(BOOL)optionalFlag;

@property(nonatomic, copy) NSString *fieldName;
@property(nonatomic, assign) FieldType fieldType;
@property(nonatomic, assign) BOOL optional;

@end
