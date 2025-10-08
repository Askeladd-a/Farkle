local anim8 = require("lib.anim8")

local diceAtlasConfig
do
    local ok, atlas = pcall(require, "assets.dice_atlas")
    if ok then
        diceAtlasConfig = atlas
    end
end

local boardImage
local boardScale = 1
local boardX, boardY = 0, 0
local dice = {}
local numDice = 6
local fonts = {}
local diceImages = {}
local diceSheet
local diceFrameSets = {}
local diceFrameMeta = {}
local diceFrameCount = 0
local scores = {roll = 0, locked = 0, banked = 0}
local turn = {
    banked = 0, -- punti messi in cassaforte
    temp = 0,   -- punti temporanei del turno
    bust = false, -- true se il turno è bust
    canContinue = false, -- true se si può continuare a rollare
    canPass = false,     -- true se si può bancare
}
local selectedDie = 1 -- indice del dado selezionato per input tastiera

local tileWidth, tileHeight = 96, 48
local diceSize = 64
local diceSpriteSize = 64
local boardAnchorX, boardAnchorY = 0.5, 0.36
local gridWidth, gridHeight = 6, 4
local rollDurationRange = {0.45, 0.8}

local function isoToScreen(ix, iy, iz)
    local x = (ix - iy) * (tileWidth * 0.5)
    local y = (ix + iy) * (tileHeight * 0.5) - iz * tileHeight
    return x, y
end

local function easeOutCubic(t)
    local inv = 1 - t
    return 1 - inv * inv * inv
end

-- Genera posizioni predefinite ben distanziate per i dadi
local function generateDicePositions(num)
    local positions = {}
    -- Tray più grande: due righe in basso
    local trayY1 = gridHeight - 0.6
    local trayY2 = gridHeight - 1.3
    local trayX = {1, 2, 3, 4, 5, 6}
    for i = 1, num do
        local gx = trayX[((i-1)%6)+1] or (i * (gridWidth-1)/(num-1))
        local row = math.floor((i-1)/6)
        local iy = (row == 0 and trayY1 or trayY2) + love.math.random() * 0.18
        local ix = gx + love.math.random() * 0.22 - 0.11
        local iz = love.math.random() * 0.2
        table.insert(positions, {ix, iy, iz})
    end
    -- Mischia le posizioni
    for i = #positions, 2, -1 do
        local j = love.math.random(1, i)
        positions[i], positions[j] = positions[j], positions[i]
    end
    return positions
end

local dicePositions = nil

local function randomGridPosition(idx)
    if dicePositions and dicePositions[idx] then
        return unpack(dicePositions[idx])
    else
        local padding = 0.6
        local ix = love.math.random() * (gridWidth - padding * 2) + padding
        local iy = love.math.random() * (gridHeight - padding * 2) + padding
        local iz = love.math.random() * 0.4
        return ix, iy, iz
    end
end

local function computeScoreFromCounts(counts)
    local total = 0

    for value = 1, 6 do
        local count = counts[value] or 0
        if count >= 3 then
            local base = value == 1 and 1000 or value * 100
            total = total + base * (2 ^ (count - 3))
            count = count - 3
        end

        if value == 1 then
            total = total + count * 100
        elseif value == 5 then
            total = total + count * 50
        end
    end

    return total
end

local scoring = require("lib.scoring")
local function calculateScoreForDice(predicate)
    local vals = {}
    for _, die in ipairs(dice) do
        if not predicate or predicate(die) then
            table.insert(vals, die.value)
        end
    end
    return scoring.scoreSelection(vals).points
end

local function refreshScores()
    scores.roll = calculateScoreForDice()
    scores.locked = calculateScoreForDice(function(die)
        return die.locked
    end)
end

local function startRoll(die, idx)
    if diceFrameCount == 0 then return end
    if die.locked then return end
    local maxFace = math.max(1, math.min(6, diceFrameCount))
    die.value = love.math.random(1, maxFace)
    die.startX, die.startY, die.startZ = die.x, die.y, die.z
    die.targetX, die.targetY, die.targetZ = randomGridPosition(idx)
    die.animTime = 0
    die.animDuration = love.math.random() * (rollDurationRange[2] - rollDurationRange[1]) + rollDurationRange[1]
    die.spinSpeed = love.math.random(6, 12)
    die.bounce = love.math.random() * 0.25 + 0.1
    die.isRolling = true
    local frameDuration = love.math.random(0.04, 0.08)
    local randomFrame = love.math.random(1, diceFrameCount)
    for _, animation in pairs(die.animations) do
        animation:setDurations(frameDuration)
        animation:resume()
        animation:gotoFrame(randomFrame)
    end
end

