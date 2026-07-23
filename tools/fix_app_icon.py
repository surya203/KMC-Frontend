"""Scale logo content larger inside full-bleed yellow for tighter Rapido-like fill."""
from PIL import Image
from pathlib import Path

src_path = Path(r"c:\Users\user\Downloads\KMC-Frontend\assets\images\app_icon.png")
# Prefer original rounded source if available, else current
orig_path = Path(r"c:\Users\user\Downloads\KMC-Frontend\assets\images\app_icon_original.png")

YELLOW = (255, 222, 89)
SIZE = 2048
# How much of the canvas the artwork should fill (1.0 = edge to edge)
FILL = 0.96

base = Image.open(orig_path if orig_path.exists() else src_path).convert("RGBA")
alpha = base.split()[-1]
bbox = alpha.getbbox()
content = base.crop(bbox).convert("RGBA")

# Fill transparent (rounded corners) with yellow
px = content.load()
cw, ch = content.size
for y in range(ch):
    for x in range(cw):
        r, g, b, a = px[x, y]
        if a < 250:
            px[x, y] = (*YELLOW, 255)
        elif r > 230 and g > 190 and b < 140:
            px[x, y] = (*YELLOW, 255)

# Detect non-yellow content bbox (seal + text) to scale up tighter
def is_yellow(r, g, b, a, tol=28):
    if a < 200:
        return True
    return abs(r - YELLOW[0]) < tol and abs(g - YELLOW[1]) < tol and abs(b - YELLOW[2]) < tol

xmin, ymin, xmax, ymax = cw, ch, 0, 0
step = 2
for y in range(0, ch, step):
    for x in range(0, cw, step):
        r, g, b, a = px[x, y]
        if not is_yellow(r, g, b, a):
            if x < xmin:
                xmin = x
            if y < ymin:
                ymin = y
            if x > xmax:
                xmax = x
            if y > ymax:
                ymax = y

print("art bbox", xmin, ymin, xmax, ymax)
# Small padding so we don't clip anti-alias
pad = 12
xmin = max(0, xmin - pad)
ymin = max(0, ymin - pad)
xmax = min(cw - 1, xmax + pad)
ymax = min(ch - 1, ymax + pad)

art = content.crop((xmin, ymin, xmax + 1, ymax + 1))
aw, ah = art.size
print("art size", aw, ah)

# Place scaled art centered on full yellow canvas
canvas = Image.new("RGB", (SIZE, SIZE), YELLOW)
target = int(SIZE * FILL)
# Keep aspect ratio
scale = min(target / aw, target / ah)
nw, nh = int(aw * scale), int(ah * scale)
art_scaled = art.resize((nw, nh), Image.Resampling.LANCZOS).convert("RGBA")

# Flatten art onto yellow (transparent -> yellow already)
flat = Image.new("RGB", (nw, nh), YELLOW)
flat.paste(art_scaled.convert("RGB"), (0, 0), art_scaled.split()[-1] if art_scaled.mode == "RGBA" else None)

ox = (SIZE - nw) // 2
oy = (SIZE - nh) // 2
canvas.paste(flat, (ox, oy))
canvas.save(src_path, format="PNG", optimize=True)

check = Image.open(src_path)
print("saved", check.size, check.mode, "corners", check.getpixel((0, 0)), check.getpixel((SIZE - 1, SIZE - 1)))
