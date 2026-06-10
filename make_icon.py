from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "Resources" / "AppIcon-source.png"
ICONSET = ROOT / "AppIcon.iconset"


def build_iconset():
    if not SOURCE.exists():
        raise SystemExit(f"missing icon source: {SOURCE}")

    ICONSET.mkdir(exist_ok=True)
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    img = Image.open(SOURCE).convert("RGBA")
    for name, size in sizes.items():
        img.resize((size, size), Image.Resampling.LANCZOS).save(ICONSET / name)


if __name__ == "__main__":
    build_iconset()
