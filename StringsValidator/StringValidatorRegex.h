//
//  StringValidatorRegex.h
//  StringsValidator
//
//  Created by Paolo Ardia on 28/02/16.
//  Copyright © 2016 Paolo Ardia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StringValidatorRegex : NSObject

@property (nonatomic, strong) NSRegularExpression *regularExpression;
@property (nonatomic, assign) NSRange rangeToExclude;

- (instancetype) initWithPattern:(NSString*)pattern;
- (instancetype) initWithPattern:(NSString*)pattern range:(NSRange)range;

@end
