import ScreenSaver
import QuartzCore
import ObjectiveC

@objc(AIMatrixSceneKitView)
public class AIMatrixSceneKitView: ScreenSaverView {
    
    // Individual drop system - each drop completely independent
    private var drops: [IndependentDrop] = []
    private var lastFrameTime: CFTimeInterval = 0
    
    // Display-specific properties
    private var targetScreen: NSScreen?
    private var displayScale: CGFloat = 1.0
    
    // Preferences
    private var colorScheme = 0
    private var speedSetting = 1
    private var sizeSetting = 1
    private var characterSet = 0
    
    // Drawing properties
    private var characterFont: NSFont!
    private var characterColor: NSColor!
    
    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.wantsLayer = true
        
        // CRITICAL: Detect which screen this instance is for
        targetScreen = detectTargetScreen()
        displayScale = targetScreen?.backingScaleFactor ?? 1.0
        
        // Configure layer for THIS screen
        self.layer?.backgroundColor = NSColor.black.cgColor
        self.layer?.isOpaque = true
        self.layer?.contentsScale = displayScale
        
        loadPreferences()
        setupIndependentDrops()
        startDisplayLink()
        
        NSLog("AIMatrix V9: Init for screen \(targetScreen?.localizedName ?? "unknown"), scale: \(displayScale), frame: \(frame)")
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        
        targetScreen = detectTargetScreen()
        displayScale = targetScreen?.backingScaleFactor ?? 1.0
        
        self.layer?.backgroundColor = NSColor.black.cgColor
        self.layer?.isOpaque = true
        self.layer?.contentsScale = displayScale
        
