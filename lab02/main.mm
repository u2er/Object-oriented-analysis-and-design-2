#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#include <string>
#include <vector>

// ── Переключатель ядер ──
#define USE_COMPOSITE 1 // 1 = Компоновщик, 0 = Без паттерна

#if USE_COMPOSITE
#include "FileSystemComposite.h"
#define CREATE_NODE(path) std::make_shared<FSDirectory>(path)
#else
#include "FileSystemPlain.h"
#define CREATE_NODE(path) std::make_shared<FSPlainNode>(path)
#endif

// ─────────────────────────────────────────────
// MARK: - Цветовая палитра
// ─────────────────────────────────────────────
struct Palette {
    static NSColor* background()  { return [NSColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:1.0]; }
    static NSColor* surface()     { return [NSColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:1.0]; }
    static NSColor* accent()      { return [NSColor colorWithRed:0.40 green:0.65 blue:1.00 alpha:1.0]; }
    static NSColor* textPrimary() { return [NSColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0]; }
    static NSColor* textSecondary(){return [NSColor colorWithRed:0.55 green:0.55 blue:0.65 alpha:1.0]; }
};

// ─────────────────────────────────────────────
// MARK: - Delegate TableView & Основная Логика
// ─────────────────────────────────────────────
@interface MainAppController : NSObject <NSTableViewDataSource, NSTableViewDelegate> {
    NSTableView* _tableView;
    NSTextField* _pathLabel;
    
    std::shared_ptr<IFileSystemNode> _currentDir;
    std::vector<std::shared_ptr<IFileSystemNode>> _files;
}
@property (nonatomic, strong) NSWindow* window;
@end

@implementation MainAppController

- (void)setupWithWindow:(NSWindow*)win {
    self.window = win;
    [self buildUI];
    [self loadDirectory:[NSHomeDirectory() UTF8String]];
}

- (void)loadDirectory:(const std::string&)path {
    _currentDir = CREATE_NODE(path);
    _files = _currentDir->children();
    
    // Сортировка: папки сверху
    std::sort(_files.begin(), _files.end(), [](const auto& a, const auto& b) {
        if (a->isDirectory() != b->isDirectory()) return a->isDirectory();
        return a->name() < b->name();
    });
    
    [_pathLabel setStringValue:[NSString stringWithUTF8String:path.c_str()]];
    [_tableView reloadData];
}

- (void)buildUI {
    NSView* content = self.window.contentView;
    content.wantsLayer = YES;
    content.layer.backgroundColor = Palette::surface().CGColor;

    // --- Top Bar ---
    NSView* topBar = [[NSView alloc] initWithFrame:NSMakeRect(0, 550, 800, 50)];
    topBar.wantsLayer = YES;
    topBar.layer.backgroundColor = Palette::background().CGColor;
    [content addSubview:topBar];

    NSButton* upBtn = [[NSButton alloc] initWithFrame:NSMakeRect(15, 10, 40, 30)];
    [upBtn setTitle:@"↑"];
    [upBtn setBezelStyle:NSBezelStyleTexturedRounded];
    [upBtn setTarget:self];
    [upBtn setAction:@selector(goUp)];
    [topBar addSubview:upBtn];

    _pathLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(65, 15, 700, 20)];
    [_pathLabel setTextColor:Palette::textPrimary()];
    [_pathLabel setDrawsBackground:NO];
    [_pathLabel setBordered:NO];
    [_pathLabel setEditable:NO];
    [_pathLabel setFont:[NSFont systemFontOfSize:14 weight:NSFontWeightMedium]];
    [topBar addSubview:_pathLabel];

    // --- Main Table ---
    NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 800, 550)];
    [scrollView setHasVerticalScroller:YES];
    
    _tableView = [[NSTableView alloc] initWithFrame:scrollView.bounds];
    NSTableColumn* colIcon = [[NSTableColumn alloc] initWithIdentifier:@"Icon"];
    [colIcon setWidth:30];
    NSTableColumn* colName = [[NSTableColumn alloc] initWithIdentifier:@"Name"];
    [colName setWidth:450];
    NSTableColumn* colSize = [[NSTableColumn alloc] initWithIdentifier:@"Size"];
    [colSize setWidth:100];
    
    [_tableView addTableColumn:colIcon];
    [_tableView addTableColumn:colName];
    [_tableView addTableColumn:colSize];
    [_tableView setHeaderView:nil]; // Скрываем заголовки для минимализма
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    [_tableView setBackgroundColor:Palette::surface()];
    [_tableView setGridColor:[NSColor clearColor]];
    [_tableView setIntercellSpacing:NSMakeSize(0, 8)];
    [_tableView setRowHeight:30];
    [_tableView setTarget:self];
    [_tableView setDoubleAction:@selector(rowDoubleClicked)];

    // Context Menu
    NSMenu* menu = [[NSMenu alloc] init];
    
    NSMenuItem* openItem = [[NSMenuItem alloc] initWithTitle:@"Open" action:@selector(rowDoubleClicked) keyEquivalent:@""];
    [openItem setTarget:self];
    [menu addItem:openItem];
    
    NSMenuItem* infoItem = [[NSMenuItem alloc] initWithTitle:@"Get Info" action:@selector(showInfo) keyEquivalent:@""];
    [infoItem setTarget:self];
    [menu addItem:infoItem];
    
    NSMenuItem* renameItem = [[NSMenuItem alloc] initWithTitle:@"Rename..." action:@selector(renameItem) keyEquivalent:@""];
    [renameItem setTarget:self];
    [menu addItem:renameItem];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem* delItem = [[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteItem) keyEquivalent:@""];
    [delItem setTarget:self];
    [menu addItem:delItem];
    
    [_tableView setMenu:menu];

    [scrollView setDocumentView:_tableView];
    [content addSubview:scrollView];
}

