#import "TSAppleIDViewController.h"

@interface TSAppleIDViewController ()
@property (nonatomic, strong) UITextField *startIndexField;
@property (nonatomic, strong) UIView *contentArea;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation TSAppleIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Apple ID";
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];

    CGFloat w = self.view.bounds.size.width;
    CGFloat pad = 16;
    CGFloat y = 100;

    // Header card
    UIView *headerCard = [self cardWithFrame:CGRectMake(pad, y, w - 2*pad, 100)];
    [self.view addSubview:headerCard];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, 200, 24)];
    title.text = @"Apple ID Management";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:17];
    [headerCard addSubview:title];

    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(12, 38, headerCard.bounds.size.width - 24, 50)];
    desc.text = @"Manage Apple ID sessions for automation. Load accounts and iterate through them.";
    desc.textColor = [UIColor lightGrayColor];
    desc.font = [UIFont systemFontOfSize:13];
    desc.numberOfLines = 0;
    [headerCard addSubview:desc];
    y += 115;

    // Start Index row
    UILabel *startLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, 90, 34)];
    startLabel.text = @"Start Index:";
    startLabel.textColor = [UIColor whiteColor];
    startLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:startLabel];

    self.startIndexField = [[UITextField alloc] initWithFrame:CGRectMake(pad + 95, y, 80, 34)];
    self.startIndexField.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    self.startIndexField.textColor = [UIColor whiteColor];
    self.startIndexField.font = [UIFont systemFontOfSize:14];
    self.startIndexField.layer.cornerRadius = 6;
    self.startIndexField.keyboardType = UIKeyboardTypeNumberPad;
    self.startIndexField.text = @"0";
    self.startIndexField.textAlignment = NSTextAlignmentCenter;
    self.startIndexField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
    self.startIndexField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.startIndexField];

    UIButton *loadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    loadBtn.frame = CGRectMake(pad + 185, y, 80, 34);
    [loadBtn setTitle:@"Load" forState:UIControlStateNormal];
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadBtn.backgroundColor = [UIColor systemBlueColor];
    loadBtn.layer.cornerRadius = 8;
    loadBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [loadBtn addTarget:self action:@selector(onLoad) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadBtn];

    UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    clearBtn.frame = CGRectMake(pad + 275, y, 80, 34);
    [clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    clearBtn.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.25 alpha:1.0];
    clearBtn.layer.cornerRadius = 8;
    clearBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [clearBtn addTarget:self action:@selector(onClear) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:clearBtn];
    y += 48;

    // Status
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, w - 2*pad, 20)];
    self.statusLabel.text = @"No accounts loaded";
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:self.statusLabel];
    y += 28;

    // Black content area
    self.contentArea = [[UIView alloc] initWithFrame:CGRectMake(pad, y, w - 2*pad, self.view.bounds.size.height - y - 100)];
    self.contentArea.backgroundColor = [UIColor blackColor];
    self.contentArea.layer.cornerRadius = 12;
    self.contentArea.clipsToBounds = YES;
    self.contentArea.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.contentArea];

    // Placeholder label in content area
    UILabel *placeholder = [[UILabel alloc] initWithFrame:self.contentArea.bounds];
    placeholder.text = @"Apple ID accounts will appear here";
    placeholder.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    placeholder.font = [UIFont systemFontOfSize:14];
    placeholder.textAlignment = NSTextAlignmentCenter;
    placeholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    placeholder.tag = 100;
    [self.contentArea addSubview:placeholder];
}

#pragma mark - Actions

- (void)onLoad {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.plain-text"] inMode:UIDocumentPickerModeImport];
    picker.delegate = (id<UIDocumentPickerDelegate>)self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    NSString *contents = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    if (!contents) return;

    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *accounts = [NSMutableArray new];
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) [accounts addObject:trimmed];
    }

    // Remove placeholder
    UIView *placeholder = [self.contentArea viewWithTag:100];
    [placeholder removeFromSuperview];

    // Add account labels
    for (UIView *sub in self.contentArea.subviews) [sub removeFromSuperview];

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:self.contentArea.bounds];
    scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentArea addSubview:scroll];

    NSInteger startIdx = [self.startIndexField.text integerValue];
    CGFloat ly = 8;
    for (NSInteger i = startIdx; i < (NSInteger)accounts.count; i++) {
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, ly, self.contentArea.bounds.size.width - 24, 20)];
        lbl.text = [NSString stringWithFormat:@"%ld. %@", (long)i, accounts[i]];
        lbl.textColor = [UIColor whiteColor];
        lbl.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
        [scroll addSubview:lbl];
        ly += 22;
    }
    scroll.contentSize = CGSizeMake(self.contentArea.bounds.size.width, ly + 8);

    self.statusLabel.text = [NSString stringWithFormat:@"%lu accounts loaded (showing from index %ld)", (unsigned long)accounts.count, (long)startIdx];
    self.statusLabel.textColor = [UIColor systemGreenColor];
}

- (void)onClear {
    for (UIView *sub in self.contentArea.subviews) [sub removeFromSuperview];

    UILabel *placeholder = [[UILabel alloc] initWithFrame:self.contentArea.bounds];
    placeholder.text = @"Apple ID accounts will appear here";
    placeholder.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    placeholder.font = [UIFont systemFontOfSize:14];
    placeholder.textAlignment = NSTextAlignmentCenter;
    placeholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    placeholder.tag = 100;
    [self.contentArea addSubview:placeholder];

    self.statusLabel.text = @"No accounts loaded";
    self.statusLabel.textColor = [UIColor grayColor];
}

#pragma mark - UI Helpers

- (UIView *)cardWithFrame:(CGRect)frame {
    UIView *card = [[UIView alloc] initWithFrame:frame];
    card.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    card.layer.cornerRadius = 12;
    return card;
}

@end