local function createDie()
    local die = {
        value = love.math.random(1, math.max(1, math.min(6, diceFrameCount))),
        x = love.math.random() * gridWidth,
        y = love.math.random() * gridHeight,
        z = love.math.random() * 0.3,
        animTime = 0,
        animDuration = 0,
        spin = love.math.random() * 360,
        spinSpeed = love.math.random(4, 9),
        bounce = love.math.random() * 0.25 + 0.1,
        jitter = love.math.random() * 2 * math.pi,
        isRolling = false,
        locked = false,
        screenX = 0,
        screenY = 0,
        animations = {}
    }
    die.startX, die.startY, die.startZ = die.x, die.y, die.z
    die.targetX, die.targetY, die.targetZ = die.x, die.y, die.z
    local baseSpeed = love.math.random(0.05, 0.09)
    for setName, quads in pairs(diceFrameSets) do
        local animation = anim8.newAnimation(quads, baseSpeed)
        animation:gotoFrame(die.value)
        animation:pause()
        die.animations[setName] = animation
    end
    return die
end

local function updateLayout()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = 24
    local scaleX = (sw - margin * 2) / boardImage:getWidth()
    local scaleY = (sh - margin * 2) / boardImage:getHeight()
    boardScale = math.min(scaleX, scaleY)
    boardX = (sw - boardImage:getWidth() * boardScale) * 0.5
    boardY = (sh - boardImage:getHeight() * boardScale) * 0.5
end

local function drawDie(die)
    local isoX, isoY = isoToScreen(die.x, die.y, die.z)
    local x = boardX + boardImage:getWidth() * boardScale * boardAnchorX + isoX * boardScale
    local y = boardY + boardImage:getHeight() * boardScale * boardAnchorY + isoY * boardScale

    local size = diceSize * boardScale
    local half = size * 0.5
    local scale = size / diceSpriteSize

    die.screenX, die.screenY = x, y

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(math.rad(die.spin))

    local hasBorderFrames = diceFrameMeta.border ~= nil
    if die.locked and not hasBorderFrames then
        -- Glow giallo
        love.graphics.setColor(0.9, 0.78, 0.2, 0.55)
        love.graphics.rectangle("fill", -half * 1.1, -half * 1.1, half * 2.2, half * 2.2, 10, 10)
        -- Bordo giallo spesso
        love.graphics.setColor(0.95, 0.85, 0.1, 1)
        love.graphics.setLineWidth(6)
        love.graphics.rectangle("line", -half * 1.12, -half * 1.12, half * 2.24, half * 2.24, 12, 12)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.ellipse("fill", 0, half * 0.95, half * 0.95, half * 0.6)

    love.graphics.setColor(1, 1, 1, 1)
    local animationKey = (die.locked and hasBorderFrames) and "border" or "normal"
    local animation = die.animations[animationKey] or die.animations.normal
    local frameIndex = die.value
    local metaList = diceFrameMeta[animationKey] or diceFrameMeta.normal
    local meta
    if metaList then
        meta = metaList[frameIndex] or metaList[1]
    end
    local drawWidth = (meta and meta.width) or diceSpriteSize
    local drawHeight = (meta and meta.height) or diceSpriteSize
    animation:draw(diceSheet, -drawWidth * 0.5, -drawHeight * 0.5, 0, scale, scale)

    love.graphics.pop()
    love.graphics.setLineWidth(1)
end

local function drawHelp()
    local text = "SPACE o clic destro: roll | Clic sinistro sul dado: blocca/sblocca"
    love.graphics.setFont(fonts.help)
    local width = fonts.help:getWidth(text)
    local height = fonts.help:getHeight()
    local x = love.graphics.getWidth() * 0.5 - width * 0.5
    local y = love.graphics.getHeight() - height - 20
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.rectangle("fill", x - 12, y - 6, width + 24, height + 12, 12, 12)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, x, y)
end

local function loadDiceFramesFromAtlas()
    if not diceAtlasConfig or not diceAtlasConfig.image or not diceAtlasConfig.frames then
        return false
    end

    if not love.filesystem.getInfo(diceAtlasConfig.image) then
        return false
    end

    diceSheet = love.graphics.newImage(diceAtlasConfig.image)
    diceSheet:setFilter("linear", "linear")

    local textureWidth, textureHeight = diceSheet:getDimensions()
    diceFrameSets = {}
    diceFrameMeta = {}

    for setName, frames in pairs(diceAtlasConfig.frames) do
        diceFrameSets[setName] = {}
        diceFrameMeta[setName] = {}
        for index, frame in ipairs(frames) do
            local quad = love.graphics.newQuad(frame.x, frame.y, frame.width, frame.height, textureWidth, textureHeight)
            diceFrameSets[setName][index] = quad
            diceFrameMeta[setName][index] = {width = frame.width, height = frame.height}
        end
    end

    if diceFrameSets.normal and #diceFrameSets.normal > 0 then
        diceFrameCount = #diceFrameSets.normal
        diceSpriteSize = diceFrameMeta.normal[1].width
        return true
    end

    return false
end

