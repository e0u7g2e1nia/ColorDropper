from pathlib import Path

from PIL import Image, ImageDraw

S = 4
W = 1024 * S
ROOT = Path(__file__).resolve().parent


def c(v):
    return int(round(v * S))


def xy(points):
    return [(c(x), c(y)) for x, y in points]


img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

dark = (35, 42, 52, 255)
mid = (65, 74, 88, 255)
cyan = (26, 184, 206, 255)
magenta = (224, 80, 150, 255)
yellow = (248, 202, 70, 255)
white = (255, 255, 255, 255)

# Large flat eyedropper, transparent background.
draw.line(xy([(738, 182), (534, 386)]), fill=dark, width=c(120))
draw.ellipse([c(684), c(128), c(798), c(242)], fill=dark)
draw.ellipse([c(474), c(338), c(594), c(458)], fill=dark)

# Collar.
draw.line(xy([(432, 356), (606, 530)]), fill=dark, width=c(92))
draw.line(xy([(446, 370), (592, 516)]), fill=mid, width=c(44))

# Glass tube.
draw.line(xy([(512, 512), (300, 724)]), fill=dark, width=c(88))
draw.line(xy([(514, 514), (320, 708)]), fill=white, width=c(52))
draw.line(xy([(348, 728), (238, 838)]), fill=dark, width=c(42))
draw.line(xy([(350, 728), (256, 822)]), fill=white, width=c(20))

# Color sample and swatches.
draw.ellipse([c(178), c(806), c(314), c(942)], fill=cyan)
draw.rounded_rectangle([c(650), c(682), c(770), c(802)], radius=c(30), fill=magenta)
draw.rounded_rectangle([c(782), c(682), c(902), c(802)], radius=c(30), fill=yellow)
draw.rounded_rectangle([c(650), c(814), c(770), c(934)], radius=c(30), fill=cyan)

img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
img.save(ROOT / "Resources" / "AppIcon-source.png")
