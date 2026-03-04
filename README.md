# LumenX

A lightweight macOS menu bar app that automatically adjusts each monitor's brightness based on what's on screen. Bright content dims the display; dark content brightens it — independently per monitor.

Built for Apple Silicon Macs with external monitors.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-M1%2FM2%2FM3%2FM4-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## How It Works

1. Captures each display's content (downsampled to 64×64 for efficiency)
2. Calculates average luminance using ITU-R BT.709 perceptual weighting
3. Maps luminance to a target brightness (bright screen → lower brightness)
4. Sends DDC/CI commands directly to each monitor's hardware via [m1ddc](https://github.com/waydabber/m1ddc)

No gamma table hacks. No color profile tricks. Real hardware brightness control.

## Features

- **Per-monitor adaptive brightness** — each display adjusts independently based on its own content
- **Manual override** — switch any monitor to manual mode with a brightness slider
- **Keyboard brightness keys** — F1/F2 adjust the monitor under your cursor and auto-switch to manual mode
- **Per-display baseline** — set a manual brightness, switch back to auto, and it becomes the ceiling for that monitor
- **Adjustable sensitivity** — control how aggressively brightness responds to content changes
- **Min/Max limits** — set brightness bounds per monitor in auto mode
- **Instant response** — large brightness changes apply near-instantly; small ones smooth gradually
- **Tiny footprint** — lives in the menu bar, ~150KB app, minimal CPU usage

## Requirements

- Apple Silicon Mac (M1/M2/M3/M4)
- macOS 13 (Ventura) or later
- External monitors connected via **DisplayPort or USB-C** (DDC doesn't work over HDMI on most Macs)

## Install

1. Download `LumenX.dmg` from the [latest release](https://github.com/dipta007/Aura/releases/latest)
2. Open the DMG and drag **LumenX** to your Applications folder
3. Right-click the app → **Open** (required on first launch since the app isn't notarized)
4. Grant the permissions when prompted:
   - **Screen Recording** — to capture screen content for luminance analysis
   - **Accessibility** — to respond to keyboard brightness keys

## Usage

Click the ☀️ sun icon in the menu bar to open the panel:

- **Global toggle** — enable/disable adaptive brightness for all monitors
- **Per-monitor controls** — click the chevron (▼) to expand:
  - **Auto/Manual** toggle — switch between adaptive and manual brightness
  - **Auto mode**: min/max brightness sliders set the range
  - **Manual mode**: direct brightness slider (0–100%)
- **Sensitivity** — how aggressively brightness reacts to content changes
- **Update interval** — how often the screen is sampled (0.5s–5s)

**Keyboard brightness keys** (F1/F2) adjust the monitor under your mouse cursor and automatically switch that monitor to manual mode.

**Setting a baseline**: Set a monitor to manual at your preferred brightness (e.g., 70%), then switch back to Auto. The adaptive engine will treat 70% as the maximum and only dim below it for bright content.

## Build from Source

```bash
git clone git@github.com:dipta007/Aura.git
cd Aura

# Build and create DMG (bundles m1ddc automatically)
./scripts/build-release.sh

# Output: dist/LumenX.app and dist/LumenX.dmg
```

### Dependencies

- Swift 5.9+
- [m1ddc](https://github.com/waydabber/m1ddc) — bundled automatically during build, or install with `brew install m1ddc`

## How the Brightness Mapping Works

```
Content luminance    →    Display brightness
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0.0  (black screen)  →    max (baseline)
0.3  (dark content)  →    ~80% of max
0.5  (mixed content) →    ~55% of max
0.8  (bright page)   →    ~25% of max
1.0  (white screen)  →    min
```

Uses a power curve (exponent 0.6) for more aggressive dimming at mid-range luminance, where most real content lives.

## Troubleshooting

**App doesn't appear in menu bar**
- Make sure it's running (check Activity Monitor)
- Grant Screen Recording permission in System Settings → Privacy & Security

**Brightness not changing on a monitor**
- Verify the monitor is connected via DisplayPort or USB-C (not HDMI)
- Check that m1ddc can see your monitor: run `m1ddc display list` in Terminal
- Some monitors have DDC disabled by default — check your monitor's OSD settings

**Keyboard brightness keys don't work**
- Grant Accessibility permission in System Settings → Privacy & Security → Accessibility
- Keys only affect the monitor under your mouse cursor

**Debug logs**
- Check `/tmp/lumenx.log` for detailed per-tick diagnostics

## Contributing

Contributions are welcome — including AI-assisted contributions, as long as they are **human-reviewed and tested** on real hardware before submitting.

See the [Contributing Guide](CONTRIBUTING.md) for setup instructions, project structure, and guidelines.

## Credits

- [m1ddc](https://github.com/waydabber/m1ddc) by waydabber — DDC/CI control for Apple Silicon (MIT License, bundled with permission)

## License

MIT
