#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        
        // Create window
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 800, 600)
                                                        styleMask:NSWindowStyleMaskTitled |
                                                                  NSWindowStyleMaskClosable |
                                                                  NSWindowStyleMaskMiniaturizable |
                                                                  NSWindowStyleMaskResizable
                                                          backing:NSBackingStoreBuffered
                                                            defer:NO];
        [window setTitle:@"AIMatrix Screen Saver Test v5.19"];
        
        // Load the screen saver bundle
        NSString *bundlePath = [@"~/Library/Screen Savers/aimatrix-v5.19.saver" stringByExpandingTildeInPath];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        
        if (!bundle) {
            NSLog(@"ERROR: Failed to load bundle from %@", bundlePath);
            return 1;
        }
        
        NSLog(@"Bundle loaded successfully from %@", bundlePath);
        
        if (![bundle load]) {
            NSLog(@"ERROR: Failed to load bundle code");
            NSError *error = nil;
            if (![bundle loadAndReturnError:&error]) {
                NSLog(@"Bundle load error: %@", error);
            }
            return 1;
        }
        
        Class viewClass = [bundle principalClass];
        if (!viewClass) {
            NSLog(@"ERROR: Failed to get principal class from bundle");
            NSLog(@"Bundle principal class name: %@", [bundle objectForInfoDictionaryKey:@"NSPrincipalClass"]);
            return 1;
        }
        
        NSLog(@"Principal class loaded: %@", NSStringFromClass(viewClass));
        
        // Create the screen saver view
        ScreenSaverView *view = [[viewClass alloc] initWithFrame:window.contentView.bounds isPreview:NO];
        if (!view) {
            NSLog(@"ERROR: Failed to create screen saver view");
            return 1;
        }
        
        NSLog(@"Screen saver view created successfully");
        
        [window setContentView:view];
        [window makeKeyAndOrderFront:nil];
        
        // Start animation
        [view startAnimation];
        NSLog(@"Animation started");
        
        // Add a timer to periodically log status
        [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            NSLog(@"Window visible: %@, View animating: %@", 
                  window.isVisible ? @"YES" : @"NO",
                  view.isAnimating ? @"YES" : @"NO");
        }];
        
        [app run];
    }
    return 0;
}