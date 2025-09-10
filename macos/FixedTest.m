#import <ScreenSaver/ScreenSaver.h>

@interface FixedTest : ScreenSaverView {
    NSArray *testStrings;
    int counter;
    NSScreen *targetScreen;
}
@end

@implementation FixedTest

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        testStrings = @[@"A", @"B", @"C", @"Α", @"Β", @"Γ"];
        counter = 0;
        
        // CRITICAL: Detect target screen for multi-display support
        targetScreen = [self detectTargetScreen];
        
        // Force layer backing for GPU acceleration
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [[NSColor blackColor] CGColor];
        self.layer.opaque = YES;
        
        [self setAnimationTimeInterval:0.5]; // 2 FPS for visibility
        
        NSLog(@"FixedTest: Init on screen %@ frame %@", 
              targetScreen ? targetScreen.localizedName : @"unknown",
              NSStringFromRect(frame));
    }
    return self;
}

- (NSScreen *)detectTargetScreen {
    // Try to detect which screen this screen saver instance is for
    NSRect myFrame = self.frame;
    
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect screenFrame = screen.frame;
        // Check if our frame overlaps significantly with this screen
        NSRect intersection = NSIntersectionRect(myFrame, screenFrame);
        if (intersection.size.width > myFrame.size.width * 0.5 && 
            intersection.size.height > myFrame.size.height * 0.5) {
            NSLog(@"FixedTest: Detected target screen %@", screen.localizedName);
            return screen;
        }
    }
    
    // Fallback to main screen
    NSLog(@"FixedTest: Using main screen as fallback");
    return [NSScreen mainScreen];
}

- (void)drawRect:(NSRect)rect {
    // CRITICAL: Always fill the entire rect, not just bounds
    [[NSColor blackColor] set];
    NSRectFill(rect);
    
    // Scale font based on screen size for better visibility
    CGFloat fontSize = 24;
    if (targetScreen) {
        CGFloat screenWidth = targetScreen.frame.size.width;
        fontSize = MAX(24, screenWidth / 80); // Scale font with screen width
    }
    
    // Draw bright green text
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: [NSColor greenColor],
        NSFontAttributeName: [NSFont fontWithName:@"Monaco" size:fontSize]
    };
    
    NSString *text = [NSString stringWithFormat:@"SCREEN: %@ - TEST %@ FRAME %d", 
                      targetScreen ? targetScreen.localizedName : @"UNKNOWN",
                      testStrings[counter % testStrings.count], 
                      counter];
    
    // Draw text at multiple positions for visibility
    CGFloat x = rect.size.width * 0.1;
    CGFloat y = rect.size.height * 0.5;
    
    [text drawAtPoint:NSMakePoint(x, y) withAttributes:attrs];
    
    // Draw additional info
    NSString *info = [NSString stringWithFormat:@"Rect: %.0fx%.0f Preview: %@", 
                      rect.size.width, rect.size.height, 
                      self.isPreview ? @"YES" : @"NO"];
    
    [info drawAtPoint:NSMakePoint(x, y - fontSize - 10) withAttributes:attrs];
    
    NSLog(@"FixedTest: Drawing frame %d on %@ rect %@ preview %@", 
          counter, 
          targetScreen ? targetScreen.localizedName : @"unknown",
          NSStringFromRect(rect),
          self.isPreview ? @"YES" : @"NO");
}

- (void)animateOneFrame {
    counter++;
    [self setNeedsDisplay:YES];
    NSLog(@"FixedTest: Animate frame %d", counter);
}

- (void)startAnimation {
    [super startAnimation];
    NSLog(@"FixedTest: Starting animation on %@", targetScreen ? targetScreen.localizedName : @"unknown");
}

- (void)stopAnimation {
    [super stopAnimation];
    NSLog(@"FixedTest: Stopping animation");
}

@end