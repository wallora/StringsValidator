//
//  StringsValidator.m
//  StringsValidator
//
//  Created by Paolo Ardia on 27/02/16.
//  Copyright © 2016 Paolo Ardia. All rights reserved.
//

#import "StringsValidator.h"
#import "DTXcodeHeaders.h"
#import "DTXcodeUtils.h"
#import "StringValidatorRegex.h"

static NSString * const kRegularExpressionPattern = @"^(\"(\\S+.*\\S+)\"|(\\S+.*\\S+))\\s*=\\s*\"(.*)\";$";
static NSString * const kInlineMultipleLineCommentRegularExpressionPattern = @"(\\/\\*(.+?|.?)\\*\\/)";
static NSString * const kInlineSingleLineCommentRegularExpressionPattern = @"\";(.+?)$";
static NSString * const kStartSingleLineCommentRegularExpressionPattern = @"^(\\/\\/)(.*)$";

@interface StringsValidator()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@end

@implementation StringsValidator

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init])
    {
        // Reference to plugin's bundle, for resource access
        self.bundle = plugin;
        
        // Sample menu item, nested under the "Edit" menu item.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
            if (menuItem)
            {
                [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
                NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Validate strings"
                                                                        action:@selector(checkAction)
                                                                 keyEquivalent:@""];
                [actionMenuItem setTarget:self];
                // Set ⌃⌘X as our plugin's keyboard shortcut.
                [actionMenuItem setKeyEquivalent:@"x"];
                [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
                [[menuItem submenu] addItem:actionMenuItem];
            }
        });
    }
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    //removeObserver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
}

- (void)checkAction
{
    IDESourceCodeDocument *currentDocument = [DTXcodeUtils currentSourceCodeDocument];
    NSString *filePath = [[currentDocument fileURL] path];
    if (![@"strings" isEqualToString:filePath.pathExtension])
    {
        [self showAlertForInvalidFilePath:filePath];
        return;
    }
    NSArray *errors = [self checkFileAtPath:filePath];
    
    [self showAlertWithErrors:errors forFileAtPath:filePath];
}

- (void) showAlertForInvalidFilePath:(NSString*)path
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"This file is not a .strings"];
    [alert setInformativeText:[NSString stringWithFormat:@"The file at path: %@ is not a .strings file", path]];
    
    [alert runModal];
}

