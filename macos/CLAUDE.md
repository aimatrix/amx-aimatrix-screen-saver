# Matrix Screen Saver Development Notes

## Versioning System
- Format: `<major-version-no>.<minor-version>`
- Minor version: 1 to 10000
- Major version only bumps when user explicitly requests it
- Display name: "aimatrix vX.Y"
- Current version: 5.10

## Development History
- v4.x: Multiple failed Swift implementations with caching issues
- v5.0: Switch to Objective-C, complete rewrite
- v5.1: Added debugging features, still black screen
- v5.2: Simplified to single color falling digital rain
- v5.3: Ultra-basic red background test to isolate drawing system issue
- v5.4: Added extensive logging to debug drawRect issue (black background, green text)
- v5.5: Fixed name back to "aimatrix v5.5", continued debugging drawRect not being called
- v5.6: Cleaned up all old versions, fixed bundle name to match display name
- v5.7: Ultra-basic test with blue background and white text
- v5.8: Fixed background to BLACK as repeatedly requested by user
- v5.9: Abandoned Metal API, implemented simple Core Graphics digital rain with Greek characters
- v5.10: Added both uppercase and lowercase Greek characters (Α/α, Β/β, etc.)
- v5.17: Fixed blank screen bug by removing framebuffer and using direct NSString drawing
- v5.18: Added extensive logging for debugging
- v5.19: Complete rewrite with proper Matrix rain effect
- v5.20: Added code signing with Apple Developer certificate to fix security issues
- v5.21: Simplified code for macOS Sequoia compatibility
- v5.22: Added hardened runtime and entitlements for enhanced security

## Current Issue
User sees black screen - drawRect method not being called at all. Added comprehensive logging to identify where in ScreenSaver framework the failure occurs.

## Requirements (Simplified)
- Screen saver must appear as "aimatrix vX.Y" in System Preferences
- Single color digital rain (green on black)
- Greek characters falling down
- Simple, working animation
- Must fix fundamental drawRect issue first