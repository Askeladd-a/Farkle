- `lib/dice_animations.lua`: spritesheet/atlas loader, multi‑speed rolling
# Farkle 3D

Advanced 3D Farkle game built with [LÖVE](https://love2d.org/) using mathematical projections for pseudo-3D rendering. Experience realistic wooden board physics, dynamic lighting, and smooth dice animations in a traditional 2D engine.

## 🎲 3D Features

- **Mathematical Projections**: Isometric, perspective, and orthographic camera modes
- **Realistic Physics**: 3D dice with gravity, collision detection, and momentum conservation  
- **Dynamic Lighting**: Real-time shadows and directional lighting system
- **Particle Effects**: 3D particle system for dust, sparks, and impact effects
- **Wooden Board**: Realistic folding board with hinges, trays, and decorative details
- **Multiple Render Modes**: Switch between projection types for different visual styles

## 🚀 Quick Demo

Run the 3D board demo to see all features in action:
```bash
# Windows (batch script)
run_demo.bat

# Or manually with LOVE2D
love demo_board3d.lua
```

### Demo Controls:
- **SPACE** - Reroll all dice
- **TAB** - Switch projection mode (isometric/perspective/orthographic)  
- **UP/DOWN** - Open/close the wooden board
- **1/2** - Add dice to top/bottom tray
- **C** - Clear all dice
- **R** - Reset board position
- **F** - Toggle fullscreen

## 🎮 How to run
1. Install LÖVE 11.5 (or a compatible 11.x build) from the official website.
   - **Windows** – download the `.exe` installer and follow the setup wizard. Optionally add LÖVE to your PATH so you can call `love` from the terminal.
   - **macOS** – drag `love.app` into Applications, then run `ln -s /Applications/love.app/Contents/MacOS/love /usr/local/bin/love` to expose the `love` command.
   - **Linux** – install the package provided by your distribution (`sudo pacman -S love`, `sudo apt install love`, etc.).
2. Confirm the installation by running `love --version` in a terminal. You should see the version banner.
3. Clone or download this repository.
4. Launch the main game with `love .` or the 3D demo with `love demo_board3d.lua`

## 🏗️ 3D Architecture

### Core 3D Systems:
- **`src/graphics/projection3d.lua`** - Mathematical projection library (Vec3, Matrix4, Camera3D)
- **`src/graphics/effects3d.lua`** - Advanced visual effects (shadows, particles, lighting)
- **`src/graphics/dice_mesh.lua`** - Enhanced 3D dice with realistic physics
- **`src/graphics/board3d_realistic.lua`** - Realistic wooden board with folding mechanism
- **`src/ui/dice_type_ui.lua`** - UI helpers for dice statistics and tooltips

### Integration:
The 3D system is modular and integrates seamlessly with the existing Farkle game logic while providing dramatic visual enhancements.

## 🎯 Game Controls
- **Roll Dice**: throws remaining dice (or keeps selection and rerolls others)
- **Bank Points**: banks round points and passes the turn
- **Guide**: toggle rules overlay
- **Options**: opens an anchored dropdown (Main Menu, Exit Game, Toggle Guide, Restart)
- **Select dice**: left‑click a die in your tray to lock/unlock it

## 📋 Game Flow
- Player vs AI turn‑based. Active guidance appears in the message panel.
- Enhanced 3D dice physics: realistic gravity, elastic collisions, momentum conservation
- Kept dice are displayed along the board hinge axis (top for AI, bottom for player)
- If a roll has no scoring dice, the turn busts and round points are lost
- Visual feedback through particle effects, shadows, and dynamic lighting

## Code structure
- `main.lua`: LOVE callbacks, state, rendering glue
- `src/layout.lua`: board/trays/buttons layout
- `src/render.lua`: scoreboard and log rendering
- `src/audio.lua`: SFX loading and playback (dice impacts, page flip, quit handle)
- `src/assets.lua`: font chains and menu background loader
- `src/ui/options.lua`: anchored options dropdown (geometry, hover, draw, click)
- `lib/dice.lua`: dice physics, drawing, kept rendering on hinge
- `lib/dice_animations.lua`: spritesheet/atlas loader, multi‑speed rolling
- `lib/ai.lua`: opponent logic
- `lib/scoring.lua`: scoring helpers
- `conf.lua`: window configuration

## Art, fonts, SFX
- Spritesheets: preferred path now `images/dice/dice_spritesheet.png` (+ optional `images/dice/dice_spritesheet.xml`). Backwards compatible legacy name `images/dice_spritesheet.png` still supported.
   - Border overlay (optional): `images/dice/border_dice_spritesheet.png` (+ `images/dice/dice_border.xml`), with fallback to legacy `images/border_dice_spritesheet.png` / `images/dice_border.xml`.
   - Frame size expected: 64x64.
- Board image: loader tries (in order) `images/board.png`, `images/UI/board.png`, then legacy `images/wooden_board.png` / `images/UI/wooden_board.png`; if none found, a procedural board is rendered.
- Fonts: place `.ttf/.otf` in `fonts/` (preferred) or `images/`; loader tries multiple fallbacks (Gregorian, Rothenbg, Teutonic, Cinzel, system).
- Background: `images/brown_age_by_darkwood67.*` (cover on main menu).
- Sounds: place dice variants in `sounds/dice/dice-1..29.(ogg|wav|mp3)`, UI page in `sounds/book_page.*`, quit handle in `sounds/book_handle.*`.

Tweak physics and layout constants in `lib/dice.lua` and `src/layout.lua` to fit your style. Enjoy rolling!
