#import "TSAppManager.h"
#import <spawn.h>
#import <sys/wait.h>

static void runCommand(NSString *cmd) {
    pid_t pid;
    const char *args[] = {"/bin/sh", "-c", [cmd UTF8String], NULL};
    posix_spawn(&pid, "/bin/sh", NULL, NULL, (char *const *)args, NULL);
    waitpid(pid, NULL, 0);
}

static NSString *const kBackupRoot = @"/var/jb/Library/TouchSpoof/Backups";
static NSString *const kSelectedKey = @"TouchSpoof_SelectedApps";

@implementation TSAppManager

#pragma mark - Installed Apps

+ (NSArray<NSDictionary *> *)installedApps {
    NSMutableArray *apps = [NSMutableArray new];

    // Read from LSApplicationWorkspace (private API, available on jailbroken devices)
    Class lsClass = NSClassFromString(@"LSApplicationWorkspace");
    if (lsClass) {
        id workspace = [lsClass performSelector:@selector(defaultWorkspace)];
        NSArray *allApps = [workspace performSelector:@selector(allInstalledApplications)];
        for (id proxy in allApps) {
            NSString *bundleID = [proxy performSelector:@selector(applicationIdentifier)];
            NSString *name = [proxy performSelector:@selector(localizedName)];
            NSString *type = [proxy performSelector:@selector(applicationType)];

            // Only user-installed apps
            if (![type isEqualToString:@"User"]) continue;

            NSString *containerPath = @"";
            NSURL *containerURL = [proxy performSelector:@selector(dataContainerURL)];
            if (containerURL) containerPath = containerURL.path;

            [apps addObject:@{
                @"bundleID": bundleID ?: @"",
                @"name": name ?: bundleID ?: @"Unknown",
                @"containerPath": containerPath,
                @"type": type ?: @"User"
            }];
        }
    }

    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [apps sortUsingDescriptors:@[sort]];
    return apps;
}

#pragma mark - Selection

+ (NSArray<NSString *> *)selectedBundleIDs {
    NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:kSelectedKey];
    return saved ?: @[];
}

+ (void)setSelectedBundleIDs:(NSArray<NSString *> *)bundleIDs {
    [[NSUserDefaults standardUserDefaults] setObject:bundleIDs forKey:kSelectedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)selectAll {
    NSMutableArray *all = [NSMutableArray new];
    for (NSDictionary *app in [self installedApps]) {
        [all addObject:app[@"bundleID"]];
    }
    [self setSelectedBundleIDs:all];
}

+ (void)deselectAll {
    [self setSelectedBundleIDs:@[]];
}

+ (BOOL)isBundleIDSelected:(NSString *)bundleID {
    return [[self selectedBundleIDs] containsObject:bundleID];
}

+ (void)toggleBundleID:(NSString *)bundleID {
    NSMutableArray *selected = [[self selectedBundleIDs] mutableCopy];
    if ([selected containsObject:bundleID]) {
        [selected removeObject:bundleID];
    } else {
        [selected addObject:bundleID];
    }
    [self setSelectedBundleIDs:selected];
}

#pragma mark - Wipe

+ (void)wipeAppWithBundleID:(NSString *)bundleID {
    NSArray *apps = [self installedApps];
    for (NSDictionary *app in apps) {
        if ([app[@"bundleID"] isEqualToString:bundleID]) {
            NSString *container = app[@"containerPath"];
            if (container.length > 0) {
                NSFileManager *fm = [NSFileManager defaultManager];
                NSArray *contents = [fm contentsOfDirectoryAtPath:container error:nil];
                for (NSString *item in contents) {
                    NSString *fullPath = [container stringByAppendingPathComponent:item];
                    [fm removeItemAtPath:fullPath error:nil];
                }
                NSLog(@"[TouchSpoof] Wiped container for %@", bundleID);
            }
            break;
        }
    }
}

+ (void)wipeSelectedApps {
    for (NSString *bundleID in [self selectedBundleIDs]) {
        [self wipeAppWithBundleID:bundleID];
    }
}

#pragma mark - Backup

+ (NSString *)backupPathForName:(NSString *)name bundleID:(NSString *)bundleID {
    return [NSString stringWithFormat:@"%@/%@/%@", kBackupRoot, name, bundleID];
}

+ (void)backup:(NSString *)name {
    NSArray *selected = [self selectedBundleIDs];
    NSArray *apps = [self installedApps];
    NSFileManager *fm = [NSFileManager defaultManager];

    for (NSDictionary *app in apps) {
        NSString *bundleID = app[@"bundleID"];
        if (![selected containsObject:bundleID]) continue;

        NSString *container = app[@"containerPath"];
        if (container.length == 0) continue;

        NSString *dest = [self backupPathForName:name bundleID:bundleID];
        [fm createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:nil];

        // Use tar to create backup archive
        NSString *archivePath = [dest stringByAppendingPathComponent:@"backup.tar.gz"];
        NSString *cmd = [NSString stringWithFormat:@"tar -czf '%@' -C '%@' .", archivePath, container];
        runCommand(cmd);
        NSLog(@"[TouchSpoof] Backed up %@ to %@", bundleID, archivePath);
    }
}

+ (void)restoreBackup:(NSString *)name forBundleID:(NSString *)bundleID {
    NSArray *apps = [self installedApps];
    NSFileManager *fm = [NSFileManager defaultManager];

    for (NSDictionary *app in apps) {
        if (![app[@"bundleID"] isEqualToString:bundleID]) continue;

        NSString *container = app[@"containerPath"];
        if (container.length == 0) continue;

        NSString *archivePath = [[self backupPathForName:name bundleID:bundleID] stringByAppendingPathComponent:@"backup.tar.gz"];
        if (![fm fileExistsAtPath:archivePath]) {
            NSLog(@"[TouchSpoof] No backup found for %@", bundleID);
            continue;
        }

        // Clear container first
        NSArray *contents = [fm contentsOfDirectoryAtPath:container error:nil];
        for (NSString *item in contents) {
            [fm removeItemAtPath:[container stringByAppendingPathComponent:item] error:nil];
        }

        // Extract backup
        NSString *cmd = [NSString stringWithFormat:@"tar -xzf '%@' -C '%@'", archivePath, container];
        runCommand(cmd);
        NSLog(@"[TouchSpoof] Restored %@ from backup", bundleID);
        break;
    }
}

+ (void)restore:(NSString *)name {
    for (NSString *bundleID in [self selectedBundleIDs]) {
        [self restoreBackup:name forBundleID:bundleID];
    }
}

+ (void)reBackup {
    // Re-backup overwrites the "default" backup with current state
    [self backup:@"default"];
}

+ (void)backupAndReset:(NSString *)name {
    [self backup:name];
    [self wipeSelectedApps];
}

+ (void)resetDataForSelectedApps {
    [self wipeSelectedApps];
}

#pragma mark - Available Backups

+ (NSArray<NSString *> *)availableBackups {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *contents = [fm contentsOfDirectoryAtPath:kBackupRoot error:nil];
    return contents ?: @[];
}

@end
