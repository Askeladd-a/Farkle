# Farkle Prototype

This repository contains a single-player Farkle prototype built with [LÖVE](https://love2d.org/). You duel Neon Bot, an AI opponent that evaluates every roll and decides whether to keep dice, roll again, or bank points. The presentation focuses on a clean board layout inspired by Balatro: the AI rolls in the upper tray, you roll in the lower tray, kept dice slide into side columns, and the score panel sits on the board hinge.

## How to run
1. Install LÖVE 11.5 (or a compatible 11.x build) from the official website.
   - **Windows** – download the `.exe` installer and follow the setup wizard. Optionally add LÖVE to your PATH so you can call `love` from the terminal.
   - **macOS** – drag `love.app` into Applications, then run `ln -s /Applications/love.app/Contents/MacOS/love /usr/local/bin/love` to expose the `love` command.
   - **Linux** – install the package provided by your distribution (`sudo pacman -S love`, `sudo apt install love`, etc.).
2. Confirm the installation by running `love --version` in a terminal. You should see the version banner.
3. Clone or download this repository.
4. Launch the prototype with `love .` executed from the project folder, or drag the folder/zip onto the LÖVE executable.

## Mouse-only controls
- **Roll Dice** – If no dice are on the tray, this throws the remaining dice for the current turn. When dice are on the tray, it keeps the selected set and rerolls the rest.
- **Bank Points** – Saves the accumulated round score (including any currently selected set) and passes the turn.
- **Guide** – Opens an overlay summarising the rules and controls.
- **Main Menu** – Returns to the start screen without closing the window.
- **Select dice** – Left-click dice in your tray to toggle their selection. Selected dice emit a subtle glow and will be locked when you roll or bank.

Everything is reachable with the mouse; keyboard shortcuts are intentionally omitted to keep the UI simple.

## Game flow at a glance
- You and Neon Bot alternate turns. The active tray is always highlighted by the message panel.
- Kept dice appear in slim columns beside each tray so you can track how many dice remain before a hot-dice reroll.
- The hinge HUD tracks your banked score, the 10,000-point goal, Neon Bot’s score, the round total, and the points currently selected on the tray.
- If a roll contains no scoring combinations the turn busts immediately and the round score is lost.

## Code structure
- `main.lua` – Handles layout, state management, AI turns, particle highlights, rendering, and all mouse-driven UI logic.
- `conf.lua` – Configures the LÖVE window.
- `lib/dice.lua` – Provides dice creation, physics-style rolling, scatter arrangement, and drawing helpers for both trays and kept columns.
- `lib/ai.lua` – Implements the Neon Bot heuristics (selection, roll/bank decisions) and exposes a simple context interface consumed by `main.lua`.
- `lib/scoring.lua` – Scores dice selections and exposes helpers to test for busts and compute round points.
- `lib/embedded_assets.lua` – Stores the gauntlet cursor and the three glow sprites as Base64 strings so no binary assets are tracked in git. They are decoded at runtime when the game loads.
- `asset/board.png`, `asset/die1.png` … `asset/die6.png`, `asset/dice_atlas.lua` – Original art supplied by the user. The current build renders dice procedurally and keeps the board texture for the wooden backdrop.

Feel free to tweak the layout constants in `main.lua` or the dice size in `lib/dice.lua` if you want a denser or wider board. Enjoy experimenting!
