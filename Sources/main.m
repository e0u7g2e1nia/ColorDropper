#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <ScreenCaptureKit/ScreenCaptureKit.h>
#import <dlfcn.h>

static EventHotKeyID const kColorHotKeyID = {'COLR', 1};
static UInt32 const kColorHotKeyModifiers = cmdKey | optionKey | controlKey;
static UInt32 const kColorHotKeyCode = kVK_ANSI_C;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSPanel *floatingPanel;
@property(nonatomic, strong) NSButton *floatingButton;
@property(nonatomic, strong) id clickMonitor;
@property(nonatomic, assign) EventHotKeyRef hotKeyRef;
@property(nonatomic, assign) EventHandlerRef hotKeyHandler;
@property(nonatomic, copy) NSString *idleTitle;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    self.idleTitle = @"取色";
    [self buildMenuBarItem];
    [self buildFloatingPanel];
    [self registerHotKey];
    [self notifyWithTitle:@"ColorDropper 已启动" body:@"鼠标移到目标颜色上，按 ⌃⌥⌘C 复制 #RRGGBB"];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (self.clickMonitor != nil) {
        [NSEvent removeMonitor:self.clickMonitor];
        self.clickMonitor = nil;
    }
    if (self.hotKeyRef != NULL) {
        UnregisterEventHotKey(self.hotKeyRef);
    }
    if (self.hotKeyHandler != NULL) {
        RemoveEventHandler(self.hotKeyHandler);
    }
}

- (void)buildMenuBarItem {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = self.idleTitle;
    self.statusItem.button.toolTip = @"ColorDropper - ⌃⌥⌘C 复制鼠标下颜色";

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"取鼠标下颜色  ⌃⌥⌘C" action:@selector(copyColorUnderMouse) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"退出" action:@selector(quit) keyEquivalent:@"q"];
    self.statusItem.menu = menu;
}

- (void)buildFloatingPanel {
    NSRect frame = NSMakeRect(0, 0, 72, 34);
    self.floatingPanel = [[NSPanel alloc] initWithContentRect:frame
                                                    styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    self.floatingPanel.opaque = NO;
    self.floatingPanel.backgroundColor = NSColor.clearColor;
    self.floatingPanel.hasShadow = YES;
    self.floatingPanel.level = NSStatusWindowLevel;
    self.floatingPanel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                                            NSWindowCollectionBehaviorFullScreenAuxiliary |
                                            NSWindowCollectionBehaviorStationary;
    self.floatingPanel.ignoresMouseEvents = NO;

    NSView *background = [[NSView alloc] initWithFrame:frame];
    background.wantsLayer = YES;
    background.layer.backgroundColor = [NSColor colorWithWhite:0.96 alpha:0.96].CGColor;
    background.layer.cornerRadius = 17;
    background.layer.masksToBounds = YES;
    background.layer.borderWidth = 1.0;
    background.layer.borderColor = [NSColor colorWithWhite:0.58 alpha:0.55].CGColor;

    self.floatingButton = [[NSButton alloc] initWithFrame:frame];
    self.floatingButton.bezelStyle = NSBezelStyleTexturedRounded;
    self.floatingButton.bordered = NO;
    self.floatingButton.target = self;
    self.floatingButton.action = @selector(startClickPickMode);
    self.floatingButton.font = [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];
    [self setFloatingButtonTitle:@"取色"];

    [background addSubview:self.floatingButton];
    self.floatingPanel.contentView = background;
    [self positionFloatingPanel];
    [self.floatingPanel orderFrontRegardless];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionFloatingPanel)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];
}

- (void)setFloatingButtonTitle:(NSString *)title {
    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: NSColor.blackColor,
        NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold]
    };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attributes];
    self.floatingButton.attributedTitle = attributedTitle;
    self.floatingButton.attributedAlternateTitle = attributedTitle;
}

