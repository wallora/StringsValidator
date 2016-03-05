//
//  NSObject_Extension.m
//  StringsValidator
//
//  Created by Paolo Ardia on 27/02/16.
//  Copyright © 2016 Paolo Ardia. All rights reserved.
//


#import "NSObject_Extension.h"
#import "StringsValidator.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[StringsValidator alloc] initWithBundle:plugin];
        });
    }
}
@end
