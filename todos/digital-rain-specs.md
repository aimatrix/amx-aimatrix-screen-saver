# Digital Rain Screen Saver - Technical Specifications

## Overview
The Digital Rain (Matrix-style) screen saver displays falling characters in columns across the screen, creating the iconic "digital rain" effect from The Matrix movie. This document specifies the exact implementation requirements based on lessons learned from the macOS development.

## Core Requirements

### Visual Appearance
1. **Background**: Pure black (#000000) - NO exceptions or variations
2. **Characters**: Green by default (#00FF00), with customizable color options
3. **Font**: Monospace font (Courier, Monaco, or system monospace)
4. **Character Set**: 
   - Numbers: 0-9
   - Latin uppercase: A-Z
   - Greek letters: Α, Β, Γ, Δ, Ε, Ζ, Η, Θ, Ι, Κ, Λ, Μ, Ν, Ξ, Ο, Π, Ρ, Σ, Τ, Υ, Φ, Χ, Ψ, Ω
   - Optional: Japanese katakana for authenticity

### Animation Mechanics

#### Drop Structure
Each "drop" represents a single column of falling characters:
```
struct Drop {
    x: integer        // Column position (in character units)
    y: float         // Current vertical position (can be fractional)
    speed: float     // Fall speed (characters per frame)
    length: integer  // Number of visible characters in trail
    characters: array // The actual characters being displayed
}
```

#### Animation Parameters
- **Frame Rate**: 30 FPS minimum, 60 FPS preferred
- **Drop Speed**: 0.3 to 1.5 characters per frame (randomized per drop)
- **Drop Length**: 5 to 35 characters (randomized per drop)
- **Character Change**: Random characters should change every 3-5 frames
- **Spawn Rate**: New drops appear when old ones fall off screen

#### Trail Effect
- **Head Character**: Brightest (100% opacity or white color)
- **Trail Gradient**: Linear fade from head to tail
- **Minimum Opacity**: 10% at the tail end
- **Color Gradient Example** (for green theme):
  - Head: #FFFFFF (white) or #00FF00 (bright green)
  - Middle: #00FF00 → #00CC00 → #009900
  - Tail: #006600 → #003300 → #001100

### Performance Optimizations

#### Memory Management
1. **Pre-allocate drops**: Create fixed array of drops, reuse instead of creating/destroying
2. **Character caching**: Pre-generate character set, don't create strings each frame
3. **Avoid string concatenation**: Use character arrays or buffers
4. **Batch rendering**: Draw all characters in one pass if possible

#### Rendering Optimizations
1. **Dirty rectangle tracking**: Only redraw changed areas
2. **Double buffering**: Prevent flicker
3. **Hardware acceleration**: Use GPU when available (Metal, OpenGL, DirectX)
4. **Text rendering cache**: Cache rendered glyphs if drawing text is expensive

## Platform-Specific Considerations

### macOS (COMPLETED - Reference Implementation)
- **Framework**: ScreenSaver.framework
- **Language**: Objective-C (Swift had issues)
- **Key Lessons**:
  - Must implement both `drawRect:` and `animateOneFrame`
  - Use `setNeedsDisplay:YES` to trigger redraws
  - Code signing with entitlements required for macOS 11+
  - Metal API works better than Core Graphics for full-screen
  - Bundle identifier must be unique
  - Info.plist requires NSPrincipalClass entry

### Windows Implementation Guidelines
- **Framework**: Windows Screen Saver API
- **Language**: C++ with Win32 API
- **File Extension**: .scr (renamed .exe)
- **Key Requirements**:
  - Implement ScreenSaverProc for rendering
  - Handle WM_CREATE, WM_DESTROY, WM_TIMER messages
  - Use GDI+ or Direct2D for rendering
  - Configuration dialog via ScreenSaverConfigureDialog
  - Preview window support (small preview in settings)
  - Multi-monitor support via EnumDisplayMonitors

### Linux Implementation Guidelines
- **Framework**: XScreenSaver or custom X11/Wayland
- **Language**: C/C++ or Python
- **Key Requirements**:
  - XScreenSaver: Follow hack format, implement draw_matrix function
  - Handle SIGTERM gracefully
  - Use Cairo or raw X11 for rendering
  - Support both X11 and Wayland if possible
  - Configuration via .xscreensaver file
  - Handle multiple displays via Xinerama/RandR

### iOS Implementation Guidelines
- **Framework**: UIKit + Metal or SpriteKit
- **Language**: Swift (preferred) or Objective-C
- **Key Requirements**:
  - Use CADisplayLink for smooth animation
  - Implement low power mode detection
  - Handle app lifecycle (background/foreground)
  - Support all device orientations
  - Adaptive layout for different screen sizes
  - Consider battery impact

### Chrome Extension Guidelines
- **Framework**: Chrome Extension Manifest V3
- **Language**: JavaScript/HTML5 Canvas
- **Key Requirements**:
  - Use requestAnimationFrame for smooth animation
  - Canvas 2D context for rendering
  - chrome.storage.sync for settings
  - Respect prefers-reduced-motion
  - Handle visibility API for pause/resume
  - WebGL optional for better performance

## Configuration Options

### User-Configurable Settings
1. **Color Scheme** (minimum 8 options):
   - Green (Classic): #00FF00
   - Blue: #00CCFF
   - Red: #FF0000
   - Yellow: #FFFF00
   - Cyan: #00FFFF
   - Purple: #CC00FF
   - Orange: #FF9900
   - Pink: #FF69B4

2. **Speed Settings**:
   - Slow: 0.3-0.5 chars/frame
   - Normal: 0.5-0.8 chars/frame
   - Fast: 0.8-1.2 chars/frame
   - Very Fast: 1.0-1.5 chars/frame

3. **Density Settings**:
   - Sparse: 30% of columns active
   - Normal: 50% of columns active
   - Dense: 70% of columns active

4. **Character Size**:
   - Small: 10-12px
   - Medium: 14-16px
   - Large: 18-20px
   - Extra Large: 22-24px

## Error Handling

### Common Issues and Solutions

1. **Black Screen Problem**:
   - Always test rendering pipeline first with simple shapes
   - Verify draw callbacks are being triggered
   - Check permissions and security settings
   - Use logging to trace execution flow

2. **Performance Issues**:
   - Profile before optimizing
   - Limit number of active drops
   - Use integer coordinates when possible
   - Cache frequently used calculations

3. **Memory Leaks**:
   - Pre-allocate all objects at start
   - Avoid creating objects in render loop
   - Use object pools for drops
   - Clear timers and intervals on cleanup

4. **Multi-Monitor Issues**:
   - Detect monitor configuration changes
   - Scale drops based on screen dimensions
   - Handle different DPI settings
   - Test with various monitor arrangements

## Testing Requirements

### Functional Tests
1. Verify animation starts immediately
2. Test all color schemes
3. Verify settings persistence
4. Test pause/resume functionality
5. Verify proper cleanup on exit

### Performance Tests
1. Measure FPS under load
2. Monitor memory usage over time
3. Test with maximum drops/density
4. Verify CPU usage is reasonable (<10% on modern hardware)

### Compatibility Tests
1. Test on minimum supported OS version
2. Test on various screen resolutions
3. Test with multiple monitors
4. Test with different DPI settings
5. Test with different graphics cards

## Security Considerations

1. **Code Signing**: Required on macOS and Windows
2. **Permissions**: Minimize required permissions
3. **Sandboxing**: Use when available (macOS, Chrome)
4. **Input Validation**: Sanitize all configuration inputs
5. **No Network Access**: Screen savers should not require internet

## Implementation Checklist

- [ ] Create drop data structure
- [ ] Implement character set
- [ ] Create rendering loop
- [ ] Add trail gradient effect
- [ ] Implement drop recycling
- [ ] Add configuration UI
- [ ] Handle multi-monitor
- [ ] Add settings persistence
- [ ] Implement proper cleanup
- [ ] Add installation scripts
- [ ] Create documentation
- [ ] Test on target platform
- [ ] Package for distribution

## Algorithm Pseudocode

```pseudocode
Initialize:
    columns = screen_width / char_width
    drops = array of Drop[columns * density]
    for each drop:
        randomize initial position and properties

Each Frame:
    clear screen to black
    for each drop:
        // Update position
        drop.y += drop.speed
        
        // Randomly change characters
        if random() < 0.1:
            randomize some characters in drop
        
        // Draw the drop
        for i from 0 to drop.length:
            char_y = drop.y - i
            if char_y >= 0 and char_y < screen_height:
                opacity = (drop.length - i) / drop.length
                color = interpolate(tail_color, head_color, opacity)
                draw_character(drop.characters[i], drop.x, char_y, color)
        
        // Reset drop when it falls off screen
        if drop.y - drop.length > screen_height:
            reset_drop(drop)
```

## Branding Guidelines

1. **Name**: "AIMatrix Screen Saver" or "AIMatrix Digital Rain"
2. **Version Format**: Major.Minor (e.g., 6.0)
3. **Attribution**: Include "aimatrix.com" in about/info
4. **Icon**: Matrix-style green text on black
5. **Preview Image**: Show actual screen saver in action

## Distribution Package Requirements

Each platform package should include:
1. The executable/bundle
2. Installation instructions (README)
3. Automated installer (if applicable)
4. Uninstaller script
5. License file (MIT)
6. Preview screenshot

## Lessons Learned from macOS Development

### DO:
- Start with the simplest possible rendering test
- Use native frameworks when possible
- Test on actual hardware, not just simulator
- Sign code early in development process
- Keep rendering code separate from configuration
- Use hardware acceleration when available
- Pre-allocate all memory before animation starts
- Test with different user permissions

### DON'T:
- Don't use experimental APIs
- Don't create objects in render loop
- Don't assume callbacks will fire
- Don't ignore platform security models
- Don't use blocking operations in render thread
- Don't forget cleanup code
- Don't hardcode screen dimensions
- Don't use excessive CPU for simple effects

## References

- Matrix Digital Rain: https://en.wikipedia.org/wiki/Matrix_digital_rain
- Original Matrix Code: Green characters on black, mix of Japanese and Latin
- Performance target: Should use <5% CPU on modern hardware
- Memory target: <50MB RAM usage