// --- Навигация ---
- (void)goUp {
    if (!_currentDir) return;
    NSString* current = [NSString stringWithUTF8String:_currentDir->path().c_str()];
    NSString* parent = [current stringByDeletingLastPathComponent];
    if (![current isEqualToString:parent]) {
        [self loadDirectory:[parent UTF8String]];
    }
}

- (void)rowDoubleClicked {
    NSInteger row = [_tableView clickedRow];
    if (row < 0 || row >= _files.size()) return;
    
    auto node = _files[row];
    if (node->isDirectory()) {
        [self loadDirectory:node->path()];
    } else {
        // Современный способ через NSURL:
        NSString* nsPath = [NSString stringWithUTF8String:node->path().c_str()];
        NSURL* fileURL = [NSURL fileURLWithPath:nsPath];
        [[NSWorkspace sharedWorkspace] openURL:fileURL];
    }
}

// --- Операции ---
- (void)showInfo {
    NSInteger row = [_tableView clickedRow];
    if (row < 0) return;
    auto node = _files[row];
    
    NSString* name = [NSString stringWithUTF8String:node->name().c_str()];
    NSString* type = node->isDirectory() ? @"Folder" : @"File";
    NSString* date = [NSString stringWithUTF8String:node->creationDate().c_str()];
    long long size = node->size();
    NSString* sizeStr = size > 1024*1024 ? [NSString stringWithFormat:@"%.2f MB", size/1048576.0] : [NSString stringWithFormat:@"%lld Bytes", size];

    // Дополнительное окошечко (Инфо)
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:@"Info: %@", name]];
    [alert setInformativeText:[NSString stringWithFormat:@"Type:\t%@\nSize:\t%@\nCreated:\t%@", type, sizeStr, date]];
    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFile:[NSString stringWithUTF8String:node->path().c_str()]];
    [alert setIcon:icon];
    [alert addButtonWithTitle:@"Close"];
    [alert runModal];
}

- (void)renameItem {
    NSInteger row = [_tableView clickedRow];
    if (row < 0) return;
    auto node = _files[row];

    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Rename Item"];
    [alert addButtonWithTitle:@"Rename"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSTextField* input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:[NSString stringWithUTF8String:node->name().c_str()]];
    [alert setAccessoryView:input];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        std::string newName = [[input stringValue] UTF8String];
        if (node->renameItem(newName)) {
            [self loadDirectory:_currentDir->path()]; // Обновляем
        }
    }
}

- (void)deleteItem {
    NSInteger row = [_tableView clickedRow];
    if (row < 0) return;
    
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Are you sure?"];
    [alert setInformativeText:@"This action cannot be undone."];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        _files[row]->remove();
        [self loadDirectory:_currentDir->path()];
    }
}

// --- TableView Data Source ---
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _files.size();
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 30)];
        cell.identifier = tableColumn.identifier;
        
        NSTextField* tf = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 5, tableColumn.width, 20)];
        [tf setBezeled:NO]; [tf setDrawsBackground:NO]; [tf setEditable:NO];
        [tf setTextColor:Palette::textPrimary()];
        [tf setFont:[NSFont systemFontOfSize:13]];
        cell.textField = tf;
        [cell addSubview:tf];
        
        if ([tableColumn.identifier isEqualToString:@"Icon"]) {
            NSImageView* iv = [[NSImageView alloc] initWithFrame:NSMakeRect(5, 5, 20, 20)];
            cell.imageView = iv;
            [cell addSubview:iv];
        }
    }
    
    auto node = _files[row];
    if ([tableColumn.identifier isEqualToString:@"Name"]) {
        cell.textField.stringValue = [NSString stringWithUTF8String:node->name().c_str()];
    } else if ([tableColumn.identifier isEqualToString:@"Icon"]) {
        NSString* p = [NSString stringWithUTF8String:node->path().c_str()];
        cell.imageView.image = [[NSWorkspace sharedWorkspace] iconForFile:p];
    } else if ([tableColumn.identifier isEqualToString:@"Size"]) {
        if (node->isDirectory()) {
            cell.textField.stringValue = @"--";
            cell.textField.textColor = Palette::textSecondary();
        } else {
            long long s = node->size();
            cell.textField.stringValue = s > 1048576 ? [NSString stringWithFormat:@"%.1f MB", s/1048576.0] : [NSString stringWithFormat:@"%lld B", s];
            cell.textField.textColor = Palette::textPrimary();
        }
    }
    return cell;
}
@end

// ─────────────────────────────────────────────
// MARK: - AppDelegate & Main
// ─────────────────────────────────────────────
@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@property (strong) MainAppController *appController;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"MyFinder"];
    [self.window center];
    [self.window setBackgroundColor:Palette::background()];
    
    self.appController = [[MainAppController alloc] init];
    [self.appController setupWithWindow:self.window];
    
    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        
        NSMenu* menuBar = [[NSMenu alloc] init];
        NSMenuItem* appMenuItem = [[NSMenuItem alloc] init];
        [menuBar addItem:appMenuItem];
        NSMenu* appMenu = [[NSMenu alloc] initWithTitle:@"MyFinder"];
        [appMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
        [appMenuItem setSubmenu:appMenu];
        [NSApp setMainMenu:menuBar];

        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}