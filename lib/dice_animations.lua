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
    
    if success then
        diceImage = image
        print("Caricato spritesheet dei dadi da file")
    else
        -- Crea un'immagine di fallback se lo spritesheet non esiste
        diceImage = DiceAnimations.createFallbackImage()
        print("Creato spritesheet di fallback per i dadi")
    end
    
    -- Crea la griglia per lo spritesheet
    -- Supporta sia layout 1x6 che 2x3
    local frameWidth = 64
    local frameHeight = 64
    diceGrid = anim8.newGrid(frameWidth, frameHeight, diceImage:getWidth(), diceImage:getHeight())
    
    -- Determina il layout dello spritesheet
    local imageWidth = diceImage:getWidth()
    local imageHeight = diceImage:getHeight()
    local isHorizontalLayout = imageWidth > imageHeight * 2  -- Se è molto più largo che alto
    
    if isHorizontalLayout then
        -- Layout orizzontale 1x6 (384x64)
        animations = {
            rolling = anim8.newAnimation(diceGrid('1-6', 1), 0.1, 'loop'),
            face1 = anim8.newAnimation(diceGrid(1, 1), 1),
            face2 = anim8.newAnimation(diceGrid(2, 1), 1),
            face3 = anim8.newAnimation(diceGrid(3, 1), 1),
            face4 = anim8.newAnimation(diceGrid(4, 1), 1),
            face5 = anim8.newAnimation(diceGrid(5, 1), 1),
            face6 = anim8.newAnimation(diceGrid(6, 1), 1),
        }
    else
        -- Layout griglia 2x3 (192x128)
        -- Mappa le posizioni della griglia ai valori dei dadi
        -- Il tuo spritesheet: (1,1)=6, (2,1)=3, (1,2)=5, (2,2)=1, (1,3)=2, (2,3)=4
        animations = {
            -- Animazione di lancio usando tutte le posizioni disponibili
            rolling = anim8.newAnimation(diceGrid('1-2', '1-3'), 0.1, 'loop'),
            
            -- Mappa i valori dei dadi alle posizioni nella griglia
            face1 = anim8.newAnimation(diceGrid(2, 2), 1),  -- Posizione (2,2) = 1 pip
            face2 = anim8.newAnimation(diceGrid(1, 3), 1),  -- Posizione (1,3) = 2 pip
            face3 = anim8.newAnimation(diceGrid(2, 1), 1),  -- Posizione (2,1) = 3 pip
            face4 = anim8.newAnimation(diceGrid(2, 3), 1),  -- Posizione (2,3) = 4 pip
            face5 = anim8.newAnimation(diceGrid(1, 2), 1),  -- Posizione (1,2) = 5 pip
            face6 = anim8.newAnimation(diceGrid(1, 1), 1),  -- Posizione (1,1) = 6 pip
        }
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
        anim:update(dt)
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
    
    -- Scegli l'animazione appropriata
    local animation
    if die.isRolling then
        animation = animations.rolling
    else
        animation = DiceAnimations.getFaceAnimation(die.value)
    end
    
    if animation then
        animation:draw(diceImage, -32, -32)  -- Centra l'animazione
    end
    
    love.graphics.pop()
    return true
end

-- Controlla se le animazioni sono inizializzate
function DiceAnimations.isInitialized()
    return diceImage ~= nil and animations ~= nil
end

return DiceAnimations
