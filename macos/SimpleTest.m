#import <ScreenSaver/ScreenSaver.h>
#import <Cocoa/Cocoa.h>

@interface SimpleTestSaver : ScreenSaverView
@end

@implementation SimpleTestSaver

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    return self;
}

- (void)drawRect:(NSRect)rect {
    // BLACK background
    [[NSColor blackColor] setFill];
    NSRectFill(self.bounds);
    
    // Draw Greek characters directly - no complex logic
    [[NSColor greenColor] set];
    NSFont *font = [NSFont systemFontOfSize:20];
    
    // Just draw some Greek characters in fixed positions
    [@"Α" drawAtPoint:NSMakePoint(50, 200) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor greenColor]
    }];
    [@"Β" drawAtPoint:NSMakePoint(80, 180) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor greenColor]
    }];
    [@"Γ" drawAtPoint:NSMakePoint(110, 160) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor greenColor]
    }];
    [@"Δ" drawAtPoint:NSMakePoint(140, 140) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor greenColor]
    }];
    [@"α" drawAtPoint:NSMakePoint(170, 120) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor greenColor]
    }];
    [@"β" drawAtPoint:NSMakePoint(200, 100) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor greenColor]
    }];
    [@"γ" drawAtPoint:NSMakePoint(230, 80) withAttributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [NSColor greenColor]
    }];
}

@end