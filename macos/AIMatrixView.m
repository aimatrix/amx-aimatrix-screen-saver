#import <ScreenSaver/ScreenSaver.h>

typedef enum {
    MatrixColorGreen = 0,
    MatrixColorBlue,
    MatrixColorRed,
    MatrixColorYellow,
    MatrixColorCyan,
    MatrixColorPurple,
    MatrixColorOrange,
    MatrixColorPink
} MatrixColorScheme;

typedef enum {
    MatrixSpeedSlow = 0,
    MatrixSpeedNormal,
    MatrixSpeedFast,
    MatrixSpeedVeryFast
} MatrixSpeed;

typedef enum {
    MatrixSizeSmall = 0,
    MatrixSizeMedium,
    MatrixSizeLarge,
    MatrixSizeExtraLarge
} MatrixCharacterSize;

// Optimized drop structure to reduce memory allocations
typedef struct {
    int x;
    float y;
    float speed;
    int length;
    unichar *characters;
} MatrixDrop;

@interface AIMatrixView : ScreenSaverView
{
    MatrixDrop *drops;
    int numDrops;
    MatrixColorScheme colorScheme;
    MatrixSpeed speedSetting;
    MatrixCharacterSize sizeSetting;
    NSUserDefaults *defaults;
    
    // Cached values for performance
    NSFont *matrixFont;
    NSDictionary *fontAttributes;
    NSArray *characterSet;
    float charWidth;
    float charHeight;
    float baseSpeed;
    
    // Pre-calculated colors to avoid recreation
    NSColor *headColor;
    NSMutableArray *trailColors;
}
@property (strong) IBOutlet NSWindow *configSheet;
@property (strong) IBOutlet NSPopUpButton *colorPopup;
@property (strong) IBOutlet NSPopUpButton *speedPopup;
@property (strong) IBOutlet NSPopUpButton *sizePopup;
@end

@implementation AIMatrixView

static NSString *const kColorSchemeKey = @"AIMatrixColorScheme";
static NSString *const kSpeedKey = @"AIMatrixSpeed";
static NSString *const kSizeKey = @"AIMatrixCharacterSize";

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        // Load preferences
        defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.aimatrix.screensaver"];
        colorScheme = [defaults integerForKey:kColorSchemeKey];
        speedSetting = [defaults integerForKey:kSpeedKey];
        sizeSetting = [defaults integerForKey:kSizeKey];
        
        // Validate settings
        if (colorScheme < 0 || colorScheme > MatrixColorPink) colorScheme = MatrixColorGreen;
        if (speedSetting < 0 || speedSetting > MatrixSpeedVeryFast) speedSetting = MatrixSpeedNormal;
        if (sizeSetting < 0 || sizeSetting > MatrixSizeExtraLarge) sizeSetting = MatrixSizeMedium;
        
        // Initialize character set once
        characterSet = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9",
                        @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J",
                        @"Α", @"Β", @"Γ", @"Δ", @"Ε", @"Ζ", @"Η", @"Θ", @"Ι", @"Κ",
                        @"Λ", @"Μ", @"Ν", @"Ξ", @"Ο", @"Π", @"Ρ", @"Σ", @"Τ", @"Υ"];
        
        // Setup font and metrics
        [self updateFontAndMetrics];
        
        // Pre-calculate colors
        [self updateColors];
        
        // Initialize drops
        [self initializeDrops];
        
        // Set animation interval based on speed
        [self updateAnimationSpeed];
    }
    return self;
}

- (void)dealloc
{
    [self cleanupDrops];
}

- (void)cleanupDrops
{
    if (drops) {
        for (int i = 0; i < numDrops; i++) {
            if (drops[i].characters) {
                free(drops[i].characters);
                drops[i].characters = NULL;
            }
        }
        free(drops);
        drops = NULL;
    }
}

- (void)updateFontAndMetrics
{
    // Font sizes based on setting
    int fontSize;
    switch (sizeSetting) {
        case MatrixSizeSmall:
            fontSize = 10;
            break;
        case MatrixSizeMedium:
            fontSize = 14;
            break;
        case MatrixSizeLarge:
            fontSize = 18;
            break;
        case MatrixSizeExtraLarge:
            fontSize = 24;
            break;
        default:
            fontSize = 14;
    }
    
    matrixFont = [NSFont fontWithName:@"Courier" size:fontSize];
    if (!matrixFont) {
        matrixFont = [NSFont monospacedSystemFontOfSize:fontSize weight:NSFontWeightRegular];
    }
    
    // Calculate character dimensions
    NSDictionary *attrs = @{NSFontAttributeName: matrixFont};
    NSSize size = [@"W" sizeWithAttributes:attrs];
    charWidth = size.width;
    charHeight = size.height;
}

