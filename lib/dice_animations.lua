-- Dice Animations Module
-- Gestisce le animazioni dei dadi usando Anim8

local anim8 = require("lib.anim8")

local DiceAnimations = {}

-- Variabili globali per le animazioni
local diceImage = nil          -- faces / base layer
local diceGrid = nil
local borderImage = nil        -- optional border/outline layer
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
    
    -- Determina il layout dello spritesheet e preferisci un atlas XML se presente
    local imageWidth = diceImage:getWidth()
    local imageHeight = diceImage:getHeight()
    print(string.format("[DiceAnimations] Image size %dx%d (frame %dx%d)", imageWidth, imageHeight, frameWidth, frameHeight))

    -- Try to load an XML atlas if present (TextureAtlas / SubTexture format) for faces
    local atlasPath = "images/dice_spritesheet.xml"
    local atlasOK, atlasContents = pcall(love.filesystem.read, atlasPath)
    local success, result
    if atlasOK and atlasContents then
        -- Parse SubTexture entries
        local quadsByName = {}
        local quadsByIndex = {}
        for name, x, y, w, h in atlasContents:gmatch('<SubTexture%s+name="([^"]+)"%s+x="(%d+)"%s+y="(%d+)"%s+width="(%d+)"%s+height="(%d+)"') do
            local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
            local quad = love.graphics.newQuad(nx, ny, nw, nh, imageWidth, imageHeight)
            quadsByName[name] = quad
            -- try to extract numeric index from filename (e.g. dieWhite3 -> 3)
            local idx = tonumber(name:match("(%d+)") or "")
            if idx then
                quadsByIndex[idx] = quad
            end
        end

        success, result = pcall(function()
            -- Ensure we have at least 6 frames mapped
            for i = 1, 6 do
                if not quadsByIndex[i] then
                    error("Atlas missing frame for index " .. i)
                end
            end
            local frames = { quadsByIndex[1], quadsByIndex[2], quadsByIndex[3], quadsByIndex[4], quadsByIndex[5], quadsByIndex[6] }
            return {
                frames = frames,
                face1 = anim8.newAnimation({frames[1]}, 1),
                face2 = anim8.newAnimation({frames[2]}, 1),
                face3 = anim8.newAnimation({frames[3]}, 1),
                face4 = anim8.newAnimation({frames[4]}, 1),
                face5 = anim8.newAnimation({frames[5]}, 1),
                face6 = anim8.newAnimation({frames[6]}, 1),
            }
        end)
        if success then
            print("[DiceAnimations] Loaded frames from atlas: " .. atlasPath)
        else
            print("[DiceAnimations] Failed to create animations from atlas: " .. tostring(result))
        end
    else
        -- Fallback: generic grid pickup (first 6 frames)
        local cols = diceGrid.width or math.floor(imageWidth / frameWidth)
        local rows = diceGrid.height or math.floor(imageHeight / frameHeight)
        if cols * rows < 6 then
            success, result = false, "Spritesheet too small: need at least 6 frames"
        else
            success, result = pcall(function()
                local frames = {}
                for i = 1, 6 do
                    local x = ((i - 1) % cols) + 1
                    local y = math.floor((i - 1) / cols) + 1
                    local quadTable = diceGrid(x, y)
                    frames[#frames + 1] = quadTable[1]
                end
                return {
                    frames = frames,
                    face1 = anim8.newAnimation({frames[1]}, 1),
                    face2 = anim8.newAnimation({frames[2]}, 1),
                    face3 = anim8.newAnimation({frames[3]}, 1),
                    face4 = anim8.newAnimation({frames[4]}, 1),
                    face5 = anim8.newAnimation({frames[5]}, 1),
                    face6 = anim8.newAnimation({frames[6]}, 1),
                }
            end)
        end
    end
    
    if success then
        animations = result or {}
    else
        print("Errore nella creazione delle animazioni: " .. tostring(result))
        animations = {}
    end

    -- Build rolling animations at multiple speeds if we have frames
    if animations.frames then
        local frames = animations.frames
        animations.rolling_slow = anim8.newAnimation(frames, 0.14)
        animations.rolling_med  = anim8.newAnimation(frames, 0.09)
        animations.rolling_fast = anim8.newAnimation(frames, 0.05)
    end

    -- Try to load optional BORDER overlay sprite/atlas
    local bOK, bImg = pcall(love.graphics.newImage, "images/border_dice_spritesheet.png")
    if bOK and bImg then
        borderImage = bImg
        -- Attempt to map frames via atlas xml
        local borderAtlas = "images/dice_border.xml"
        local aOK, aContents = pcall(love.filesystem.read, borderAtlas)
        if aOK and aContents then
            local bQuads = {}
            for name, x, y, w, h in aContents:gmatch('<SubTexture%s+name="([^"]+)"%s+x="(%d+)"%s+y="(%d+)"%s+width="(%d+)"%s+height="(%d+)"') do
                local nx, ny, nw, nh = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
                local quad = love.graphics.newQuad(nx, ny, nw, nh, borderImage:getWidth(), borderImage:getHeight())
                local idx = tonumber(name:match("(%d+)") or "")
                if idx then bQuads[idx] = quad end
            end
            animations.border_faces = bQuads
            if bQuads[1] then
                animations.border_rolling_slow = anim8.newAnimation({bQuads[1], bQuads[2], bQuads[3], bQuads[4], bQuads[5], bQuads[6]}, 0.14)
                animations.border_rolling_med  = anim8.newAnimation({bQuads[1], bQuads[2], bQuads[3], bQuads[4], bQuads[5], bQuads[6]}, 0.09)
                animations.border_rolling_fast = anim8.newAnimation({bQuads[1], bQuads[2], bQuads[3], bQuads[4], bQuads[5], bQuads[6]}, 0.05)
            end
        end
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
    
    -- Scegli l'animazione appropriata in base alla velocità
    local speed = 0
    if die and die.vx and die.vy then
        speed = math.sqrt(die.vx * die.vx + die.vy * die.vy)
    end
    local rollingAnim
    if animations.rolling_fast then
        if speed > 600 then
            rollingAnim = animations.rolling_fast
        elseif speed > 280 then
            rollingAnim = animations.rolling_med
        else
            rollingAnim = animations.rolling_slow
        end
    end

    local animation = die.isRolling and rollingAnim or DiceAnimations.getFaceAnimation(die.value)

    -- Base layer (faces)
    if animation and animation.draw then
        local ok = pcall(function()
            animation:draw(diceImage, -32, -32)
        end)
        if not ok then animation = nil end
    end
    if not animation then
        -- Fallback: dado solido con pip
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", -32, -32, 64, 64, 8, 8)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", -32, -32, 64, 64, 8, 8)
        DiceAnimations.drawSimplePips(die.value or 1)
    end

    -- Overlay border layer (optional)
    if borderImage and animations.border_faces then
        local bAnim
        if die.isRolling then
            if speed > 600 then
                bAnim = animations.border_rolling_fast
            elseif speed > 280 then
                bAnim = animations.border_rolling_med
            else
                bAnim = animations.border_rolling_slow
            end
        else
            local quad = animations.border_faces[math.max(1, math.min(6, die.value or 1))]
            if quad then
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(borderImage, quad, -32, -32)
            end
        end
        if bAnim and bAnim.draw then
            love.graphics.setColor(1,1,1,1)
            bAnim:draw(borderImage, -32, -32)
        end
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
