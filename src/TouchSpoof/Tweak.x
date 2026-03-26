/*
 * TouchSpoof - Device Spoofing Tweak
 * All features work locally, no server/login required.
 * Settings via PreferenceLoader (Settings app).
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreMotion/CoreMotion.h>
#import <AdSupport/ASIdentifierManager.h>
#import <WebKit/WebKit.h>
#import <sys/sysctl.h>
#import <dlfcn.h>
#import <objc/runtime.h>

// MobileGestalt
extern CFPropertyListRef MGCopyAnswer(CFStringRef property);

// ============================================================
// Global config - loaded from plist
// ============================================================

// Feature toggles
static BOOL gFakeDevice = YES;
static BOOL gFakeHardware = YES;
static BOOL gFakeLocation = YES;
static BOOL gFakeAds = YES;
static BOOL gFakeScreen = YES;
static BOOL gFakeBrowser = YES;
static BOOL gFakeDateTime = YES;
static BOOL gFakeNetwork = YES;
static BOOL gFakeLocale = YES;
static BOOL gFakeSensor = YES;
static BOOL gFakeSysctl = YES;
static BOOL gFakeWifiInfo = YES;
static BOOL gFakeSysOSVersion = YES;

// Fake values
static NSString *gDeviceName = @"iPhone";
static NSString *gDeviceModel = @"iPhone15,2";
static NSString *gSystemVersion = @"17.0";
static NSString *gUDID = nil;
static NSString *gIDFA = nil;
static NSString *gIDFV = nil;
static double gLatitude = 0.0;
static double gLongitude = 0.0;
static CGFloat gScreenW = 390.0;
static CGFloat gScreenH = 844.0;
static CGFloat gScreenScale = 3.0;
static NSString *gUserAgent = nil;
static NSString *gTimezone = nil;
static NSInteger gTimezoneOffset = 0;
static NSString *gLocaleID = nil;
static NSString *gCarrierName = nil;
static NSString *gMCC = nil;
static NSString *gMNC = nil;
static NSString *gSSID = nil;
static NSString *gBSSID = nil;
static NSString *gWifiMAC = nil;

#define PREFS_PATH @"/var/jb/Library/PreferenceLoader/Preferences/fSettings.plist"
#define GENERAL_PATH @"/var/jb/Library/PreferenceLoader/Preferences/generalSettings.plist"
#define DATA_PATH @"/var/jb/Library/PreferenceLoader/Preferences/data.json"

static void loadSettings() {
    NSDictionary *fPrefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    __unused NSDictionary *gPrefs = [NSDictionary dictionaryWithContentsOfFile:GENERAL_PATH];

    if (fPrefs) {
        gFakeDevice = [fPrefs[@"fakeDevice"] boolValue];
        gFakeHardware = [fPrefs[@"fakeHardware"] boolValue];
        gFakeLocation = [fPrefs[@"fakeLocation"] boolValue];
        gFakeAds = [fPrefs[@"fakeAds"] boolValue];
        gFakeScreen = [fPrefs[@"fakeScreen"] boolValue];
        gFakeBrowser = [fPrefs[@"fakeBrowser"] boolValue];
        gFakeDateTime = [fPrefs[@"fakeDateTime"] boolValue];
        gFakeNetwork = [fPrefs[@"fakeNetWork"] boolValue];
        gFakeLocale = [fPrefs[@"fakeLocale"] boolValue];
        gFakeSensor = [fPrefs[@"fakeSensor"] boolValue];
        gFakeSysctl = [fPrefs[@"fakeSysctl"] boolValue];
        gFakeWifiInfo = [fPrefs[@"fakeWifiInfo"] boolValue];
        gFakeSysOSVersion = [fPrefs[@"fakeSysOSVersion"] boolValue];
    }

    // Load fake values from data.json
    NSData *jsonData = [NSData dataWithContentsOfFile:DATA_PATH];
    if (jsonData) {
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        if (data) {
            if (data[@"deviceName"]) gDeviceName = data[@"deviceName"];
            if (data[@"model"]) gDeviceModel = data[@"model"];
            if (data[@"systemVersion"]) gSystemVersion = data[@"systemVersion"];
            if (data[@"udid"]) gUDID = data[@"udid"];
            if (data[@"idfa"]) gIDFA = data[@"idfa"];
            if (data[@"idfv"]) gIDFV = data[@"idfv"];
            if (data[@"latitude"]) gLatitude = [data[@"latitude"] doubleValue];
            if (data[@"longitude"]) gLongitude = [data[@"longitude"] doubleValue];
            if (data[@"screenW"]) gScreenW = [data[@"screenW"] floatValue];
            if (data[@"screenH"]) gScreenH = [data[@"screenH"] floatValue];
            if (data[@"screenScale"]) gScreenScale = [data[@"screenScale"] floatValue];
            if (data[@"useragent"]) gUserAgent = data[@"useragent"];
            if (data[@"timezone"]) gTimezone = data[@"timezone"];
            if (data[@"timezone_offset"]) gTimezoneOffset = [data[@"timezone_offset"] integerValue];
            if (data[@"locale"]) gLocaleID = data[@"locale"];
            if (data[@"carriername"]) gCarrierName = data[@"carriername"];
            if (data[@"mcc"]) gMCC = data[@"mcc"];
            if (data[@"mnc"]) gMNC = data[@"mnc"];
            if (data[@"ssid"]) gSSID = data[@"ssid"];
            if (data[@"bssid"]) gBSSID = data[@"bssid"];
            if (data[@"wifi_mac"]) gWifiMAC = data[@"wifi_mac"];
        }
    }
}

// ============================================================
#pragma mark - fakeDevice (UIDevice hooks)
// ============================================================

%group FakeDevice

%hook UIDevice
- (NSString *)name {
    return gDeviceName ?: %orig;
}
- (NSString *)model {
    return @"iPhone";
}
- (NSString *)systemVersion {
    return gSystemVersion ?: %orig;
}
- (NSUUID *)identifierForVendor {
    if (gIDFV) {
        return [[NSUUID alloc] initWithUUIDString:gIDFV];
    }
    return %orig;
}
%end

%end // FakeDevice

// ============================================================
#pragma mark - fakeAds (Advertising ID)
// ============================================================

%group FakeAds

%hook ASIdentifierManager
- (NSUUID *)advertisingIdentifier {
    if (gIDFA) {
        return [[NSUUID alloc] initWithUUIDString:gIDFA];
    }
    return [[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"];
}
- (BOOL)isAdvertisingTrackingEnabled {
    return NO;
}
%end

%end // FakeAds

// ============================================================
#pragma mark - fakeLocation (CLLocation hooks)
// ============================================================

%group FakeLocation

%hook CLLocationManager
- (CLLocation *)location {
    if (gLatitude != 0.0 || gLongitude != 0.0) {
        CLLocationCoordinate2D fakeCoord = CLLocationCoordinate2DMake(gLatitude, gLongitude);
        return [[CLLocation alloc] initWithCoordinate:fakeCoord
                                             altitude:50.0
                                   horizontalAccuracy:10.0
                                     verticalAccuracy:10.0
                                            timestamp:[NSDate date]];
    }
    return %orig;
}

- (void)setDelegate:(id<CLLocationManagerDelegate>)delegate {
    %orig;
}
%end

%hook CLLocation
- (CLLocationCoordinate2D)coordinate {
    if (gLatitude != 0.0 || gLongitude != 0.0) {
        return CLLocationCoordinate2DMake(gLatitude, gLongitude);
    }
    return %orig;
}
%end

%end // FakeLocation

// ============================================================
#pragma mark - fakeScreen (UIScreen hooks)
// ============================================================

%group FakeScreen

%hook UIScreen
- (CGRect)bounds {
    return CGRectMake(0, 0, gScreenW, gScreenH);
}
- (CGRect)nativeBounds {
    return CGRectMake(0, 0, gScreenW * gScreenScale, gScreenH * gScreenScale);
}
- (CGFloat)scale {
    return gScreenScale;
}
- (CGFloat)nativeScale {
    return gScreenScale;
}
%end

%end // FakeScreen

// ============================================================
#pragma mark - fakeBrowser (UserAgent hooks)
// ============================================================

%group FakeBrowser

%hook WKWebView
- (NSString *)customUserAgent {
    return gUserAgent ?: %orig;
}
- (void)setCustomUserAgent:(NSString *)userAgent {
    %orig(gUserAgent ?: userAgent);
}
%end

%hook NSMutableURLRequest
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if (gUserAgent && [field.lowercaseString isEqualToString:@"user-agent"]) {
        %orig(gUserAgent, field);
        return;
    }
    %orig;
}
%end

%end // FakeBrowser

// ============================================================
#pragma mark - fakeDateTime (NSTimeZone + NSDate hooks)
// ============================================================

%group FakeDateTime

%hook NSTimeZone
+ (NSTimeZone *)systemTimeZone {
    if (gTimezone) {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:gTimezone];
        if (tz) return tz;
    }
    return %orig;
}
+ (NSTimeZone *)localTimeZone {
    if (gTimezone) {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:gTimezone];
        if (tz) return tz;
    }
    return %orig;
}
+ (NSTimeZone *)defaultTimeZone {
    if (gTimezone) {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:gTimezone];
        if (tz) return tz;
    }
    return %orig;
}
- (NSInteger)secondsFromGMTForDate:(NSDate *)date {
    if (gTimezoneOffset != 0) {
        return gTimezoneOffset * 3600;
    }
    return %orig;
}
%end

%end // FakeDateTime

// ============================================================
#pragma mark - fakeNetwork (CTCarrier hooks)
// ============================================================

%group FakeNetwork

%hook CTCarrier
- (NSString *)carrierName {
    return gCarrierName ?: %orig;
}
- (NSString *)mobileCountryCode {
    return gMCC ?: %orig;
}
- (NSString *)mobileNetworkCode {
    return gMNC ?: %orig;
}
- (NSString *)isoCountryCode {
    return gLocaleID ? [gLocaleID substringToIndex:MIN(2, gLocaleID.length)] : %orig;
}
%end

%end // FakeNetwork

// ============================================================
#pragma mark - fakeLocale (NSLocale hooks)
// ============================================================

%group FakeLocale

%hook NSLocale
+ (NSLocale *)currentLocale {
    if (gLocaleID) {
        return [[NSLocale alloc] initWithLocaleIdentifier:gLocaleID];
    }
    return %orig;
}
+ (NSLocale *)systemLocale {
    if (gLocaleID) {
        return [[NSLocale alloc] initWithLocaleIdentifier:gLocaleID];
    }
    return %orig;
}
+ (NSArray<NSString *> *)preferredLanguages {
    if (gLocaleID) {
        return @[gLocaleID];
    }
    return %orig;
}
%end

%end // FakeLocale

// ============================================================
#pragma mark - fakeSensor (CMMotionManager hooks)
// ============================================================

%group FakeSensor

%hook CMMotionManager
- (CMAccelerometerData *)accelerometerData {
    return nil;
}
- (CMGyroData *)gyroData {
    return nil;
}
- (BOOL)isAccelerometerActive {
    return NO;
}
- (BOOL)isGyroActive {
    return NO;
}
%end

%hook UIDevice
- (float)batteryLevel {
    return 1.0;
}
- (UIDeviceBatteryState)batteryState {
    return UIDeviceBatteryStateFull;
}
- (BOOL)isBatteryMonitoringEnabled {
    return YES;
}
%end

%end // FakeSensor

// ============================================================
#pragma mark - fakeSysctl (sysctlbyname hook)
// ============================================================

static int (*orig_sysctlbyname)(const char *, void *, size_t *, void *, size_t);
static int hook_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    if (!gFakeSysctl) return orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);

    int ret = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);

    if (oldp && oldlenp) {
        if (strcmp(name, "hw.machine") == 0 && gDeviceModel) {
            const char *model = [gDeviceModel UTF8String];
            strlcpy((char *)oldp, model, *oldlenp);
            *oldlenp = strlen(model) + 1;
        } else if (strcmp(name, "hw.model") == 0 && gDeviceModel) {
            const char *model = [gDeviceModel UTF8String];
            strlcpy((char *)oldp, model, *oldlenp);
            *oldlenp = strlen(model) + 1;
        }
    }

    return ret;
}

// ============================================================
#pragma mark - MobileGestalt hooks (UDID, Serial, etc.)
// ============================================================

static CFPropertyListRef (*orig_MGCopyAnswer)(CFStringRef property);
static CFPropertyListRef hook_MGCopyAnswer(CFStringRef property) {
    if (!gFakeDevice) return orig_MGCopyAnswer(property);

    NSString *key = (__bridge NSString *)property;

    if (gUDID && ([key isEqualToString:@"UniqueDeviceID"] || [key isEqualToString:@"UniqueDeviceIDData"])) {
        return (__bridge_retained CFPropertyListRef)gUDID;
    }
    if (gDeviceModel && [key isEqualToString:@"ProductType"]) {
        return (__bridge_retained CFPropertyListRef)gDeviceModel;
    }
    if (gDeviceName && [key isEqualToString:@"DeviceName"]) {
        return (__bridge_retained CFPropertyListRef)gDeviceName;
    }
    if (gWifiMAC && ([key isEqualToString:@"WifiAddress"] || [key isEqualToString:@"WifiAddressData"])) {
        return (__bridge_retained CFPropertyListRef)gWifiMAC;
    }
    if (gSSID && [key isEqualToString:@"SSID"]) {
        return (__bridge_retained CFPropertyListRef)gSSID;
    }

    return orig_MGCopyAnswer(property);
}

// ============================================================
#pragma mark - Constructor
// ============================================================

%ctor {
    @autoreleasepool {
        loadSettings();

        NSLog(@"[TouchSpoof] Loading tweak...");

        if (gFakeDevice) {
            NSLog(@"[TouchSpoof] fakeDevice Enabled");
            %init(FakeDevice);
        }
        if (gFakeAds) {
            NSLog(@"[TouchSpoof] fakeAds Enabled");
            %init(FakeAds);
        }
        if (gFakeLocation) {
            NSLog(@"[TouchSpoof] fakeLocation Enabled");
            %init(FakeLocation);
        }
        if (gFakeScreen) {
            NSLog(@"[TouchSpoof] fakeScreen Enabled");
            %init(FakeScreen);
        }
        if (gFakeBrowser) {
            NSLog(@"[TouchSpoof] fakeBrowser Enabled");
            %init(FakeBrowser);
        }
        if (gFakeDateTime) {
            NSLog(@"[TouchSpoof] fakeDateTime Enabled");
            %init(FakeDateTime);
        }
        if (gFakeNetwork) {
            NSLog(@"[TouchSpoof] fakeNetwork Enabled");
            %init(FakeNetwork);
        }
        if (gFakeLocale) {
            NSLog(@"[TouchSpoof] fakeLocale Enabled");
            %init(FakeLocale);
        }
        if (gFakeSensor) {
            NSLog(@"[TouchSpoof] fakeSensor Enabled");
            %init(FakeSensor);
        }

        // Hook C functions
        if (gFakeSysctl) {
            NSLog(@"[TouchSpoof] fakeSysctl Enabled");
            MSHookFunction((void *)sysctlbyname, (void *)hook_sysctlbyname, (void **)&orig_sysctlbyname);
        }

        // Hook MobileGestalt
        if (gFakeDevice || gFakeWifiInfo) {
            void *mg = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
            if (mg) {
                void *mgFunc = dlsym(mg, "MGCopyAnswer");
                if (mgFunc) {
                    MSHookFunction(mgFunc, (void *)hook_MGCopyAnswer, (void **)&orig_MGCopyAnswer);
                    NSLog(@"[TouchSpoof] MobileGestalt hooked");
                }
            }
        }

        NSLog(@"[TouchSpoof] Loaded successfully");
    }
}
