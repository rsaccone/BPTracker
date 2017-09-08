//
//  URLHandler.h
//  BPTracker
//
//  Created by Robert Saccone on 1/31/13.
//  Copyright (c) 2017 Robert Saccone. All rights reserved.
//

#import <Foundation/Foundation.h>

@class URLHandler;

@protocol URLHandlerDelegate <NSObject>

- (void)handlerCompletion:(URLHandler * __weak)urlHandler;

@end

@interface URLHandler : NSObject

- (id)initWithURL:(NSURL *)url parentManagedObjectContext:(NSManagedObjectContext *)moc
        initError:(NSError * __autoreleasing *)initError;

- (void)begin:(id<URLHandlerDelegate>)delegate;

@property(nonatomic, readonly, assign) BOOL finished;
@property(nonatomic, readonly, assign) BOOL success;
@property(nonatomic, readonly, assign) BOOL canceled;
@property(nonatomic, readonly, strong) NSError *error;
@property(nonatomic, readonly, assign) NSUInteger recordsImportedCount;

@end
