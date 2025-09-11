#import <ScreenSaver/ScreenSaver.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <GLUT/glut.h>
#import <OpenGL/OpenGL.h>
#import "AIMatrixConfig.h"

typedef struct {
    float x, y;
    float speed;
    float brightness;
    int charIndex;
    int columnIndex;
} MatrixChar;

@interface AIMatrixView : ScreenSaverView {
    NSOpenGLView *glView;
    NSOpenGLContext *glContext;
    NSOpenGLPixelFormat *pixelFormat;
    
    NSString *displayText;
    MatrixChar *particles;
    int particleCount;
    
    GLuint textureID;
    unsigned char *textureData;
    int textureWidth;
    int textureHeight;
    
    CFAbsoluteTime lastFrameTime;
    float screenWidth;
    float screenHeight;
    float backingScaleFactor;
}
@end

@implementation AIMatrixView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    // Create OpenGL pixel format with multi-monitor support
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADepthSize, 16,
        NSOpenGLPFAMinimumPolicy,
        NSOpenGLPFAAllowOfflineRenderers,  // Support external displays
        0
    };
    
    pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    if (!pixelFormat) {
        NSLog(@"Failed to create pixel format");
        return nil;
    }
    
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        // Load configuration
        AIMatrixConfig *config = [AIMatrixConfig sharedConfig];
        displayText = [config getCharacterSetString];
        
        // Create OpenGL context
        glContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
        [glContext setView:self];
        [glContext makeCurrentContext];
        
        // Enable vsync for smooth animation
        GLint swapInt = 1;
        [glContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
        
        // Get the backing scale factor (for Retina displays)
        backingScaleFactor = [[NSScreen mainScreen] backingScaleFactor];
        if (self.window && self.window.screen) {
            backingScaleFactor = self.window.screen.backingScaleFactor;
        }
        
        // Calculate the actual pixel dimensions (accounting for Retina)
        NSRect bounds = [self bounds];
        screenWidth = bounds.size.width * backingScaleFactor;
        screenHeight = bounds.size.height * backingScaleFactor;
        
        NSLog(@"Screen saver initialized with bounds: %.0fx%.0f, backing scale: %.1f, pixel dimensions: %.0fx%.0f",
              bounds.size.width, bounds.size.height, backingScaleFactor, screenWidth, screenHeight);
        
        [self setupOpenGL];
        [self createTextTexture];
        [self initializeParticles];
        
        lastFrameTime = CFAbsoluteTimeGetCurrent();
        
        [self setAnimationTimeInterval:1.0/60.0];
    }
    return self;
}


- (void)setupOpenGL {
    [glContext makeCurrentContext];
    
    // Clear to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    
    // Setup viewport using actual pixel dimensions (important for Retina displays)
    glViewport(0, 0, screenWidth, screenHeight);
    
    // Setup 2D projection using logical coordinates (not pixel coordinates)
    // This ensures consistent rendering across Retina and non-Retina displays
    NSRect bounds = [self bounds];
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, bounds.size.width, bounds.size.height, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    NSLog(@"OpenGL viewport: %.0fx%.0f pixels, projection: %.0fx%.0f points", 
          screenWidth, screenHeight, bounds.size.width, bounds.size.height);
}

- (void)createTextTexture {
    // Create texture for text characters
    textureWidth = 512;
    textureHeight = 512;
    textureData = calloc(textureWidth * textureHeight * 4, sizeof(unsigned char));
    
    // Create bitmap context
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(textureData,
                                                 textureWidth,
                                                 textureHeight,
                                                 8,
                                                 textureWidth * 4,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    
    // Draw characters (70% of previous 80pt = 56pt)
    AIMatrixConfig *config = [AIMatrixConfig sharedConfig];
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSelectFont(context, "Menlo", config.fontSize, kCGEncodingMacRoman);
    CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1.0, -1.0));
    
    // Draw each character from displayText (adjusted for 56pt font)
    for (int i = 0; i < displayText.length && i < 64; i++) {
        int row = i / 5;  // 5 chars per row for 56pt font
        int col = i % 5;
        float x = col * 100 + 20;  // Adjusted spacing
        float y = textureHeight - (row * 100 + 70);  // Adjusted for font size
        
        NSString *charStr = [displayText substringWithRange:NSMakeRange(i, 1)];
        const char *ch = [charStr UTF8String];
        CGContextShowTextAtPoint(context, x, y, ch, strlen(ch));
    }
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create OpenGL texture
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, textureWidth, textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
}

