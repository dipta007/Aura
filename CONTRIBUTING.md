# Contributing to LumenX

Thanks for your interest in contributing! LumenX is a small, focused app and contributions are welcome.

## Getting Started

1. Fork the repo and clone it
2. Make sure you have:
   - Xcode 15+ (for Swift 5.9)
   - Apple Silicon Mac (required for DDC/m1ddc)
   - `brew install m1ddc`
3. Build and run:
   ```bash
   swift build -c release
   ./scripts/build-release.sh
   ```

## Development

### Project Structure

```
Sources/LumenX/
├── App/                # App entry point, AppDelegate
├── Core/               # Engine, brightness control, screen capture
├── Display/            # Display enumeration, DDC control
├── UI/                 # SwiftUI views (menu bar, settings)
└── Utilities/          # Preferences, constants
```

### Debug Logs

The app writes detailed logs to `/tmp/lumenx.log`. Tail it while developing:

```bash
tail -f /tmp/lumenx.log
```

### Key Files

- `AdaptiveEngine.swift` — Main loop: capture → analyze → map → smooth → apply
- `BrightnessController.swift` — DDC commands via m1ddc
- `KeyboardBrightnessHandler.swift` — Keyboard brightness key interception
- `DisplayRowView.swift` — Per-monitor UI with auto/manual toggle

## Making Changes

1. Create a branch from `main`
2. Keep changes focused — one feature or fix per PR
3. Test with at least one external monitor connected via DisplayPort/USB-C
4. Make sure `swift build -c release` passes with no errors

## What to Contribute

- Bug fixes (especially for specific monitor models)
- Monitor compatibility improvements
- UI polish
- Documentation improvements
- Performance optimizations

## What to Avoid

- Adding heavy dependencies
- Features that require notarization or paid signing
- Changes that break the single-binary + m1ddc architecture

## Reporting Bugs

Use the [bug report template](https://github.com/dipta007/Aura/issues/new?template=bug_report.yml) and include:

- Your Mac model and macOS version
- Monitor model and connection type (DisplayPort/USB-C/HDMI)
- Contents of `/tmp/lumenx.log` around the time of the issue

## Code Style

- Follow existing patterns in the codebase
- No external dependencies unless absolutely necessary
- Keep files small and focused
- Use `debugLog()` for diagnostic logging

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
