#import <Foundation/Foundation.h>
#import <ScreenSaver/ScreenSaver.h>

int main() {
    @autoreleasepool {
        ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:@"com.aimatrix.screensaver"];
        
        NSLog(@"Reading ALL preferences:");
        NSDictionary *dict = [defaults dictionaryRepresentation];
        for (NSString *key in dict) {
            NSLog(@"  %@: %@", key, dict[key]);
        }
        
        NSLog(@"\nSpecific AIMatrix settings:");
        NSLog(@"  Color: %ld (0=Green, 1=Blue, 2=Red...)", [defaults integerForKey:@"AIMatrixColorScheme"]);
        NSLog(@"  Speed: %ld (0=Slow, 1=Normal, 2=Fast, 3=VeryFast)", [defaults integerForKey:@"AIMatrixSpeed"]);
        NSLog(@"  Size: %ld (0=Small, 1=Medium, 2=Large, 3=ExtraLarge)", [defaults integerForKey:@"AIMatrixCharacterSize"]);
    }
    return 0;
}