- (void)initializeParticles {
    // Use logical coordinates (points) not pixel coordinates
    NSRect bounds = [self bounds];
    float logicalWidth = bounds.size.width;
    float logicalHeight = bounds.size.height;
    
    // Create particle system for Matrix rain (adjusted for 56pt font)
    int numColumns = logicalWidth / 45;  // Spacing for 70% size
    int charsPerColumn = (int)(logicalHeight / 45);  // No overlapping
    particleCount = numColumns * charsPerColumn;
    particles = calloc(particleCount, sizeof(MatrixChar));
    
    int index = 0;
    for (int col = 0; col < numColumns; col++) {
        float x = col * 45.0 + 22.5;  // 70% of previous spacing
        float startY = -(float)(random() % (int)logicalHeight);
        AIMatrixConfig *config = [AIMatrixConfig sharedConfig];
        float speed = (50.0 + (random() % 100)) * config.animationSpeed;
        
        for (int row = 0; row < charsPerColumn; row++) {
            particles[index].x = x;
            particles[index].y = startY + (row * 45);  // No overlapping spacing
            particles[index].speed = speed;
            // Reversed gradient: brighter at bottom (higher row = brighter)
            particles[index].brightness = (row / (float)charsPerColumn);
            particles[index].charIndex = random() % displayText.length;
            particles[index].columnIndex = col;
            index++;
        }
    }
}

- (void)animateOneFrame {
    [glContext makeCurrentContext];
    
    // Check if we need to update dimensions
    NSRect bounds = [self bounds];
    float expectedWidth = bounds.size.width * backingScaleFactor;
    float expectedHeight = bounds.size.height * backingScaleFactor;
    
    if (fabs(expectedWidth - screenWidth) > 1.0 || fabs(expectedHeight - screenHeight) > 1.0) {
        [self reshape];
    }
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    float deltaTime = currentTime - lastFrameTime;
    if (deltaTime > 0.1) deltaTime = 0.1; // Cap delta time
    lastFrameTime = currentTime;
    
    // Clear entire framebuffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Enable texturing
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    // Update and draw particles (using logical coordinates)
    float logicalHeight = bounds.size.height;
    
    for (int i = 0; i < particleCount; i++) {
        // Update position - ADD to make it fall DOWN (y increases downward in our coordinate system)
        particles[i].y += particles[i].speed * deltaTime;
        
        // Reset if off bottom of screen (use logical height)
        if (particles[i].y > logicalHeight + 20) {
            particles[i].y = -20 - (random() % 200);
            particles[i].charIndex = random() % displayText.length;
        }
        
        // Calculate color (green with brightness)
        float brightness = particles[i].brightness;
        
        // Fade at bottom (use logical height)
        if (particles[i].y > logicalHeight * 0.7) {
            brightness *= 1.0 - ((particles[i].y - logicalHeight * 0.7) / (logicalHeight * 0.3));
        }
        
        // Set color based on configuration
        AIMatrixConfig *config = [AIMatrixConfig sharedConfig];
        NSColor *baseColor = config.primaryColor;
        CGFloat r, g, b, a;
        [baseColor getRed:&r green:&g blue:&b alpha:&a];
        
        // Head of column check adjusted for dynamic column height
        int charsPerCol = (int)(logicalHeight / 45);
        if (i % charsPerCol == charsPerCol - 1) {
            // Head of column - brighter
            glColor4f(MIN(1.0, r * 0.8 + 0.2), MIN(1.0, g), MIN(1.0, b * 0.8 + 0.2), brightness);
        } else {
            // Trail - use configured color
            glColor4f(r * brightness, g * brightness, b * brightness, brightness * 0.9);
        }
        
        // Calculate texture coordinates for character (5 chars per row for 56pt font)
        int charIndex = particles[i].charIndex;
        float texSize = 1.0 / 5.0;  // 5 chars per row
        float texX = (charIndex % 5) * texSize;
        float texY = (charIndex / 5) * texSize;
        
        // Draw character as textured quad (70% of 60 = 42)
        float x = particles[i].x;
        float y = particles[i].y;
        float size = 42.0;  // 70% of previous 60pt
        
        glBegin(GL_QUADS);
        glTexCoord2f(texX, texY);
        glVertex2f(x - size/2, y - size/2);
        
        glTexCoord2f(texX + texSize, texY);
        glVertex2f(x + size/2, y - size/2);
        
        glTexCoord2f(texX + texSize, texY + texSize);
        glVertex2f(x + size/2, y + size/2);
        
        glTexCoord2f(texX, texY + texSize);
        glVertex2f(x - size/2, y + size/2);
        glEnd();
    }
    
    glDisable(GL_TEXTURE_2D);
    
    // Swap buffers for smooth animation
    [glContext flushBuffer];
}

