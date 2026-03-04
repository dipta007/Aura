# LumenX — Project Instructions for Claude

## What This Project Is

LumenX is a macOS menu bar app that adjusts each monitor's hardware brightness based on on-screen content. It captures the screen, calculates luminance, and sends DDC/CI commands via m1ddc. Apple Silicon only.

## Architecture

```
Sources/LumenX/
├── App/
│   ├── LumenXApp.swift          # @main entry, MenuBarExtra with sun icon
│   └── AppDelegate.swift        # Lifecycle, permissions, starts engine + keyboard handler
├── Core/
│   ├── AdaptiveEngine.swift      # Main loop: capture → analyze → map → smooth → DDC
│   ├── BrightnessController.swift # Sends DDC via m1ddc CLI, CoreDisplay for built-in
│   ├── KeyboardBrightnessHandler.swift # CGEventTap for F1/F2 brightness keys
│   ├── ScreenCapturer.swift      # CGDisplayCreateImage → 64×64 downsample
│   ├── LuminanceAnalyzer.swift   # ITU-R BT.709 perceptual luminance from pixels
│   └── SmoothingFilter.swift     # Exponential moving average with configurable alpha
├── Display/
│   ├── DisplayInfo.swift         # Display model struct (id, name, brightness, mode)
│   ├── DisplayManager.swift      # CGGetActiveDisplayList, reconfiguration callback
│   ├── CoreDisplayControl.swift  # Private API via dlopen for built-in displays
│   └── DDCBrightnessControl.swift # Legacy stub (unused, m1ddc replaced it)
├── UI/
│   ├── MenuBarView.swift         # Main popover: global toggle, sensitivity, interval
│   ├── DisplayRowView.swift      # Per-display: auto/manual toggle, brightness slider
│   └── SettingsView.swift        # Settings form (currently unused in menu bar)
└── Utilities/
    ├── Constants.swift           # Default values for all settings
    └── Preferences.swift         # UserDefaults wrapper, per-display settings
```

## Key Technical Details

### Brightness Control
- **External monitors**: DDC/CI via `m1ddc` CLI tool (bundled in app Resources)
- **Built-in display**: `CoreDisplay_Display_SetUserBrightness` private API via dlopen
- BrightnessController looks for m1ddc in: Bundle.main Resources → /opt/homebrew/bin → /usr/local/bin
- DDC values are 0-100 integers. App uses 0.0-1.0 floats internally, multiplied by 100 for DDC

### Adaptive Engine Loop (every 2s by default)
1. `CGDisplayCreateImage` → downsample to 64×64
2. Calculate average luminance (BT.709 weighted RGB)
3. Map luminance to brightness using power curve (exponent 0.6) within display's [min, max] range
4. Smooth via EMA — alpha 0.85 for large changes (>15%), 0.1+sensitivity*0.5 for small
5. Apply via DDC if change > 1%
6. Displays in manual mode or disabled are skipped

### Keyboard Brightness
- Uses CGEventTap (requires Accessibility permission)
- Intercepts NX_KEYTYPE_BRIGHTNESS_UP (2) and NX_KEYTYPE_BRIGHTNESS_DOWN (3)
- Only adjusts the monitor under the mouse cursor (CGGetDisplaysWithPoint)
- Auto-switches that display to manual mode
- Step size: 6.25% (16 steps from 0 to 100)

### Per-Display Settings (persisted via UserDefaults)
- `isEnabled` — whether display participates at all
- `isAutoMode` — true = adaptive, false = manual slider
- `manualBrightness` — last manual value (also becomes maxBrightness baseline for auto)
- `minBrightness` / `maxBrightness` — auto mode range

### Permissions Required
- **Screen Recording** — for CGDisplayCreateImage
- **Accessibility** — for CGEventTap (keyboard brightness keys)

## Build & Run

```bash
swift build -c release          # Build
./scripts/build-release.sh      # Build + bundle m1ddc + create DMG
```

Debug logs go to `/tmp/lumenx.log`. All components use `debugLog()` file-based logging.

## Code Conventions

- No external Swift packages — only system frameworks
- `debugLog()` for diagnostics (file-based, not NSLog)
- Display brightness values are always 0.0-1.0 Float internally
- Use `display.id` (CGDirectDisplayID) as the canonical key for per-display state
- Main thread for UI/DisplayManager updates, utility queue for capture/analysis
- Ad-hoc codesign (`codesign --force --deep --sign -`), not notarized

## Known Limitations

- DDC doesn't work over HDMI on most Macs (DisplayPort/USB-C only)
- Apple Silicon only (m1ddc requirement)
- `DDCBrightnessControl.swift` is a dead stub — m1ddc replaced it, can be removed
- `SettingsView.swift` is rendered in code but not currently used in the menu bar UI
- Screen Recording permission resets after re-codesigning — user must re-grant
- No app icon (uses system `sun.max.fill`)

## Pitfalls Learned

- **Never use gamma tables for brightness**: CGDisplayCreateImage captures post-gamma output, creating a feedback loop (bright→dim→captures darker→brightens→flicker)
- **isRunning didSet recursion**: Setting `isRunning = true` inside `start()` which is called from `didSet` causes stack overflow. Guard with `oldValue` check
- **NSLog shows `<private>` on macOS**: Use file-based logging instead
- **m1ddc display matching**: Match displays by name string, not by CGDirectDisplayID (IDs don't map directly to m1ddc's numbering)
- **Smoothing too aggressive = invisible changes**: Alpha < 0.1 makes brightness changes take 30+ seconds to converge
- **Manual slider @State doesn't sync**: SwiftUI @State persists across parent re-renders for same Identifiable id — must use `.onChange(of: display.property)` to sync external changes
