#import <Foundation/Foundation.h>

@interface TSProxyManager : NSObject

+ (NSArray<NSDictionary *> *)allProxies;
+ (void)addProxyWithHost:(NSString *)host port:(NSString *)port username:(NSString *)user password:(NSString *)pass;
+ (void)editProxyAtIndex:(NSUInteger)index host:(NSString *)host port:(NSString *)port username:(NSString *)user password:(NSString *)pass;
+ (void)deleteProxyAtIndex:(NSUInteger)index;

+ (NSDictionary *)currentProxy;
+ (void)rotateProxy;
+ (NSUInteger)currentProxyIndex;
+ (void)setCurrentProxyIndex:(NSUInteger)index;

+ (void)enableProxy;
+ (void)disableProxy;
+ (BOOL)isProxyEnabled;

+ (NSDictionary *)readProxySettings;
+ (void)writeProxySettings:(NSDictionary *)settings;

@end
