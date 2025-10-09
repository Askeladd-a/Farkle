- `lib/dice_animations.lua`: spritesheet/atlas loader, multi‑speed rolling
# Dice & Debts

Single‑player dice game built with [LÖVE](https://love2d.org/). You duel an AI across a wooden board: roll, lock scoring dice, risk another throw, or bank before you bust. Presentation takes cues from card‑roguelikes: clear trays, hinge HUD, and responsive SFX.

## How to run
1. Install LÖVE 11.5 (or a compatible 11.x build) from the official website.
   - **Windows** – download the `.exe` installer and follow the setup wizard. Optionally add LÖVE to your PATH so you can call `love` from the terminal.
   - **macOS** – drag `love.app` into Applications, then run `ln -s /Applications/love.app/Contents/MacOS/love /usr/local/bin/love` to expose the `love` command.
   - **Linux** – install the package provided by your distribution (`sudo pacman -S love`, `sudo apt install love`, etc.).
2. Confirm the installation by running `love --version` in a terminal. You should see the version banner.
3. Clone or download this repository.
4. Launch the prototype with `love .` executed from the project folder, or drag the folder/zip onto the LÖVE executable.

## Controls
- Roll Dice: throws remaining dice (or keeps selection and rerolls others)
- Bank Points: banks round points and passes the turn
- Guide: toggle rules overlay
- Options: opens an anchored dropdown (Main Menu, Exit Game, Toggle Guide, Restart)
- Select dice: left‑click a die in your tray to lock/unlock it

## Game flow at a glance
- Player vs AI turn‑based. Active guidance appears in the message panel.
- Dice physics are arcade‑style: energetic launch upward, elastic wall bounces, multi‑pass collision resolution.
- Kept dice are displayed along the board hinge axis (top for AI, bottom for player).
- If a roll has no scoring dice, the turn busts and round points are lost.

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
