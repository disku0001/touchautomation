#import "TSAccountsViewController.h"
#import <sys/utsname.h>

@interface TSAccountsViewController ()
@property (nonatomic, strong) UILabel *statusBadge;
@property (nonatomic, strong) UILabel *serialLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@end

@implementation TSAccountsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Accounts";
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];

    CGFloat w = self.view.bounds.size.width;
    CGFloat pad = 16;
    CGFloat y = 100;

    // Status card
    UIView *statusCard = [self cardWithFrame:CGRectMake(pad, y, w - 2*pad, 90)];
    [self.view addSubview:statusCard];

    UILabel *statusTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 120, 24)];
    statusTitle.text = @"Login Status";
    statusTitle.textColor = [UIColor whiteColor];
    statusTitle.font = [UIFont boldSystemFontOfSize:16];
    [statusCard addSubview:statusTitle];

    self.statusBadge = [[UILabel alloc] initWithFrame:CGRectMake(12, 42, 80, 30)];
    self.statusBadge.text = @"  Active  ";
    self.statusBadge.textColor = [UIColor whiteColor];
    self.statusBadge.backgroundColor = [UIColor systemGreenColor];
    self.statusBadge.font = [UIFont boldSystemFontOfSize:14];
    self.statusBadge.textAlignment = NSTextAlignmentCenter;
    self.statusBadge.layer.cornerRadius = 6;
    self.statusBadge.clipsToBounds = YES;
    [statusCard addSubview:self.statusBadge];

    UILabel *noAuthLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 42, statusCard.bounds.size.width - 112, 30)];
    noAuthLabel.text = @"No authentication required";
    noAuthLabel.textColor = [UIColor lightGrayColor];
    noAuthLabel.font = [UIFont systemFontOfSize:12];
    [statusCard addSubview:noAuthLabel];
    y += 105;

    // Device Info card
    UIView *deviceCard = [self cardWithFrame:CGRectMake(pad, y, w - 2*pad, 140)];
    [self.view addSubview:deviceCard];

    UILabel *deviceTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 200, 24)];
    deviceTitle.text = @"Account Details";
    deviceTitle.textColor = [UIColor whiteColor];
    deviceTitle.font = [UIFont boldSystemFontOfSize:16];
    [deviceCard addSubview:deviceTitle];

    // Serial Number
    UILabel *serialTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 44, 120, 20)];
    serialTitle.text = @"Serial Number:";
    serialTitle.textColor = [UIColor lightGrayColor];
    serialTitle.font = [UIFont systemFontOfSize:13];
    [deviceCard addSubview:serialTitle];

    self.serialLabel = [[UILabel alloc] initWithFrame:CGRectMake(135, 44, deviceCard.bounds.size.width - 147, 20)];
    self.serialLabel.text = [self deviceSerialNumber];
    self.serialLabel.textColor = [UIColor whiteColor];
    self.serialLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightMedium];
    [deviceCard addSubview:self.serialLabel];

    // Username
    UILabel *userTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 72, 120, 20)];
    userTitle.text = @"Username:";
    userTitle.textColor = [UIColor lightGrayColor];
    userTitle.font = [UIFont systemFontOfSize:13];
    [deviceCard addSubview:userTitle];

    self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(135, 72, deviceCard.bounds.size.width - 147, 20)];
    self.usernameLabel.text = [self deviceUsername];
    self.usernameLabel.textColor = [UIColor whiteColor];
    self.usernameLabel.font = [UIFont systemFontOfSize:13];
    [deviceCard addSubview:self.usernameLabel];

    // Device model
    UILabel *modelTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 100, 120, 20)];
    modelTitle.text = @"Device:";
    modelTitle.textColor = [UIColor lightGrayColor];
    modelTitle.font = [UIFont systemFontOfSize:13];
    [deviceCard addSubview:modelTitle];

    UILabel *modelLabel = [[UILabel alloc] initWithFrame:CGRectMake(135, 100, deviceCard.bounds.size.width - 147, 20)];
    modelLabel.text = [self deviceModel];
    modelLabel.textColor = [UIColor whiteColor];
    modelLabel.font = [UIFont systemFontOfSize:13];
    [deviceCard addSubview:modelLabel];
    y += 155;

    // Session info card
    UIView *sessionCard = [self cardWithFrame:CGRectMake(pad, y, w - 2*pad, 100)];
    [self.view addSubview:sessionCard];

    UILabel *sessionTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 200, 24)];
    sessionTitle.text = @"Session Info";
    sessionTitle.textColor = [UIColor whiteColor];
    sessionTitle.font = [UIFont boldSystemFontOfSize:16];
    [sessionCard addSubview:sessionTitle];

    UILabel *appVersionTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 44, 120, 20)];
    appVersionTitle.text = @"App Version:";
    appVersionTitle.textColor = [UIColor lightGrayColor];
    appVersionTitle.font = [UIFont systemFontOfSize:13];
    [sessionCard addSubview:appVersionTitle];

    UILabel *appVersionLabel = [[UILabel alloc] initWithFrame:CGRectMake(135, 44, sessionCard.bounds.size.width - 147, 20)];
    appVersionLabel.text = @"1.0.0";
    appVersionLabel.textColor = [UIColor whiteColor];
    appVersionLabel.font = [UIFont systemFontOfSize:13];
    [sessionCard addSubview:appVersionLabel];

    UILabel *jbTitle = [[UILabel alloc] initWithFrame:CGRectMake(12, 68, 120, 20)];
    jbTitle.text = @"Jailbreak:";
    jbTitle.textColor = [UIColor lightGrayColor];
    jbTitle.font = [UIFont systemFontOfSize:13];
    [sessionCard addSubview:jbTitle];

    UILabel *jbLabel = [[UILabel alloc] initWithFrame:CGRectMake(135, 68, sessionCard.bounds.size.width - 147, 20)];
    jbLabel.text = [self jailbreakStatus];
    jbLabel.textColor = [UIColor systemGreenColor];
    jbLabel.font = [UIFont systemFontOfSize:13];
    [sessionCard addSubview:jbLabel];
}

#pragma mark - Device Info Helpers

- (NSString *)deviceSerialNumber {
    // On jailbroken devices we can read the serial via IOKit or MGCopyAnswer
    // Fallback to vendor UUID
    NSString *vendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    // Use last 12 chars as pseudo-serial
    if (vendorID.length >= 12) {
        return [[vendorID stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:12];
    }
    return vendorID ?: @"Unknown";
}

- (NSString *)deviceUsername {
    return [[UIDevice currentDevice] name];
}

- (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *hw = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@ (iOS %@)", hw, [[UIDevice currentDevice] systemVersion]];
}

- (NSString *)jailbreakStatus {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:@"/var/jb"] || [fm fileExistsAtPath:@"/var/jb/usr/bin/su"]) {
        return @"Detected (rootless)";
    }
    if ([fm fileExistsAtPath:@"/Applications/Cydia.app"] || [fm fileExistsAtPath:@"/usr/sbin/sshd"]) {
        return @"Detected (rootful)";
    }
    return @"Not detected";
}

#pragma mark - UI Helpers

- (UIView *)cardWithFrame:(CGRect)frame {
    UIView *card = [[UIView alloc] initWithFrame:frame];
    card.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    card.layer.cornerRadius = 12;
    return card;
}

@end
