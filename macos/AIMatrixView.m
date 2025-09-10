#import <ScreenSaver/ScreenSaver.h>

@interface AIMatrixView : ScreenSaverView {
    NSMutableArray *columns;
    NSFont *matrixFont;
    int columnWidth;
    int charHeight;
}
@end

@implementation AIMatrixView

- (BOOL)isFlipped {
    return YES;  // Top-left origin
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        // 60 FPS for smooth animation
        [self setAnimationTimeInterval:1.0/60.0];
        
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
            column[@"y"] = @(-arc4random_uniform(500)); // Start above the screen
            column[@"length"] = @(5 + arc4random_uniform(20));
            column[@"speed"] = @(50 + arc4random_uniform(100)); // pixels per second
            column[@"lastUpdate"] = @(CACurrentMediaTime());
            column[@"chars"] = [self generateRandomChars:[column[@"length"] intValue]];
            [columns addObject:column];
        }
    }
    return self;
}

- (NSMutableArray *)generateRandomChars:(int)length {
    NSMutableArray *chars = [NSMutableArray array];
    NSString *text = @"aimatrix.com - the agentic twin platform ";
    
    // Fill the array with characters from the text, repeating as needed
    for (int i = 0; i < length; i++) {
        unichar c = [text characterAtIndex:(i % text.length)];
        [chars addObject:[NSString stringWithCharacters:&c length:1]];
    }
    return chars;
}

- (void)drawRect:(NSRect)rect {
    // Black background
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    // Draw each column
    for (NSMutableDictionary *column in columns) {
        float x = [column[@"x"] floatValue];
        float y = [column[@"y"] floatValue];
        int length = [column[@"length"] intValue];
        NSArray *chars = column[@"chars"];
        
        // Draw characters in the column
        for (int i = 0; i < length; i++) {
            // Calculate position (trail extends downward behind head)
            float charY = y + (i * charHeight);
            
            // Skip if off screen
            if (charY < -charHeight || charY > rect.size.height) continue;
            
            // Color intensity (brightest at head)
            float intensity;
            NSColor *color;
            
            if (i == 0) {
                // Head - bright white-green
                color = [NSColor colorWithRed:0.8 green:1.0 blue:0.8 alpha:1.0];
            } else {
                // Trail - fading green
                intensity = 1.0 - ((float)i / (float)length);
                color = [NSColor colorWithRed:0 green:intensity blue:0 alpha:intensity];
            }
            
            NSDictionary *attrs = @{
                NSFontAttributeName: matrixFont,
                NSForegroundColorAttributeName: color
            };
            
            [chars[i % chars.count] drawAtPoint:NSMakePoint(x, charY) withAttributes:attrs];
        }
    }
}

- (void)animateOneFrame {
    double currentTime = CACurrentMediaTime();
    
    // Update each column
    for (NSMutableDictionary *column in columns) {
        double lastUpdate = [column[@"lastUpdate"] doubleValue];
        double deltaTime = currentTime - lastUpdate;
        
        float y = [column[@"y"] floatValue];
        float speed = [column[@"speed"] floatValue];
        
        // Move down smoothly based on time
        y += speed * deltaTime;
        
        // Reset when the head goes off screen at the bottom
        if (y > self.bounds.size.height) {
            y = -arc4random_uniform(500);
            column[@"length"] = @(5 + arc4random_uniform(20));
            column[@"speed"] = @(50 + arc4random_uniform(100));
            column[@"chars"] = [self generateRandomChars:[column[@"length"] intValue]];
        }
        
        column[@"y"] = @(y);
        column[@"lastUpdate"] = @(currentTime);
        
        // No need to randomly change characters since we're showing specific text
    }
    
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