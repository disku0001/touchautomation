#import <Foundation/Foundation.h>

@interface TSAppManager : NSObject

+ (NSArray<NSDictionary *> *)installedApps;
+ (NSArray<NSString *> *)selectedBundleIDs;
+ (void)setSelectedBundleIDs:(NSArray<NSString *> *)bundleIDs;
+ (void)selectAll;
+ (void)deselectAll;
+ (BOOL)isBundleIDSelected:(NSString *)bundleID;
+ (void)toggleBundleID:(NSString *)bundleID;

+ (void)wipeAppWithBundleID:(NSString *)bundleID;
+ (void)wipeSelectedApps;

+ (void)backup:(NSString *)name;
+ (void)restoreBackup:(NSString *)name forBundleID:(NSString *)bundleID;
+ (void)restore:(NSString *)name;
+ (void)reBackup;
+ (void)backupAndReset:(NSString *)name;

+ (void)resetDataForSelectedApps;

+ (NSArray<NSString *> *)availableBackups;

@end
