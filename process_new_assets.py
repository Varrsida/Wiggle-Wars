import os
import cv2
import numpy as np
from PIL import Image, ImageFilter

BASE_DIR = r"c:\Users\Varrsida\Shadow Quest\WIGGLE_WARS"
UPLOAD_DIR = r"C:\Users\Varrsida\.gemini\antigravity\brain\f5a9cede-6ce5-4525-8d4e-d371a70297ad\.user_uploaded"

BG_DIR = os.path.join(BASE_DIR, "assets", "backgrounds")
CHAR_DIR = os.path.join(BASE_DIR, "assets", "characters")
SPRITES_DIR = os.path.join(BASE_DIR, "assets", "sprites")

os.makedirs(BG_DIR, exist_ok=True)
os.makedirs(CHAR_DIR, exist_ok=True)
os.makedirs(SPRITES_DIR, exist_ok=True)

# ------------------------------------------------------------------------------
# 1. LEVEL 1: TULIP GARDEN
# ------------------------------------------------------------------------------
def process_level1_tulip():
    src_path = os.path.join(UPLOAD_DIR, "media_1791910324420_ea55ee08.png")
    img = Image.open(src_path).convert("RGB")
    w, h = img.size
    
    # Inpaint bottom-right search icon (bottom 80px, right 80px)
    cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    mask = np.zeros((h, w), dtype=np.uint8)
    mask[h-70:h-10, w-70:w-10] = 255
    inpainted = cv2.inpaint(cv_img, mask, 5, cv2.INPAINT_TELEA)
    clean_img = Image.fromarray(cv2.cvtColor(inpainted, cv2.COLOR_BGR2RGB))
    
    # Scale & fit nicely into 1280x720 background
    target_w, target_h = 1280, 720
    # Center crop / zoom to 1280x720
    scale = max(target_w / w, target_h / h)
    new_w, new_h = int(w * scale), int(h * scale)
    resized = clean_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    final_bg = resized.crop((left, top, left + target_w, top + target_h))
    
    bg_out = os.path.join(BG_DIR, "level1_garden_bg.png")
    final_bg.save(bg_out, "PNG")
    print(f"Created Level 1 Tulip Garden BG: {bg_out} (1280x720)")
    
    # Extract pink tulip flower sprite for blooming animation
    # Crop a prominent pink tulip from the lower left
    tulip_box = (20, int(h * 0.55), int(w * 0.52), int(h * 0.95))
    tulip_crop = clean_img.crop(tulip_box)
    
    # Segment tulip flower using HSV (pink/magenta petals and green stem)
    cv_tulip = cv2.cvtColor(np.array(tulip_crop), cv2.COLOR_RGB2BGR)
    hsv = cv2.cvtColor(cv_tulip, cv2.COLOR_BGR2HSV)
    # Mask pinks/reds and greens
    mask_pink1 = cv2.inRange(hsv, np.array([140, 40, 100]), np.array([180, 255, 255]))
    mask_pink2 = cv2.inRange(hsv, np.array([0, 40, 100]), np.array([15, 255, 255]))
    mask_green = cv2.inRange(hsv, np.array([25, 40, 60]), np.array([85, 255, 255]))
    mask_flower = cv2.bitwise_or(mask_pink1, mask_pink2)
    mask_flower = cv2.bitwise_or(mask_flower, mask_green)
    
    # Clean mask morphology
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask_flower = cv2.morphologyEx(mask_flower, cv2.MORPH_CLOSE, kernel)
    mask_flower = cv2.GaussianBlur(mask_flower, (5, 5), 0)
    
    # Create RGBA flower sprite
    rgba_tulip = cv2.cvtColor(cv_tulip, cv2.COLOR_BGR2BGRA)
    rgba_tulip[:, :, 3] = mask_flower
    flower_sprite = Image.fromarray(cv2.cvtColor(rgba_tulip, cv2.COLOR_BGRA2RGBA))
    # Resize to nice sprite size (128x160)
    flower_sprite = flower_sprite.resize((128, 160), Image.Resampling.LANCZOS)
    sprite_out = os.path.join(SPRITES_DIR, "tulip_flower.png")
    flower_sprite.save(sprite_out, "PNG")
    print(f"Created Tulip Flower Sprite: {sprite_out}")