        loadPreferences()
        setupIndependentDrops()
        startDisplayLink()
    }
    
    private func detectTargetScreen() -> NSScreen? {
        // Try to get the screen this view is actually on
        if let window = self.window {
            return window.screen
        }
        
        // Fallback: find screen by frame intersection
        let windowFrame = self.convert(self.bounds, to: nil)
        
        for screen in NSScreen.screens {
            if screen.frame.intersects(windowFrame) {
                return screen
            }
        }
        
        return NSScreen.main
    }
    
    private func loadPreferences() {
        let defaults = ScreenSaverDefaults(forModuleWithName: "com.aimatrix.screensaver.v9")
        defaults?.synchronize()
        
        colorScheme = defaults?.integer(forKey: "ColorScheme") ?? 0
        speedSetting = defaults?.integer(forKey: "SpeedSetting") ?? 1
        sizeSetting = defaults?.integer(forKey: "SizeSetting") ?? 1
        characterSet = defaults?.integer(forKey: "CharacterSet") ?? 0
        
        // Setup drawing properties
        characterFont = NSFont(name: "Courier", size: getFontSize()) ?? NSFont.systemFont(ofSize: getFontSize())
        characterColor = getColor()
        
        NSLog("AIMatrix V9: Loaded preferences - Color: \(colorScheme), Speed: \(speedSetting), Size: \(sizeSetting)")
    }
    
    private func setupIndependentDrops() {
        drops.removeAll()
        
        // Create truly independent drops
        let screenWidth = self.bounds.width
        let screenHeight = self.bounds.height
        
        // Calculate number of drops based on screen size
        let dropCount = Int(screenWidth / 25) // One drop per 25 pixels width
        
        NSLog("AIMatrix V9: Creating \(dropCount) independent drops for size \(screenWidth)x\(screenHeight)")
        
        for i in 0..<dropCount {
            // Each drop gets a UNIQUE random seed based on time + index
            let uniqueSeed = UInt32(CFAbsoluteTimeGetCurrent() * 1000000) + UInt32(i) * 1337
            
            let drop = IndependentDrop(
                screenBounds: self.bounds,
                uniqueRandomSeed: uniqueSeed,
                characterSet: getCharacterSet(),
                baseSpeed: getSpeedMultiplier(),
                font: characterFont,
                color: characterColor
            )
            
            drops.append(drop)
        }
    }
    
    private var displayTimer: Timer?
    
    private func startDisplayLink() {
        // Use Timer for macOS (CADisplayLink is iOS only)
        let refreshRate = targetScreen?.maximumFramesPerSecond ?? 60
        let interval = 1.0 / Double(refreshRate)
        
        displayTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateFrame()
        }
    }
    
    @objc private func updateFrame() {
        let currentTime = CACurrentMediaTime()
        
        if lastFrameTime == 0 {
            lastFrameTime = currentTime
        }
        
        let deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        // Update each drop independently with its own timing
        for drop in drops {
            drop.update(deltaTime: deltaTime, currentTime: currentTime)
        }
        
        // Trigger redraw
        self.needsDisplay = true
    }
    
    public override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        // Fill background
        NSColor.black.setFill()
        rect.fill()
        
        // Draw each drop independently
        for drop in drops {
            drop.draw(in: rect)
        }
    }
    
    public override func startAnimation() {
        super.startAnimation()
        NSLog("AIMatrix V9: Starting animation on \(targetScreen?.localizedName ?? "unknown")")
    }
    
    public override func stopAnimation() {
        super.stopAnimation()
        displayTimer?.invalidate()
        displayTimer = nil
        NSLog("AIMatrix V9: Stopping animation")
    }
    
    public override func resize(withOldSuperviewSize oldSize: NSSize) {
        super.resize(withOldSuperviewSize: oldSize)
        NSLog("AIMatrix V9: Resizing from \(oldSize) to \(self.bounds)")
        setupIndependentDrops()
    }
    
    public override var isOpaque: Bool {
        return true
    }
    
    private func getCharacterSet() -> String {
        switch characterSet {
        case 0: return "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()+-="
        case 1: return "αβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ"
        case 2: return "アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッン"
        case 3: return "أبتثجحخدذرزسشصضطظعغفقكلمنهويءآةىإؤئ"
        default: return "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        }
    }
    
    private func getColor() -> NSColor {
        switch colorScheme {
        case 0: return NSColor.green
        case 1: return NSColor.blue
        case 2: return NSColor.red
        case 3: return NSColor.yellow
        case 4: return NSColor.cyan
        case 5: return NSColor.magenta
        case 6: return NSColor.orange
        case 7: return NSColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0)
        default: return NSColor.green
        }
    }
    
    private func getSpeedMultiplier() -> Double {
        switch speedSetting {
        case 0: return 0.5
        case 1: return 1.0
        case 2: return 1.5
        case 3: return 2.0
        default: return 1.0
        }
    }
    
    private func getFontSize() -> CGFloat {
        switch sizeSetting {
        case 0: return 12
        case 1: return 16
        case 2: return 20
        case 3: return 24
        default: return 16
        }
    }
    
    // MARK: - Configuration Sheet
    
    public override var hasConfigureSheet: Bool {
        return true
    }
    
    public override var configureSheet: NSWindow? {
        return ConfigSheetController.createConfigSheet(
            colorScheme: colorScheme,
            speedSetting: speedSetting,
            sizeSetting: sizeSetting,
            characterSet: characterSet,
            delegate: self
        )
    }
}

// MARK: - Independent Drop Class

class IndependentDrop {
    private var x: Double
    private var y: Double
    private var trail: [Character] = []
    private let maxTrailLength: Int
    private let characterSet: String
    private let font: NSFont
    private let color: NSColor
    private let screenBounds: NSRect
    
    // CRITICAL: Each drop has its own independent timing
    private var speed: Double
    private var lastUpdateTime: CFTimeInterval = 0
    private var updateInterval: CFTimeInterval // Each drop updates at different rate!
    private var mutationTimer: CFTimeInterval = 0
    private var mutationInterval: CFTimeInterval
    
    // Random number generator with unique seed
    private var rng: RandomNumberGeneratorWithSeed
    
    init(screenBounds: NSRect, uniqueRandomSeed: UInt32, characterSet: String, baseSpeed: Double, font: NSFont, color: NSColor) {
        self.screenBounds = screenBounds
        self.characterSet = characterSet
        self.font = font
        self.color = color
        
        // Initialize RNG with unique seed
        self.rng = RandomNumberGeneratorWithSeed(seed: uniqueRandomSeed)
        
        // Each drop has completely different properties
        self.x = Double.random(in: 0...Double(screenBounds.width), using: &rng)
        self.y = Double.random(in: -500...0, using: &rng) // Start above screen
        
        self.maxTrailLength = Int.random(in: 8...25, using: &rng)
        
        // CRITICAL: Each drop updates at a different rate
        self.speed = Double.random(in: 0.3...3.0, using: &rng) * baseSpeed
        self.updateInterval = Double.random(in: 0.008...0.05, using: &rng) // 8ms to 50ms
        self.mutationInterval = Double.random(in: 0.1...0.8, using: &rng)
        
        // Initialize trail with random characters
        for _ in 0..<maxTrailLength {
            if let randomChar = characterSet.randomElement(using: &rng) {
                trail.append(randomChar)
            }
        }
    }
    
