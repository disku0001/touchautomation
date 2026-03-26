#import "TSRRSViewController.h"

@interface TSRRSViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *rrsItems;
@property (nonatomic, strong) NSMutableArray<NSString *> *filteredItems;
@property (nonatomic, strong) UITextField *startFromField;
@property (nonatomic, strong) UITextField *filterField;
@property (nonatomic, assign) BOOL selectAllOn;
@property (nonatomic, assign) BOOL isFiltering;
@end

@implementation TSRRSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"RRS";
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];

    self.rrsItems = [NSMutableArray new];
    self.filteredItems = [NSMutableArray new];
    self.selectAllOn = NO;
    self.isFiltering = NO;

    CGFloat w = self.view.bounds.size.width;
    CGFloat pad = 16;
    CGFloat y = 100;

    // Top button row
    CGFloat btnW = (w - 5 * pad) / 4;
    CGFloat btnH = 36;

    UIButton *loadBtn = [self actionButtonWithFrame:CGRectMake(pad, y, btnW, btnH) title:@"Load RRS"];
    [loadBtn addTarget:self action:@selector(onLoadRRS) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loadBtn];

    UIButton *deleteBtn = [self actionButtonWithFrame:CGRectMake(pad + (btnW + pad), y, btnW, btnH) title:@"Delete"];
    [deleteBtn addTarget:self action:@selector(onDelete) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteBtn];

    UIButton *selectAllBtn = [self actionButtonWithFrame:CGRectMake(pad + 2*(btnW + pad), y, btnW, btnH) title:@"Select All"];
    [selectAllBtn addTarget:self action:@selector(onSelectAll) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectAllBtn];

    UIButton *editBtn = [self actionButtonWithFrame:CGRectMake(pad + 3*(btnW + pad), y, btnW, btnH) title:@"Edit"];
    [editBtn addTarget:self action:@selector(onEdit) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:editBtn];
    y += btnH + 12;

    // Filter row
    UILabel *filterLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, 50, 34)];
    filterLabel.text = @"Filter:";
    filterLabel.textColor = [UIColor whiteColor];
    filterLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:filterLabel];

    self.filterField = [[UITextField alloc] initWithFrame:CGRectMake(pad + 55, y, w - 2*pad - 55 - 70, 34)];
    self.filterField.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    self.filterField.textColor = [UIColor whiteColor];
    self.filterField.font = [UIFont systemFontOfSize:14];
    self.filterField.layer.cornerRadius = 6;
    self.filterField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
    self.filterField.leftViewMode = UITextFieldViewModeAlways;
    self.filterField.placeholder = @"Search...";
    self.filterField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search..." attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
    [self.view addSubview:self.filterField];

    UIButton *filterBtn = [self actionButtonWithFrame:CGRectMake(w - pad - 60, y, 60, 34) title:@"Filter"];
    [filterBtn addTarget:self action:@selector(onFilter) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:filterBtn];
    y += 44;

    // Start From row
    UILabel *startLabel = [[UILabel alloc] initWithFrame:CGRectMake(pad, y, 80, 34)];
    startLabel.text = @"Start From:";
    startLabel.textColor = [UIColor whiteColor];
    startLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:startLabel];

    self.startFromField = [[UITextField alloc] initWithFrame:CGRectMake(pad + 85, y, 80, 34)];
    self.startFromField.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1.0];
    self.startFromField.textColor = [UIColor whiteColor];
    self.startFromField.font = [UIFont systemFontOfSize:14];
    self.startFromField.layer.cornerRadius = 6;
    self.startFromField.keyboardType = UIKeyboardTypeNumberPad;
    self.startFromField.text = @"0";
    self.startFromField.textAlignment = NSTextAlignmentCenter;
    self.startFromField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 0)];
    self.startFromField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.startFromField];
    y += 44;

    // RRS list (dark purple area)
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(pad, y, w - 2*pad, self.view.bounds.size.height - y - 100) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor colorWithRed:0.15 green:0.10 blue:0.25 alpha:1.0];
    self.tableView.layer.cornerRadius = 12;
    self.tableView.clipsToBounds = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"RRSCell"];
    [self.view addSubview:self.tableView];
}

#pragma mark - Actions

