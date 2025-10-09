# Shaders

Qui puoi inserire gli shader Love2D.

## Struttura consigliata
- `shaders/common/` per include riutilizzabili (es: funzioni noise, util.glsl)
- `shaders/effects/` per effetti (glow, vignette, blur, highlight dadi)
- `shaders/materials/` per shading legno, metallo, feltro ecc.
- `shaders/post/` per effetti full-screen (bloom, tonemapping, CRT, vignette)

## Nomenclatura
Usa suffissi:
- `*_fs.glsl` fragment shader
- `*_vs.glsl` vertex shader (raramente in Love2D)
- oppure semplice `.glsl` se unico

Esempio caricamento in Lua:
```lua
local glowCode = love.filesystem.read('shaders/effects/dice_glow_fs.glsl')
local diceGlowShader = love.graphics.newShader(glowCode)
```

Ricorda: Love2D usa GLSL ES 1.00 style (vecchie versioni) o compat equivalenti; evita costrutti moderni troppo avanzati.

## Uniform comuni suggerite
- `time` (float) -> love.timer.getTime()
- `resolution` (vec2) -> width, height finestra
- `intensity`, `alpha` per controllare effetti

## Prossimi passi
Creare almeno un effetto base: es. leggero outline/glow per dadi bloccati.
