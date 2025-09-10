#import <ScreenSaver/ScreenSaver.h>

@interface TestFall : ScreenSaverView {
    float ballY;
}
@end

@implementation TestFall

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1.0/30.0];
        ballY = frame.size.height - 50; // Start near top
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    [[NSColor greenColor] setFill];
    // Draw a simple circle
    NSRect ball = NSMakeRect(rect.size.width/2 - 25, ballY, 50, 50);
    [[NSBezierPath bezierPathWithOvalInRect:ball] fill];
    
    // Draw text showing Y value
    NSString *text = [NSString stringWithFormat:@"Y: %.0f", ballY];
    NSDictionary *attrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:20],
        NSForegroundColorAttributeName: [NSColor whiteColor]
    };
    [text drawAtPoint:NSMakePoint(10, rect.size.height - 30) withAttributes:attrs];
}

- (void)animateOneFrame {
    // Try decreasing Y
    ballY -= 2;
    
    // Reset when it goes off bottom
    if (ballY < -50) {
        ballY = self.bounds.size.height;
    }
    
    [self setNeedsDisplay:YES];
}

@end