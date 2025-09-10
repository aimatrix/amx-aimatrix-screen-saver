#import <ScreenSaver/ScreenSaver.h>

@interface ForceDrawTest : ScreenSaverView {
    NSArray *testStrings;
    int counter;
    NSTimer *forceTimer;
}
@end

@implementation ForceDrawTest

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        testStrings = @[@"A", @"B", @"C", @"Α", @"Β", @"Γ"];
        counter = 0;
        
        // FORCE no layer backing
        [self setWantsLayer:NO];
        
        // CRITICAL: Different approach - use our own timer instead of framework
        [self setAnimationTimeInterval:1000]; // Disable framework animation
        
        NSLog(@"ForceDrawTest: Init frame %@ preview %@", 
              NSStringFromRect(frame), isPreview ? @"YES" : @"NO");
    }
    return self;
}

// FORCE drawing using our own timer instead of framework
- (void)startForceDraw {
    forceTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(forceRedraw:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)forceRedraw:(NSTimer *)timer {
    counter++;
    NSLog(@"ForceDrawTest: Force redraw %d", counter);
    
    // FORCE multiple redraw methods
    [self setNeedsDisplay:YES];
    [self display];  // Force immediate draw
    [self displayIfNeeded];  // Force if needed
    
    // Also try updating the entire rect
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)stopForceDraw {
    [forceTimer invalidate];
    forceTimer = nil;
}

- (void)drawRect:(NSRect)rect {
    NSLog(@"ForceDrawTest: *** drawRect CALLED *** rect %@ preview %@", 
          NSStringFromRect(rect), self.isPreview ? @"YES" : @"NO");
    
    // FORCE black background - try multiple methods
    [[NSColor blackColor] set];
    NSRectFill(rect);
    NSRectFill(self.bounds);  // Also fill bounds
    
    // Use maximum contrast colors
    CGFloat fontSize = self.isPreview ? 12 : 64;  // HUGE font for full-screen
    
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: [NSColor colorWithRed:0 green:1 blue:0 alpha:1], // Pure green
        NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Bold" size:fontSize]
    };
    
    NSString *text = [NSString stringWithFormat:@"FORCE DRAW TEST %d %@", 
                      counter, testStrings[counter % testStrings.count]];
    
    // Draw at multiple positions for visibility
    CGFloat x = rect.size.width * 0.1;
    CGFloat y = rect.size.height * 0.5;
    
    [text drawAtPoint:NSMakePoint(x, y) withAttributes:attrs];
    
    // Also draw at corners
    [text drawAtPoint:NSMakePoint(20, 20) withAttributes:attrs];
    [text drawAtPoint:NSMakePoint(20, rect.size.height - 100) withAttributes:attrs];
    
    // Draw debug info
    NSString *debug = [NSString stringWithFormat:@"Rect: %.0fx%.0f Bounds: %.0fx%.0f Preview: %@", 
                       rect.size.width, rect.size.height,
                       self.bounds.size.width, self.bounds.size.height,
                       self.isPreview ? @"YES" : @"NO"];
    
    NSDictionary *debugAttrs = @{
        NSForegroundColorAttributeName: [NSColor yellowColor],
        NSFontAttributeName: [NSFont fontWithName:@"Monaco" size:fontSize * 0.4]
    };
    
    [debug drawAtPoint:NSMakePoint(x, y - fontSize - 10) withAttributes:debugAttrs];
    
    NSLog(@"ForceDrawTest: *** drawRect COMPLETED *** drew text at %.0f,%.0f", x, y);
}

// Override framework animation method - do nothing, we handle our own
- (void)animateOneFrame {
    NSLog(@"ForceDrawTest: animateOneFrame called (ignored - using our timer)");
    // Do nothing - our timer handles everything
}

- (void)startAnimation {
    [super startAnimation];
    [self startForceDraw];
    NSLog(@"ForceDrawTest: Starting animation and force timer");
}

- (void)stopAnimation {
    [super stopAnimation];
    [self stopForceDraw];
    NSLog(@"ForceDrawTest: Stopping animation and force timer");
}

@end