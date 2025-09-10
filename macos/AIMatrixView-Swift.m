#import <ScreenSaver/ScreenSaver.h>

// Forward declaration of Swift class
@interface AIMatrixSceneKitView : ScreenSaverView
@end

@interface AIMatrixViewBridge : ScreenSaverView
@end

@implementation AIMatrixViewBridge

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    // Create and return the Swift view
    Class swiftClass = NSClassFromString(@"aimatrix.AIMatrixSceneKitView");
    if (swiftClass) {
        return [[swiftClass alloc] initWithFrame:frame isPreview:isPreview];
    }
    
    // Fallback to basic view if Swift class not found
    self = [super initWithFrame:frame isPreview:isPreview];
    return self;
}

@end