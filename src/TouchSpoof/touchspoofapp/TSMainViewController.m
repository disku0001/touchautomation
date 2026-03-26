#import "TSMainViewController.h"
#import "TSDeviceManager.h"
#import "TSProxyManager.h"
#import "TSAppManager.h"

@interface TSMainViewController ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *deviceInfoLabel;
@property (nonatomic, strong) UILabel *ipInfoLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UISwitch *proxySwitch;
@property (nonatomic, strong) UISwitch *servicesSwitch;
@property (nonatomic, strong) UISwitch *trialSwitch;
@property (nonatomic, strong) UISwitch *webSwitch;
@end

@implementation TSMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scroll.contentSize = CGSizeMake(self.view.bounds.size.width, 900);
    [self.view addSubview:scroll];

    CGFloat w = self.view.bounds.size.width;
    CGFloat pad = 16;
    CGFloat y = 10;

    // Header
    self.titleLabel = [self labelWithFrame:CGRectMake(pad, y, w - 2*pad, 40) text:@"TouchSpoof" fontSize:24 bold:YES];
    [scroll addSubview:self.titleLabel];

    UILabel *ver = [self labelWithFrame:CGRectMake(pad, y + 30, w - 2*pad, 20) text:@"Version: 1.0.0" fontSize:12 bold:NO];
    ver.textColor = [UIColor grayColor];
    [scroll addSubview:ver];
    y += 60;

    // Device Info Card
    UIView *infoCard = [self cardWithFrame:CGRectMake(pad, y, w - 2*pad, 130)];
    [scroll addSubview:infoCard];

    UILabel *devTitle = [self labelWithFrame:CGRectMake(12, 8, 150, 24) text:@"Device Info" fontSize:16 bold:YES];
    [infoCard addSubview:devTitle];

    NSDictionary *devInfo = [TSDeviceManager currentDeviceInfo];
    self.deviceInfoLabel = [self labelWithFrame:CGRectMake(12, 34, (w/2) - 40, 90) text:[NSString stringWithFormat:@"Model: %@\nVersion: %@\nIDFA: %@\nStatus: Worked", devInfo[@"model"] ?: @"Unknown", devInfo[@"version"] ?: @"Unknown", devInfo[@"idfa"] ?: @"Unknown"] fontSize:11 bold:NO];
    self.deviceInfoLabel.numberOfLines = 0;
    [infoCard addSubview:self.deviceInfoLabel];

    UILabel *ipTitle = [self labelWithFrame:CGRectMake(w/2 - pad, 8, 150, 24) text:@"IP Info" fontSize:16 bold:YES];
    [infoCard addSubview:ipTitle];

    self.ipInfoLabel = [self labelWithFrame:CGRectMake(w/2 - pad, 34, (w/2) - 40, 90) text:@"Proxy: null\nIP: Loading...\nCountry: --\nTimezone: --" fontSize:11 bold:NO];
    self.ipInfoLabel.numberOfLines = 0;
    [infoCard addSubview:self.ipInfoLabel];

    self.statusLabel = [self labelWithFrame:CGRectMake(12, 100, 100, 20) text:@"Worked" fontSize:13 bold:YES];
    self.statusLabel.textColor = [UIColor systemGreenColor];
    [infoCard addSubview:self.statusLabel];
    y += 145;

    // Action Buttons
    UIButton *resetBtn = [self buttonWithFrame:CGRectMake(pad, y, (w - 3*pad)/2, 60) title:@"Reset Data" color:[UIColor systemBlueColor]];
    [resetBtn addTarget:self action:@selector(onResetData) forControlEvents:UIControlEventTouchUpInside];
    [scroll addSubview:resetBtn];

    UIButton *backupResetBtn = [self buttonWithFrame:CGRectMake(pad + (w - 3*pad)/2 + pad, y, (w - 3*pad)/2, 60) title:@"Backup & Reset" color:[UIColor systemBlueColor]];
    [backupResetBtn addTarget:self action:@selector(onBackupReset) forControlEvents:UIControlEventTouchUpInside];
    [scroll addSubview:backupResetBtn];
    y += 75;

    // Row buttons
    NSArray *rowBtns = @[
        @[@"Change Device", @"changeDevice"],
        @[@"Change IP", @"changeIP"],
        @[@"Wipe App", @"wipeApp"],
        @[@"Backup", @"backup"],
        @[@"Restore", @"restore"],
        @[@"Re-Backup", @"reBackup"],
        @[@"Login iTunes", @"loginItune"],
        @[@"Change System Info", @"changeSystem"],
        @[@"Load Link", @"loadLink"],
        @[@"Update Location", @"updateLocation"],
        @[@"Reset Config", @"resetConfig"],
    ];

    for (NSArray *btn in rowBtns) {
        UIButton *b = [self buttonWithFrame:CGRectMake(pad, y, w - 2*pad, 44) title:btn[0] color:[UIColor colorWithRed:0.15 green:0.15 blue:0.25 alpha:1.0]];
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        b.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 0);
        [b addTarget:self action:NSSelectorFromString(btn[1]) forControlEvents:UIControlEventTouchUpInside];
        [scroll addSubview:b];
        y += 50;
    }

    // Toggles
    y += 10;
    NSArray *toggles = @[
        @[@"Enable Proxy", @"proxySwitch"],
        @[@"Enable Services", @"servicesSwitch"],
        @[@"Enable Trial", @"trialSwitch"],
        @[@"Enable Web Services", @"webSwitch"],
    ];

    for (NSArray *t in toggles) {
        UILabel *lbl = [self labelWithFrame:CGRectMake(pad, y, w - 100, 30) text:t[0] fontSize:15 bold:NO];
        [scroll addSubview:lbl];

        UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(w - 70, y, 50, 30)];
        sw.onTintColor = [UIColor systemGreenColor];
        [scroll addSubview:sw];

        if ([t[1] isEqualToString:@"proxySwitch"]) self.proxySwitch = sw;
        else if ([t[1] isEqualToString:@"servicesSwitch"]) self.servicesSwitch = sw;
        else if ([t[1] isEqualToString:@"trialSwitch"]) self.trialSwitch = sw;
        else if ([t[1] isEqualToString:@"webSwitch"]) self.webSwitch = sw;

        y += 44;
    }

    scroll.contentSize = CGSizeMake(w, y + 40);
    [self fetchIPInfo];
}

