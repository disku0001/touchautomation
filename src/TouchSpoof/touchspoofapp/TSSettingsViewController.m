#import "TSSettingsViewController.h"

static NSString *const kSettingsPlistPath = @"/var/jb/Library/PreferenceLoader/Preferences/generalSettings.plist";

@interface TSSettingsViewController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *trackingURLField;
@property (nonatomic, strong) NSMutableDictionary *settings;

// Toggle switches
@property (nonatomic, strong) UISwitch *loopProxySwitch;
@property (nonatomic, strong) UISwitch *changeProxyOnResetSwitch;
@property (nonatomic, strong) UISwitch *clearAllAppsSwitch;
@property (nonatomic, strong) UISwitch *clearSafariSwitch;
@property (nonatomic, strong) UISwitch *backupSafariSwitch;
@property (nonatomic, strong) UISwitch *backupKeychainSQLSwitch;
@property (nonatomic, strong) UISwitch *uninstallAfterWipeSwitch;
@property (nonatomic, strong) UISwitch *closeAppAfterResetSwitch;
@property (nonatomic, strong) UISwitch *openAppAfterRestoreSwitch;
@property (nonatomic, strong) UISwitch *autoDownloadAppSwitch;
@property (nonatomic, strong) UISwitch *openAppAfterDownloadSwitch;
@property (nonatomic, strong) UISwitch *useOldDeviceSwitch;
@property (nonatomic, strong) UISwitch *autoAllowAlertSwitch;
@end

