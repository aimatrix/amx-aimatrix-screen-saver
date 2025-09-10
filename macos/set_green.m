#import <Foundation/Foundation.h>
#import <ScreenSaver/ScreenSaver.h>

int main() {
    @autoreleasepool {
        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.aimatrix.screensaver"];
        
        NSLog(@"Setting preferences to Green/Normal/Medium...");
        [defaults setInteger:0 forKey:@"AIMatrixColorScheme"]; // Green
        [defaults setInteger:1 forKey:@"AIMatrixSpeed"]; // Normal
        [defaults setInteger:1 forKey:@"AIMatrixCharacterSize"]; // Medium
        [defaults synchronize];
        
        NSLog(@"Preferences set!");
        NSLog(@"  Color: %ld (should be 0 for Green)", [defaults integerForKey:@"AIMatrixColorScheme"]);
        NSLog(@"  Speed: %ld (should be 1 for Normal)", [defaults integerForKey:@"AIMatrixSpeed"]);
        NSLog(@"  Size: %ld (should be 1 for Medium)", [defaults integerForKey:@"AIMatrixCharacterSize"]);
    }
    return 0;
}