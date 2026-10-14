# 🎮✨ WIGGLE WARS! — Master Build Documentation
## Complete Webcam-Controlled Party Game with Real Gestures, 5 Levels & Secret Final Surprise

Welcome to **WIGGLE WARS!**, an expressive, funny, and heartwarming webcam-controlled party game built with **Godot 4.7.2**, **Python 3.13**, **OpenCV**, and **MediaPipe**.

---

## 📁 1. Project Folder Location & Structure

- **Primary Project Path:** `c:\Users\Varrsida\Shadow Quest\WIGGLE_WARS`
- **Linked Path (Directory Junction):** `C:\Users\Varrsida\WIGGLE_WARS`
- **Original Shadow Quest Preservation:** The existing `Shadow Quest` project and all of its assets/scripts are **100% preserved and untouched**.

### Directory Structure:
```
WIGGLE_WARS/
├── project.godot                     # Godot 4.7.2 Project Configuration & Autoloads
├── launch_game.bat                   # 1-Click Game Launcher
├── launch_tracker.bat                # 1-Click Python Multi-Modal Tracker Launcher
├── README.md                         # This Master Documentation
├── tracker/
│   ├── tracker.py                    # Multi-modal CV tracker (Face, Hand, Pose, Video, Speech)
│   ├── test_tracker_integration.py   # Tracker verification suite
│   ├── face_landmarker.task          # MediaPipe Face Landmarker model (3.58 MB)
│   ├── hand_landmarker.task          # MediaPipe Hand Landmarker model (7.46 MB)
│   └── pose_landmarker_lite.task     # MediaPipe Pose Landmarker model (5.51 MB)
├── scripts/
│   ├── globals/
│   │   ├── game_manager.gd           # Progression, scoring state machine, secret ending safeguards
│   │   ├── gesture_listener.gd       # TCP 9999 JSON telemetry & TCP 9998 video client
│   │   └── audio_manager.gd          # Procedural sound synthesis & voice narration player
│   ├── ui/
│   │   ├── main_menu.gd              # Title, settings, credits, navigation
│   │   ├── webcam_setup.gd           # Live camera preview, lighting guidance & gesture test
│   │   ├── hud.gd                    # In-game HUD, scoring, subtitles, webcam PiP, pause menu
│   │   └── level_results.gd          # Level completion results & progression triggers
│   ├── levels/
│   │   ├── level1_face_frenzy.gd     # Magical Expression Garden
│   │   ├── level2_fruit_ninja.gd     # Tropical Fruit-Slicing Arena
│   │   ├── level3_waddle_wars.gd     # The Cute Penguin Adventure
│   │   ├── level4_copycat_chaos.gd   # Shinchan's Crazy Toy Workshop
│   │   ├── level5_lucky_wheel.gd     # Lucky Chaos Wheel (Exactly 7 Slices)
│   │   └── secret_ending.gd          # Surprise Wonderland & Exact Final Messages
│   └── tests/
│       └── test_runner.gd            # Comprehensive automated QA test runner
├── scenes/
│   ├── main_menu.tscn
│   ├── webcam_setup.tscn
│   ├── hud.tscn
│   ├── level_results.tscn
│   ├── level1_face_frenzy.tscn
│   ├── level2_fruit_ninja.tscn
│   ├── level3_waddle_wars.tscn
│   ├── level4_copycat_chaos.tscn
│   ├── level5_lucky_wheel.tscn
│   ├── secret_ending.tscn
│   └── test_runner.tscn
└── assets/
    └── audio/                        # Spoken voice lines for Lumi & Shinchan + generated WAVs
```

---

## 🚀 2. How to Launch & Play

### Step 1: Start the Python Webcam Tracker
Double-click `launch_tracker.bat` or run in terminal:
```powershell
python "c:\Users\Varrsida\Shadow Quest\WIGGLE_WARS\tracker\tracker.py" --preview
```
- Streams telemetry on `127.0.0.1:9999` (TCP JSON-lines)
- Streams live camera video on `127.0.0.1:9998` (TCP JPEG stream)
- Speech recognition and TTS bridge active.

### Step 2: Start the Game in Godot 4.7.2
Double-click `launch_game.bat` or run in terminal:
```powershell
& "C:\Users\Varrsida\Downloads\Godot_v4.7.2-stable_win64_console.exe" --path "c:\Users\Varrsida\Shadow Quest\WIGGLE_WARS"
```

---

## 🎮 3. Game Flow & Level Overview

### 🌸 Level 1 — Face Frenzy (Magical Expression Garden)
- **Smile (+10):** Flowers bloom, glow, and pulse with color.
- **Open Mouth (+10):** Colorful bubbles soar upward with pop sounds.
- **Raise Eyebrows (+10):** Star bursts explode across the sky with sparkles.
- **Sustained Eye Closure (+15):** Garden enters peaceful sleepy nightlights.
- **Surprised Expression (+15):** A magical gust of wind moves leaves and petals.

