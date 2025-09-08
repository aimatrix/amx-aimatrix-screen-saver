#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Create image
        NSSize imageSize = NSMakeSize(800, 600);
        NSImage *image = [[NSImage alloc] initWithSize:imageSize];
        
        [image lockFocus];
        
        // Black background
        [[NSColor blackColor] setFill];
        NSRectFill(NSMakeRect(0, 0, imageSize.width, imageSize.height));
        
        // Font for characters
        NSFont *font = [NSFont fontWithName:@"Menlo" size:14];
        if (!font) font = [NSFont monospacedSystemFontOfSize:14 weight:NSFontWeightRegular];
        
        // Characters to use
        NSArray *chars = @[@"Α", @"Β", @"Γ", @"Δ", @"Ε", @"Ζ", @"Η", @"Θ", @"Ι", @"Κ",
                          @"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"];
        
        // Draw columns of falling text
        int columns = imageSize.width / 20;
        for (int col = 0; col < columns; col++) {
            float x = col * 20;
            
            // Random starting position for each column
            float y = arc4random_uniform((int)imageSize.height);
            int length = 5 + arc4random_uniform(15);
            
            for (int i = 0; i < length; i++) {
                float charY = y + (i * 20);
                if (charY > imageSize.height) break;
                
                NSColor *color;
                if (i == length - 1) {
                    // Head - bright white/green
                    color = [NSColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:1.0];
                } else {
                    // Trail - fading green
                    float intensity = 1.0 - ((float)i / (float)length);
                    color = [NSColor colorWithRed:0 green:intensity blue:0 alpha:intensity];
                }
                
                NSString *character = chars[arc4random_uniform((uint32_t)chars.count)];
                NSDictionary *attrs = @{
                    NSFontAttributeName: font,
                    NSForegroundColorAttributeName: color
                };
                
                [character drawAtPoint:NSMakePoint(x, imageSize.height - charY - 20) 
                        withAttributes:attrs];
            }
        }
        
        // Add title text
        NSString *title = @"AIMatrix Screen Saver";
        NSFont *titleFont = [NSFont boldSystemFontOfSize:32];
        NSDictionary *titleAttrs = @{
            NSFontAttributeName: titleFont,
            NSForegroundColorAttributeName: [NSColor colorWithRed:0 green:0.8 blue:0 alpha:0.9]
        };
        NSSize titleSize = [title sizeWithAttributes:titleAttrs];
        [title drawAtPoint:NSMakePoint((imageSize.width - titleSize.width) / 2, 50) 
                withAttributes:titleAttrs];
        
        [image unlockFocus];
        
        // Save as PNG
        NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
        NSData *data = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        [data writeToFile:@"preview.png" atomically:YES];
        
        NSLog(@"Preview image generated: preview.png");
    }
    return 0;
}