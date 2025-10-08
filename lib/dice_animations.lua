-- Dice Animations Module
-- Gestisce le animazioni dei dadi usando Anim8

local anim8 = require("lib.anim8")

local DiceAnimations = {}

-- Variabili globali per le animazioni
local diceImage = nil
local diceGrid = nil
local animations = {}

-- Inizializza le animazioni dei dadi
function DiceAnimations.init()
    -- Carica l'immagine del dado (assumendo che sia in images/dice_spritesheet.png)
    -- Se non esiste, usa un'immagine di fallback generata
    local success, image = pcall(love.graphics.newImage, "images/dice_spritesheet.png")
    
    if success and image then
        diceImage = image
        print("✅ Caricato spritesheet dei dadi da file - Dimensioni: " .. image:getWidth() .. "x" .. image:getHeight())
    else
        -- Crea un'immagine di fallback se lo spritesheet non esiste
        diceImage = DiceAnimations.createFallbackImage()
        print("⚠️ Creato spritesheet di fallback per i dadi - Dimensioni: " .. diceImage:getWidth() .. "x" .. diceImage:getHeight())
        print("   Assicurati che 'images/dice_spritesheet.png' esista!")
    end
    
    -- Crea la griglia per lo spritesheet
    -- Supporta sia layout 1x6 che 2x3
    local frameWidth = 64
    local frameHeight = 64
    
    if not diceImage then
        print("Errore: Immagine del dado non caricata")
        return false
    end
    
    diceGrid = anim8.newGrid(frameWidth, frameHeight, diceImage:getWidth(), diceImage:getHeight())
    -- Debug: mostra le dimensioni della griglia calcolata
    print(string.format("[DiceAnimations] Grid created: frame %dx%d, image %dx%d -> grid %dx%d",
        frameWidth, frameHeight, diceImage:getWidth(), diceImage:getHeight(), diceGrid.width, diceGrid.height))
    
    -- Determina il layout dello spritesheet in modo generico (colonne x righe)
    local imageWidth = diceImage:getWidth()
    local imageHeight = diceImage:getHeight()
    local cols = diceGrid.width or math.floor(imageWidth / frameWidth)
    local rows = diceGrid.height or math.floor(imageHeight / frameHeight)

    print(string.format("[DiceAnimations] Image size %dx%d -> cols=%d rows=%d (frame %dx%d)", imageWidth, imageHeight, cols, rows, frameWidth, frameHeight))

    -- Crea le animazioni usando i primi 6 frame in ordine di lettura (left->right, top->bottom)
    local success, result = pcall(function()
        if cols * rows < 6 then
            error(string.format("Spritesheet troppo piccolo: serve almeno 6 frame (cols=%d rows=%d)", cols, rows))
        end

        -- Preleva i primi 6 quad dalla griglia
        local frames = {}
        for i = 1, 6 do
            local x = ((i - 1) % cols) + 1
            local y = math.floor((i - 1) / cols) + 1
            local quadTable = diceGrid(x, y) -- ritorna una tabella con 1 elemento
            frames[#frames + 1] = quadTable[1]
        end

        -- Crea una animazione rolling usando i primi 6 frame
        local rollingAnim = anim8.newAnimation(frames, 0.1)

        -- Crea animazioni faccia singola (frame statico) mappando face1..face6 ai frame 1..6
        return {
            rolling = rollingAnim,
            face1 = anim8.newAnimation({frames[1]}, 1),
            face2 = anim8.newAnimation({frames[2]}, 1),
            face3 = anim8.newAnimation({frames[3]}, 1),
            face4 = anim8.newAnimation({frames[4]}, 1),
            face5 = anim8.newAnimation({frames[5]}, 1),
            face6 = anim8.newAnimation({frames[6]}, 1),
        }
    end)
    
    if success then
        animations = result or {}
        -- Se per qualche motivo non esiste l'animazione di rolling, creala come fallback
        if not animations.rolling then
            local ok, anim = pcall(function()
                -- Prova prioritariamente una riga orizzontale, poi la griglia 2x3
                if diceGrid.width >= 6 then
                    return anim8.newAnimation(diceGrid('1-6', 1), 0.1)
                else
                    return anim8.newAnimation(diceGrid('1-2', '1-3'), 0.1)
                end
            end)
            if ok and anim then
                animations.rolling = anim
                print("[DiceAnimations] Rolling animation fallback creata")
            else
                print("[DiceAnimations] Impossibile creare rolling animation di fallback: " .. tostring(anim))
            end
        end

        print("Animazioni create con successo - Layout: " .. (isHorizontalLayout and "Orizzontale 1x6" or "Griglia 2x3"))
        local animNames = {}
        for name, _ in pairs(animations) do
            table.insert(animNames, name)
        end
        print("Animazioni disponibili: " .. table.concat(animNames, ", "))
    else
        print("Errore nella creazione delle animazioni: " .. tostring(result))
        animations = {}
    end
end

-- Crea un'immagine di fallback se lo spritesheet non esiste
function DiceAnimations.createFallbackImage()
    local frameWidth = 64
    local frameHeight = 64
    local frames = 6
    local totalWidth = frameWidth * frames
    local totalHeight = frameHeight
    
    -- Crea un ImageData per lo spritesheet
    local imageData = love.image.newImageData(totalWidth, totalHeight)
    
    -- Colori per ogni faccia
    local faceColors = {
        {0.9, 0.9, 0.9},  -- Bianco
        {0.8, 0.8, 0.8},  -- Grigio chiaro
        {0.7, 0.7, 0.7},  -- Grigio
        {0.6, 0.6, 0.6},  -- Grigio scuro
        {0.5, 0.5, 0.5},  -- Grigio più scuro
        {0.4, 0.4, 0.4},  -- Grigio molto scuro
    }
    
    -- Disegna ogni frame
    for frame = 1, frames do
        local startX = (frame - 1) * frameWidth
        local color = faceColors[frame]
        
        -- Riempie il frame con il colore di base
        for y = 0, frameHeight - 1 do
            for x = 0, frameWidth - 1 do
                imageData:setPixel(startX + x, y, color[1], color[2], color[3], 1)
            end
        end
        
        -- Disegna i pip per ogni faccia
        DiceAnimations.drawPipsOnFrame(imageData, startX, frameWidth, frameHeight, frame)
    end
    
    return love.graphics.newImage(imageData)
end

-- Disegna i pip su un frame specifico
function DiceAnimations.drawPipsOnFrame(imageData, startX, frameWidth, frameHeight, faceValue)
    local pipColor = {0.2, 0.2, 0.2}  -- Nero per i pip
    local pipSize = 6
    local centerX = frameWidth / 2
    local centerY = frameHeight / 2
    local offset = 15
    
    -- Configurazione pip per ogni faccia
    local pipPositions = {
        [1] = {{centerX, centerY}},
        [2] = {{centerX - offset, centerY - offset}, {centerX + offset, centerY + offset}},
        [3] = {{centerX - offset, centerY - offset}, {centerX, centerY}, {centerX + offset, centerY + offset}},
        [4] = {{centerX - offset, centerY - offset}, {centerX + offset, centerY - offset}, 
               {centerX - offset, centerY + offset}, {centerX + offset, centerY + offset}},
        [5] = {{centerX - offset, centerY - offset}, {centerX + offset, centerY - offset}, 
               {centerX, centerY}, {centerX - offset, centerY + offset}, {centerX + offset, centerY + offset}},
        [6] = {{centerX - offset, centerY - offset}, {centerX + offset, centerY - offset},
               {centerX - offset, centerY}, {centerX + offset, centerY},
               {centerX - offset, centerY + offset}, {centerX + offset, centerY + offset}},
    }
    
    local positions = pipPositions[faceValue] or {}
    for _, pos in ipairs(positions) do
        local x, y = pos[1], pos[2]
        -- Disegna un cerchio per il pip
        for dy = -pipSize, pipSize do
            for dx = -pipSize, pipSize do
                if dx * dx + dy * dy <= pipSize * pipSize then
                    local pixelX = startX + x + dx
                    local pixelY = y + dy
                    if pixelX >= 0 and pixelX < imageData:getWidth() and 
                       pixelY >= 0 and pixelY < imageData:getHeight() then
                        imageData:setPixel(pixelX, pixelY, pipColor[1], pipColor[2], pipColor[3], 1)
                    end
                end
            end
        end
    end
end

-- Ottieni l'animazione per un valore di dado specifico
function DiceAnimations.getFaceAnimation(value)
    if not animations then
        return nil
    end
    
    if value >= 1 and value <= 6 then
        return animations["face" .. value]
    end
    return nil
end

-- Ottieni l'animazione di lancio
function DiceAnimations.getRollingAnimation()
    return animations.rolling
end

-- Ottieni l'immagine del dado
function DiceAnimations.getImage()
    return diceImage
end

-- Aggiorna tutte le animazioni
function DiceAnimations.update(dt)
    if not animations then return end
    
    for _, anim in pairs(animations) do
        if anim and anim.update then
            pcall(function() anim:update(dt) end)
        end
    end
end

-- Disegna un dado con animazione
function DiceAnimations.drawDie(die, x, y, scale, rotation)
    if not diceImage or not animations then
        return false
    end
    
    scale = scale or 1
    rotation = rotation or 0
    
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(rotation)
    love.graphics.scale(scale, scale)
    
    -- Assicurati che il colore sia opaco
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Scegli l'animazione appropriata
    local animation
    if die.isRolling then
        animation = animations.rolling
    else
        animation = DiceAnimations.getFaceAnimation(die.value)
    end
    
    -- Prova prima le animazioni, poi fallback se necessario
    if animation and animation.draw then
        local success = pcall(function() 
            animation:draw(diceImage, -32, -32)  -- Centra l'animazione
        end)
        if success then
            print("Animazione disegnata con successo per dado valore " .. (die.value or "nil"))
        else
            print("Errore nel disegno dell'animazione per dado valore " .. (die.value or "nil"))
            -- Fallback: disegna un dado bianco solido
            love.graphics.setColor(1, 1, 1, 1)  -- Bianco puro
            love.graphics.rectangle("fill", -32, -32, 64, 64, 8, 8)
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", -32, -32, 64, 64, 8, 8)
            DiceAnimations.drawSimplePips(die.value or 1)
        end
    else
        print("Nessuna animazione disponibile per dado valore " .. (die.value or "nil") .. " - isRolling: " .. tostring(die.isRolling))
        -- Fallback: disegna un dado bianco solido
        love.graphics.setColor(1, 1, 1, 1)  -- Bianco puro
        love.graphics.rectangle("fill", -32, -32, 64, 64, 8, 8)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", -32, -32, 64, 64, 8, 8)
        DiceAnimations.drawSimplePips(die.value or 1)
    end
    
    love.graphics.pop()
    return true
end

-- Disegna pip semplici per il fallback
function DiceAnimations.drawSimplePips(value)
    love.graphics.setColor(0, 0, 0, 1)  -- Nero puro per massima visibilità
    local pipSize = 6  -- Pip più grandi
    local centerX, centerY = 0, 0
    local offset = 14  -- Offset maggiore per pip più visibili
    
    -- Configurazione pip per ogni faccia
    local pipPositions = {
        [1] = {{centerX, centerY}},
        [2] = {{-offset, -offset}, {offset, offset}},
        [3] = {{-offset, -offset}, {centerX, centerY}, {offset, offset}},
        [4] = {{-offset, -offset}, {offset, -offset}, {-offset, offset}, {offset, offset}},
        [5] = {{-offset, -offset}, {offset, -offset}, {centerX, centerY}, {-offset, offset}, {offset, offset}},
        [6] = {{-offset, -offset}, {offset, -offset}, {-offset, centerY}, {offset, centerY}, {-offset, offset}, {offset, offset}},
    }
    
    local positions = pipPositions[value] or pipPositions[1]
    for _, pos in ipairs(positions) do
        love.graphics.circle("fill", pos[1], pos[2], pipSize)
    end
end

-- Controlla se le animazioni sono inizializzate
function DiceAnimations.isInitialized()
    return diceImage ~= nil and animations ~= nil
end

return DiceAnimations
