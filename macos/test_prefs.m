#import <Foundation/Foundation.h>
#import <ScreenSaver/ScreenSaver.h>

int main() {
    @autoreleasepool {
        // Test writing preferences
        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.aimatrix.screensaver"];
        
        NSLog(@"Current preferences:");
        NSLog(@"  Color: %ld", [defaults integerForKey:@"AIMatrixColorScheme"]);
        NSLog(@"  Speed: %ld", [defaults integerForKey:@"AIMatrixSpeed"]);
        NSLog(@"  Size: %ld", [defaults integerForKey:@"AIMatrixCharacterSize"]);
        
        // Set test values
        [defaults setInteger:0 forKey:@"AIMatrixColorScheme"]; // Green
        [defaults setInteger:1 forKey:@"AIMatrixSpeed"]; // Normal
        [defaults setInteger:1 forKey:@"AIMatrixCharacterSize"]; // Medium
        [defaults synchronize];
        
        NSLog(@"\nAfter setting defaults to Green/Normal/Medium:");
        NSLog(@"  Color: %ld", [defaults integerForKey:@"AIMatrixColorScheme"]);
        NSLog(@"  Speed: %ld", [defaults integerForKey:@"AIMatrixSpeed"]);
        NSLog(@"  Size: %ld", [defaults integerForKey:@"AIMatrixCharacterSize"]);
    }
    return 0;
}