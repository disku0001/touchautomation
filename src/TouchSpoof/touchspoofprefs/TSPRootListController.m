#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface TSPRootListController : PSListController
@end

@implementation TSPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

@end
