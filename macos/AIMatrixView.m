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

@interface AIMatrixView : ScreenSaverView
{
    NSMutableArray *drops;
    MatrixColorScheme colorScheme;
    NSUserDefaults *defaults;
}
@property (strong) IBOutlet NSWindow *configSheet;
@property (strong) IBOutlet NSPopUpButton *colorPopup;
@end

@implementation AIMatrixView

static NSString *const kColorSchemeKey = @"AIMatrixColorScheme";

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1.0/30.0];
        drops = [[NSMutableArray alloc] init];
        
        // Load saved color preference
        defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.aimatrix.screensaver"];
        colorScheme = [defaults integerForKey:kColorSchemeKey];
        if (colorScheme < 0 || colorScheme > MatrixColorPink) {
            colorScheme = MatrixColorGreen;
        }
        
        // Initialize drops
        int columns = frame.size.width / 20;
        for (int i = 0; i < columns; i++) {
            NSMutableDictionary *drop = [NSMutableDictionary dictionary];
            drop[@"x"] = @(i * 20);
            drop[@"y"] = @(arc4random_uniform((int)frame.size.height));
            drop[@"speed"] = @(2 + arc4random_uniform(4));
            drop[@"chars"] = [self randomCharacterString];
            [drops addObject:drop];
        }
    }
    return self;
}

- (NSMutableArray *)randomCharacterString
{
    NSArray *chars = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9",
                      @"A", @"B", @"C", @"D", @"E", @"F", @"Α", @"Β", @"Γ", @"Δ", 
                      @"Ε", @"Ζ", @"Η", @"Θ", @"Ι", @"Κ", @"Λ", @"Μ", @"Ν", @"Ξ"];
    
    NSMutableArray *trail = [NSMutableArray array];
    int length = 5 + arc4random_uniform(15);
    for (int i = 0; i < length; i++) {
        [trail addObject:chars[arc4random_uniform((uint32_t)chars.count)]];
    }
    return trail;
}

- (NSColor *)colorForIntensity:(float)intensity isHead:(BOOL)isHead
{
    if (isHead) {
        // Head is always bright white-ish
        return [NSColor colorWithRed:0.95 green:1.0 blue:0.95 alpha:1.0];
    }
    
    switch (colorScheme) {
        case MatrixColorGreen:
            return [NSColor colorWithRed:0 green:intensity blue:0 alpha:1];
        case MatrixColorBlue:
            return [NSColor colorWithRed:0 green:0 blue:intensity alpha:1];
        case MatrixColorRed:
            return [NSColor colorWithRed:intensity green:0 blue:0 alpha:1];
        case MatrixColorYellow:
            return [NSColor colorWithRed:intensity green:intensity blue:0 alpha:1];
        case MatrixColorCyan:
            return [NSColor colorWithRed:0 green:intensity blue:intensity alpha:1];
        case MatrixColorPurple:
            return [NSColor colorWithRed:intensity green:0 blue:intensity alpha:1];
        case MatrixColorOrange:
            return [NSColor colorWithRed:intensity green:intensity*0.5 blue:0 alpha:1];
        case MatrixColorPink:
            return [NSColor colorWithRed:intensity green:intensity*0.4 blue:intensity*0.6 alpha:1];
        default:
            return [NSColor colorWithRed:0 green:intensity blue:0 alpha:1];
    }
}

- (void)startAnimation
{
    [super startAnimation];
    [self setNeedsDisplay:YES];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    // Fill background
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    // Draw drops
    NSFont *font = [NSFont fontWithName:@"Courier" size:14];
    if (!font) font = [NSFont systemFontOfSize:14];
    
    for (NSMutableDictionary *drop in drops) {
        int x = [drop[@"x"] intValue];
        float y = [drop[@"y"] floatValue];
        NSArray *chars = drop[@"chars"];
        
        for (int i = 0; i < chars.count; i++) {
            float charY = y - (i * 16);
            if (charY < -16 || charY > rect.size.height) continue;
            
            // Color based on position
            BOOL isHead = (i == 0);
            float intensity = isHead ? 1.0 : (1.0 - ((float)i / (float)chars.count));
            NSColor *color = [self colorForIntensity:intensity isHead:isHead];
            
            NSDictionary *attributes = @{
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: color
            };
            
            NSString *character = chars[i];
            [character drawAtPoint:NSMakePoint(x, rect.size.height - charY - 16) 
                    withAttributes:attributes];
        }
    }
}

- (void)animateOneFrame
{
    // Update drops
    for (NSMutableDictionary *drop in drops) {
        float y = [drop[@"y"] floatValue];
        float speed = [drop[@"speed"] floatValue];
        y += speed;
        
        // Reset if off screen
        if (y - [drop[@"chars"] count] * 16 > self.bounds.size.height) {
            y = -20;
            drop[@"chars"] = [self randomCharacterString];
            drop[@"speed"] = @(2 + arc4random_uniform(4));
        }
        
        drop[@"y"] = @(y);
    }
    
    [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet
{
    return YES;
}

- (NSWindow *)configureSheet
{
    if (!_configSheet) {
        // Create configuration window
        _configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 300, 150)
                                                    styleMask:NSWindowStyleMaskTitled
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
        
        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 300, 150)];
        
        // Color selection label
        NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 100, 100, 20)];
        [label setStringValue:@"Color Scheme:"];
        [label setBezeled:NO];
        [label setDrawsBackground:NO];
        [label setEditable:NO];
        [label setSelectable:NO];
        [contentView addSubview:label];
        
        // Color popup menu
        _colorPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(130, 98, 150, 25)];
        [_colorPopup addItemsWithTitles:@[@"Green (Classic)", @"Blue", @"Red", @"Yellow", 
                                          @"Cyan", @"Purple", @"Orange", @"Pink"]];
        [_colorPopup selectItemAtIndex:colorScheme];
        [_colorPopup setTarget:self];
        [_colorPopup setAction:@selector(colorChanged:)];
        [contentView addSubview:_colorPopup];
        
        // OK button
        NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(210, 20, 80, 30)];
        [okButton setTitle:@"OK"];
        [okButton setBezelStyle:NSBezelStyleRounded];
        [okButton setTarget:self];
        [okButton setAction:@selector(closeConfig:)];
        [contentView addSubview:okButton];
        
        // Cancel button
        NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(120, 20, 80, 30)];
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
}

- (void)closeConfig:(id)sender
{
    // Save the color preference
    [defaults setInteger:colorScheme forKey:kColorSchemeKey];
    [defaults synchronize];
    
    [[NSApplication sharedApplication] endSheet:_configSheet];
}

- (void)cancelConfig:(id)sender
{
    // Restore original selection
    colorScheme = [defaults integerForKey:kColorSchemeKey];
    [_colorPopup selectItemAtIndex:colorScheme];
    
    [[NSApplication sharedApplication] endSheet:_configSheet];
}

@end