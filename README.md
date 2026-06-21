# ColorDropper

A tiny macOS menu-bar and floating color picker built locally with AppKit.

## Features

- Global shortcut: `Control` + `Option` + `Command` + `C`
- Native macOS menu-bar item with picker, floating-button, and quit controls
- Draggable floating `取色` button that remembers its screen position
- Native macOS pixel magnifier powered by `NSColorSampler`
- Automatically copies uppercase hex colors like `#AABBCC`
- Includes a generated flat icon asset

Press the shortcut or click the floating button, position the magnifier over the
exact pixel, and click to copy its sRGB hex value. Press `Esc` to cancel.

## Build

```bash
./build.sh
```

The built app is written to `outputs/ColorDropper.app`.

## Install Locally

```bash
ditto outputs/ColorDropper.app /Applications/ColorDropper.app
open /Applications/ColorDropper.app
```