@implementation TSSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];

    [self loadSettings];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];

    CGFloat w = self.view.bounds.size.width;
    CGFloat pad = 16;
    CGFloat y = 10;

    // Tracking URL section
    UILabel *urlTitle = [self sectionLabelWithFrame:CGRectMake(pad, y, w - 2*pad, 24) text:@"Tracking URL"];
    [self.scrollView addSubview:urlTitle];
    y += 28;

    self.trackingURLField = [[UITextField alloc] initWithFrame:CGRectMake(pad, y, w - 2*pad - 70, 38)];
    self.trackingURLField.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    self.trackingURLField.textColor = [UIColor whiteColor];
    self.trackingURLField.font = [UIFont systemFontOfSize:13];
    self.trackingURLField.layer.cornerRadius = 8;
    self.trackingURLField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    self.trackingURLField.leftViewMode = UITextFieldViewModeAlways;
    self.trackingURLField.text = self.settings[@"trackingURL"] ?: @"http://ip-api.com/json";
    self.trackingURLField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.trackingURLField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.trackingURLField.keyboardType = UIKeyboardTypeURL;
    self.trackingURLField.placeholder = @"http://ip-api.com/json";
    self.trackingURLField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"http://ip-api.com/json" attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
    [self.scrollView addSubview:self.trackingURLField];

    UIButton *saveURLBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveURLBtn.frame = CGRectMake(w - pad - 60, y, 60, 38);
    [saveURLBtn setTitle:@"Save" forState:UIControlStateNormal];
    [saveURLBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveURLBtn.backgroundColor = [UIColor systemBlueColor];
    saveURLBtn.layer.cornerRadius = 8;
    saveURLBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [saveURLBtn addTarget:self action:@selector(onSaveURL) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:saveURLBtn];
    y += 52;

    // Toggle settings
    UILabel *toggleTitle = [self sectionLabelWithFrame:CGRectMake(pad, y, w - 2*pad, 24) text:@"Automation Settings"];
    [self.scrollView addSubview:toggleTitle];
    y += 32;

    // Define all toggles with their keys and labels
    NSArray *toggleDefs = @[
        @[@"Loop Proxy",                        @"loopProxy"],
        @[@"Change proxy when reset",           @"changeProxyOnReset"],
        @[@"Clear All Apps",                    @"clearAllApps"],
        @[@"Clear Safari",                      @"clearSafari"],
        @[@"Backup Safari when backup",         @"backupSafari"],
        @[@"Backup keychain SQL Type",          @"backupKeychainSQL"],
        @[@"Uninstall app after wipe",          @"uninstallAfterWipe"],
        @[@"Close App after reset or backup",   @"closeAppAfterReset"],
        @[@"Open App after restore",            @"openAppAfterRestore"],
        @[@"Auto Download App",                 @"autoDownloadApp"],
        @[@"Open App after downloaded",         @"openAppAfterDownload"],
        @[@"Use Old Device",                    @"useOldDevice"],
        @[@"Auto Allow Alert in App",           @"autoAllowAlert"],
    ];

    for (NSArray *def in toggleDefs) {
        UIView *row = [self toggleRowWithFrame:CGRectMake(pad, y, w - 2*pad, 50) label:def[0] key:def[1]];
        [self.scrollView addSubview:row];
        y += 54;
    }

    // Save All button
    y += 10;
    UIButton *saveAllBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveAllBtn.frame = CGRectMake(pad, y, w - 2*pad, 48);
    [saveAllBtn setTitle:@"Save All Settings" forState:UIControlStateNormal];
    [saveAllBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveAllBtn.backgroundColor = [UIColor systemBlueColor];
    saveAllBtn.layer.cornerRadius = 10;
    saveAllBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [saveAllBtn addTarget:self action:@selector(onSaveAll) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:saveAllBtn];
    y += 60;

    // Reset button
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(pad, y, w - 2*pad, 48);
    [resetBtn setTitle:@"Reset to Defaults" forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resetBtn.backgroundColor = [UIColor colorWithRed:0.6 green:0.1 blue:0.1 alpha:1.0];
    resetBtn.layer.cornerRadius = 10;
    resetBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [resetBtn addTarget:self action:@selector(onResetDefaults) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:resetBtn];
    y += 70;

    self.scrollView.contentSize = CGSizeMake(w, y);
}

#pragma mark - Settings Persistence

- (void)loadSettings {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kSettingsPlistPath];
    self.settings = dict ? [dict mutableCopy] : [NSMutableDictionary new];
}

- (void)saveSettings {
    NSString *dir = [kSettingsPlistPath stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    [self.settings writeToFile:kSettingsPlistPath atomically:YES];
    NSLog(@"[TouchSpoof] Settings saved to %@", kSettingsPlistPath);
}

#pragma mark - Actions

- (void)onSaveURL {
    self.settings[@"trackingURL"] = self.trackingURLField.text ?: @"http://ip-api.com/json";
    [self saveSettings];
    [self showToast:@"Tracking URL saved"];
}

- (void)onSaveAll {
    // Collect all toggle values
    self.settings[@"trackingURL"] = self.trackingURLField.text ?: @"http://ip-api.com/json";
    self.settings[@"loopProxy"] = @(self.loopProxySwitch.isOn);
    self.settings[@"changeProxyOnReset"] = @(self.changeProxyOnResetSwitch.isOn);
    self.settings[@"clearAllApps"] = @(self.clearAllAppsSwitch.isOn);
    self.settings[@"clearSafari"] = @(self.clearSafariSwitch.isOn);
    self.settings[@"backupSafari"] = @(self.backupSafariSwitch.isOn);
    self.settings[@"backupKeychainSQL"] = @(self.backupKeychainSQLSwitch.isOn);
    self.settings[@"uninstallAfterWipe"] = @(self.uninstallAfterWipeSwitch.isOn);
    self.settings[@"closeAppAfterReset"] = @(self.closeAppAfterResetSwitch.isOn);
    self.settings[@"openAppAfterRestore"] = @(self.openAppAfterRestoreSwitch.isOn);
    self.settings[@"autoDownloadApp"] = @(self.autoDownloadAppSwitch.isOn);
    self.settings[@"openAppAfterDownload"] = @(self.openAppAfterDownloadSwitch.isOn);
    self.settings[@"useOldDevice"] = @(self.useOldDeviceSwitch.isOn);
    self.settings[@"autoAllowAlert"] = @(self.autoAllowAlertSwitch.isOn);

    [self saveSettings];
    [self showToast:@"All settings saved"];
}

- (void)onResetDefaults {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset Settings" message:@"Are you sure you want to reset all settings to defaults?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[NSFileManager defaultManager] removeItemAtPath:kSettingsPlistPath error:nil];
        self.settings = [NSMutableDictionary new];
        self.trackingURLField.text = @"http://ip-api.com/json";

        // Turn off all switches
        NSArray *switches = @[
            self.loopProxySwitch, self.changeProxyOnResetSwitch, self.clearAllAppsSwitch,
            self.clearSafariSwitch, self.backupSafariSwitch, self.backupKeychainSQLSwitch,
            self.uninstallAfterWipeSwitch, self.closeAppAfterResetSwitch, self.openAppAfterRestoreSwitch,
            self.autoDownloadAppSwitch, self.openAppAfterDownloadSwitch, self.useOldDeviceSwitch,
            self.autoAllowAlertSwitch
        ];
        for (UISwitch *sw in switches) {
            [sw setOn:NO animated:YES];
        }
        [self showToast:@"Settings reset to defaults"];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onToggleChanged:(UISwitch *)sender {
    // Tag is used to identify the key - auto-save on change
    NSArray *keys = @[
        @"loopProxy", @"changeProxyOnReset", @"clearAllApps", @"clearSafari",
        @"backupSafari", @"backupKeychainSQL", @"uninstallAfterWipe", @"closeAppAfterReset",
        @"openAppAfterRestore", @"autoDownloadApp", @"openAppAfterDownload", @"useOldDevice",
        @"autoAllowAlert"
    ];
    NSInteger idx = sender.tag;
    if (idx >= 0 && idx < (NSInteger)keys.count) {
        self.settings[keys[idx]] = @(sender.isOn);
        [self saveSettings];
    }
}

#pragma mark - UI Helpers

- (UILabel *)sectionLabelWithFrame:(CGRect)frame text:(NSString *)text {
    UILabel *lbl = [[UILabel alloc] initWithFrame:frame];
    lbl.text = text;
    lbl.textColor = [UIColor systemBlueColor];
    lbl.font = [UIFont boldSystemFontOfSize:15];
    return lbl;
}

- (UIView *)toggleRowWithFrame:(CGRect)frame label:(NSString *)label key:(NSString *)key {
    UIView *row = [[UIView alloc] initWithFrame:frame];
    row.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    row.layer.cornerRadius = 10;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, frame.size.width - 80, frame.size.height)];
    lbl.text = label;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:14];
    [row addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(frame.size.width - 62, (frame.size.height - 31) / 2, 51, 31)];
    sw.onTintColor = [UIColor systemBlueColor];
    sw.on = [self.settings[key] boolValue];
    [row addSubview:sw];

    // Map key to property and tag
    static NSArray *keyOrder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyOrder = @[
            @"loopProxy", @"changeProxyOnReset", @"clearAllApps", @"clearSafari",
            @"backupSafari", @"backupKeychainSQL", @"uninstallAfterWipe", @"closeAppAfterReset",
            @"openAppAfterRestore", @"autoDownloadApp", @"openAppAfterDownload", @"useOldDevice",
            @"autoAllowAlert"
        ];
    });

    NSUInteger idx = [keyOrder indexOfObject:key];
    sw.tag = (idx != NSNotFound) ? (NSInteger)idx : -1;
    [sw addTarget:self action:@selector(onToggleChanged:) forControlEvents:UIControlEventValueChanged];

    // Assign to property
    if ([key isEqualToString:@"loopProxy"])            self.loopProxySwitch = sw;
    else if ([key isEqualToString:@"changeProxyOnReset"])  self.changeProxyOnResetSwitch = sw;
    else if ([key isEqualToString:@"clearAllApps"])         self.clearAllAppsSwitch = sw;
    else if ([key isEqualToString:@"clearSafari"])          self.clearSafariSwitch = sw;
    else if ([key isEqualToString:@"backupSafari"])         self.backupSafariSwitch = sw;
    else if ([key isEqualToString:@"backupKeychainSQL"])    self.backupKeychainSQLSwitch = sw;
    else if ([key isEqualToString:@"uninstallAfterWipe"])   self.uninstallAfterWipeSwitch = sw;
    else if ([key isEqualToString:@"closeAppAfterReset"])   self.closeAppAfterResetSwitch = sw;
    else if ([key isEqualToString:@"openAppAfterRestore"])  self.openAppAfterRestoreSwitch = sw;
    else if ([key isEqualToString:@"autoDownloadApp"])      self.autoDownloadAppSwitch = sw;
    else if ([key isEqualToString:@"openAppAfterDownload"]) self.openAppAfterDownloadSwitch = sw;
    else if ([key isEqualToString:@"useOldDevice"])         self.useOldDeviceSwitch = sw;
    else if ([key isEqualToString:@"autoAllowAlert"])       self.autoAllowAlertSwitch = sw;

    return row;
}

- (void)showToast:(NSString *)message {
    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:0.95];
    toast.font = [UIFont boldSystemFontOfSize:14];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.layer.cornerRadius = 10;
    toast.clipsToBounds = YES;
    toast.alpha = 0;

    CGSize size = [message sizeWithAttributes:@{NSFontAttributeName: toast.font}];
    CGFloat toastW = size.width + 40;
    toast.frame = CGRectMake((self.view.bounds.size.width - toastW) / 2, self.view.bounds.size.height - 140, toastW, 40);
    [self.view addSubview:toast];

    [UIView animateWithDuration:0.3 animations:^{
        toast.alpha = 1.0;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        });
    }];
}

@end
