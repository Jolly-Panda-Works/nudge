"""Draws Nudge's original app icon and the Google Play graphics.

Run it when the design changes (needs Pillow: `pip install pillow`):

    python3 tools/make_icons.py

It writes into assets/branding/. CI does not run it; the PNGs are committed and
tools/wire_capture.py copies them into the generated Android and Windows
projects.
"""

import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover
    sys.exit('Pillow is needed: pip install pillow')

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'branding')
SCALE = 4  # draw large, then shrink, for smooth edges
INDIGO_TOP = (57, 73, 171)
INDIGO_BOTTOM = (92, 107, 192)
AMBER = (255, 193, 7)
WHITE = (255, 255, 255)


def gradient(size):
    image = Image.new('RGB', (size, size))
    pixels = image.load()
    for y in range(size):
        t = y / (size - 1)
        color = tuple(
            round(INDIGO_TOP[i] + (INDIGO_BOTTOM[i] - INDIGO_TOP[i]) * t)
            for i in range(3)
        )
        for x in range(size):
            pixels[x, y] = color
    return image


def glyph(draw, s):
    """A bold N with an amber notification dot: a nudge."""
    width = round(s * 0.094)
    left, right = round(s * 0.30), round(s * 0.70)
    top, bottom = round(s * 0.31), round(s * 0.69)
    points = [(left, bottom), (left, top), (right, bottom), (right, top)]
    draw.line(points, fill=WHITE, width=width, joint='curve')
    for x, y in points:  # round caps
        r = width // 2
        draw.ellipse((x - r, y - r, x + r, y + r), fill=WHITE)
    cx, cy, r = round(s * 0.775), round(s * 0.235), round(s * 0.085)
    ring = round(s * 0.024)
    outer = r + ring
    draw.ellipse((cx - outer, cy - outer, cx + outer, cy + outer), fill=INDIGO_TOP)
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=AMBER)


def square_icon(size):
    """Full-bleed icon (Google Play applies its own mask)."""
    big = size * SCALE
    image = gradient(big)
    glyph(ImageDraw.Draw(image), big)
    return image.resize((size, size), Image.LANCZOS)


def rounded_icon(size):
    """Rounded square with transparent corners, for the launcher PNGs."""
    big = size * SCALE
    base = gradient(big).convert('RGBA')
    glyph(ImageDraw.Draw(base), big)
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, big - 1, big - 1), radius=round(big * 0.22), fill=255)
    base.putalpha(mask)
    return base.resize((size, size), Image.LANCZOS)


def feature_graphic():
    w, h = 1024, 500
    big = Image.new('RGB', (w * 2, h * 2))
    px = big.load()
    for y in range(h * 2):
        t = y / (h * 2 - 1)
        color = tuple(
            round(INDIGO_TOP[i] + (INDIGO_BOTTOM[i] - INDIGO_TOP[i]) * t)
            for i in range(3)
        )
        for x in range(w * 2):
            px[x, y] = color
    icon = rounded_icon(560)
    big.paste(icon, (90, 220), icon)
    draw = ImageDraw.Draw(big)
    bold = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
    plain = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    title = ImageFont.truetype(bold, 250)
    sub = ImageFont.truetype(plain, 78)
    draw.text((760, 330), 'Nudge', font=title, fill=WHITE)
    draw.text((768, 640), 'Notifications into tasks', font=sub, fill=(224, 228, 255))
    draw.text((768, 740), 'and a calendar you enjoy', font=sub, fill=(224, 228, 255))
    return big.resize((w, h), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    densities = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    for name, size in densities.items():
        rounded_icon(size).save(os.path.join(OUT, f'ic_launcher_{name}.png'))
    square_icon(512).save(os.path.join(OUT, 'play_icon_512.png'))
    feature_graphic().save(os.path.join(OUT, 'play_feature_1024x500.png'))
    sizes = [16, 24, 32, 48, 64, 128, 256]
    rounded_icon(256).save(
        os.path.join(OUT, 'app_icon.ico'), sizes=[(s, s) for s in sizes])
    print('Wrote', sorted(os.listdir(OUT)))


if __name__ == '__main__':
    main()
