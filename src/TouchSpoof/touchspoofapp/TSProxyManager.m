#import "TSProxyManager.h"
#import <SystemConfiguration/SystemConfiguration.h>

static NSString *const kProxyPlistPath = @"/var/jb/Library/PreferenceLoader/Preferences/proxySettings.plist";

@implementation TSProxyManager

#pragma mark - Plist Read/Write

+ (NSDictionary *)readProxySettings {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kProxyPlistPath];
    return dict ?: @{};
}

+ (void)writeProxySettings:(NSDictionary *)settings {
    NSString *dir = [kProxyPlistPath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    [settings writeToFile:kProxyPlistPath atomically:YES];
}

#pragma mark - CRUD

+ (NSArray<NSDictionary *> *)allProxies {
    NSDictionary *settings = [self readProxySettings];
    NSArray *list = settings[@"proxies"];
    return list ?: @[];
}

+ (void)addProxyWithHost:(NSString *)host port:(NSString *)port username:(NSString *)user password:(NSString *)pass {
    NSMutableDictionary *settings = [[self readProxySettings] mutableCopy];
    NSMutableArray *proxies = [(settings[@"proxies"] ?: @[]) mutableCopy];

    NSDictionary *entry = @{
        @"host": host ?: @"",
        @"port": port ?: @"",
        @"username": user ?: @"",
        @"password": pass ?: @""
    };
    [proxies addObject:entry];
    settings[@"proxies"] = proxies;
    [self writeProxySettings:settings];
    NSLog(@"[TouchSpoof] Added proxy %@:%@", host, port);
}

+ (void)editProxyAtIndex:(NSUInteger)index host:(NSString *)host port:(NSString *)port username:(NSString *)user password:(NSString *)pass {
    NSMutableDictionary *settings = [[self readProxySettings] mutableCopy];
    NSMutableArray *proxies = [(settings[@"proxies"] ?: @[]) mutableCopy];
    if (index >= proxies.count) return;

    proxies[index] = @{
        @"host": host ?: @"",
        @"port": port ?: @"",
        @"username": user ?: @"",
        @"password": pass ?: @""
    };
    settings[@"proxies"] = proxies;
    [self writeProxySettings:settings];
    NSLog(@"[TouchSpoof] Edited proxy at index %lu", (unsigned long)index);
}

+ (void)deleteProxyAtIndex:(NSUInteger)index {
    NSMutableDictionary *settings = [[self readProxySettings] mutableCopy];
    NSMutableArray *proxies = [(settings[@"proxies"] ?: @[]) mutableCopy];
    if (index >= proxies.count) return;

    [proxies removeObjectAtIndex:index];
    settings[@"proxies"] = proxies;
    [self writeProxySettings:settings];
    NSLog(@"[TouchSpoof] Deleted proxy at index %lu", (unsigned long)index);
}

#pragma mark - Current / Rotate

+ (NSUInteger)currentProxyIndex {
    NSDictionary *settings = [self readProxySettings];
    return [settings[@"currentIndex"] unsignedIntegerValue];
}

+ (void)setCurrentProxyIndex:(NSUInteger)index {
    NSMutableDictionary *settings = [[self readProxySettings] mutableCopy];
    settings[@"currentIndex"] = @(index);
    [self writeProxySettings:settings];
}

+ (NSDictionary *)currentProxy {
    NSArray *proxies = [self allProxies];
    if (proxies.count == 0) return nil;
    NSUInteger idx = [self currentProxyIndex];
    if (idx >= proxies.count) idx = 0;
    return proxies[idx];
}

+ (void)rotateProxy {
    NSArray *proxies = [self allProxies];
    if (proxies.count == 0) {
        NSLog(@"[TouchSpoof] No proxies configured");
        return;
    }
    NSUInteger idx = [self currentProxyIndex];
    idx = (idx + 1) % proxies.count;
    [self setCurrentProxyIndex:idx];

    NSDictionary *proxy = proxies[idx];
    NSLog(@"[TouchSpoof] Rotated to proxy %@:%@ (index %lu)", proxy[@"host"], proxy[@"port"], (unsigned long)idx);

    if ([self isProxyEnabled]) {
        [self applySystemProxy:proxy];
    }
}

#pragma mark - Enable / Disable via SystemConfiguration

+ (BOOL)isProxyEnabled {
    NSDictionary *settings = [self readProxySettings];
    return [settings[@"enabled"] boolValue];
}

+ (void)enableProxy {
    NSMutableDictionary *settings = [[self readProxySettings] mutableCopy];
    settings[@"enabled"] = @YES;
    [self writeProxySettings:settings];

    NSDictionary *proxy = [self currentProxy];
    if (proxy) {
        [self applySystemProxy:proxy];
    }
    NSLog(@"[TouchSpoof] Proxy enabled");
}

+ (void)disableProxy {
    NSMutableDictionary *settings = [[self readProxySettings] mutableCopy];
    settings[@"enabled"] = @NO;
    [self writeProxySettings:settings];
    [self clearSystemProxy];
    NSLog(@"[TouchSpoof] Proxy disabled");
}

#pragma mark - System Proxy Helpers

+ (void)applySystemProxy:(NSDictionary *)proxy {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("TouchSpoof"), NULL, NULL);
    if (!store) return;

    NSString *host = proxy[@"host"] ?: @"";
    int port = [proxy[@"port"] intValue];

    NSDictionary *proxyDict = @{
        (__bridge NSString *)kSCPropNetProxiesHTTPEnable:  @1,
        (__bridge NSString *)kSCPropNetProxiesHTTPProxy:   host,
        (__bridge NSString *)kSCPropNetProxiesHTTPPort:    @(port),
        (__bridge NSString *)kSCPropNetProxiesHTTPSEnable: @1,
        (__bridge NSString *)kSCPropNetProxiesHTTPSProxy:  host,
        (__bridge NSString *)kSCPropNetProxiesHTTPSPort:   @(port),
    };

    SCDynamicStoreSetValue(store, CFSTR("State:/Network/Global/Proxies"), (__bridge CFDictionaryRef)proxyDict);
    CFRelease(store);
    NSLog(@"[TouchSpoof] System proxy set to %@:%d", host, port);
}

+ (void)clearSystemProxy {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("TouchSpoof"), NULL, NULL);
    if (!store) return;

    NSDictionary *proxyDict = @{
        (__bridge NSString *)kSCPropNetProxiesHTTPEnable:  @0,
        (__bridge NSString *)kSCPropNetProxiesHTTPSEnable: @0,
    };

    SCDynamicStoreSetValue(store, CFSTR("State:/Network/Global/Proxies"), (__bridge CFDictionaryRef)proxyDict);
    CFRelease(store);
    NSLog(@"[TouchSpoof] System proxy cleared");
}

@end
