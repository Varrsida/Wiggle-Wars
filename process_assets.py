import os
import shutil
from PIL import Image, ImageFilter
import numpy as np

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(PROJECT_ROOT, "assets")
IMPORTED_DIR = os.path.join(ASSETS_DIR, "imported")
BG_DIR = os.path.join(ASSETS_DIR, "backgrounds")
CHAR_DIR = os.path.join(ASSETS_DIR, "characters")

for d in [IMPORTED_DIR, BG_DIR, CHAR_DIR]:
    os.makedirs(d, exist_ok=True)

UPLOADED_PATHS = {
    "garden": "C:/Users/Varrsida/.gemini/antigravity/brain/f5a9cede-6ce5-4525-8d4e-d371a70297ad/.user_uploaded/media_1791897991295_2fe1e6f6.jpg",
    "snowy_path": "C:/Users/Varrsida/.gemini/antigravity/brain/f5a9cede-6ce5-4525-8d4e-d371a70297ad/.user_uploaded/media_1791897965793_0e510293.png",
    "penguin": "C:/Users/Varrsida/.gemini/antigravity/brain/f5a9cede-6ce5-4525-8d4e-d371a70297ad/.user_uploaded/media_1791897973352_8f09895d.png",
    "shinchan": "C:/Users/Varrsida/.gemini/antigravity/brain/f5a9cede-6ce5-4525-8d4e-d371a70297ad/.user_uploaded/media_1791897999720_db816d99.png",
    "carnival": "C:/Users/Varrsida/.gemini/antigravity/brain/f5a9cede-6ce5-4525-8d4e-d371a70297ad/.user_uploaded/media_1791897981244_28eab146.png"
}

# 1. Copy raw originals into assets/imported/
for k, src in UPLOADED_PATHS.items():
    ext = os.path.splitext(src)[1]
    dest = os.path.join(IMPORTED_DIR, f"original_{k}{ext}")
    shutil.copyfile(src, dest)
    print(f"Copied original {k} -> {dest}")