- (void) showAlertWithErrors:(NSArray *)errors forFileAtPath:(NSString*)filePath
{
    NSAlert *alert = [[NSAlert alloc] init];
    if (errors.count == 0)
    {
        [alert setMessageText:@"This file is valid."];
        [alert setInformativeText:[NSString stringWithFormat:@"Checked File: %@", filePath]];
    }
    else
    {
        [alert setMessageText:[NSString stringWithFormat:@"Oh no! There %@ %lu %@ in this file!", (errors.count == 1 ? @"is" : @"are"), errors.count, (errors.count == 1 ? @"error" : @"errors")]];
        NSMutableString *text = [NSMutableString string];
        for (int i = 0; i < MIN(10, errors.count) ; i++)
        {
            NSNumber *number = errors[i];
            [text appendFormat:@"Line %i\n", [number intValue]];
        }
        
        if (errors.count > 10)
        {
            [text appendFormat:@"\n... and other %lu %@\n", (errors.count-10), ((errors.count-10) == 1 ? @"error" : @"errors")];
        }
        [text appendFormat:@"\nChecked File: %@", filePath];
        [alert setInformativeText:text];
    }
    
    [alert runModal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Check methods

- (NSArray*)checkFileAtPath:(NSString*)path
{
    NSMutableArray *linesWithErrors = [NSMutableArray new];
    NSString *string = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
    
    // valid regex
    StringValidatorRegex *validRegularExpression = [[StringValidatorRegex alloc] initWithPattern:kRegularExpressionPattern];
    
    // regexs to sanitize
    StringValidatorRegex *multilineCommentRegularExpression = [[StringValidatorRegex alloc] initWithPattern:kInlineMultipleLineCommentRegularExpressionPattern];
    StringValidatorRegex *inlineCommentRegularExpression = [[StringValidatorRegex alloc] initWithPattern:kInlineSingleLineCommentRegularExpressionPattern range:NSMakeRange(0, 2)];
    StringValidatorRegex *startSingleLineCommentRegularExpression = [[StringValidatorRegex alloc] initWithPattern:kStartSingleLineCommentRegularExpressionPattern];
    
    __block NSInteger lineNumber = 1;
    __block BOOL multipleLineCommentBlockFound = NO;
    [string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        // Trim the line
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        BOOL valid = [self isLine:line validWithRegex:validRegularExpression regexsToSanitize:@[multilineCommentRegularExpression, inlineCommentRegularExpression, startSingleLineCommentRegularExpression] isInsideMultipleLineCommentBlock:&multipleLineCommentBlockFound];
        
        if (!valid)
        {
            NSLog(@"Line %ld is invalid", (long)lineNumber);
            [linesWithErrors addObject:@(lineNumber)];
        }
        lineNumber++;
    }];
    
    return [NSArray arrayWithArray:linesWithErrors];
}

- (BOOL) isLine:(NSString*)line validWithRegex:(StringValidatorRegex*)validRegex regexsToSanitize:(NSArray*)regexs isInsideMultipleLineCommentBlock:(BOOL*)multipleLineCommentBlock
{
    // try to validate the line
    BOOL valid = [self isLine:line validWithRegex:validRegex isInsideMultipleLineCommentBlock:multipleLineCommentBlock];
    
    if (!valid)
    {
        // invalid line, try to sanitize it
        NSString *lineCopy = [line copy];
        for (StringValidatorRegex *regex in regexs)
        {
            // after everyone loop, retry to validate it
            lineCopy = [self sanitizeLine:lineCopy withRegex:regex];
            valid = [self isLine:lineCopy validWithRegex:validRegex isInsideMultipleLineCommentBlock:multipleLineCommentBlock];
            if (valid)
            {
                break;
            }
        }
    }
    return valid;
}

- (BOOL) isLine:(NSString*)line validWithRegex:(StringValidatorRegex*)validRegex isInsideMultipleLineCommentBlock:(BOOL*)multipleLineCommentBlock
{
    // validate the line
    
    // empty line is valid
    if (line.length == 0)
    {
        return YES;
    }
    
    // if is inside a multiline comment block, check if the block ends. The line is always valid
    if (*multipleLineCommentBlock == YES)
    {
        if ([line rangeOfString:@"*/"].location != NSNotFound)
        {
            *multipleLineCommentBlock = NO;
        }
        return YES;
    }
    
    // here starts a multiline comment block. This is valid
    if ([line rangeOfString:@"/*"].location == 0 && [line rangeOfString:@"*/"].location == NSNotFound)
    {
        *multipleLineCommentBlock = YES;
        return YES;
    }
    
    NSTextCheckingResult *result = [validRegex.regularExpression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
    if (result.range.location != NSNotFound && result.numberOfRanges == 5)
    {
        NSRange keyRange = [result rangeAtIndex:2];
        NSRange valueRange = [result rangeAtIndex:4];
        // checks the ranges
        if (keyRange.location != NSNotFound && valueRange.location != NSNotFound)
        {
            NSString *key = [line substringWithRange:keyRange];
            //checks the length of the key
            if (key.length > 0)
            {
                return YES;
            }
        }
        
    }
    return NO;
}

- (NSString*)sanitizeLine:(NSString*)line withRegex:(StringValidatorRegex*)regex
{
    NSString *lineCopy = [line copy];
    NSRange range;
    do {
        range = [regex.regularExpression rangeOfFirstMatchInString:lineCopy options:0 range:NSMakeRange(0, lineCopy.length)];
        if (range.location != NSNotFound)
        {
            NSRange rangeToReplace = NSMakeRange(range.location + regex.rangeToExclude.length, range.length - regex.rangeToExclude.length);
            lineCopy = [lineCopy stringByReplacingCharactersInRange:rangeToReplace withString:@""];
        }
    } while (range.location != NSNotFound);
    return lineCopy;
}

@end