- (void)positionFloatingPanel {
    NSScreen *screen = NSScreen.mainScreen ?: NSScreen.screens.firstObject;
    if (screen == nil || self.floatingPanel == nil) {
        return;
    }

    NSRect visible = screen.visibleFrame;
    NSRect frame = self.floatingPanel.frame;
    CGFloat x = NSMaxX(visible) - frame.size.width - 16;
    CGFloat y = NSMaxY(visible) - frame.size.height - 56;
    [self.floatingPanel setFrameOrigin:NSMakePoint(x, y)];
}

- (void)registerHotKey {
    OSStatus registerStatus = RegisterEventHotKey(kColorHotKeyCode,
                                                  kColorHotKeyModifiers,
                                                  kColorHotKeyID,
                                                  GetApplicationEventTarget(),
                                                  0,
                                                  &_hotKeyRef);
    if (registerStatus != noErr) {
        self.statusItem.button.title = @"取色!";
        [self notifyWithTitle:@"快捷键注册失败"
                         body:@"⌃⌥⌘C 可能被其它 App 占用了；仍可从菜单栏点击“取鼠标下颜色”。"];
        return;
    }

    EventTypeSpec eventType = {kEventClassKeyboard, kEventHotKeyPressed};
    OSStatus handlerStatus = InstallEventHandler(GetApplicationEventTarget(),
                                                 HotKeyHandler,
                                                 1,
                                                 &eventType,
                                                 (__bridge void *)self,
                                                 &_hotKeyHandler);
    if (handlerStatus != noErr) {
        self.statusItem.button.title = @"取色!";
        [self notifyWithTitle:@"快捷键监听失败"
                         body:@"仍可从菜单栏点击“取鼠标下颜色”。"];
    }
}

static OSStatus HotKeyHandler(EventHandlerCallRef nextHandler, EventRef event, void *userData) {
    EventHotKeyID hotKeyID;
    GetEventParameter(event,
                      kEventParamDirectObject,
                      typeEventHotKeyID,
                      NULL,
                      sizeof(hotKeyID),
                      NULL,
                      &hotKeyID);

    if (hotKeyID.signature == kColorHotKeyID.signature && hotKeyID.id == kColorHotKeyID.id) {
        AppDelegate *delegate = (__bridge AppDelegate *)userData;
        [delegate copyColorUnderMouse];
    }

    return noErr;
}

- (void)copyColorUnderMouse {
    [self copyColorAtPoint:NSEvent.mouseLocation];
}

- (void)startClickPickMode {
    if (self.clickMonitor != nil) {
        return;
    }

    [self setFloatingButtonTitle:@"点击目标"];
    [self.floatingPanel orderOut:nil];
    [self notifyWithTitle:@"进入取色模式" body:@"点击屏幕上的目标颜色，或直接用 ⌃⌥⌘C 取鼠标当前位置。"];

    self.clickMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown
                                                               handler:^(NSEvent *event) {
        NSPoint point = NSEvent.mouseLocation;
        if (self.clickMonitor != nil) {
            [NSEvent removeMonitor:self.clickMonitor];
            self.clickMonitor = nil;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self copyColorAtPoint:point];
            [self.floatingPanel orderFrontRegardless];
        });
    }];
}

- (void)copyColorAtPoint:(NSPoint)mouse {
    NSColor *compositeColor = [self compositeScreenColorAtPoint:mouse];
    if (compositeColor != nil) {
        [self copyColor:compositeColor];
        return;
    }

    if (@available(macOS 15.2, *)) {
        NSRect captureRect = [self topLeftScreenRectForMousePoint:mouse size:1];
        self.statusItem.button.title = @"…";
        [self setFloatingButtonTitle:@"读取中"];

        [SCScreenshotManager captureImageInRect:NSRectToCGRect(captureRect)
                              completionHandler:^(CGImageRef _Nullable image, NSError * _Nullable error) {
            if (image == NULL || error != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusItem.button.title = self.idleTitle;
                    [self setFloatingButtonTitle:@"取色"];
                    [self.floatingPanel orderFrontRegardless];
                    [self notifyWithTitle:@"取色失败"
                                     body:@"请在 系统设置 > 隐私与安全性 > 屏幕录制 中允许 ColorDropper"];
                });
                return;
            }

            NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
            NSInteger centerX = MAX(0, bitmap.pixelsWide / 2);
            NSInteger centerY = MAX(0, bitmap.pixelsHigh / 2);
            NSColor *color = [bitmap colorAtX:centerX y:centerY];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.floatingPanel orderFrontRegardless];
                [self copyColor:color];
            });
        }];
    } else {
        [self notifyWithTitle:@"系统版本太低" body:@"这个取色器需要 macOS 15.2 或更新版本"];
    }
}