# Helper: fit portrait/any image onto a 1280x720 canvas with blurred ambient background
def fit_to_1280x720(im_src, crop_bottom_px=0):
    w, h = im_src.size
    if crop_bottom_px > 0:
        im_src = im_src.crop((0, 0, w, h - crop_bottom_px))
        w, h = im_src.size

    # Background canvas 1280x720
    canvas = Image.new("RGBA", (1280, 720), (0, 0, 0, 255))
    
    # Scale to cover for ambient blur backdrop
    scale_cover = max(1280 / w, 720 / h)
    bg_blur = im_src.resize((int(w * scale_cover), int(h * scale_cover)), Image.Resampling.LANCZOS)
    bg_blur = bg_blur.filter(ImageFilter.GaussianBlur(radius=25))
    # Crop center to 1280x720
    bw, bh = bg_blur.size
    bg_blur = bg_blur.crop(((bw - 1280) // 2, (bh - 720) // 2, (bw - 1280) // 2 + 1280, (bh - 720) // 2 + 720))
    canvas.paste(bg_blur, (0, 0))

    # Scale to fit cleanly in center or stretch if landscape
    aspect = w / h
    if aspect > 1.2: # wide enough, fit width and height smoothly
        fg = im_src.resize((1280, 720), Image.Resampling.LANCZOS)
        return fg
    else:
        # Portrait: keep clear aspect ratio in center
        scale_fit = 720 / h
        fg = im_src.resize((int(w * scale_fit), 720), Image.Resampling.LANCZOS)
        offset_x = (1280 - fg.size[0]) // 2
        canvas.paste(fg, (offset_x, 0))
        return canvas

# 2. Process Level 1 Garden Background
garden_im = Image.open(UPLOADED_PATHS["garden"]).convert("RGBA")
# Crop bottom 75px to remove "Search image" pill cleanly
gw, gh = garden_im.size
garden_clean = garden_im.crop((0, 0, gw, gh - 75))
garden_bg = garden_clean.resize((1280, 720), Image.Resampling.LANCZOS)
garden_bg_path = os.path.join(BG_DIR, "level1_garden_bg.png")
garden_bg.save(garden_bg_path, "PNG")
print(f"Created Level 1 Garden BG: {garden_bg_path} (1280x720)")

# 3. Process Level 3 Snowy Lantern-Path Background
snow_im = Image.open(UPLOADED_PATHS["snowy_path"]).convert("RGBA")
snowy_bg = fit_to_1280x720(snow_im, crop_bottom_px=75)
snowy_bg_path = os.path.join(BG_DIR, "level3_snowy_path_bg.png")
snowy_bg.save(snowy_bg_path, "PNG")
print(f"Created Level 3 Snowy Path BG: {snowy_bg_path} (1280x720)")

# 4. Process Level 3 Cute Penguin Sprite
penguin_im = Image.open(UPLOADED_PATHS["penguin"]).convert("RGBA")
# Crop search button
pw, ph = penguin_im.size
penguin_crop = penguin_im.crop((0, 0, pw, ph - 65))
# Create clean transparent sprite of penguin with soft cutout
np_arr = np.array(penguin_crop)
# The penguin is central: hat at top, white belly, orange feet.
# Mask out background snow using color distance from white/blue sky corners
# Or circular/soft vignette bounding box centered on penguin
cx, cy = pw // 2, int(ph * 0.52)
rx, ry = int(pw * 0.44), int(ph * 0.44)
mask = Image.new("L", penguin_crop.size, 0)
from PIL import ImageDraw
draw = ImageDraw.Draw(mask)
# Draw rounded polygon/ellipse covering penguin
draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
# Smooth mask edges
mask = mask.filter(ImageFilter.GaussianBlur(radius=8))

# Save penguin sprite
penguin_sprite = penguin_crop.copy()
penguin_sprite.putalpha(mask)
# Crop to content bounding box
bbox = mask.getbbox()
if bbox:
    penguin_sprite = penguin_sprite.crop(bbox)
penguin_sprite = penguin_sprite.resize((260, int(260 * (penguin_sprite.size[1] / penguin_sprite.size[0]))), Image.Resampling.LANCZOS)
penguin_sprite_path = os.path.join(CHAR_DIR, "penguin_hero.png")
penguin_sprite.save(penguin_sprite_path, "PNG")
print(f"Created Penguin Sprite: {penguin_sprite_path} ({penguin_sprite.size})")

# 5. Process Level 4 Shin Chan Scenic BG & Character
shinchan_im = Image.open(UPLOADED_PATHS["shinchan"]).convert("RGBA")
# Background
shinchan_bg = fit_to_1280x720(shinchan_im, crop_bottom_px=75)
shinchan_bg_path = os.path.join(BG_DIR, "level4_shinchan_bg.png")
shinchan_bg.save(shinchan_bg_path, "PNG")
print(f"Created Level 4 Shinchan Scenic BG: {shinchan_bg_path} (1280x720)")

# Shin Chan character cutout
sw, sh = shinchan_im.size
# Shin Chan is located in bottom-center: x ~ 100 to 280, y ~ 380 to 640
sc_crop = shinchan_im.crop((int(sw * 0.22), int(sh * 0.52), int(sw * 0.78), int(sh * 0.90)))
sc_mask = Image.new("L", sc_crop.size, 0)
sc_draw = ImageDraw.Draw(sc_mask)
sc_draw.ellipse((8, 8, sc_crop.size[0] - 8, sc_crop.size[1] - 8), fill=255)
sc_mask = sc_mask.filter(ImageFilter.GaussianBlur(radius=5))
shinchan_sprite = sc_crop.copy()
shinchan_sprite.putalpha(sc_mask)
shinchan_sprite = shinchan_sprite.resize((240, int(240 * (shinchan_sprite.size[1] / shinchan_sprite.size[0]))), Image.Resampling.LANCZOS)
shinchan_sprite_path = os.path.join(CHAR_DIR, "shinchan_hero.png")
shinchan_sprite.save(shinchan_sprite_path, "PNG")
print(f"Created Shin Chan Sprite: {shinchan_sprite_path} ({shinchan_sprite.size})")

# 6. Process Level 5 Carnival Studio BG
carnival_im = Image.open(UPLOADED_PATHS["carnival"]).convert("RGBA")
carnival_bg = fit_to_1280x720(carnival_im, crop_bottom_px=75)
carnival_bg_path = os.path.join(BG_DIR, "level5_carnival_bg.png")
carnival_bg.save(carnival_bg_path, "PNG")
print(f"Created Level 5 Carnival BG: {carnival_bg_path} (1280x720)")

print("\n>>> ALL ASSETS PROCESSED AND IMPORTED SUCCESSFULLY!")
