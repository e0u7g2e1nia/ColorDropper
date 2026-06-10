# ColorDropper

A tiny macOS menu-bar and floating color picker built locally with AppKit.

## Features

- Global shortcut: `Control` + `Option` + `Command` + `C`
- Floating `取色` button near the top-right of the screen
- Click-to-pick mode for choosing a pixel from any visible app
- Automatically copies uppercase hex colors like `#AABBCC`
- Includes a generated flat icon asset

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
