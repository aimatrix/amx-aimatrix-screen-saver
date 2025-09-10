#import <Foundation/Foundation.h>
#import <ScreenSaver/ScreenSaver.h>

int main() {
    @autoreleasepool {
        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.aimatrix.screensaver"];
        
        NSLog(@"Setting preferences to Red/Fast/Large...");
        [defaults setInteger:2 forKey:@"AIMatrixColorScheme"]; // Red
        [defaults setInteger:2 forKey:@"AIMatrixSpeed"]; // Fast
        [defaults setInteger:2 forKey:@"AIMatrixCharacterSize"]; // Large
        [defaults synchronize];
        
        NSLog(@"Preferences set!");
        NSLog(@"  Color: %ld (should be 2 for Red)", [defaults integerForKey:@"AIMatrixColorScheme"]);
        NSLog(@"  Speed: %ld (should be 2 for Fast)", [defaults integerForKey:@"AIMatrixSpeed"]);
        NSLog(@"  Size: %ld (should be 2 for Large)", [defaults integerForKey:@"AIMatrixCharacterSize"]);
    }
    return 0;
}