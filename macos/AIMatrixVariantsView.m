#import <ScreenSaver/ScreenSaver.h>

typedef enum {
    VariantGreekAlphabets = 0,    // Green, Greek alphabets only
    VariantAIMatrix,              // Green, "aimatrix.com - agentic twins"
    VariantBigLeder,              // Red, "bigleder.com - the business operating systems"
    VariantAILedger,              // Blue, "ailedger.com - the agentic financial controller"
    VariantAwanjasa               // Purple, "awanjasa.com - the learning management agent"
} TextVariant;

@interface AIMatrixVariantsView : ScreenSaverView {
    NSMutableArray *drops;
    NSFont *matrixFont;
    int columnWidth;
    int charHeight;
    int numColumns;
    int numRows;
    TextVariant currentVariant;
    NSUserDefaults *defaults;
    NSWindow *configSheet;
    NSPopUpButton *variantPopup;
}
@end

@implementation AIMatrixVariantsView

static NSString *const kVariantKey = @"AIMatrixVariant";

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        // Load preferences
        defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.aimatrix.variants"];
        currentVariant = [defaults integerForKey:kVariantKey];
        if (currentVariant < 0 || currentVariant > VariantAwanjasa) {
            currentVariant = VariantGreekAlphabets;
        }
        
        // 30 FPS for smooth animation
        [self setAnimationTimeInterval:1.0/30.0];
        
        // Font setup
        matrixFont = [NSFont fontWithName:@"Courier New" size:14];
        if (!matrixFont) {
            matrixFont = [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightRegular];
        }
        
        // Calculate character dimensions
        NSSize charSize = [@"M" sizeWithAttributes:@{NSFontAttributeName: matrixFont}];
        columnWidth = charSize.width;
        charHeight = charSize.height;
        
        // Calculate grid
        numColumns = frame.size.width / columnWidth;
        numRows = frame.size.height / charHeight;
        
        // Initialize drops
        [self initializeDrops];
    }
    return self;
}

