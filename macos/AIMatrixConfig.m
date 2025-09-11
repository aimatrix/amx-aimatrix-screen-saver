#import "AIMatrixConfig.h"

@implementation AIMatrixConfig

+ (instancetype)sharedConfig {
    static AIMatrixConfig *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AIMatrixConfig alloc] init];
        [sharedInstance loadDefaults];
    });
    return sharedInstance;
}

- (void)loadDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Load saved settings or use defaults
    NSString *savedText = [defaults stringForKey:@"AIMatrix_CustomText"];
    self.customText = savedText ?: @"aimatrix.com - Agentic Twin Platform.... ";
    
    self.characterSet = [defaults integerForKey:@"AIMatrix_CharacterSet"];
    
    NSData *colorData = [defaults dataForKey:@"AIMatrix_PrimaryColor"];
    if (colorData) {
        NSError *error = nil;
        self.primaryColor = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSColor class] fromData:colorData error:&error];
        if (!self.primaryColor) {
            self.primaryColor = [NSColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0]; // Green
        }
    } else {
        self.primaryColor = [NSColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0]; // Green
    }
    
    float savedSpeed = [defaults floatForKey:@"AIMatrix_AnimationSpeed"];
    self.animationSpeed = (savedSpeed > 0) ? savedSpeed : 1.0;
    
    float savedFontSize = [defaults floatForKey:@"AIMatrix_FontSize"];
    self.fontSize = (savedFontSize > 0) ? savedFontSize : 56; // 70% of 80
    
    self.useRandomCharacters = [defaults boolForKey:@"AIMatrix_UseRandomCharacters"];
}

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:self.customText forKey:@"AIMatrix_CustomText"];
    [defaults setInteger:self.characterSet forKey:@"AIMatrix_CharacterSet"];
    
    NSError *error = nil;
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:self.primaryColor requiringSecureCoding:NO error:&error];
    if (colorData) {
        [defaults setObject:colorData forKey:@"AIMatrix_PrimaryColor"];
    }
    
    [defaults setFloat:self.animationSpeed forKey:@"AIMatrix_AnimationSpeed"];
    [defaults setFloat:self.fontSize forKey:@"AIMatrix_FontSize"];
    [defaults setBool:self.useRandomCharacters forKey:@"AIMatrix_UseRandomCharacters"];
    
    [defaults synchronize];
}

- (NSString *)getCharacterSetString {
    switch (self.characterSet) {
        case AIMatrixCharacterSetGreek:
            return @"ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩαβγδεζηθικλμνξοπρστυφχψω";
            
        case AIMatrixCharacterSetArabic:
            return @"أبتثجحخدذرزسشصضطظعغفقكلمنهوي٠١٢٣٤٥٦٧٨٩";
            
        case AIMatrixCharacterSetJapanese:
            return @"あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん";
            
        case AIMatrixCharacterSetBinary:
            return @"01010101001110010110100101010011";
            
        case AIMatrixCharacterSetCustom:
        default:
            return self.customText;
    }
}

@end