    func update(deltaTime: CFTimeInterval, currentTime: CFTimeInterval) {
        // CRITICAL: Each drop only updates when ITS time has come
        if currentTime - lastUpdateTime >= updateInterval {
            // Move this drop
            y += speed * (currentTime - lastUpdateTime) * 60 // Normalize to ~60fps
            lastUpdateTime = currentTime
            
            // Reset if off screen
            if y > Double(screenBounds.height) + 100 {
                y = Double.random(in: -500...(-50), using: &rng)
                x = Double.random(in: 0...Double(screenBounds.width), using: &rng)
                
                // Randomize trail again
                trail.removeAll()
                let newLength = Int.random(in: 8...25, using: &rng)
                for _ in 0..<newLength {
                    if let randomChar = characterSet.randomElement(using: &rng) {
                        trail.append(randomChar)
                    }
                }
            }
        }
        
        // Character mutation on independent timer
        mutationTimer += deltaTime
        if mutationTimer >= mutationInterval {
            mutationTimer = 0
            mutationInterval = Double.random(in: 0.1...0.8, using: &rng) // Randomize next mutation time
            
            // Mutate a random character
            if !trail.isEmpty, Bool.random(using: &rng) {
                let randomIndex = Int.random(in: 0..<trail.count, using: &rng)
                if let randomChar = characterSet.randomElement(using: &rng) {
                    trail[randomIndex] = randomChar
                }
            }
        }
    }
    
    func draw(in rect: NSRect) {
        for (index, char) in trail.enumerated() {
            let charY = y - Double(index) * 20.0
            
            // Only draw visible characters
            if charY > -30 && charY < Double(rect.height + 30) {
                let brightness = Float(trail.count - index) / Float(trail.count)
                let alpha = CGFloat(brightness * 0.8 + 0.2)
                let drawColor = color.withAlphaComponent(alpha)
                
                // Add glow for leading character
                if index == 0 {
                    let glowString = NSAttributedString(string: String(char), attributes: [
                        .font: font,
                        .foregroundColor: color,
                        .strokeWidth: -2.0,
                        .strokeColor: color
                    ])
                    glowString.draw(at: NSPoint(x: x, y: charY))
                }
                
                // Draw character
                let string = NSAttributedString(string: String(char), attributes: [
                    .font: font,
                    .foregroundColor: drawColor
                ])
                
                string.draw(at: NSPoint(x: x, y: charY))
            }
        }
    }
}

