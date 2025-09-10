#import <ScreenSaver/ScreenSaver.h>
#import <QuartzCore/QuartzCore.h>

@interface AIMatrixView : ScreenSaverView {
    NSMutableArray *columns;
    NSFont *matrixFont;
    int columnWidth;
    int charHeight;
    CFTimeInterval lastFrameTime;
}
@end

@implementation AIMatrixView

- (BOOL)isFlipped {
    return YES;  // Top-left origin
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        // Use CADisplayLink for buttery smooth 60 FPS animation synchronized with display refresh
        [self setAnimationTimeInterval:1.0/60.0];
        
        // Enable layer-backing for better performance and smoother rendering
        [self setWantsLayer:YES];
        self.layer.drawsAsynchronously = YES;
        
        // Font setup
        matrixFont = [NSFont fontWithName:@"Menlo" size:14];
        if (!matrixFont) {
            matrixFont = [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightMedium];
        }
        
        columnWidth = 10;
        charHeight = 16;
        
        // Initialize columns
        columns = [NSMutableArray array];
        int numColumns = frame.size.width / columnWidth;
        
        for (int i = 0; i < numColumns; i++) {
            NSMutableDictionary *column = [NSMutableDictionary dictionary];
            column[@"x"] = @(i * columnWidth);
            // Use double precision for ultra-smooth subpixel animation
            column[@"y"] = @((double)-arc4random_uniform(500)); // Start above the screen
            column[@"length"] = @(5 + arc4random_uniform(20));
            column[@"speed"] = @(60.0 + (double)(arc4random_uniform(80))); // pixels per second, optimized for 60fps
            column[@"lastUpdate"] = @(CACurrentMediaTime());
            column[@"chars"] = [self generateRandomChars:[column[@"length"] intValue]];
            [columns addObject:column];
        }
        
        // Initialize display link for precise frame timing
        lastFrameTime = CACurrentMediaTime();
    }
    return self;
}

- (NSMutableArray *)generateRandomChars:(int)length {
    NSMutableArray *chars = [NSMutableArray array];
    NSString *text = @"aimatrix.com - the agentic twin platform.... ";
    
    // Fill the array with characters from the text, repeating as needed
    for (int i = 0; i < length; i++) {
        unichar c = [text characterAtIndex:(i % text.length)];
        [chars addObject:[NSString stringWithCharacters:&c length:1]];
    }
    return chars;
}

- (void)drawRect:(NSRect)rect {
    // Enable high-quality rendering for ultra-smooth text
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context setShouldAntialias:YES];
    [context setImageInterpolation:NSImageInterpolationHigh];
    
    // Enable subpixel text positioning for smoothest possible rendering
    CGContextRef cgContext = [context CGContext];
    CGContextSetShouldSubpixelPositionFonts(cgContext, YES);
    CGContextSetShouldSubpixelQuantizeFonts(cgContext, YES);
    CGContextSetAllowsAntialiasing(cgContext, YES);
    CGContextSetShouldSmoothFonts(cgContext, YES);
    
    // Black background
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    // Draw each column with subpixel precision
    for (NSMutableDictionary *column in columns) {
        double x = [column[@"x"] doubleValue];
        double y = [column[@"y"] doubleValue];
        int length = [column[@"length"] intValue];
        NSArray *chars = column[@"chars"];
        
        // Draw characters in the column with subpixel positioning
        for (int i = 0; i < length; i++) {
            // Calculate position with double precision for ultra-smooth movement
            double charY = y + ((double)i * (double)charHeight);
            
            // Skip if off screen (with some margin for smooth transitions)
            if (charY < -charHeight * 2 || charY > rect.size.height + charHeight) continue;
            
            // Color intensity (brightest at head)
            double intensity;
            NSColor *color;
            
            if (i == 0) {
                // Head - bright white-green
                color = [NSColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:1.0];
            } else {
                // Trail - fading green with smooth gradient
                intensity = 1.0 - ((double)i / (double)length);
                color = [NSColor colorWithRed:0 green:intensity * 0.8 blue:0 alpha:intensity];
            }
            
            NSDictionary *attrs = @{
                NSFontAttributeName: matrixFont,
                NSForegroundColorAttributeName: color
            };
            
            // Use subpixel-precise positioning for ultra-smooth text rendering
            [chars[i % chars.count] drawAtPoint:NSMakePoint(x, charY) withAttributes:attrs];
        }
    }
}

- (void)animateOneFrame {
    CFTimeInterval currentTime = CACurrentMediaTime();
    CFTimeInterval deltaTime = currentTime - lastFrameTime;
    
    // Cap delta time to prevent large jumps if frame rate drops
    if (deltaTime > 1.0/30.0) deltaTime = 1.0/30.0;
    
    // Update each column with ultra-precise timing
    for (NSMutableDictionary *column in columns) {
        double y = [column[@"y"] doubleValue];
        double speed = [column[@"speed"] doubleValue];
        
        // Move down smoothly with subpixel precision
        double movement = speed * deltaTime;
        y += movement;
        
        // Reset when the head goes off screen at the bottom
        if (y > self.bounds.size.height + 100) {
            y = (double)(-arc4random_uniform(800) - 100); // Start further up for smoother entry
            column[@"length"] = @(8 + arc4random_uniform(15)); // Slightly longer trails
            column[@"speed"] = @(80.0 + (double)(arc4random_uniform(60))); // Faster for 60fps
            column[@"chars"] = [self generateRandomChars:[column[@"length"] intValue]];
        }
        
        column[@"y"] = @(y);
    }
    
    lastFrameTime = currentTime;
    
    // Use display synchronization for perfectly smooth updates
    [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet { 
    return YES; 
}

- (NSWindow *)configureSheet {
    NSWindow *sheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    
    NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 200)];
    
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 100, 300, 40)];
    [label setStringValue:@"AIMatrix Screen Saver\nDigital Rain Effect"];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setAlignment:NSTextAlignmentCenter];
    [contentView addSubview:label];
    
    NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(160, 20, 80, 30)];
    [okButton setTitle:@"OK"];
    [okButton setBezelStyle:NSBezelStyleRounded];
    [okButton setTarget:self];
    [okButton setAction:@selector(closeSheet:)];
    [contentView addSubview:okButton];
    
    [sheet setContentView:contentView];
    return sheet;
}

- (void)closeSheet:(id)sender {
    [[NSApplication sharedApplication] endSheet:[sender window]];
}

@end