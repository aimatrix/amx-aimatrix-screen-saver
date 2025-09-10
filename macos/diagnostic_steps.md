# macOS Screen Saver Diagnostic Steps

## Security Analysis
1. **Check Code Signing Status:**
   ```bash
   codesign -dv /Users/vincent/Library/Screen\ Savers/forcedrawtest.saver
   spctl -a -t install /Users/vincent/Library/Screen\ Savers/forcedrawtest.saver
   ```

2. **Monitor System Calls During Full-Screen:**
   ```bash
   sudo dtruss -p `pgrep ScreenSaverEngine` 2>&1 | grep -E "(draw|render|context)"
   ```

3. **Check Console for Security Blocks:**
   ```bash
   log stream --predicate 'eventMessage CONTAINS "screen" OR eventMessage CONTAINS "saver"' --level debug
   ```

## Permission Testing
4. **Test Single Display Mode:**
   - Disconnect external monitor
   - Test screen saver on built-in display only

5. **Test System Screen Savers:**
   - Switch to built-in "Flurry" or "Arabesque"
   - Verify they work in full-screen

## Alternative Approaches
6. **Try Metal Rendering:**
   - Implement MTKView-based screen saver
   - Use Metal instead of OpenGL/Core Graphics

7. **Test Legacy Mode:**
   - Add entitlements plist
   - Request specific GPU access permissions

## Security Workarounds
8. **Disable SIP Temporarily (TESTING ONLY):**
   ```bash
   # Boot to Recovery Mode, open Terminal:
   csrutil disable
   # Test screen saver, then re-enable:
   csrutil enable
   ```

9. **Check App Sandbox:**
   ```bash
   codesign -d --entitlements - /Users/vincent/Library/Screen\ Savers/forcedrawtest.saver
   ```