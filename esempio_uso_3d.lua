-- esempio_uso_3d.lua
-- Esempio di come usare il sistema 3D per Farkle

local Projection3D = require("src.graphics.projection3d")
local Board3D = require("src.graphics.board3d_realistic")
local Dice = require("src.graphics.dice_mesh")
local Effects3D = require("src.graphics.effects3d")

function love.load()
    love.window.setTitle("Esempio Sistema 3D Farkle")
    
    print("=== ESEMPIO SISTEMA 3D FARKLE ===")
    
    -- 1. INIZIALIZZAZIONE SISTEMA 3D
    print("1. Inizializzazione sistema 3D...")
    Projection3D.setCamera("isometric")
    print("   ✓ Proiezione isometrica attivata")
    
    -- 2. CREAZIONE BOARD 3D
    print("2. Creazione board 3D...")
    local board = Board3D.new({
        x = 0, y = 0, z = 0,
        openAmount = 1.0,
        projectionMode = "isometric"
    })
    print("   ✓ Board 3D creata")
    
    -- 3. SETUP SISTEMA DADI
    print("3. Setup sistema dadi...")
    Dice.load()
    Dice.setBoard(board)
    print("   ✓ Sistema dadi configurato")
    
    -- 4. SPAWN DADI
    print("4. Spawn dadi...")
    Dice.spawn(3, nil, 3, 1, "top")    -- 3 dadi vasca superiore
    Dice.spawn(3, nil, 3, 1, "bottom") -- 3 dadi vasca inferiore
    print("   ✓ " .. #Dice.list .. " dadi spawnati")
    
    -- 5. CONFIGURAZIONE EFFETTI
    print("5. Configurazione effetti...")
    Effects3D.setProjectionMode("isometric")
    print("   ✓ Effetti visivi configurati")
    
    print("\n=== SISTEMA 3D PRONTO! ===")
    print("Controlli:")
    print("- SPACE: Rilancia dadi")
    print("- TAB: Cambia proiezione")
    print("- UP/DOWN: Apri/chiudi board")
    print("- R: Reset")
    print("- ESC: Esci")
    
    -- Salva riferimenti globali
    _G.board = board
    _G.currentMode = "isometric"
    _G.modes = {"isometric", "perspective", "orthographic"}
    _G.modeIndex = 1
end

function love.update(dt)
    -- Aggiorna tutti i sistemi 3D
    if _G.board then
        _G.board:update(dt)
    end
    Dice.update(dt)
    Effects3D.update(dt)
end

function love.draw()
    -- Sfondo
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    -- Renderizza scena 3D
    if _G.board then
        _G.board:draw()
    end
    Dice.draw()
    
    -- UI
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Modalità: " .. (_G.currentMode or "isometric"), 10, 10)
    love.graphics.print("Dadi: " .. #Dice.list, 10, 30)
    
    -- Statistiche dadi
    local resting = 0
    for _, die in ipairs(Dice.list) do
        if die.resting then resting = resting + 1 end
    end
    love.graphics.print("Dadi fermi: " .. resting .. "/" .. #Dice.list, 10, 50)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        
    elseif key == "space" then
        -- Rilancia dadi
        Dice.reroll()
        print("→ Dadi rilanciati!")
        
    elseif key == "tab" then
        -- Cambia proiezione
        _G.modeIndex = (_G.modeIndex % #_G.modes) + 1
        _G.currentMode = _G.modes[_G.modeIndex]
        
        Projection3D.setCamera(_G.currentMode)
        Dice.setMode(_G.currentMode)
        if _G.board then
            _G.board:setProjectionMode(_G.currentMode)
        end
        Effects3D.setProjectionMode(_G.currentMode)
        
        print("→ Modalità: " .. _G.currentMode)
        
    elseif key == "r" then
        -- Reset
        if _G.board then
            _G.board:setPosition(0, 0, 0)
            _G.board:setOpen(1)
        end
        print("→ Board resettata")
        
    elseif key == "1" then
        -- Aggiungi dadi vasca superiore
        Dice.spawn(2, nil, 2, 1, "top")
        print("→ Dadi aggiunti vasca superiore")
        
    elseif key == "2" then
        -- Aggiungi dadi vasca inferiore
        Dice.spawn(2, nil, 2, 1, "bottom")
        print("→ Dadi aggiunti vasca inferiore")
        
    elseif key == "c" then
        -- Pulisci dadi
        Dice.list = {}
        print("→ Tutti i dadi rimossi")
    end
end

function love.resize(w, h)
    Projection3D.resize(w, h)
end