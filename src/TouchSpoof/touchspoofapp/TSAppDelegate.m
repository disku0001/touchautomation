#import "TSAppDelegate.h"
#import "TSMainViewController.h"
#import "TSRRSViewController.h"
#import "TSAppleIDViewController.h"
#import "TSAccountsViewController.h"
#import "TSSettingsViewController.h"

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    UITabBarController *tabBar = [[UITabBarController alloc] init];
    tabBar.tabBar.barStyle = UIBarStyleBlack;
    tabBar.tabBar.tintColor = [UIColor systemBlueColor];

    TSMainViewController *mainVC = [[TSMainViewController alloc] init];
    mainVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Main" image:[UIImage systemImageNamed:@"house.fill"] tag:0];

    TSRRSViewController *rrsVC = [[TSRRSViewController alloc] init];
    rrsVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"RRS" image:[UIImage systemImageNamed:@"list.clipboard.fill"] tag:1];

    TSAppleIDViewController *appleVC = [[TSAppleIDViewController alloc] init];
    appleVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Apple ID" image:[UIImage systemImageNamed:@"apple.logo"] tag:2];

    TSAccountsViewController *accVC = [[TSAccountsViewController alloc] init];
    accVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Accounts" image:[UIImage systemImageNamed:@"person.fill"] tag:3];

    TSSettingsViewController *setVC = [[TSSettingsViewController alloc] init];
    setVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage systemImageNamed:@"gearshape.fill"] tag:4];

    tabBar.viewControllers = @[
        [[UINavigationController alloc] initWithRootViewController:mainVC],
        [[UINavigationController alloc] initWithRootViewController:rrsVC],
        [[UINavigationController alloc] initWithRootViewController:appleVC],
        [[UINavigationController alloc] initWithRootViewController:accVC],
        [[UINavigationController alloc] initWithRootViewController:setVC]
    ];

    self.window.rootViewController = tabBar;
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary *)options {
    NSString *host = url.host;
    NSDictionary *params = [self parseQueryParams:url.query];

    if ([host isEqualToString:@"swipe2kill"]) {
        [self runCmd:@"killall -9 SpringBoard"];
    } else if ([host isEqualToString:@"reset"]) {
        // Reset device config
    } else if ([host isEqualToString:@"wipeapp"]) {
        // Wipe selected apps
    } else if ([host isEqualToString:@"changeip"]) {
        // Change proxy IP
    } else if ([host isEqualToString:@"backup"]) {
        NSString *name = params[@"name"];
        if (name) NSLog(@"[TouchSpoof] Backup: %@", name);
    } else if ([host isEqualToString:@"restore"]) {
        NSString *name = params[@"name"];
        if (name) NSLog(@"[TouchSpoof] Restore: %@", name);
    } else if ([host isEqualToString:@"backup-reset"]) {
        NSString *name = params[@"name"];
        if (name) NSLog(@"[TouchSpoof] Backup & Reset: %@", name);
    } else if ([host isEqualToString:@"rebackup"]) {
        // Re-backup
    } else if ([host isEqualToString:@"proxy-on"]) {
        // Enable proxy
    } else if ([host isEqualToString:@"proxy-off"]) {
        // Disable proxy
    } else if ([host isEqualToString:@"login-itune"]) {
        // Login iTunes
    } else if ([host isEqualToString:@"change-system"]) {
        // Change system info
    } else if ([host isEqualToString:@"trial"]) {
        // Toggle trial
    } else if ([host isEqualToString:@"loadlink"]) {
        NSString *linkUrl = params[@"url"];
        if (linkUrl) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkUrl] options:@{} completionHandler:nil];
    }

    return YES;
}

- (NSDictionary *)parseQueryParams:(NSString *)query {
    NSMutableDictionary *params = [NSMutableDictionary new];
    for (NSString *pair in [query componentsSeparatedByString:@"&"]) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        if (kv.count == 2) params[kv[0]] = [kv[1] stringByRemovingPercentEncoding];
    }
    return params;
}

- (void)runCmd:(NSString *)cmd {
    system([cmd UTF8String]);
}

@end
