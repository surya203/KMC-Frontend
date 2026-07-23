"""Compose a properly padded KMC Alumni app icon (safe-zone aware)."""

from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFont

BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "images")
OUT_PATH = os.path.join(BASE, "app_icon.png")
BACKUP = os.path.join(BASE, "app_icon_before_pad.png")

SIZE = 2048
YELLOW = (255, 222, 89, 255)  # #FFDE59
BLUE = (26, 39, 68, 255)


def circle_mask_seal(seal: Image.Image) -> Image.Image:
    """Keep seal pixels inside a circle; clear outside."""
    seal = seal.convert("RGBA")
    w, h = seal.size
    cx, cy = w / 2, h / 2
    r = min(w, h) / 2 - 2
    pixels = seal.load()
    assert pixels is not None
    for y in range(h):
        for x in range(w):
            dx, dy = x - cx, y - cy
            dist = (dx * dx + dy * dy) ** 0.5
            if dist > r:
                pixels[x, y] = (0, 0, 0, 0)
            elif dist > r - 1.5:
                a = int(255 * max(0.0, (r - dist) / 1.5))
                pr, pg, pb, _ = pixels[x, y]
                pixels[x, y] = (pr, pg, pb, a)
    return seal


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\calibrib.ttf",
        r"C:\Windows\Fonts\arial.ttf",
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size=size)
    return ImageFont.load_default()


def main() -> None:
    current = os.path.join(BASE, "app_icon.png")
    if os.path.exists(current) and not os.path.exists(BACKUP):
        Image.open(current).save(BACKUP)
        print("backed up:", BACKUP)

    canvas = Image.new("RGBA", (SIZE, SIZE), YELLOW)
    draw = ImageDraw.Draw(canvas)

    seal = circle_mask_seal(
        Image.open(os.path.join(BASE, "logo_kmc.jpeg"))
    )
    # Content in safe zone: seal ~58% with ~21% side padding
    seal_diam = int(SIZE * 0.58)
    seal = seal.resize((seal_diam, seal_diam), Image.Resampling.LANCZOS)
    top_pad = int(SIZE * 0.10)
    seal_x = (SIZE - seal_diam) // 2
    seal_y = top_pad
    canvas.paste(seal, (seal_x, seal_y), seal)

    text = "KMC ALUMNI"
    font = load_font(int(SIZE * 0.085))
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    band_top = seal_y + seal_diam
    band_bottom = SIZE - int(SIZE * 0.10)
    text_y = band_top + (band_bottom - band_top - th) // 2 - bbox[1]
    text_x = (SIZE - tw) // 2 - bbox[0]
    draw.text((text_x, text_y), text, font=font, fill=BLUE)

    final = Image.new("RGB", (SIZE, SIZE), (255, 222, 89))
    final.paste(canvas, mask=canvas.split()[-1])
    final.save(OUT_PATH, "PNG", optimize=True)
    print("wrote", OUT_PATH, final.size)
    print(
        f"seal={seal_diam/SIZE:.2f} side_pad={seal_x/SIZE:.2f} "
        f"top={top_pad/SIZE:.2f} text_y={text_y/SIZE:.2f}"
    )


if __name__ == "__main__":
    main()
