#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

typedef NS_ENUM(NSInteger, AIMatrixCharacterSet) {
    AIMatrixCharacterSetCustom = 0,
    AIMatrixCharacterSetGreek,
    AIMatrixCharacterSetArabic,
    AIMatrixCharacterSetJapanese,
    AIMatrixCharacterSetBinary
};

@interface AIMatrixConfig : NSObject

@property (nonatomic, strong) NSString *customText;
@property (nonatomic, assign) AIMatrixCharacterSet characterSet;
@property (nonatomic, strong) NSColor *primaryColor;
@property (nonatomic, assign) float animationSpeed;
@property (nonatomic, assign) float fontSize;
@property (nonatomic, assign) BOOL useRandomCharacters;

+ (instancetype)sharedConfig;
- (void)loadDefaults;
- (void)saveSettings;
- (NSString *)getCharacterSetString;

@end