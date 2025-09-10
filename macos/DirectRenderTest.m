#import <ScreenSaver/ScreenSaver.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

@interface DirectRenderTest : ScreenSaverView {
    NSOpenGLView *glView;
    NSTimer *renderTimer;
    int frameCount;
}
@end

@implementation DirectRenderTest

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        frameCount = 0;
        
        // Create OpenGL view that bypasses normal drawing
        NSOpenGLPixelFormatAttribute attrs[] = {
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
            0
        };
        
        NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
        glView = [[NSOpenGLView alloc] initWithFrame:frame pixelFormat:pixelFormat];
        
        if (glView) {
            [self addSubview:glView];
            glView.frame = self.bounds;
            glView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        }
        
        NSLog(@"DirectRenderTest: Init frame %@ preview %@ OpenGL: %@", 
              NSStringFromRect(frame), 
              isPreview ? @"YES" : @"NO",
              glView ? @"SUCCESS" : @"FAILED");
    }
    return self;
}

- (void)renderOpenGL {
    if (!glView || !glView.openGLContext) return;
    
    [glView.openGLContext makeCurrentContext];
    
    frameCount++;
    
    // Clear to black
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Draw bright green rectangle
    float brightness = 0.5 + 0.5 * sin(frameCount * 0.1); // Pulse
    glColor3f(0.0, brightness, 0.0);
    
    glBegin(GL_QUADS);
        glVertex2f(-0.5, -0.2);
        glVertex2f( 0.5, -0.2);
        glVertex2f( 0.5,  0.2);
        glVertex2f(-0.5,  0.2);
    glEnd();
    
    // Draw pulsing border
    glColor3f(1.0, 1.0, 0.0); // Yellow
    glLineWidth(5.0);
    glBegin(GL_LINE_LOOP);
        glVertex2f(-0.9, -0.9);
        glVertex2f( 0.9, -0.9);
        glVertex2f( 0.9,  0.9);
        glVertex2f(-0.9,  0.9);
    glEnd();
    
    [glView.openGLContext flushBuffer];
    
    NSLog(@"DirectRenderTest: OpenGL frame %d rendered", frameCount);
}

// Fallback: regular drawing if OpenGL fails
- (void)drawRect:(NSRect)rect {
    NSLog(@"DirectRenderTest: drawRect fallback - rect %@", NSStringFromRect(rect));
    
    [[NSColor blackColor] set];
    NSRectFill(rect);
    
    // Draw fallback text
    NSDictionary *attrs = @{
        NSForegroundColorAttributeName: [NSColor redColor],
        NSFontAttributeName: [NSFont fontWithName:@"Helvetica-Bold" size:36]
    };
    
    NSString *text = [NSString stringWithFormat:@"FALLBACK DRAWING %d", frameCount];
    CGFloat x = rect.size.width * 0.1;
    CGFloat y = rect.size.height * 0.5;
    
    [text drawAtPoint:NSMakePoint(x, y) withAttributes:attrs];
}

- (void)startRenderTimer {
    renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0  // 30 FPS
                                                   target:self
                                                 selector:@selector(timerRender:)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)timerRender:(NSTimer *)timer {
    [self renderOpenGL];
    [self setNeedsDisplay:YES]; // Also trigger fallback
}

- (void)stopRenderTimer {
    [renderTimer invalidate];
    renderTimer = nil;
}

- (void)startAnimation {
    [super startAnimation];
    [self startRenderTimer];
    NSLog(@"DirectRenderTest: Starting direct rendering");
}

- (void)stopAnimation {
    [super stopAnimation];
    [self stopRenderTimer];
    NSLog(@"DirectRenderTest: Stopping direct rendering");
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if (self.window) {
        NSLog(@"DirectRenderTest: Moved to window %@", self.window);
        // Ensure OpenGL view is properly sized
        if (glView) {
            glView.frame = self.bounds;
        }
    }
}

@end