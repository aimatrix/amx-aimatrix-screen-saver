#import <ScreenSaver/ScreenSaver.h>

@interface SimpleTest2 : ScreenSaverView {
    NSArray *testStrings;
    int counter;
}
@end

@implementation SimpleTest2

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        testStrings = @[@"A", @"B", @"C", @"Α", @"Β", @"Γ"];
        counter = 0;
        [self setAnimationTimeInterval:0.5]; // 2 FPS for visibility
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Fill with black
    [[NSColor blackColor] set];
    NSRectFill(rect);
    
    // Draw bright green text
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: [NSColor greenColor],
        NSFontAttributeName: [NSFont fontWithName:@"Monaco" size:24]
    };
    
    NSString *text = [NSString stringWithFormat:@"TEST %@ FRAME %d", 
                      testStrings[counter % testStrings.count], counter];
    
    [text drawAtPoint:NSMakePoint(50, 50) withAttributes:attrs];
    
    NSLog(@"SimpleTest2: Drawing frame %d", counter);
}

- (void)animateOneFrame {
    counter++;
    [self setNeedsDisplay:YES];
}

@end