- (void)updateColors
{
    // Pre-calculate head color
    headColor = [NSColor colorWithRed:0.95 green:1.0 blue:0.95 alpha:1.0];
    
    // Pre-calculate trail colors (20 levels of intensity)
    trailColors = [[NSMutableArray alloc] initWithCapacity:20];
    for (int i = 0; i < 20; i++) {
        float intensity = 1.0f - ((float)i / 20.0f);
        NSColor *color;
        
        switch (colorScheme) {
            case MatrixColorGreen:
                color = [NSColor colorWithRed:0 green:intensity blue:0 alpha:1];
                break;
            case MatrixColorBlue:
                color = [NSColor colorWithRed:0 green:0 blue:intensity alpha:1];
                break;
            case MatrixColorRed:
                color = [NSColor colorWithRed:intensity green:0 blue:0 alpha:1];
                break;
            case MatrixColorYellow:
                color = [NSColor colorWithRed:intensity green:intensity blue:0 alpha:1];
                break;
            case MatrixColorCyan:
                color = [NSColor colorWithRed:0 green:intensity blue:intensity alpha:1];
                break;
            case MatrixColorPurple:
                color = [NSColor colorWithRed:intensity green:0 blue:intensity alpha:1];
                break;
            case MatrixColorOrange:
                color = [NSColor colorWithRed:intensity green:intensity*0.5 blue:0 alpha:1];
                break;
            case MatrixColorPink:
                color = [NSColor colorWithRed:intensity green:intensity*0.4 blue:intensity*0.6 alpha:1];
                break;
            default:
                color = [NSColor colorWithRed:0 green:intensity blue:0 alpha:1];
        }
        [trailColors addObject:color];
    }
}

- (void)updateAnimationSpeed
{
    // Speed multipliers
    switch (speedSetting) {
        case MatrixSpeedSlow:
            baseSpeed = 0.5f;
            [self setAnimationTimeInterval:1.0/20.0]; // 20 FPS
            break;
        case MatrixSpeedNormal:
            baseSpeed = 1.0f;
            [self setAnimationTimeInterval:1.0/30.0]; // 30 FPS
            break;
        case MatrixSpeedFast:
            baseSpeed = 1.5f;
            [self setAnimationTimeInterval:1.0/40.0]; // 40 FPS
            break;
        case MatrixSpeedVeryFast:
            baseSpeed = 2.0f;
            [self setAnimationTimeInterval:1.0/60.0]; // 60 FPS
            break;
        default:
            baseSpeed = 1.0f;
            [self setAnimationTimeInterval:1.0/30.0];
    }
}

- (void)initializeDrops
{
    [self cleanupDrops];
    
    // Calculate number of columns based on character width
    numDrops = MAX(1, (int)(self.bounds.size.width / charWidth));
    drops = calloc(numDrops, sizeof(MatrixDrop));
    
    for (int i = 0; i < numDrops; i++) {
        drops[i].x = i * charWidth;
        [self resetDrop:&drops[i]];
    }
}

- (void)resetDrop:(MatrixDrop *)drop
{
    // Random speed variation
    drop->speed = baseSpeed * (0.5f + (arc4random_uniform(150) / 100.0f));
    
    // Random length
    drop->length = 5 + arc4random_uniform(15);
    
    // Allocate/reallocate characters if needed
    if (drop->characters) {
        free(drop->characters);
    }
    drop->characters = malloc(sizeof(unichar) * drop->length);
    
    // Fill with random characters
    for (int i = 0; i < drop->length; i++) {
        NSString *charStr = characterSet[arc4random_uniform((uint32_t)characterSet.count)];
        drop->characters[i] = [charStr characterAtIndex:0];
    }
    
    // Random starting position
    drop->y = -(float)(arc4random_uniform(20));
}

- (void)drawRect:(NSRect)rect
{
    // Fill background
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    // Draw all drops
    for (int i = 0; i < numDrops; i++) {
        MatrixDrop *drop = &drops[i];
        
        for (int j = 0; j < drop->length; j++) {
            float charY = drop->y + (j * charHeight);
            
            // Skip if outside visible area
            if (charY < -charHeight || charY > rect.size.height) {
                continue;
            }
            
            // Select pre-calculated color
            NSColor *color;
            if (j == drop->length - 1) {
                color = headColor;
            } else {
                int colorIndex = (j * 20) / drop->length;
                if (colorIndex >= trailColors.count) colorIndex = trailColors.count - 1;
                color = trailColors[colorIndex];
            }
            
            // Draw character
            NSString *character = [NSString stringWithCharacters:&drop->characters[j] length:1];
            NSDictionary *attrs = @{
                NSFontAttributeName: matrixFont,
                NSForegroundColorAttributeName: color
            };
            
            [character drawAtPoint:NSMakePoint(drop->x, rect.size.height - charY - charHeight)
                    withAttributes:attrs];
        }
    }
}