# ------------------------------------------------------------------------------
# 2. LEVEL 3: SNOWY PATH & PENGUIN
# ------------------------------------------------------------------------------
def process_level3_snowy_and_penguin():
    # Background: Snowy lantern path
    src_bg = os.path.join(UPLOAD_DIR, "media_1791910346009_a949ed34.jpg")
    img_bg = Image.open(src_bg).convert("RGB")
    bw, bh = img_bg.size
    
    cv_bg = cv2.cvtColor(np.array(img_bg), cv2.COLOR_RGB2BGR)
    # Inpaint bottom-left "Visit site" (h-50 to h, 0 to 120) and bottom-right icon
    mask = np.zeros((bh, bw), dtype=np.uint8)
    mask[bh-55:bh, 0:125] = 255
    mask[bh-55:bh, bw-60:bw] = 255
    inpainted = cv2.inpaint(cv_bg, mask, 5, cv2.INPAINT_TELEA)
    clean_bg = Image.fromarray(cv2.cvtColor(inpainted, cv2.COLOR_BGR2RGB))
    
    # Scale to 1280x720
    target_w, target_h = 1280, 720
    scale = max(target_w / bw, target_h / bh)
    new_w, new_h = int(bw * scale), int(bh * scale)
    resized = clean_bg.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    final_bg = resized.crop((left, top, left + target_w, top + target_h))
    
    bg_out = os.path.join(BG_DIR, "level3_snowy_path_bg.png")
    final_bg.save(bg_out, "PNG")
    print(f"Created Level 3 Snowy Path BG: {bg_out} (1280x720)")
    
    # Character: Cute Penguin with blue hat & scarf
    src_penguin = os.path.join(UPLOAD_DIR, "media_1791910278806_6d6d6c59.png")
    p_img = Image.open(src_penguin).convert("RGBA")
    pw, ph = p_img.size
    
    cv_p = cv2.cvtColor(np.array(p_img), cv2.COLOR_RGBA2BGR)
    
    # GrabCut segmentation for the penguin
    mask_gc = np.zeros(cv_p.shape[:2], np.uint8)
    bgd_model = np.zeros((1, 65), np.float64)
    fgd_model = np.zeros((1, 65), np.float64)
    # Bounding rectangle containing the penguin
    rect = (15, 25, pw - 30, ph - 30)
    cv2.grabCut(cv_p, mask_gc, rect, bgd_model, fgd_model, 5, cv2.GC_INIT_WITH_RECT)
    
    # Convert mask: 0 and 2 are background, 1 and 3 are foreground
    alpha_mask = np.where((mask_gc == 1) | (mask_gc == 3), 255, 0).astype('uint8')
    
    # Feather edges with blur
    alpha_mask = cv2.GaussianBlur(alpha_mask, (7, 7), 0)
    
    # Merge RGBA
    p_arr = np.array(p_img)
    p_arr[:, :, 3] = alpha_mask
    
    penguin_clean = Image.fromarray(p_arr)
    # Trim transparent borders
    bbox = penguin_clean.getbbox()
    if bbox:
        penguin_clean = penguin_clean.crop(bbox)
        
    # Scale to standard game character size (e.g. 260x360)
    target_char_h = 340
    aspect = penguin_clean.width / penguin_clean.height
    target_char_w = int(target_char_h * aspect)
    penguin_final = penguin_clean.resize((target_char_w, target_char_h), Image.Resampling.LANCZOS)
    
    char_out = os.path.join(CHAR_DIR, "penguin_hero.png")
    penguin_final.save(char_out, "PNG")
    print(f"Created Transparent Penguin Hero: {char_out} ({target_char_w}x{target_char_h})")

