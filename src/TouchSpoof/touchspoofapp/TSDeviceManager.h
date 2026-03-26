#import <Foundation/Foundation.h>

@interface TSDeviceManager : NSObject

+ (NSDictionary *)currentDeviceInfo;
+ (NSString *)currentModel;
+ (NSString *)currentVersion;
+ (NSString *)currentIDFA;
+ (NSString *)currentUDID;

+ (NSDictionary *)readDataJSON;
+ (void)writeDataJSON:(NSDictionary *)data;

+ (NSArray<NSDictionary *> *)devicePresets;
+ (NSDictionary *)presetForName:(NSString *)name;

+ (NSArray<NSString *> *)firmwareList;

+ (void)applyPreset:(NSDictionary *)preset;
+ (void)resetConfig;

@end