### 🍉 Level 2 — Fruit Ninja (Tropical Fruit-Slicing Arena)
- **Real Hand Swipe:** Detected via hand velocity and displacement over time.
- **Combos:** Slicing multiple fruits in succession triggers combo multipliers.
- **Special Events:**
  - **Watermelon Fountain (+25):** Massive watermelon explodes into vibrant juice particles.
  - **Banana Split (+20):** Flying banana triggers comedic split visual and points.
  - **Sus Strawberry (+20):** Suspicious strawberry with funny animated eyes reacts when sliced.
- **Hazards:** Bombs (-10 points, hazard buzzer), Rotten Fruit (-5 points).

### 🐧 Level 3 — Waddle Wars (The Cute Penguin Adventure)
- **Hero:** The adorable baby penguin with big expressive eyes, tiny flippers, and orange beak.
- **Pose Gestures:**
  - **Lean Left / Right (+10):** Penguin dodges horizontally.
  - **Raise Both Hands (+10):** Penguin jumps high.
  - **Lean Forward (+5 per crystal):** Penguin executes a fast belly slide across the ice.
  - **Extend Both Arms Sideways (+15):** Penguin balances with extended flippers.
  - **Squat (+10):** Tiny adorable squatting penguin pose.
  - **Reach Upward (+15):** Grabs high floating crystals.
- **Random Events:** Banana-Foot Wobble, Snowball Chase, Penguin Parade, Dizzy Penguin.

### 🎭 Level 4 — Copycat Chaos (Shinchan's Crazy Toy Workshop)
- **Hero:** Shinchan / Cheeky workshop cartoon star with red shirt, yellow shorts, thick eyebrows, and playful grin.
- **Wave Copycat (+15):** Player waves -> Shinchan waves back with comedic wobbles.
- **Dance & Body Copycat (+20):** Player dances / flaps -> Shinchan imitates and reaction meter fills.
- **Speak & Repeat (+25):** Click `Speak to Shinchan` -> speaks into microphone -> Python recognizes words via SpeechRecognition -> Shinchan repeats words aloud with TTS!
- **Funny Pose Challenge (+15):** Match poses (hands raised, airplane arms) on stage.

### 🎡 Level 5 — Lucky Chaos Wheel (The Carnival of Unexpected Prizes)
- **EXACTLY 7 Wheel Slices:**
  1. Chocolate Prize 🍫
  2. Legendary Pen ✨
  3. Sticker Jackpot 🌈
  4. Mystery Keychain 🔑
  5. Mirror Twin 🪞 (5-second reverse imitation challenge)
  6. Duck Apocalypse 🦆 (Giant duck balances on character's head + duck chase)
  7. Chicken Dance Challenge 🐔 (5-second flapping imitation challenge)
- **Wheel Behavior:** Deterministic angle mapping ensures the wheel stops smoothly on the exact slice chosen.
- **Normal Results Sequence:** Normal Level 5 results must be displayed and acknowledged by the player before the secret ending can unlock.

### 🎁🌈 Secret Final Surprise — Surprise Wonderland (The Hidden Ending)
- **Safeguard Verification:** Unlocks ONLY after all 5 levels have been genuinely completed and normal Level 5 results acknowledged!
- **Opening:** Carnival lights dim, Lumi appears:
  > *“Psst… wait! There's one more little surprise for you!”*
- **Wonderland Reveal:** Glowing rainbow doorway opens, characters gather (baby penguin, Shinchan, blooming flowers, flying fruits, confetti).
- **Lumi's Fixed Final Quote:**
  > *“Hey, superstar… the real magic was never the points, the prizes, or the victory. It was YOU — every silly move, every laugh, and every moment you didn't give up. Thank you for making this little world come alive. I'll be right here whenever you return.”*
- **Exact Final On-Screen Message:**
  Revealed typewriter-style with golden glow and rainbow sparkles:
  > **“YOU WERE NEVER JUST A PLAYER. YOU WERE PART OF OUR WORLD. 🌈”**
- **Final Reward Screen:**
  > **“WIGGLE WARS LEGEND! 🏆”**
  Displays actual total score, all 5 completed levels, and working `Play Again` and `Back to Main Menu` buttons.

---

## ⌨️ 4. Keyboard Fallback & QA Cheat Sheet
In addition to real webcam tracking, the game supports instant keyboard testing anytime:
- `1` : Smile
- `2` : Open Mouth
- `3` : Eyebrows Raised
- `4` : Sleepy (Eyes Closed)
- `5` : Surprised Expression
- `Left Arrow` : Swipe Left
- `Right Arrow` : Swipe Right
- `Up Arrow` : Swipe Up / Reach
- `W` : Wave Hand
- `A` / `D` : Lean Left / Lean Right
- `J` : Jump (Hands Raised)
- `B` : Balance (Arms Extended)
- `S` : Squat
- `F` : Belly Slide (Lean Forward)
- `C` : Chicken Dance

---

## 🧪 5. Automated QA Testing
Run the automated test runner anytime:
```powershell
& "C:\Users\Varrsida\Downloads\Godot_v4.7.2-stable_win64_console.exe" --headless --path "c:\Users\Varrsida\Shadow Quest\WIGGLE_WARS" "res://scenes/test_runner.tscn"
```
**Results:** 8/8 Tests Passed (100% clean, 0 errors).
