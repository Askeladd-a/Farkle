# Farkle 3D - Sistema di Proiezione Matematica per LOVE2D

## 🎯 Descrizione

Un sistema 3D avanzato per LOVE2D che simula la profondità usando proiezioni matematiche, ispirato a Euclid's Inferno. Implementa dadi 3D realistici, board animata e effetti visivi professionali.

## ✨ Caratteristiche

- **🎲 Dadi 3D Realistici**: Fisica avanzata con gravità, collisioni e rotazioni
- **🏗️ Board 3D Animata**: Tavolo da gioco con vasche per dadi e animazioni fluide
- **📐 Proiezioni Multiple**: Isometrica, prospettica e ortografica
- **✨ Effetti Visivi**: Ombre dinamiche, particelle e illuminazione
- **🎮 Controlli Intuitivi**: Interfaccia semplice e responsive

## 🚀 Installazione

### Prerequisiti
- LOVE2D 11.5+
- Linux/Windows/macOS

### Esecuzione
```bash
# Demo completo
love demo_board3d.lua

# Esempio di utilizzo
love esempio_uso_3d.lua

# Test senza grafica
lua5.1 test_demo.lua
```

## 🎮 Controlli

| Tasto | Azione |
|-------|--------|
| `SPACE` | Rilancia tutti i dadi |
| `TAB` | Cambia modalità proiezione |
| `UP/DOWN` | Apri/chiudi board |
| `R` | Reset board |
| `1/2` | Aggiungi dadi nelle vasche |
| `C` | Pulisci tutti i dadi |
| `ESC` | Esci |

## 📁 Struttura del Progetto

```
src/graphics/
├── projection3d.lua      # Sistema di proiezione 3D
├── dice_mesh.lua         # Dadi 3D con fisica
├── board3d_realistic.lua # Board 3D animata
├── effects3d.lua         # Effetti visivi
└── projection.lua        # Helper matematici

demo_board3d.lua          # Demo completo
esempio_uso_3d.lua        # Esempio di utilizzo
test_demo.lua             # Test senza grafica
```

## 🔧 API Principale

### Sistema di Proiezione
```lua
-- Cambia modalità proiezione
Projection3D.setCamera("isometric")    -- Perfetta per giochi da tavolo
Projection3D.setCamera("perspective")  -- Profondità realistica
Projection3D.setCamera("orthographic") -- Vista tecnica

-- Proietta punto 3D
local x, y, z, w = Projection3D.project(1, 2, 3, "isometric")
```

### Sistema Dadi
```lua
-- Spawn dadi
Dice.spawn(3, nil, 3, 1, "top")    -- 3 dadi vasca superiore
Dice.spawn(3, nil, 3, 1, "bottom") -- 3 dadi vasca inferiore

-- Rilancia dadi
Dice.reroll()

-- Cambia modalità
Dice.setMode("perspective")
```

### Board 3D
```lua
-- Crea board
local board = Board3D.new({
    x = 0, y = 0, z = 0,
    openAmount = 1.0,
    projectionMode = "isometric"
})

-- Anima board
board:setOpen(0.5)  -- 50% aperto
board:animateTo(1.0, 2.0)  -- Apri in 2 secondi
```

### Effetti Visivi
```lua
-- Ombre
Effects3D.drawShadow(position, size, projectionMode)

-- Particelle
Effects3D.emitParticles(position, count, {
    color = {1, 0.8, 0.3, 1},
    spread = 8,
    upwardVel = 3,
    size = 1.5,
    lifetime = 1.0
})

-- Illuminazione
local litColor = Effects3D.calculateLighting(normal, baseColor)
```

## 🎨 Modalità di Proiezione

### Isometrica (Raccomandata)
- **Angoli**: 35.264° e 45°
- **Uso**: Perfetta per giochi da tavolo
- **Vantaggi**: Nessuna distorsione prospettica, facile da leggere

### Prospettica
- **FOV**: 60° (regolabile)
- **Uso**: Profondità realistica
- **Vantaggi**: Effetto 3D più drammatico

### Ortografica
- **Uso**: Viste tecniche
- **Vantaggi**: Misure precise, nessuna distorsione

## 🔬 Dettagli Tecnici

### Matematica 3D
- **Matrici 4x4**: Trasformazioni complete
- **Proiezioni**: Isometrica, prospettica, ortografica
- **Back-face Culling**: Ottimizzazione rendering
- **Depth Sorting**: Painter's algorithm

### Fisica Dadi
- **Gravità**: -22 unità/secondo²
- **Restituzione**: 0.35 (rimbalzo)
- **Attrito**: 0.98 (XY), 0.985 (rotazione)
- **Collisioni**: Con board e vasche

### Effetti Visivi
- **Ombre**: Proiezione lungo direzione luce
- **Particelle**: Sistema modulare
- **Illuminazione**: Ambient + direzionale
- **Materiali**: Legno, felt, metallo

## 🚀 Performance

### Ottimizzazioni Implementate
- ✅ Back-face culling
- ✅ Depth sorting
- ✅ Particelle con limite massimo
- ✅ Caching matrici di trasformazione

### Aree di Miglioramento
- 🔄 Frustum culling
- 🔄 Level of detail
- 🔄 Instanced rendering
- 🔄 Spatial partitioning

## 🎯 Ispirazione

Il sistema è ispirato a **Euclid's Inferno**, un gioco che dimostra come creare effetti 3D convincenti usando solo primitive 2D. Implementa:

- Proiezioni matematicamente corrette
- Illuminazione realistica
- Animazioni fluide
- Fisica convincente

## 📝 Licenza

Questo progetto è parte del gioco Farkle 3D. Vedi il file principale per i dettagli della licenza.

## 🤝 Contributi

Per contribuire al sistema 3D:

1. Fork del repository
2. Crea feature branch
3. Implementa miglioramenti
4. Testa con `lua5.1 test_demo.lua`
5. Submit pull request

## 📞 Supporto

Per problemi o domande:
- Controlla `SISTEMA_3D_ANALISI.md` per dettagli tecnici
- Usa `test_demo.lua` per debug
- Verifica log console per errori

---

**Sistema 3D Farkle** - Portando la profondità in LOVE2D! 🎲✨