local function buildDiceSpriteSheet()
    if #diceImages == 0 then
        return
    end

    local frameWidth = diceImages[1]:getWidth()
    local frameHeight = diceImages[1]:getHeight()
    local canvas = love.graphics.newCanvas(frameWidth * #diceImages, frameHeight)

    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    for index, image in ipairs(diceImages) do
        love.graphics.draw(image, (index - 1) * frameWidth, 0)
    end
    love.graphics.setCanvas()
    love.graphics.pop()

    canvas:setFilter("linear", "linear")
    diceSheet = canvas
    diceSpriteSize = frameWidth

    diceFrameSets = {normal = {}}
    diceFrameMeta = {normal = {}}
    local textureWidth, textureHeight = diceSheet:getDimensions()
    for index = 1, #diceImages do
        local quad = love.graphics.newQuad((index - 1) * frameWidth, 0, frameWidth, frameHeight, textureWidth, textureHeight)
        diceFrameSets.normal[index] = quad
        diceFrameMeta.normal[index] = {width = frameWidth, height = frameHeight}
    end
    diceFrameCount = #diceImages
end

local function drawScore()
    love.graphics.setFont(fonts.score)
    local panelPadding = 16
    local lineSpacing = fonts.score:getHeight() + 6
    local rollText = string.format("Roll attuale: %d", scores.roll)
    local lockedText = string.format("Punteggio bloccati: %d", scores.locked)
    local textWidth = math.max(fonts.score:getWidth(rollText), fonts.score:getWidth(lockedText))
    local bgWidth = textWidth + panelPadding * 2
    local bgHeight = lineSpacing * 2 + panelPadding * 2 - 6
    local x = 24
    local y = 24

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x - panelPadding, y - panelPadding, bgWidth, bgHeight, 14, 14)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(rollText, x, y)
    love.graphics.print(lockedText, x, y + lineSpacing)
end

function love.load()
    love.graphics.setBackgroundColor(0.07, 0.09, 0.11)
    love.graphics.setDefaultFilter("linear", "linear", 4)
    boardImage = love.graphics.newImage("asset/board.png")
    boardImage:setFilter("linear", "linear")

    for value = 1, 6 do
        local image = love.graphics.newImage(string.format("asset/die%d.png", value))
        image:setFilter("linear", "linear")
        diceImages[value] = image
    end

    if not loadDiceFramesFromAtlas() then
        buildDiceSpriteSheet()
    end

    love.window.setTitle("Farkle Prototype")

    love.math.setRandomSeed(os.time())

    fonts.help = love.graphics.newFont(18)
    fonts.score = love.graphics.newFont(28)
    love.graphics.setFont(fonts.help)

    for i = 1, numDice do
        table.insert(dice, createDie())
    end

    updateLayout()
    refreshScores()
end

function love.resize()
    updateLayout()
end

local function updateDie(die, dt)
    for _, animation in pairs(die.animations) do
        animation:update(dt)
    end
    if die.animTime < die.animDuration then
        die.animTime = math.min(die.animDuration, die.animTime + dt)
        local t = die.animDuration == 0 and 1 or die.animTime / die.animDuration
        local eased = easeOutCubic(t)
        die.x = die.startX + (die.targetX - die.startX) * eased
        die.y = die.startY + (die.targetY - die.startY) * eased
        die.z = die.startZ + (die.targetZ - die.startZ) * eased + math.sin(t * math.pi) * die.bounce * (1 - t)
        die.spin = die.spin + die.spinSpeed * dt * 60
        die.jitter = die.jitter + dt * 4
    else
        local wobble = math.sin(love.timer.getTime() * 2 + die.jitter) * 0.005
        die.z = die.targetZ + wobble
        if die.isRolling then
            for _, animation in pairs(die.animations) do
                animation:gotoFrame(die.value)
                animation:pause()
            end
            die.isRolling = false
        end
    end
end

function love.update(dt)
    for _, die in ipairs(dice) do
        updateDie(die, dt)
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(boardImage, boardX, boardY, 0, boardScale, boardScale)

    table.sort(dice, function(a, b)
        return (a.x + a.y + a.z) < (b.x + b.y + b.z)
    end)

    for _, die in ipairs(dice) do
        drawDie(die)
    end

    drawHelp()
    drawScore()
end

local function rollAllDice()
    dicePositions = generateDicePositions(#dice)
    for idx, die in ipairs(dice) do
        startRoll(die, idx)
    end
    refreshScores()
end

function love.keypressed(key)
    if key == "space" then
        rollAllDice()
    end
end

local function toggleDieLock(x, y)
    local clicked = false
    for index = #dice, 1, -1 do
        local die = dice[index]
        local size = diceSize * boardScale
        local half = size * 0.5
        local dx = x - die.screenX
        local dy = y - die.screenY
        local angle = -math.rad(die.spin)
        local cosA = math.cos(angle)
        local sinA = math.sin(angle)
        local localX = dx * cosA - dy * sinA
        local localY = dx * sinA + dy * cosA
        if math.abs(localX) <= half and math.abs(localY) <= half and die.animTime >= die.animDuration then
            die.locked = not die.locked
            clicked = true
            break
        end
    end
    if clicked then
        refreshScores()
    end
    return clicked
end

function love.mousepressed(x, y, button)
    if button == 1 then
        local handled = toggleDieLock(x, y)
        if not handled then
            rollAllDice()
        end
    elseif button == 2 then
        rollAllDice()
    end
end