- (void)fetchIPInfo {
    NSURL *url = [NSURL URLWithString:@"http://ip-api.com/json"];
    [[NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
        if (data) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.ipInfoLabel.text = [NSString stringWithFormat:@"Proxy: null\nIP: %@\nCountry: %@\nTimezone: %@",
                    json[@"query"] ?: @"?", json[@"country"] ?: @"?", json[@"timezone"] ?: @"?"];
            });
        }
    }] resume];
}

#pragma mark - Actions
- (void)onResetData { [TSAppManager resetDataForSelectedApps]; }
- (void)onBackupReset { [TSAppManager backupAndReset:@"default"]; }
- (void)changeDevice { NSLog(@"[TouchSpoof] Change Device"); }
- (void)changeIP { [TSProxyManager rotateProxy]; }
- (void)wipeApp { [TSAppManager wipeSelectedApps]; }
- (void)backup { [TSAppManager backup:@"default"]; }
- (void)restore { [TSAppManager restore:@"default"]; }
- (void)reBackup { [TSAppManager reBackup]; }
- (void)loginItune { NSLog(@"[TouchSpoof] Login iTunes"); }
- (void)changeSystem { NSLog(@"[TouchSpoof] Change System"); }
- (void)loadLink { NSLog(@"[TouchSpoof] Load Link"); }
- (void)updateLocation { NSLog(@"[TouchSpoof] Update Location"); }
- (void)resetConfig { [TSDeviceManager resetConfig]; }

#pragma mark - UI Helpers
- (UILabel *)labelWithFrame:(CGRect)frame text:(NSString *)text fontSize:(CGFloat)size bold:(BOOL)bold {
    UILabel *lbl = [[UILabel alloc] initWithFrame:frame];
    lbl.text = text;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    return lbl;
}

- (UIView *)cardWithFrame:(CGRect)frame {
    UIView *card = [[UIView alloc] initWithFrame:frame];
    card.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    card.layer.cornerRadius = 12;
    return card;
}

- (UIButton *)buttonWithFrame:(CGRect)frame title:(NSString *)title color:(UIColor *)color {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = color;
    btn.layer.cornerRadius = 10;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    return btn;
}

@end
