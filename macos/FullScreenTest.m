#import <ScreenSaver/ScreenSaver.h>

@interface FullScreenTest : ScreenSaverView {
    NSArray *testStrings;
    int counter;
    NSScreen *targetScreen;
}
@end

@implementation FullScreenTest

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        testStrings = @[@"A", @"B", @"C", @"Α", @"Β", @"Γ"];
        counter = 0;
        
        // CRITICAL: Detect target screen for multi-display support
        targetScreen = [self detectTargetScreen];
        
        // FORCE proper layer setup for full-screen
        [self setWantsLayer:NO];  // Disable layer backing for full-screen compatibility
        
        [self setAnimationTimeInterval:0.5];
        
        NSLog(@"FullScreenTest: Init frame %@ preview %@ screen %@", 
              NSStringFromRect(frame),
              isPreview ? @"YES" : @"NO",
              targetScreen ? targetScreen.localizedName : @"unknown");
    }
    return self;
}

- (NSScreen *)detectTargetScreen {
    // More aggressive screen detection for full-screen mode
    NSRect myFrame = self.frame;
    
    NSLog(@"FullScreenTest: Detecting screen for frame %@", NSStringFromRect(myFrame));
    
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect screenFrame = screen.frame;
        NSLog(@"FullScreenTest: Checking screen %@ frame %@", 
              screen.localizedName, NSStringFromRect(screenFrame));
        
        // Check if our frame is anywhere on this screen
        NSRect intersection = NSIntersectionRect(myFrame, screenFrame);
        if (intersection.size.width > 0 && intersection.size.height > 0) {
            NSLog(@"FullScreenTest: MATCHED screen %@ intersection %@", 
                  screen.localizedName, NSStringFromRect(intersection));
            return screen;
        }
    }
    
    // If no intersection found, use main screen
    NSLog(@"FullScreenTest: No intersection found, using main screen");
    return [NSScreen mainScreen];
}

- (void)drawRect:(NSRect)rect {
    NSLog(@"FullScreenTest: drawRect called with rect %@ preview %@", 
          NSStringFromRect(rect), self.isPreview ? @"YES" : @"NO");
    
    // CRITICAL: Always fill the entire rect with black
    [[NSColor blackColor] set];
    NSRectFill(rect);
    
    // Use larger font for full-screen visibility
    CGFloat fontSize = self.isPreview ? 14 : 48;  // Much larger for full-screen
    
    // Bright colors for maximum visibility
    NSColor *textColor = [NSColor colorWithRed:0 green:1 blue:0 alpha:1]; // Pure green
    
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: textColor,
        NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Bold" size:fontSize]
    };
    
    NSString *text = [NSString stringWithFormat:@"FULLSCREEN TEST - FRAME %d - %@", 
                      counter,
                      testStrings[counter % testStrings.count]];
    
    // Draw text at center of screen
    NSSize textSize = [text sizeWithAttributes:attrs];
    CGFloat x = (rect.size.width - textSize.width) / 2;
    CGFloat y = (rect.size.height - textSize.height) / 2;
    
    [text drawAtPoint:NSMakePoint(x, y) withAttributes:attrs];
    
    // Draw screen info
    NSString *info = [NSString stringWithFormat:@"Screen: %@ | Rect: %.0fx%.0f | Preview: %@", 
                      targetScreen ? targetScreen.localizedName : @"UNKNOWN",
                      rect.size.width, rect.size.height,
                      self.isPreview ? @"YES" : @"NO"];
    
    NSDictionary *infoAttrs = @{
        NSForegroundColorAttributeName: [NSColor yellowColor],
        NSFontAttributeName: [NSFont fontWithName:@"Monaco" size:fontSize * 0.6]
    };
    
    [info drawAtPoint:NSMakePoint(20, 20) withAttributes:infoAttrs];
    
    NSLog(@"FullScreenTest: Drew text '%@' at %.0f,%.0f in rect %@", 
          text, x, y, NSStringFromRect(rect));
}

- (void)animateOneFrame {
    counter++;
    [self setNeedsDisplay:YES];
    NSLog(@"FullScreenTest: Animate frame %d, calling setNeedsDisplay", counter);
}

- (void)startAnimation {
    [super startAnimation];
    NSLog(@"FullScreenTest: Starting animation on %@ preview %@", 
          targetScreen ? targetScreen.localizedName : @"unknown",
          self.isPreview ? @"YES" : @"NO");
}

- (void)stopAnimation {
    [super stopAnimation];
    NSLog(@"FullScreenTest: Stopping animation");
}

// Override to detect when we become full-screen
- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    NSLog(@"FullScreenTest: viewDidMoveToWindow - window %@ frame %@", 
          self.window, NSStringFromRect(self.frame));
}

@end