- (void)startAnimation {
    [super startAnimation];
    [glContext makeCurrentContext];
}

- (void)stopAnimation {
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect {
    // Ensure we draw to the full rect
    [self animateOneFrame];
}

- (BOOL)isOpaque {
    // Tell the system we're completely opaque (no transparency)
    return YES;
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    // Update backing scale factor when moving to a new window/screen
    if (self.window && self.window.screen) {
        CGFloat newBackingScale = self.window.screen.backingScaleFactor;
        if (newBackingScale != backingScaleFactor) {
            backingScaleFactor = newBackingScale;
            [self reshape];
        }
    }
}

- (void)reshape {
    // Get the actual bounds of our view
    NSRect bounds = [self bounds];
    
    // Update backing scale factor
    backingScaleFactor = [[NSScreen mainScreen] backingScaleFactor];
    if (self.window && self.window.screen) {
        backingScaleFactor = self.window.screen.backingScaleFactor;
    }
    
    // Calculate pixel dimensions
    screenWidth = bounds.size.width * backingScaleFactor;
    screenHeight = bounds.size.height * backingScaleFactor;
    
    [glContext makeCurrentContext];
    
    // Update viewport using pixel dimensions
    glViewport(0, 0, screenWidth, screenHeight);
    
    // Update projection matrix using logical points
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, bounds.size.width, bounds.size.height, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // Reinitialize particles for new screen dimensions
    if (particles) {
        free(particles);
        [self initializeParticles];
    }
    
    NSLog(@"Reshape - bounds: %.0fx%.0f, scale: %.1f, pixels: %.0fx%.0f", 
          bounds.size.width, bounds.size.height, backingScaleFactor, screenWidth, screenHeight);
}

- (void)dealloc {
    if (particles) free(particles);
    if (textureData) free(textureData);
    if (textureID) glDeleteTextures(1, &textureID);
}

- (BOOL)hasConfigureSheet {
    return YES;
}

- (NSWindow *)configureSheet {
    // Create configuration window
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 450, 400)
                                                    styleMask:NSWindowStyleMaskTitled
                                                      backing:NSBackingStoreBuffered
                                                        defer:YES];
    window.title = @"AIMatrix Screen Saver Settings";
    
    AIMatrixConfig *config = [AIMatrixConfig sharedConfig];
    
    NSView *contentView = window.contentView;
    
    // Custom text field
    NSTextField *textLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 350, 100, 20)];
    textLabel.stringValue = @"Custom Text:";
    textLabel.bordered = NO;
    textLabel.editable = NO;
    textLabel.backgroundColor = [NSColor clearColor];
    [contentView addSubview:textLabel];
    
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 350, 300, 25)];
    textField.stringValue = config.customText;
    textField.tag = 1;
    [contentView addSubview:textField];
    
    // Character set selection
    NSTextField *charSetLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 310, 100, 20)];
    charSetLabel.stringValue = @"Character Set:";
    charSetLabel.bordered = NO;
    charSetLabel.editable = NO;
    charSetLabel.backgroundColor = [NSColor clearColor];
    [contentView addSubview:charSetLabel];
    
    NSPopUpButton *charSetPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(130, 310, 200, 25)];
    [charSetPopup addItemsWithTitles:@[@"Custom Text", @"Greek", @"Arabic", @"Japanese", @"Binary"]];
    [charSetPopup selectItemAtIndex:config.characterSet];
    charSetPopup.tag = 2;
    [contentView addSubview:charSetPopup];
    
    // Speed slider
    NSTextField *speedLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 270, 100, 20)];
    speedLabel.stringValue = @"Speed:";
    speedLabel.bordered = NO;
    speedLabel.editable = NO;
    speedLabel.backgroundColor = [NSColor clearColor];
    [contentView addSubview:speedLabel];
    
    NSSlider *speedSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(130, 270, 200, 25)];
    speedSlider.minValue = 0.1;
    speedSlider.maxValue = 3.0;
    speedSlider.floatValue = config.animationSpeed;
    speedSlider.tag = 3;
    [contentView addSubview:speedSlider];
    
    // Font size slider
    NSTextField *sizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 230, 100, 20)];
    sizeLabel.stringValue = @"Font Size:";
    sizeLabel.bordered = NO;
    sizeLabel.editable = NO;
    sizeLabel.backgroundColor = [NSColor clearColor];
    [contentView addSubview:sizeLabel];
    
    NSSlider *sizeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(130, 230, 200, 25)];
    sizeSlider.minValue = 20;
    sizeSlider.maxValue = 100;
    sizeSlider.floatValue = config.fontSize;
    sizeSlider.tag = 4;
    [contentView addSubview:sizeSlider];
    
    // Color well
    NSTextField *colorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 190, 100, 20)];
    colorLabel.stringValue = @"Color:";
    colorLabel.bordered = NO;
    colorLabel.editable = NO;
    colorLabel.backgroundColor = [NSColor clearColor];
    [contentView addSubview:colorLabel];
    
    NSColorWell *colorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(130, 190, 60, 30)];
    colorWell.color = config.primaryColor;
    colorWell.tag = 5;
    [contentView addSubview:colorWell];
    
    // OK and Cancel buttons
    NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(260, 20, 80, 30)];
    cancelButton.title = @"Cancel";
    cancelButton.bezelStyle = NSBezelStyleRounded;
    cancelButton.target = self;
    cancelButton.action = @selector(cancelConfig:);
    [contentView addSubview:cancelButton];
    
    NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(350, 20, 80, 30)];
    okButton.title = @"OK";
    okButton.bezelStyle = NSBezelStyleRounded;
    okButton.target = self;
    okButton.action = @selector(saveConfig:);
    okButton.keyEquivalent = @"\r";
    [contentView addSubview:okButton];
    
    return window;
}

- (void)saveConfig:(id)sender {
    NSWindow *window = [(NSButton *)sender window];
    AIMatrixConfig *config = [AIMatrixConfig sharedConfig];
    
    // Save all settings
    NSTextField *textField = [window.contentView viewWithTag:1];
    config.customText = textField.stringValue;
    
    NSPopUpButton *charSetPopup = [window.contentView viewWithTag:2];
    config.characterSet = charSetPopup.indexOfSelectedItem;
    
    NSSlider *speedSlider = [window.contentView viewWithTag:3];
    config.animationSpeed = speedSlider.floatValue;
    
    NSSlider *sizeSlider = [window.contentView viewWithTag:4];
    config.fontSize = sizeSlider.floatValue;
    
    NSColorWell *colorWell = [window.contentView viewWithTag:5];
    config.primaryColor = colorWell.color;
    
    [config saveSettings];
    
    // Reload display text and reinitialize
    displayText = [config getCharacterSetString];
    [self createTextTexture];
    [self initializeParticles];
    
    [[NSApplication sharedApplication] endSheet:window];
}

- (void)cancelConfig:(id)sender {
    NSWindow *window = [(NSButton *)sender window];
    [[NSApplication sharedApplication] endSheet:window];
}

@end