#!/bin/bash

echo "=== AIMatrix Screen Saver Debugger ==="
echo ""

echo "1. Checking if screen saver is installed..."
if [ -d ~/Library/Screen\ Savers/aimatrix-v5.21.saver ]; then
    echo "✓ Found in ~/Library/Screen Savers/"
else
    echo "✗ Not found in ~/Library/Screen Savers/"
fi

echo ""
echo "2. Checking bundle signature..."
codesign -dvv ~/Library/Screen\ Savers/aimatrix-v5.21.saver 2>&1 | grep -E "Signature|Authority|Identifier"

echo ""
echo "3. Checking bundle loading..."
echo "Testing if bundle can be loaded..."

cat > /tmp/test_load.m << 'EOF'
#import <Foundation/Foundation.h>
#import <ScreenSaver/ScreenSaver.h>

int main() {
    @autoreleasepool {
        NSString *path = [@"~/Library/Screen Savers/aimatrix-v5.21.saver" stringByExpandingTildeInPath];
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        
        if (!bundle) {
            NSLog(@"✗ Failed to create bundle");
            return 1;
        }
        
        if (![bundle load]) {
            NSLog(@"✗ Failed to load bundle");
            return 1;
        }
        
        Class principalClass = [bundle principalClass];
        if (!principalClass) {
            NSLog(@"✗ Failed to get principal class");
            return 1;
        }
        
        NSLog(@"✓ Bundle loads successfully!");
        NSLog(@"  Principal class: %@", NSStringFromClass(principalClass));
        
        // Try to instantiate
        ScreenSaverView *view = [[principalClass alloc] initWithFrame:NSMakeRect(0, 0, 100, 100) isPreview:NO];
        if (view) {
            NSLog(@"✓ Can instantiate screen saver view");
        } else {
            NSLog(@"✗ Cannot instantiate screen saver view");
        }
    }
    return 0;
}
EOF

clang -o /tmp/test_load /tmp/test_load.m -framework Foundation -framework ScreenSaver 2>/dev/null
/tmp/test_load

echo ""
echo "4. Checking System Preferences..."
echo "Please check if 'aimatrix v5.21' appears in:"
echo "  System Settings > Screen Saver"
echo ""
echo "If not visible, try:"
echo "  1. Quit System Settings completely"
echo "  2. Run: defaults delete com.apple.screensaver moduleDict"
echo "  3. Reopen System Settings"

echo ""
echo "5. Testing in preview window..."
echo "Press Ctrl+C to stop the test"
/System/Library/CoreServices/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background -module "aimatrix v5.21"