- (void)initializeDrops {
    drops = [NSMutableArray array];
    
    // Create drops for 50% of columns (normal density)
    int numDrops = numColumns * 0.5;
    NSMutableArray *availableColumns = [NSMutableArray array];
    for (int i = 0; i < numColumns; i++) {
        [availableColumns addObject:@(i)];
    }
    
    // Shuffle columns
    for (int i = availableColumns.count - 1; i > 0; i--) {
        int j = arc4random_uniform(i + 1);
        [availableColumns exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    
    // Create drops
    for (int i = 0; i < numDrops && i < availableColumns.count; i++) {
        NSMutableDictionary *drop = [NSMutableDictionary dictionary];
        drop[@"column"] = availableColumns[i];
        drop[@"y"] = @(arc4random_uniform(numRows * 2) - numRows); // Random starting position
        drop[@"speed"] = @(0.3 + (arc4random_uniform(120) / 100.0)); // 0.3 to 1.5
        drop[@"length"] = @(5 + arc4random_uniform(31)); // 5 to 35
        drop[@"characters"] = [self generateCharactersForDrop:[drop[@"length"] intValue]];
        drop[@"charIndex"] = @(0); // For text variants, track position in string
        [drops addObject:drop];
    }
}

- (NSMutableArray *)generateCharactersForDrop:(int)length {
    NSMutableArray *chars = [NSMutableArray array];
    
    switch (currentVariant) {
        case VariantGreekAlphabets: {
            // Greek alphabets only
            NSString *greek = @"ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρστυφχψω";
            for (int i = 0; i < length; i++) {
                unichar c = [greek characterAtIndex:arc4random_uniform((uint32_t)greek.length)];
                [chars addObject:[NSString stringWithCharacters:&c length:1]];
            }
            break;
        }
        case VariantAIMatrix: {
            NSString *text = @"aimatrix.com - agentic twins ";
            [self fillCharsFromText:text length:length chars:chars];
            break;
        }
        case VariantBigLeder: {
            NSString *text = @"bigleder.com - the business operating systems ";
            [self fillCharsFromText:text length:length chars:chars];
            break;
        }
        case VariantAILedger: {
            NSString *text = @"ailedger.com - the agentic financial controller ";
            [self fillCharsFromText:text length:length chars:chars];
            break;
        }
        case VariantAwanjasa: {
            NSString *text = @"awanjasa.com - the learning management agent ";
            [self fillCharsFromText:text length:length chars:chars];
            break;
        }
    }
    
    return chars;
}

- (void)fillCharsFromText:(NSString *)text length:(int)length chars:(NSMutableArray *)chars {
    // For text variants, repeat the text to fill the drop length
    int textLength = text.length;
    for (int i = 0; i < length; i++) {
        unichar c = [text characterAtIndex:(i % textLength)];
        [chars addObject:[NSString stringWithCharacters:&c length:1]];
    }
}

- (NSColor *)getColorForVariant {
    switch (currentVariant) {
        case VariantGreekAlphabets:
        case VariantAIMatrix:
            return [NSColor colorWithRed:0 green:1 blue:0 alpha:1]; // Green
        case VariantBigLeder:
            return [NSColor colorWithRed:1 green:0 blue:0 alpha:1]; // Red
        case VariantAILedger:
            return [NSColor colorWithRed:0 green:0.8 blue:1 alpha:1]; // Blue
        case VariantAwanjasa:
            return [NSColor colorWithRed:0.8 green:0 blue:1 alpha:1]; // Purple
        default:
            return [NSColor greenColor];
    }
}

- (void)drawRect:(NSRect)rect {
    // Black background
    [[NSColor blackColor] setFill];
    NSRectFill(rect);
    
    NSColor *baseColor = [self getColorForVariant];
    
    // Draw each drop
    for (NSMutableDictionary *drop in drops) {
        int column = [drop[@"column"] intValue];
        float y = [drop[@"y"] floatValue];
        int length = [drop[@"length"] intValue];
        NSArray *characters = drop[@"characters"];
        
        // Draw characters in the drop
        for (int i = 0; i < length; i++) {
            float charY = (y - i) * charHeight;
            
            // Skip if off screen
            if (charY < -charHeight || charY > rect.size.height) continue;
            
            // Calculate intensity (fade from head to tail)
            float intensity;
            NSColor *color;
            
            if (i == 0) {
                // Head character - bright white
                color = [NSColor whiteColor];
            } else {
                // Trail - fading in the variant color
                intensity = MAX(0.1, 1.0 - ((float)i / (float)length));
                
                // Get RGB components of base color
                CGFloat r, g, b, a;
                [[baseColor colorUsingColorSpace:[NSColorSpace sRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
                color = [NSColor colorWithRed:r*intensity green:g*intensity blue:b*intensity alpha:intensity];
            }
            
            NSDictionary *attrs = @{
                NSFontAttributeName: matrixFont,
                NSForegroundColorAttributeName: color
            };
            
            NSString *charStr = characters[i % characters.count];
            [charStr drawAtPoint:NSMakePoint(column * columnWidth, charY) withAttributes:attrs];
        }
    }
}

- (void)animateOneFrame {
    // Update each drop
    for (NSMutableDictionary *drop in drops) {
        float y = [drop[@"y"] floatValue];
        float speed = [drop[@"speed"] floatValue];
        int length = [drop[@"length"] intValue];
        
        // Move drop down
        y += speed;
        
        // Reset if off screen
        if ((y - length) * charHeight > self.bounds.size.height) {
            y = -arc4random_uniform(20);
            drop[@"speed"] = @(0.3 + (arc4random_uniform(120) / 100.0));
            drop[@"length"] = @(5 + arc4random_uniform(31));
            drop[@"characters"] = [self generateCharactersForDrop:[drop[@"length"] intValue]];
        }
        
        drop[@"y"] = @(y);
        
        // Randomly change some characters (for Greek variant only)
        if (currentVariant == VariantGreekAlphabets) {
            NSMutableArray *chars = [drop[@"characters"] mutableCopy];
            NSString *greek = @"ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρστυφχψω";
            for (int i = 0; i < chars.count; i++) {
                if (arc4random_uniform(100) < 5) { // 5% chance to change
                    unichar c = [greek characterAtIndex:arc4random_uniform((uint32_t)greek.length)];
                    chars[i] = [NSString stringWithCharacters:&c length:1];
                }
            }
            drop[@"characters"] = chars;
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (BOOL)hasConfigureSheet {
    return YES;
}

- (NSWindow *)configureSheet {
    if (!configSheet) {
        if (![NSBundle bundleForClass:[self class]].bundleURL) {
            return nil;
        }
        
        // Create configuration window programmatically
        configSheet = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200)
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
        configSheet.title = @"AIMatrix Variants Configuration";
        
        NSView *contentView = configSheet.contentView;
        
        // Create popup button
        variantPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(50, 100, 300, 30)];
        [variantPopup addItemWithTitle:@"Greek Alphabets (Green)"];
        [variantPopup addItemWithTitle:@"AIMatrix - Agentic Twins (Green)"];
        [variantPopup addItemWithTitle:@"BigLeder - Business OS (Red)"];
        [variantPopup addItemWithTitle:@"AILedger - Financial Controller (Blue)"];
        [variantPopup addItemWithTitle:@"Awanjasa - Learning Agent (Purple)"];
        [variantPopup selectItemAtIndex:currentVariant];
        [contentView addSubview:variantPopup];
        
        // Create label
        NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 130, 300, 20)];
        label.stringValue = @"Select Display Variant:";
        label.bezeled = NO;
        label.drawsBackground = NO;
        label.editable = NO;
        label.selectable = NO;
        [contentView addSubview:label];
        
        // Create OK button
        NSButton *okButton = [[NSButton alloc] initWithFrame:NSMakeRect(250, 20, 80, 30)];
        okButton.title = @"OK";
        okButton.bezelStyle = NSBezelStyleRounded;
        okButton.target = self;
        okButton.action = @selector(saveConfiguration:);
        okButton.keyEquivalent = @"\r";
        [contentView addSubview:okButton];
        
        // Create Cancel button
        NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(160, 20, 80, 30)];
        cancelButton.title = @"Cancel";
        cancelButton.bezelStyle = NSBezelStyleRounded;
        cancelButton.target = self;
        cancelButton.action = @selector(cancelConfiguration:);
        [contentView addSubview:cancelButton];
    }
    
    return configSheet;
}

- (void)saveConfiguration:(id)sender {
    currentVariant = (TextVariant)variantPopup.indexOfSelectedItem;
    [defaults setInteger:currentVariant forKey:kVariantKey];
    [defaults synchronize];
    
    // Reinitialize drops with new variant
    [self initializeDrops];
    
    [[NSApplication sharedApplication] endSheet:configSheet];
}

- (void)cancelConfiguration:(id)sender {
    [[NSApplication sharedApplication] endSheet:configSheet];
}

@end