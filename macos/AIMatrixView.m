#import <ScreenSaver/ScreenSaver.h>
#import <QuartzCore/QuartzCore.h>

@interface TextStream : NSObject
@property (nonatomic, strong) CATextLayer *textLayer;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) CGFloat currentY;
@end

@implementation TextStream
@end

@interface AIMatrixView : ScreenSaverView {
    NSString *displayText;
    NSMutableArray *textStreams;
    NSFont *matrixFont;
    CFTimeInterval lastFrameTime;
    CGFloat textHeight;
    CGFloat textWidth;
}
@end

@implementation AIMatrixView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        // Enable layer-backing for GPU acceleration
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [[NSColor blackColor] CGColor];
        
        // Turn off automatic animations for better control
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        // Initialize display text
        displayText = @"aimatrix.com - the agentic twin platform.... ";
        
        // Font setup
        matrixFont = [NSFont fontWithName:@"Menlo-Bold" size:18];
        if (!matrixFont) {
            matrixFont = [NSFont monospacedSystemFontOfSize:18 weight:NSFontWeightBold];
        }
        
        // Calculate text dimensions
        NSDictionary *attrs = @{NSFontAttributeName: matrixFont};
        NSSize textSize = [displayText sizeWithAttributes:attrs];
        textWidth = textSize.width;
        textHeight = textSize.height;
        
        textStreams = [NSMutableArray array];
        
        // Create text streams distributed across the screen
        int numColumns = 8;
        CGFloat columnSpacing = frame.size.width / numColumns;
        
        for (int col = 0; col < numColumns; col++) {
            // Create multiple streams per column
            for (int i = 0; i < 5; i++) {
                TextStream *stream = [[TextStream alloc] init];
                
                // Create CATextLayer for GPU-accelerated text rendering
                CATextLayer *textLayer = [CATextLayer layer];
                textLayer.string = displayText;
                textLayer.fontSize = 18;
                textLayer.font = (__bridge CFTypeRef)matrixFont;
                textLayer.foregroundColor = [[NSColor greenColor] CGColor];
                textLayer.frame = CGRectMake(col * columnSpacing, 
                                            -(i * 150) - arc4random_uniform(200),
                                            textWidth, 
                                            textHeight);
                textLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
                textLayer.allowsFontSubpixelQuantization = YES;
                
                // Add shadow for glow effect
                textLayer.shadowColor = [[NSColor greenColor] CGColor];
                textLayer.shadowOffset = CGSizeMake(0, 0);
                textLayer.shadowRadius = 3.0;
                textLayer.shadowOpacity = 0.8;
                
                [self.layer addSublayer:textLayer];
                
                stream.textLayer = textLayer;
                stream.speed = 80 + arc4random_uniform(40);
                stream.currentY = textLayer.frame.origin.y;
                
                [textStreams addObject:stream];
            }
        }
        
        [CATransaction commit];
        
        // Use 60 FPS timer
        [self setAnimationTimeInterval:1.0/60.0];
        lastFrameTime = CACurrentMediaTime();
    }
    return self;
}

- (void)animateOneFrame {
    CFTimeInterval currentTime = CACurrentMediaTime();
    CFTimeInterval deltaTime = currentTime - lastFrameTime;
    
    if (deltaTime > 1.0/30.0) deltaTime = 1.0/30.0;
    
    // Disable implicit animations for smooth updates
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    for (TextStream *stream in textStreams) {
        // Update position
        stream.currentY += stream.speed * deltaTime;
        
        // Reset if off screen
        if (stream.currentY > self.bounds.size.height) {
            stream.currentY = -textHeight - arc4random_uniform(300);
            CGFloat newX = arc4random_uniform(self.bounds.size.width - textWidth);
            stream.textLayer.frame = CGRectMake(newX, stream.currentY, textWidth, textHeight);
            stream.speed = 80 + arc4random_uniform(40);
            
            // Vary the green color slightly
            CGFloat greenValue = 0.7 + (arc4random_uniform(30) / 100.0);
            stream.textLayer.foregroundColor = [[NSColor colorWithRed:0 green:greenValue blue:0 alpha:1.0] CGColor];
            stream.textLayer.shadowColor = [[NSColor colorWithRed:0 green:greenValue blue:0 alpha:1.0] CGColor];
        } else {
            // Just update Y position
            CGRect frame = stream.textLayer.frame;
            frame.origin.y = stream.currentY;
            stream.textLayer.frame = frame;
        }
        
        // Fade based on position
        CGFloat fadeStart = self.bounds.size.height * 0.7;
        if (stream.currentY > fadeStart) {
            CGFloat fadeAmount = 1.0 - ((stream.currentY - fadeStart) / (self.bounds.size.height * 0.3));
            stream.textLayer.opacity = fadeAmount;
        } else {
            stream.textLayer.opacity = 1.0;
        }
    }
    
    [CATransaction commit];
    
    lastFrameTime = currentTime;
}

- (void)drawRect:(NSRect)rect {
    // Background is handled by layer, no need to draw
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
    [label setStringValue:@"AIMatrix Screen Saver\nGPU-Accelerated Digital Rain"];
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