// Custom RNG with seed for reproducible randomness per drop
struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt32) {
        self.state = UInt64(seed)
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

// MARK: - Configuration Sheet (same as before)

protocol ConfigSheetDelegate: AnyObject {
    func configSheetDidSave(colorScheme: Int, speedSetting: Int, sizeSetting: Int, characterSet: Int)
}

extension AIMatrixSceneKitView: ConfigSheetDelegate {
    func configSheetDidSave(colorScheme: Int, speedSetting: Int, sizeSetting: Int, characterSet: Int) {
        self.colorScheme = colorScheme
        self.speedSetting = speedSetting
        self.sizeSetting = sizeSetting
        self.characterSet = characterSet
        
        let defaults = ScreenSaverDefaults(forModuleWithName: "com.aimatrix.screensaver.v9")
        defaults?.set(colorScheme, forKey: "ColorScheme")
        defaults?.set(speedSetting, forKey: "SpeedSetting")
        defaults?.set(sizeSetting, forKey: "SizeSetting")
        defaults?.set(characterSet, forKey: "CharacterSet")
        defaults?.synchronize()
        
        characterFont = NSFont(name: "Courier", size: getFontSize()) ?? NSFont.systemFont(ofSize: getFontSize())
        characterColor = getColor()
        
        setupIndependentDrops()
    }
}

class ConfigSheetController: NSObject {
    static func createConfigSheet(colorScheme: Int, speedSetting: Int, sizeSetting: Int, characterSet: Int, delegate: ConfigSheetDelegate?) -> NSWindow? {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "AIMatrix V9 Settings"
        window.center()
        
        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        
        let colorLabel = NSTextField(labelWithString: "Color Scheme:")
        colorLabel.frame = NSRect(x: 20, y: 230, width: 100, height: 20)
        contentView.addSubview(colorLabel)
        
        let colorPopup = NSPopUpButton(frame: NSRect(x: 130, y: 225, width: 250, height: 30))
        colorPopup.addItems(withTitles: ["Green (Classic)", "Blue", "Red", "Yellow", "Cyan", "Purple", "Orange", "Pink"])
        colorPopup.selectItem(at: colorScheme)
        contentView.addSubview(colorPopup)
        
        let charLabel = NSTextField(labelWithString: "Character Set:")
        charLabel.frame = NSRect(x: 20, y: 180, width: 100, height: 20)
        contentView.addSubview(charLabel)
        
        let characterPopup = NSPopUpButton(frame: NSRect(x: 130, y: 175, width: 250, height: 30))
        characterPopup.addItems(withTitles: ["Classic Matrix (Latin)", "Greek Letters", "Japanese Katakana", "Arabic"])
        characterPopup.selectItem(at: characterSet)
        contentView.addSubview(characterPopup)
        
        let speedTitle = NSTextField(labelWithString: "Animation Speed:")
        speedTitle.frame = NSRect(x: 20, y: 130, width: 120, height: 20)
        contentView.addSubview(speedTitle)
        
        let speedSlider = NSSlider(frame: NSRect(x: 150, y: 130, width: 180, height: 20))
        speedSlider.minValue = 0
        speedSlider.maxValue = 3
        speedSlider.numberOfTickMarks = 4
        speedSlider.allowsTickMarkValuesOnly = true
        speedSlider.integerValue = speedSetting
        contentView.addSubview(speedSlider)
        
        let sizeTitle = NSTextField(labelWithString: "Character Size:")
        sizeTitle.frame = NSRect(x: 20, y: 80, width: 120, height: 20)
        contentView.addSubview(sizeTitle)
        
        let sizeSlider = NSSlider(frame: NSRect(x: 150, y: 80, width: 180, height: 20))
        sizeSlider.minValue = 0
        sizeSlider.maxValue = 3
        sizeSlider.numberOfTickMarks = 4
        sizeSlider.allowsTickMarkValuesOnly = true
        sizeSlider.integerValue = sizeSetting
        contentView.addSubview(sizeSlider)
        
        let cancelButton = NSButton(frame: NSRect(x: 200, y: 20, width: 80, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.action = #selector(NSWindow.close)
        cancelButton.target = nil
        contentView.addSubview(cancelButton)
        
        let okButton = NSButton(frame: NSRect(x: 290, y: 20, width: 80, height: 30))
        okButton.title = "OK"
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)
        
        let settings = ConfigSettings(
            colorPopup: colorPopup,
            characterPopup: characterPopup,
            speedSlider: speedSlider,
            sizeSlider: sizeSlider,
            delegate: delegate
        )
        
        okButton.target = settings
        okButton.action = #selector(ConfigSettings.okClicked(_:))
        
        objc_setAssociatedObject(window, "settings", settings, .OBJC_ASSOCIATION_RETAIN)
        
        window.contentView = contentView
        return window
    }
}

class ConfigSettings: NSObject {
    let colorPopup: NSPopUpButton
    let characterPopup: NSPopUpButton
    let speedSlider: NSSlider
    let sizeSlider: NSSlider
    weak var delegate: ConfigSheetDelegate?
    
    init(colorPopup: NSPopUpButton, characterPopup: NSPopUpButton, speedSlider: NSSlider, sizeSlider: NSSlider, delegate: ConfigSheetDelegate?) {
        self.colorPopup = colorPopup
        self.characterPopup = characterPopup
        self.speedSlider = speedSlider
        self.sizeSlider = sizeSlider
        self.delegate = delegate
        super.init()
    }
    
    @objc func okClicked(_ sender: NSButton) {
        delegate?.configSheetDidSave(
            colorScheme: colorPopup.indexOfSelectedItem,
            speedSetting: speedSlider.integerValue,
            sizeSetting: sizeSlider.integerValue,
            characterSet: characterPopup.indexOfSelectedItem
        )
        sender.window?.close()
    }
}