-- demo_3d_headless.lua
-- Demo 3D per testare il sistema senza display grafico

local Projection3D = require("src.graphics.projection3d")
local Board3D = require("src.graphics.board3d_realistic")
local Dice = require("src.graphics.dice_mesh")
local Effects3D = require("src.graphics.effects3d")

function love.load()
    love.window.setTitle("Farkle 3D System Demo")
    
    print("=== FARKLE 3D SYSTEM DEMO ===")
    print("Inizializzazione sistemi 3D...")
    
    -- Inizializza sistemi 3D
    Projection3D.setCamera("isometric")
    print("✓ Sistema di proiezione 3D inizializzato")
    
    -- Crea la board realistica
    board = Board3D.new({
        x = 0, y = 0, z = 0,
        openAmount = 1.0,
        projectionMode = "isometric"
    })
    print("✓ Board 3D realistica creata")
    
    -- Setup sistema dadi
    Dice.load()
    Dice.setBoard(board)
    print("✓ Sistema dadi 3D inizializzato")
    
    -- Spawna dadi nelle due vasche
    Dice.spawn(3, nil, 3, 1, "top")    -- 3 dadi nella vasca superiore
    Dice.spawn(3, nil, 3, 1, "bottom") -- 3 dadi nella vasca inferiore
    print("✓ Dadi spawnati nelle vasche")
    
    print("\n=== CONTROLLI DISPONIBILI ===")
    print("SPACE - Rilancia i dadi")
    print("TAB   - Cambia proiezione")
    print("UP/DOWN - Apri/chiudi board")
    print("R     - Reset board")
    print("ESC   - Esci")
    
    print("\n=== STATO INIZIALE ===")
    print("Modalità: isometric")
    print("Board Apertura: 100%")
    print("Dadi Totali: " .. #Dice.list)
    
    currentMode = "isometric"
    modes = {"isometric", "perspective", "orthographic"}
    modeIndex = 1
end

function love.update(dt)
    -- Aggiorna tutti i sistemi 3D
    board:update(dt)
    Dice.update(dt)
    Effects3D.update(dt)
    
    -- Simula alcuni secondi di fisica
    if love.timer.getTime() < 5 then
        -- Controlli apertura board
        if love.keyboard.isDown("up") then
            board:setOpen(math.min(1, board.openAmount + dt * 2))
        elseif love.keyboard.isDown("down") then
            board:setOpen(math.max(0, board.openAmount - dt * 2))
        end
    end
end

function love.draw()
    -- Sfondo elegante
    love.graphics.clear(0.1, 0.1, 0.15, 1)
    
    -- Renderizza la scena 3D
    board:draw()
    Dice.draw()
    
    -- UI informazioni
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Modalità: " .. currentMode, 10, 10)
    love.graphics.print("Board Apertura: " .. math.floor(board.openAmount * 100) .. "%", 10, 30)
    love.graphics.print("Dadi Totali: " .. #Dice.list, 10, 50)
    
    -- Statistiche per vasca
    local topCount, bottomCount = 0, 0
    local topResting, bottomResting = 0, 0
    
    for _, die in ipairs(Dice.list) do
        if die.assignedTray == "top" then
            topCount = topCount + 1
            if die.resting then topResting = topResting + 1 end
        elseif die.assignedTray == "bottom" then
            bottomCount = bottomCount + 1
            if die.resting then bottomResting = bottomResting + 1 end
        end
    end
    
    love.graphics.print("Vasca Superiore: " .. topResting .. "/" .. topCount .. " fermi", 10, 90)
    love.graphics.print("Vasca Inferiore: " .. bottomResting .. "/" .. bottomCount .. " fermi", 10, 110)
    
    -- Info modalità corrente
    if currentMode == "perspective" then
        love.graphics.print("» Modalità Prospettica - Profondità realistica", 10, 150)
    elseif currentMode == "isometric" then
        love.graphics.print("» Modalità Isometrica - Perfetta per giochi da tavolo", 10, 150)
    else
        love.graphics.print("» Modalità Ortografica - Vista tecnica", 10, 150)
    end
    
    -- Controlli
    love.graphics.print("SPACE=Rilancia | TAB=Proiezione | UP/DOWN=Board | R=Reset", 10, love.graphics.getHeight() - 40)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        
    elseif key == "space" then
        -- Rilancia tutti i dadi
        Dice.reroll()
        print("→ Dadi rilanciati!")
        
    elseif key == "tab" then
        -- Cambia modalità proiezione
        modeIndex = (modeIndex % #modes) + 1
        currentMode = modes[modeIndex]
        
        Projection3D.setCamera(currentMode)
        Dice.setMode(currentMode)
        board:setProjectionMode(currentMode)
        Effects3D.setProjectionMode(currentMode)
        
        print("→ Modalità cambiata a: " .. currentMode)
        
    elseif key == "r" then
        -- Reset board
        board:setPosition(0, 0, 0)
        board:setOpen(1)
        print("→ Board resettata")
        
    elseif key == "1" then
        -- Aggiungi dadi vasca superiore
        Dice.spawn(2, nil, 2, 1, "top")
        print("→ Aggiunti dadi nella vasca superiore")
        
    elseif key == "2" then
        -- Aggiungi dadi vasca inferiore
        Dice.spawn(2, nil, 2, 1, "bottom")
        print("→ Aggiunti dadi nella vasca inferiore")
        
    elseif key == "c" then
        -- Pulisci tutti i dadi
        Dice.list = {}
        print("→ Tutti i dadi rimossi")
    end
end

function love.resize(w, h)
    Projection3D.resize(w, h)
end