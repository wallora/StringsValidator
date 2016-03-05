//
//  StringValidatorRegex.m
//  StringsValidator
//
//  Created by Paolo Ardia on 28/02/16.
//  Copyright © 2016 Paolo Ardia. All rights reserved.
//

#import "StringValidatorRegex.h"

@implementation StringValidatorRegex

- (instancetype)initWithPattern:(NSString *)pattern range:(NSRange)range
{
    self = [super init];
    if (self)
    {
        self.regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        self.rangeToExclude = range;
    }
    return self;
}

- (instancetype)initWithPattern:(NSString *)pattern
{
    return [self initWithPattern:pattern range:NSMakeRange(0, 0)];
}

@end