- (void)animateOneFrame
{
    // Update all drops
    for (int i = 0; i < numDrops; i++) {
        MatrixDrop *drop = &drops[i];
        drop->y += drop->speed * charHeight;
        
        // Reset if completely off screen
        if (drop->y - (drop->length * charHeight) > self.bounds.size.height) {
            [self resetDrop:drop];
        }
        
        // Randomly change a character for effect
        if (arc4random_uniform(100) < 5) { // 5% chance
            int charIndex = arc4random_uniform(drop->length);
            NSString *newChar = characterSet[arc4random_uniform((uint32_t)characterSet.count)];
            drop->characters[charIndex] = [newChar characterAtIndex:0];
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    
    // Recalculate drops for new size
    [self initializeDrops];
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow *)configureSheet
{
    if (!_configSheet) {
        // Create larger configuration window for more options
        _configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 350, 220)
                                                    styleMask:NSWindowStyleMaskTitled
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
        
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 350, 220)];
        
        // Color selection
        NSTextField *colorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 170, 100, 20)];
        [colorLabel setStringValue:@"Color Scheme:"];
        [colorLabel setBezeled:NO];
        [colorLabel setDrawsBackground:NO];
        [colorLabel setEditable:NO];
        [colorLabel setSelectable:NO];
        [contentView addSubview:colorLabel];
        
        _colorPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(130, 168, 200, 25)];
        [_colorPopup addItemsWithTitles:@[@"Green (Classic)", @"Blue", @"Red", @"Yellow",
                                          @"Cyan", @"Purple", @"Orange", @"Pink"]];
        [_colorPopup selectItemAtIndex:colorScheme];
        [_colorPopup setTarget:self];
        [_colorPopup setAction:@selector(colorChanged:)];
        [contentView addSubview:_colorPopup];
        
        // Speed selection
        NSTextField *speedLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 130, 100, 20)];
        [speedLabel setStringValue:@"Rain Speed:"];
        [speedLabel setBezeled:NO];
        [speedLabel setDrawsBackground:NO];
        [speedLabel setEditable:NO];
        [speedLabel setSelectable:NO];
        [contentView addSubview:speedLabel];
        
        _speedPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(130, 128, 200, 25)];
        [_speedPopup addItemsWithTitles:@[@"Slow", @"Normal", @"Fast", @"Very Fast"]];
        [_speedPopup selectItemAtIndex:speedSetting];
        [_speedPopup setTarget:self];
        [_speedPopup setAction:@selector(speedChanged:)];
        [contentView addSubview:_speedPopup];
        
        // Size selection
        NSTextField *sizeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 90, 100, 20)];
        [sizeLabel setStringValue:@"Character Size:"];
        [sizeLabel setBezeled:NO];
        [sizeLabel setDrawsBackground:NO];
        [sizeLabel setEditable:NO];
        [sizeLabel setSelectable:NO];
        [contentView addSubview:sizeLabel];
        
        _sizePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(130, 88, 200, 25)];
        [_sizePopup addItemsWithTitles:@[@"Small", @"Medium", @"Large", @"Extra Large"]];
        [_sizePopup selectItemAtIndex:sizeSetting];
        [_sizePopup setTarget:self];
        [_sizePopup setAction:@selector(sizeChanged:)];
        [contentView addSubview:_sizePopup];
        
        // Buttons
        NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(250, 20, 80, 30)];
        [okButton setTitle:@"OK"];
        [okButton setBezelStyle:NSBezelStyleRounded];
        [okButton setTarget:self];
        [okButton setAction:@selector(closeConfig:)];
        [contentView addSubview:okButton];
        
        NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(160, 20, 80, 30)];
        [cancelButton setTitle:@"Cancel"];
        [cancelButton setBezelStyle:NSBezelStyleRounded];
        [cancelButton setTarget:self];
        [cancelButton setAction:@selector(cancelConfig:)];
        [contentView addSubview:cancelButton];
        
        [_configSheet setContentView:contentView];
    }
    
    return _configSheet;
}

- (void)colorChanged:(id)sender
{
    colorScheme = [_colorPopup indexOfSelectedItem];
    [self updateColors];
}

- (void)speedChanged:(id)sender
{
    speedSetting = [_speedPopup indexOfSelectedItem];
    [self updateAnimationSpeed];
}

- (void)sizeChanged:(id)sender
{
    sizeSetting = [_sizePopup indexOfSelectedItem];
    [self updateFontAndMetrics];
    [self initializeDrops];
}

- (void)closeConfig:(id)sender
{
    // Save all preferences
    [defaults setInteger:colorScheme forKey:kColorSchemeKey];
    [defaults setInteger:speedSetting forKey:kSpeedKey];
    [defaults setInteger:sizeSetting forKey:kSizeKey];
    [defaults synchronize];
    
    [[NSApplication sharedApplication] endSheet:_configSheet];
}

- (void)cancelConfig:(id)sender
{
    // Restore original selections
    colorScheme = [defaults integerForKey:kColorSchemeKey];
    speedSetting = [defaults integerForKey:kSpeedKey];
    sizeSetting = [defaults integerForKey:kSizeKey];
    
    [_colorPopup selectItemAtIndex:colorScheme];
    [_speedPopup selectItemAtIndex:speedSetting];
    [_sizePopup selectItemAtIndex:sizeSetting];
    
    // Revert settings
    [self updateColors];
    [self updateAnimationSpeed];
    [self updateFontAndMetrics];
    [self initializeDrops];
    
    [[NSApplication sharedApplication] endSheet:_configSheet];
}

@end