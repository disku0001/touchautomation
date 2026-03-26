#import "TSDeviceManager.h"
#import <UIKit/UIKit.h>
#import <AdSupport/ASIdentifierManager.h>
#import <sys/utsname.h>

static NSString *const kDataPath = @"/var/jb/Library/PreferenceLoader/Preferences/data.json";

@implementation TSDeviceManager

#pragma mark - Device Info

+ (NSDictionary *)currentDeviceInfo {
    NSDictionary *saved = [self readDataJSON];
    NSString *model = saved[@"model"] ?: [self hardwareModel];
    NSString *version = saved[@"version"] ?: [[UIDevice currentDevice] systemVersion];
    NSString *idfa = saved[@"idfa"] ?: [self hardwareIDFA];
    NSString *udid = saved[@"udid"] ?: [self hardwareUDID];

    return @{
        @"model": model,
        @"version": version,
        @"idfa": idfa,
        @"udid": udid
    };
}

+ (NSString *)currentModel {
    return [self currentDeviceInfo][@"model"];
}

+ (NSString *)currentVersion {
    return [self currentDeviceInfo][@"version"];
}

+ (NSString *)currentIDFA {
    return [self currentDeviceInfo][@"idfa"];
}

+ (NSString *)currentUDID {
    return [self currentDeviceInfo][@"udid"];
}

#pragma mark - Hardware Reads

+ (NSString *)hardwareModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (NSString *)hardwareIDFA {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

+ (NSString *)hardwareUDID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

#pragma mark - Data JSON

+ (NSDictionary *)readDataJSON {
    NSData *data = [NSData dataWithContentsOfFile:kDataPath];
    if (!data) return @{};
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return json ?: @{};
}

+ (void)writeDataJSON:(NSDictionary *)data {
    NSString *dir = [kDataPath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    [jsonData writeToFile:kDataPath atomically:YES];
}

#pragma mark - Device Presets

+ (NSArray<NSDictionary *> *)devicePresets {
    return @[
        @{@"name": @"iPhone 14",      @"model": @"iPhone15,2", @"board": @"D73AP",  @"chip": @"A15"},
        @{@"name": @"iPhone 14 Plus", @"model": @"iPhone15,3", @"board": @"D74AP",  @"chip": @"A15"},
        @{@"name": @"iPhone 14 Pro",  @"model": @"iPhone15,4", @"board": @"D73pAP", @"chip": @"A16"},
        @{@"name": @"iPhone 14 Pro Max", @"model": @"iPhone15,5", @"board": @"D74pAP", @"chip": @"A16"},
        @{@"name": @"iPhone 15",      @"model": @"iPhone16,1", @"board": @"D37AP",  @"chip": @"A16"},
        @{@"name": @"iPhone 15 Plus", @"model": @"iPhone16,2", @"board": @"D38AP",  @"chip": @"A16"},
        @{@"name": @"iPhone 15 Pro",  @"model": @"iPhone16,3", @"board": @"D83AP",  @"chip": @"A17"},
        @{@"name": @"iPhone 15 Pro Max", @"model": @"iPhone16,4", @"board": @"D84AP", @"chip": @"A17"},
        @{@"name": @"iPhone 16",      @"model": @"iPhone17,1", @"board": @"D47AP",  @"chip": @"A18"},
        @{@"name": @"iPhone 16 Plus", @"model": @"iPhone17,2", @"board": @"D48AP",  @"chip": @"A18"},
        @{@"name": @"iPhone 16 Pro",  @"model": @"iPhone17,3", @"board": @"D93AP",  @"chip": @"A18Pro"},
        @{@"name": @"iPhone 16 Pro Max", @"model": @"iPhone17,4", @"board": @"D94AP", @"chip": @"A18Pro"},
    ];
}

+ (NSDictionary *)presetForName:(NSString *)name {
    for (NSDictionary *preset in [self devicePresets]) {
        if ([preset[@"name"] isEqualToString:name]) return preset;
    }
    return nil;
}

#pragma mark - Firmware List

+ (NSArray<NSString *> *)firmwareList {
    return @[
        @"15.0", @"15.1", @"15.2", @"15.3", @"15.4", @"15.5", @"15.6", @"15.7",
        @"16.0", @"16.1", @"16.2", @"16.3", @"16.4", @"16.5", @"16.6", @"16.7",
        @"17.0", @"17.1", @"17.2", @"17.3", @"17.4", @"17.5", @"17.6", @"17.7",
        @"18.0", @"18.1", @"18.2", @"18.3",
    ];
}

#pragma mark - Apply / Reset

+ (void)applyPreset:(NSDictionary *)preset {
    NSMutableDictionary *data = [[self readDataJSON] mutableCopy];
    if (preset[@"model"]) data[@"model"] = preset[@"model"];
    if (preset[@"board"]) data[@"board"] = preset[@"board"];
    if (preset[@"chip"])  data[@"chip"]  = preset[@"chip"];
    if (preset[@"name"])  data[@"deviceName"] = preset[@"name"];
    [self writeDataJSON:data];
    NSLog(@"[TouchSpoof] Applied preset: %@", preset[@"name"]);
}

+ (void)resetConfig {
    [[NSFileManager defaultManager] removeItemAtPath:kDataPath error:nil];
    NSLog(@"[TouchSpoof] Config reset to defaults");
}

@end