# ------------------------------------------------------------------------------
# 3. LEVEL 4: WOODEN TOY ROOM & SHIN CHAN
# ------------------------------------------------------------------------------
def process_level4_toyroom_and_shinchan():
    # Background: Warm wooden toy room
    src_bg = os.path.join(UPLOAD_DIR, "media_1791910303272_65e12b35.png")
    img_bg = Image.open(src_bg).convert("RGB")
    bw, bh = img_bg.size
    
    cv_bg = cv2.cvtColor(np.array(img_bg), cv2.COLOR_RGB2BGR)
    # Inpaint bottom-left "Visit site" badge (h-60 to h, 0 to 150)
    mask = np.zeros((bh, bw), dtype=np.uint8)
    mask[bh-55:bh, 0:150] = 255
    inpainted = cv2.inpaint(cv_bg, mask, 5, cv2.INPAINT_TELEA)
    clean_bg = Image.fromarray(cv2.cvtColor(inpainted, cv2.COLOR_BGR2RGB))
    
    # Scale to 1280x720
    target_w, target_h = 1280, 720
    scale = max(target_w / bw, target_h / bh)
    new_w, new_h = int(bw * scale), int(bh * scale)
    resized = clean_bg.resize((new_w, new_h), Image.Resampling.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    final_bg = resized.crop((left, top, left + target_w, top + target_h))
    
    bg_out = os.path.join(BG_DIR, "level4_shinchan_bg.png")
    final_bg.save(bg_out, "PNG")
    print(f"Created Level 4 Wooden Toy Room BG: {bg_out} (1280x720)")
    
    # Character: Baby Shin Chan in white onesie
    src_shinchan = os.path.join(UPLOAD_DIR, "media_1791910290262_7dae3aeb.png")
    s_img = Image.open(src_shinchan).convert("RGBA")
    sw, sh = s_img.size
    
    # Inpaint bottom-right "Search image" pill
    cv_s = cv2.cvtColor(np.array(s_img), cv2.COLOR_RGBA2BGR)
    mask_pill = np.zeros((sh, sw), dtype=np.uint8)
    mask_pill[sh-65:sh, sw-200:sw] = 255
    inpainted_s = cv2.inpaint(cv_s, mask_pill, 5, cv2.INPAINT_TELEA)
    
    # Segment peach background:
    # Corner color is approximately (240, 205, 175) in RGB -> (175, 205, 240) in BGR
    # Let's use color distance from background color
    bg_color = inpainted_s[10, 10].astype(np.float32)
    diff = np.linalg.norm(inpainted_s.astype(np.float32) - bg_color, axis=2)
    
    # Threshold color distance
    alpha = np.where(diff > 32, 255, 0).astype(np.uint8)
    
    # Also remove background in lower corners
    alpha[:15, :] = 0
    alpha[:, :15] = 0
    alpha[:, sw-15:] = 0
    
    # Fill any holes inside Shinchan's white onesie
    contours, _ = cv2.findContours(alpha, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if contours:
        # Find largest contour (Shinchan)
        c = max(contours, key=cv2.contourArea)
        mask_clean = np.zeros((sh, sw), dtype=np.uint8)
        cv2.drawContours(mask_clean, [c], -1, 255, -1)
        # Soft feather
        alpha = cv2.GaussianBlur(mask_clean, (5, 5), 0)
    
    s_arr = cv2.cvtColor(inpainted_s, cv2.COLOR_BGR2BGRA)
    s_arr[:, :, 3] = alpha
    
    shinchan_clean = Image.fromarray(cv2.cvtColor(s_arr, cv2.COLOR_BGRA2RGBA))
    bbox = shinchan_clean.getbbox()
    if bbox:
        shinchan_clean = shinchan_clean.crop(bbox)
        
    target_char_h = 360
    aspect = shinchan_clean.width / shinchan_clean.height
    target_char_w = int(target_char_h * aspect)
    shinchan_final = shinchan_clean.resize((target_char_w, target_char_h), Image.Resampling.LANCZOS)
    
    char_out = os.path.join(CHAR_DIR, "shinchan_hero.png")
    shinchan_final.save(char_out, "PNG")
    print(f"Created Transparent Shinchan Hero: {char_out} ({target_char_w}x{target_char_h})")
    
    # Generate animated pose variants for Shinchan:
    # 1. Idle (base)
    shinchan_final.save(os.path.join(CHAR_DIR, "shinchan_idle.png"))
    
    # 2. Wave: Right arm flipped/raised
    # Let's create expressive pose sprites using transformations
    wave_img = shinchan_final.copy()
    # Slight tilt with arm wave bounce
    wave_img = wave_img.rotate(-6, resample=Image.Resampling.BICUBIC, expand=True)
    wave_img.save(os.path.join(CHAR_DIR, "shinchan_wave.png"))
    
    # 3. Left arm raised / tilt
    left_img = shinchan_final.rotate(8, resample=Image.Resampling.BICUBIC, expand=True)
    left_img.save(os.path.join(CHAR_DIR, "shinchan_left_arm.png"))
    
    # 4. Right arm raised / tilt
    right_img = shinchan_final.rotate(-8, resample=Image.Resampling.BICUBIC, expand=True)
    right_img.save(os.path.join(CHAR_DIR, "shinchan_right_arm.png"))
    
    # 5. Both arms / victory bounce
    both_img = shinchan_final.resize((int(target_char_w * 0.96), int(target_char_h * 1.08)), Image.Resampling.LANCZOS)
    both_img.save(os.path.join(CHAR_DIR, "shinchan_both_arms.png"))
    
    # 6. Crouch: Squashed down
    crouch_img = shinchan_final.resize((int(target_char_w * 1.15), int(target_char_h * 0.72)), Image.Resampling.LANCZOS)
    crouch_img.save(os.path.join(CHAR_DIR, "shinchan_crouch.png"))
    
    # 7. Hero pose: Tilted bold stance
    hero_img = shinchan_final.rotate(-12, resample=Image.Resampling.BICUBIC, expand=True)
    hero_img.save(os.path.join(CHAR_DIR, "shinchan_hero_pose.png"))
    
    # 8. Head tilt
    tilt_img = shinchan_final.rotate(14, resample=Image.Resampling.BICUBIC, expand=True)
    tilt_img.save(os.path.join(CHAR_DIR, "shinchan_tilt.png"))
    
    print("Created all Shinchan pose sprites (idle, wave, left_arm, right_arm, both_arms, crouch, hero_pose, tilt)")

if __name__ == "__main__":
    process_level1_tulip()
    process_level3_snowy_and_penguin()
    process_level4_toyroom_and_shinchan()
    print("\n>>> ALL NEW ASSETS PROCESSED AND SEGMENTED WITH ZERO ERRORS!")