- (NSColor *)compositeScreenColorAtPoint:(NSPoint)mouse {
    typedef CGImageRef (*CGWindowListCreateImageFunc)(CGRect, CGWindowListOption, CGWindowID, CGWindowImageOption);
    static CGWindowListCreateImageFunc createImage = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        createImage = (CGWindowListCreateImageFunc)dlsym(RTLD_DEFAULT, "CGWindowListCreateImage");
    });

    if (createImage == NULL) {
        return nil;
    }

    CGRect captureRect = NSRectToCGRect([self topLeftScreenRectForMousePoint:mouse size:1]);
    CGImageRef image = createImage(captureRect,
                                   kCGWindowListOptionOnScreenOnly,
                                   kCGNullWindowID,
                                   kCGWindowImageBestResolution | kCGWindowImageShouldBeOpaque);
    if (image == NULL) {
        return nil;
    }

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:image];
    CGImageRelease(image);

    if (bitmap.pixelsWide < 1 || bitmap.pixelsHigh < 1) {
        return nil;
    }

    NSInteger centerX = bitmap.pixelsWide / 2;
    NSInteger centerY = bitmap.pixelsHigh / 2;
    return [bitmap colorAtX:centerX y:centerY];
}

- (NSRect)topLeftScreenRectForMousePoint:(NSPoint)mouse size:(CGFloat)size {
    CGFloat minX = CGFLOAT_MAX;
    CGFloat maxY = -CGFLOAT_MAX;

    for (NSScreen *screen in NSScreen.screens) {
        minX = MIN(minX, NSMinX(screen.frame));
        maxY = MAX(maxY, NSMaxY(screen.frame));
    }

    CGFloat originX = floor(mouse.x - minX - (size / 2.0));
    CGFloat originY = floor(maxY - mouse.y - (size / 2.0));
    return NSMakeRect(originX, originY, size, size);
}

- (void)copyColor:(NSColor *)color {
    if (color == nil) {
        self.statusItem.button.title = self.idleTitle;
        [self setFloatingButtonTitle:@"取色"];
        [self notifyWithTitle:@"取色失败"
                         body:@"请在 系统设置 > 隐私与安全性 > 屏幕录制 中允许 ColorDropper"];
        return;
    }

    NSColor *rgbColor = [color colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    NSInteger red = (NSInteger)lrint(rgbColor.redComponent * 255.0);
    NSInteger green = (NSInteger)lrint(rgbColor.greenComponent * 255.0);
    NSInteger blue = (NSInteger)lrint(rgbColor.blueComponent * 255.0);
    NSString *hex = [NSString stringWithFormat:@"#%02lX%02lX%02lX", (long)red, (long)green, (long)blue];

    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:hex forType:NSPasteboardTypeString];

    self.statusItem.button.title = @"✓";
    [self setFloatingButtonTitle:@"已复制"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.statusItem.button.title = self.idleTitle;
        [self setFloatingButtonTitle:@"取色"];
    });
    [self notifyWithTitle:@"已复制颜色" body:hex];
}

- (void)notifyWithTitle:(NSString *)title body:(NSString *)body {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = body;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)quit {
    [NSApp terminate:nil];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}
