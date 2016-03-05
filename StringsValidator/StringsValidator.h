//
//  StringsValidator.h
//  StringsValidator
//
//  Created by Paolo Ardia on 27/02/16.
//  Copyright © 2016 Paolo Ardia. All rights reserved.
//

#import <AppKit/AppKit.h>

@class StringsValidator;

static StringsValidator *sharedPlugin;

@interface StringsValidator : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@end