- (void)onLoadRRS {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.plain-text"] inMode:UIDocumentPickerModeImport];
    picker.delegate = (id<UIDocumentPickerDelegate>)self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    NSString *contents = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    if (!contents) return;

    [self.rrsItems removeAllObjects];
    NSArray *lines = [contents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            [self.rrsItems addObject:trimmed];
        }
    }

    self.isFiltering = NO;
    [self.tableView reloadData];
}

- (void)onDelete {
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    if (!selectedRows || selectedRows.count == 0) {
        [self.rrsItems removeAllObjects];
        [self.filteredItems removeAllObjects];
    } else {
        NSMutableIndexSet *indices = [NSMutableIndexSet new];
        for (NSIndexPath *ip in selectedRows) {
            [indices addIndex:ip.row];
        }
        NSArray *source = self.isFiltering ? self.filteredItems : self.rrsItems;
        NSMutableArray *toRemove = [NSMutableArray new];
        [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            if (idx < source.count) [toRemove addObject:source[idx]];
        }];
        [self.rrsItems removeObjectsInArray:toRemove];
        [self.filteredItems removeObjectsInArray:toRemove];
    }
    [self.tableView reloadData];
}

- (void)onSelectAll {
    self.selectAllOn = !self.selectAllOn;
    NSArray *source = self.isFiltering ? self.filteredItems : self.rrsItems;
    if (self.selectAllOn) {
        for (NSUInteger i = 0; i < source.count; i++) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    } else {
        for (NSUInteger i = 0; i < source.count; i++) {
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
        }
    }
}

- (void)onFilter {
    NSString *query = self.filterField.text;
    if (query.length == 0) {
        self.isFiltering = NO;
        [self.tableView reloadData];
        return;
    }
    self.isFiltering = YES;
    [self.filteredItems removeAllObjects];
    for (NSString *item in self.rrsItems) {
        if ([item localizedCaseInsensitiveContainsString:query]) {
            [self.filteredItems addObject:item];
        }
    }
    [self.tableView reloadData];
}

- (void)onEdit {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Edit RRS Item" message:@"Enter new value" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        NSIndexPath *sel = self.tableView.indexPathForSelectedRow;
        NSArray *source = self.isFiltering ? self.filteredItems : self.rrsItems;
        if (sel && sel.row < (NSInteger)source.count) {
            tf.text = source[sel.row];
        }
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *newVal = alert.textFields.firstObject.text;
        NSIndexPath *sel = self.tableView.indexPathForSelectedRow;
        if (!sel || !newVal) return;
        NSArray *source = self.isFiltering ? self.filteredItems : self.rrsItems;
        if (sel.row < (NSInteger)source.count) {
            NSString *oldVal = source[sel.row];
            NSUInteger mainIdx = [self.rrsItems indexOfObject:oldVal];
            if (mainIdx != NSNotFound) self.rrsItems[mainIdx] = newVal;
            if (self.isFiltering) self.filteredItems[sel.row] = newVal;
            [self.tableView reloadData];
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *source = self.isFiltering ? self.filteredItems : self.rrsItems;
    NSInteger startFrom = [self.startFromField.text integerValue];
    if (startFrom >= (NSInteger)source.count) return 0;
    return source.count - startFrom;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RRSCell" forIndexPath:indexPath];
    NSArray *source = self.isFiltering ? self.filteredItems : self.rrsItems;
    NSInteger startFrom = [self.startFromField.text integerValue];
    NSInteger actualIndex = indexPath.row + startFrom;

    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    UIView *selBg = [[UIView alloc] init];
    selBg.backgroundColor = [UIColor colorWithRed:0.2 green:0.15 blue:0.4 alpha:1.0];
    cell.selectedBackgroundView = selBg;

    if (actualIndex < (NSInteger)source.count) {
        cell.textLabel.text = [NSString stringWithFormat:@"%ld. %@", (long)actualIndex, source[actualIndex]];
    } else {
        cell.textLabel.text = @"";
    }
    return cell;
}

#pragma mark - UI Helpers

- (UIButton *)actionButtonWithFrame:(CGRect)frame title:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor systemBlueColor];
    btn.layer.cornerRadius = 8;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    return btn;
}

@end
