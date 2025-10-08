local anim8 = require("lib.anim8")

local diceAtlasConfig
do
    local ok, atlas = pcall(require, "asset.dice_atlas")
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
local diceFrameImages = {}
local diceFrameCount = 0
local scores = {roll = 0, selection = 0}
local turn = {
    banked = 0, -- points stored in the bank
    temp = 0,   -- points accumulated during the current turn
    bust = false, -- true if the last roll was a bust
    canContinue = false, -- true if there is a valid selection to keep rolling
    canPass = false,     -- true if banking is allowed
}
local selectedDie = 1 -- index of the die selected for keyboard input
local selection = {points = 0, valid = false, dice = 0}

local function setGameState(state)
    gameState = state
    if state == "menu" then
        mainMenu.pulse = 0
        if #mainMenu.items > 0 then
            mainMenu.selectedIndex = 1
        end
    end
end

local function drawShadowedText(font, text, x, y, color, shadowColor)
    love.graphics.setFont(font)
    shadowColor = shadowColor or {0, 0, 0, 0.65}
    color = color or {1, 1, 1, 1}
    love.graphics.setColor(shadowColor)
    love.graphics.print(text, x + 3, y + 3)
    love.graphics.setColor(color)
    love.graphics.print(text, x, y)
end
local function ensureSelectedDieValid()
    if #dice == 0 then return end
    if dice[selectedDie] and not dice[selectedDie].spent then
        return
    end
    for index, die in ipairs(dice) do
        if not die.spent then
            selectedDie = index
            return
        end
    end
    selectedDie = 1
end

local function moveSelection(delta)
    if #dice == 0 then return end
    local count = #dice
    local idx = selectedDie
    for _ = 1, count do
        idx = ((idx - 1 + delta) % count) + 1
        if not dice[idx].spent then
            selectedDie = idx
            return
        end
    end
end

local rollAllDice
local startNewGame

local gameState = "menu"
local globalTime = 0

local mainMenu = {
    items = {
        {id = "start", label = "Start Game", blurb = "Roll the bones and chase a streak."},
        {id = "options", label = "Options", blurb = "Tune the experience (coming soon)."},
        {id = "guide", label = "How to Play", blurb = "Learn the flow of Farkle."},
        {id = "exit", label = "Exit", blurb = "Leave the table."},
    },
    selectedIndex = 1,
    pulse = 0,
    itemBounds = {},
}

local function getAvailableFaceCount()
    if diceFrameSets.normal and #diceFrameSets.normal > 0 then
        return math.min(6, #diceFrameSets.normal)
    end
    return 6
end

-- Rolls only dice that are not locked
local function rollUnlockedDice()
    local toRoll = {}
    for _, die in ipairs(dice) do
        if not die.spent and not die.locked then
            table.insert(toRoll, die)
        end
    end
    if #toRoll == 0 then return end
    dicePositions = generateDicePositions(#toRoll)
    for idx, die in ipairs(toRoll) do
        startRoll(die, idx)
    end
    refreshScores()
    detectBust()
end

-- Banks the temporary points
local function bankPoints()
    turn.banked = turn.banked + turn.temp
    turn.temp = 0
    turn.canPass = false
    turn.canContinue = false
    for _, die in ipairs(dice) do
        die.locked = false
        die.spent = false
    end
    rollAllDice()
end

-- Resets the turn after a bust
local function bustTurn()
    turn.temp = 0
    turn.bust = true
    turn.canContinue = false
    turn.canPass = false
    for _, die in ipairs(dice) do
        die.locked = false
        die.spent = false
    end
    ensureSelectedDieValid()
end

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
    -- Tray piu' grande: due righe in basso
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
local function updateSelectionScore()
    local vals = {}
    for _, die in ipairs(dice) do
        if die.locked and not die.spent then
            table.insert(vals, die.value)
        end
    end
    local result = scoring.scoreSelection(vals)
    selection.points = result.points
    selection.valid = result.valid
    selection.dice = #vals
end

local function calculateScoreForDice(predicate)
    local vals = {}
    for _, die in ipairs(dice) do
        if (not die.spent) and (not predicate or predicate(die)) then
            table.insert(vals, die.value)
        end
    end
    return scoring.scoreSelection(vals).points
end

local function refreshScores()
    updateSelectionScore()
    scores.roll = calculateScoreForDice()
    scores.selection = selection.points
    turn.canContinue = selection.valid and selection.dice > 0
    turn.canPass = turn.temp > 0 or turn.canContinue
end

local function detectBust()
    local activeValues = {}
    for _, die in ipairs(dice) do
        if not die.spent then
            table.insert(activeValues, die.value)
        end
    end
    if #activeValues == 0 then
        turn.bust = false
        return
    end
    if scoring.hasAnyScoring(activeValues) then
        turn.bust = false
    else
        bustTurn()
        refreshScores()
    end
end

local function commitSelection()
    updateSelectionScore()
    if selection.dice == 0 or not selection.valid then
        return false, false
    end
    turn.temp = turn.temp + selection.points
    for _, die in ipairs(dice) do
        if die.locked then
            die.locked = false
            die.spent = true
        end
    end
    local allSpent = true
    for _, die in ipairs(dice) do
        if not die.spent then
            allSpent = false
            break
        end
    end
    selection.points = 0
    selection.valid = false
    selection.dice = 0
    ensureSelectedDieValid()
    refreshScores()
    return true, allSpent
end

local function attemptRoll()
    if selection.dice > 0 then
        if not selection.valid then
            return false
        end
        local success, allSpent = commitSelection()
        if not success then return false end
        if allSpent then
            for _, die in ipairs(dice) do
                die.spent = false
            end
            rollAllDice()
        else
            rollUnlockedDice()
        end
        return true
    else
        if turn.temp > 0 then
            return false
        end
        rollAllDice()
        return true
    end
end

local function attemptBank()
    if selection.dice > 0 then
        if not selection.valid then
            return false
        end
        local success = commitSelection()
        if not success then
            return false
        end
    elseif turn.temp == 0 then
        return false
    end
    bankPoints()
    refreshScores()
    return true
end

local function startRoll(die, idx)
    if die.locked then return end
    local maxFace = getAvailableFaceCount()
    die.value = love.math.random(1, maxFace)
    die.startX, die.startY, die.startZ = die.x, die.y, die.z
    die.targetX, die.targetY, die.targetZ = randomGridPosition(idx)
    die.animTime = 0
    die.animDuration = love.math.random() * (rollDurationRange[2] - rollDurationRange[1]) + rollDurationRange[1]
    die.spinSpeed = love.math.random(6, 12)
    die.bounce = love.math.random() * 0.25 + 0.1
    die.isRolling = true
    if diceFrameCount > 0 then
        local frameDuration = love.math.random(0.04, 0.08)
        for _, animation in pairs(die.animations) do
            local randomFrame = love.math.random(1, math.max(1, #animation.frames))
            animation:setDurations(frameDuration)
            animation:resume()
            animation:gotoFrame(randomFrame)
        end
    end
end

local function createDie()
    local die = {
        value = love.math.random(1, getAvailableFaceCount()),
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
        spent = false,
        screenX = 0,
        screenY = 0,
        animations = {},
        animationImages = {}
    }
    die.startX, die.startY, die.startZ = die.x, die.y, die.z
    die.targetX, die.targetY, die.targetZ = die.x, die.y, die.z
    local baseSpeed = love.math.random(0.05, 0.09)
    for setName, quads in pairs(diceFrameSets) do
        local animation = anim8.newAnimation(quads, baseSpeed)
        animation:gotoFrame(die.value)
        animation:pause()
        die.animations[setName] = animation
        die.animationImages[setName] = diceFrameImages[setName] or diceSheet
    end
    return die
end

function startNewGame()
    dicePositions = nil
    dice = {}
    for i = 1, numDice do
        table.insert(dice, createDie())
    end

    turn.banked = 0
    turn.temp = 0
    turn.bust = false
    turn.canContinue = false
    turn.canPass = false

    selection.points = 0
    selection.valid = false
    selection.dice = 0

    selectedDie = 1
    ensureSelectedDieValid()
    rollAllDice()
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
        -- Yellow glow
        love.graphics.setColor(0.9, 0.78, 0.2, 0.55)
        love.graphics.rectangle("fill", -half * 1.1, -half * 1.1, half * 2.2, half * 2.2, 10, 10)
        -- Thick yellow border
        love.graphics.setColor(0.95, 0.85, 0.1, 1)
        love.graphics.setLineWidth(6)
        love.graphics.rectangle("line", -half * 1.12, -half * 1.12, half * 2.24, half * 2.24, 12, 12)
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.ellipse("fill", 0, half * 0.95, half * 0.95, half * 0.6)

    local dieAlpha = die.spent and 0.45 or 1
    love.graphics.setColor(1, 1, 1, dieAlpha)
    local animationKey = (die.locked and hasBorderFrames) and "border" or "normal"
    local animation = die.animations[animationKey] or die.animations.normal
    local image = die.animationImages[animationKey] or die.animationImages.normal or diceSheet
    if not animation or not image then
        love.graphics.pop()
        love.graphics.setLineWidth(1)
        return
    end
    local frameIndex = die.value
    local metaList = diceFrameMeta[animationKey] or diceFrameMeta.normal
    local meta
    if metaList then
        meta = metaList[frameIndex] or metaList[1]
    end
    local drawWidth = (meta and meta.width) or diceSpriteSize
    local drawHeight = (meta and meta.height) or diceSpriteSize
    animation:draw(image, -drawWidth * 0.5, -drawHeight * 0.5, 0, scale, scale)

    love.graphics.pop()
    love.graphics.setLineWidth(1)
end

local function drawHelp()
    local text = "Space/Enter/F or Right Click: score & roll    Q: bank winnings    Esc: main menu"
    love.graphics.setFont(fonts.help)
    local width = fonts.help:getWidth(text)
    local height = fonts.help:getHeight()
    local x = love.graphics.getWidth() * 0.5 - width * 0.5
    local y = love.graphics.getHeight() - height - 24
    love.graphics.setColor(0.03, 0.07, 0.12, 0.78)
    love.graphics.rectangle("fill", x - 18, y - 10, width + 36, height + 20, 16, 16)
    love.graphics.setColor(0.98, 0.8, 0.3, 0.9)
    love.graphics.rectangle("line", x - 18, y - 10, width + 36, height + 20, 16, 16)
    drawShadowedText(fonts.help, text, x, y, {0.92, 0.94, 0.98, 1})
end

local function updateMenu(dt)
    mainMenu.pulse = (mainMenu.pulse or 0) + dt * 2
end

local function drawAmbientBackground()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0.05, 0.06, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.push()
    love.graphics.translate(w * 0.5, h * 0.5)
    love.graphics.rotate(math.rad(32))
    for i = -6, 6 do
        local offset = (i * 140 + globalTime * 120) % (h * 2) - h
        love.graphics.setColor(0.14, 0.2, 0.32, 0.12)
        love.graphics.rectangle("fill", -w * 1.5, offset, w * 3, 36)
    end
    love.graphics.pop()
end

local function drawMenuCard(x, y, w, h, isSelected, accentPulse)
    love.graphics.setColor(0.06, 0.09, 0.14, 0.86)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(0.3, 0.4, 0.68, 0.55)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
    if isSelected then
        local glow = 0.6 + 0.3 * math.sin(accentPulse)
        love.graphics.setColor(0.98, 0.72 + 0.08 * glow, 0.28 + 0.1 * glow, 1)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", x - 6, y - 6, w + 12, h + 12, 22, 22)
        love.graphics.setLineWidth(1)
    end
end

local function drawMainMenu()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0.02, 0.03, 0.05, 0.78)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local title = "Neon Farkle"
    local titleWidth = fonts.title:getWidth(title)
    local titleX = (w - titleWidth) * 0.5
    local titleY = h * 0.18
    drawShadowedText(fonts.title, title, titleX, titleY, {0.98, 0.78, 0.32, 1}, {0.02, 0.02, 0.02, 0.8})

    local subtitle = "Roll with style. Bank with nerve."
    local subtitleX = (w - fonts.help:getWidth(subtitle)) * 0.5
    drawShadowedText(fonts.help, subtitle, subtitleX, titleY + fonts.title:getHeight() + 12, {0.82, 0.86, 0.96, 1})

    local itemHeight = fonts.menu:getHeight() + 22
    local spacing = 16
    local totalHeight = #mainMenu.items * itemHeight + (#mainMenu.items - 1) * spacing
    local baseY = h * 0.45 - totalHeight * 0.5
    local cardWidth = math.max(360, w * 0.32)
    local cardX = (w - cardWidth) * 0.5

    mainMenu.itemBounds = {}
    for index, item in ipairs(mainMenu.items) do
        local itemY = baseY + (index - 1) * (itemHeight + spacing)
        local isSelected = index == mainMenu.selectedIndex
        drawMenuCard(cardX, itemY, cardWidth, itemHeight, isSelected, mainMenu.pulse * 2 + index)
        mainMenu.itemBounds[index] = {x = cardX, y = itemY, w = cardWidth, h = itemHeight}

        local textY = itemY + (itemHeight - fonts.menu:getHeight()) * 0.5 - 2
        local textColor = isSelected and {0.98, 0.93, 0.85, 1} or {0.78, 0.82, 0.9, 1}
        drawShadowedText(fonts.menu, item.label, cardX + 28, textY, textColor)
    end

    local selectedItem = mainMenu.items[mainMenu.selectedIndex]
    if selectedItem then
        local blurb = selectedItem.blurb
        local blurbWidth = fonts.body:getWidth(blurb)
        local blurbX = (w - blurbWidth) * 0.5
        drawShadowedText(fonts.body, blurb, blurbX, baseY + totalHeight + 42, {0.86, 0.88, 0.95, 1})
    end

    local hint = "Enter / Click to confirm    Esc to quit"
    drawShadowedText(fonts.help, hint, (w - fonts.help:getWidth(hint)) * 0.5, h - 86, {0.96, 0.78, 0.36, 1})
end

local function drawOptionsScreen()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0.02, 0.03, 0.05, 0.82)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local title = "Options"
    drawShadowedText(fonts.title, title, (w - fonts.title:getWidth(title)) * 0.5, h * 0.18, {0.98, 0.76, 0.3, 1})

    local lines = {
        "Audio sliders, visual filters, and accessibility toggles",
        "will live here soon. For now, enjoy the neon bones!",
    }
    for i, line in ipairs(lines) do
        local textWidth = fonts.body:getWidth(line)
        local x = (w - textWidth) * 0.5
        local y = h * 0.4 + (i - 1) * (fonts.body:getHeight() + 12)
        drawShadowedText(fonts.body, line, x, y, {0.86, 0.88, 0.95, 1})
    end

    local hint = "Press ESC or Right Click to return"
    drawShadowedText(fonts.help, hint, (w - fonts.help:getWidth(hint)) * 0.5, h - 86, {0.96, 0.78, 0.36, 1})
end

local function drawGuideScreen()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0.02, 0.03, 0.05, 0.82)
    love.graphics.rectangle("fill", 0, 0, w, h)

    local title = "How to Play"
    drawShadowedText(fonts.title, title, (w - fonts.title:getWidth(title)) * 0.5, h * 0.18, {0.98, 0.76, 0.3, 1})

    local lines = {
        "Roll six dice. Lock scoring dice to build your combo streak.",
        "Bank points with Q to keep them safe, but busting erases turn points.",
        "Hot dice! Score all dice in a roll and you'll throw all six again.",
        "Chase high scores like a Balatro run—risky plays pay the neon bills.",
    }
    for i, line in ipairs(lines) do
        local textWidth = fonts.body:getWidth(line)
        local x = (w - textWidth) * 0.5
        local y = h * 0.38 + (i - 1) * (fonts.body:getHeight() + 10)
        drawShadowedText(fonts.body, line, x, y, {0.86, 0.88, 0.95, 1})
    end

    local hint = "Press ESC or Right Click to return"
    drawShadowedText(fonts.help, hint, (w - fonts.help:getWidth(hint)) * 0.5, h - 86, {0.96, 0.78, 0.36, 1})
end

local function activateMenuItem(index)
    local item = mainMenu.items[index]
    if not item then return end

    if item.id == "start" then
        startNewGame()
        setGameState("game")
    elseif item.id == "options" then
        setGameState("options")
    elseif item.id == "guide" then
        setGameState("guide")
    elseif item.id == "exit" then
        love.event.quit()
    end
end

local function parseTextureAtlasXML(xmlPath, imagePath)
    if not (love.filesystem.getInfo(xmlPath) and love.filesystem.getInfo(imagePath)) then
        return nil
    end

    local contents = love.filesystem.read(xmlPath)
    if not contents then
        return nil
    end

    local image = love.graphics.newImage(imagePath)
    image:setFilter("linear", "linear")
    local textureWidth, textureHeight = image:getDimensions()

    local frames = {}
    for element in contents:gmatch("<SubTexture%s+[^>]-/>") do
        local name = element:match('name="([^"]+)"')
        local x = tonumber(element:match('x="([^"]+)"')) or 0
        local y = tonumber(element:match('y="([^"]+)"')) or 0
        local width = tonumber(element:match('width="([^"]+)"')) or 0
        local height = tonumber(element:match('height="([^"]+)"')) or 0
        if name and width > 0 and height > 0 then
            local digits = name:match("(%d+)%D*$") or name:match("(%d+)$")
            local numeric = digits and tonumber(digits) or nil
            local index = (numeric and numeric > 0) and numeric or (#frames + 1)
            table.insert(frames, {
                name = name,
                index = index,
                x = x,
                y = y,
                width = width,
                height = height,
            })
        end
    end

    if #frames == 0 then
        return nil
    end

    table.sort(frames, function(a, b)
        if a.index == b.index then
            return a.name < b.name
        end
        return a.index < b.index
    end)

    local quads, meta = {}, {}
    for i, frame in ipairs(frames) do
        quads[i] = love.graphics.newQuad(frame.x, frame.y, frame.width, frame.height, textureWidth, textureHeight)
        meta[i] = {width = frame.width, height = frame.height}
    end

    return {
        image = image,
        quads = quads,
        meta = meta,
    }
end

local function loadDiceFramesFromAtlas()
    local function loadFromXml()
        local normal = parseTextureAtlasXML("asset/diceWhite.xml", "asset/diceWhite.png")
        if not normal then
            return false
        end

        diceFrameSets = {normal = normal.quads}
        diceFrameMeta = {normal = normal.meta}
        diceFrameImages = {normal = normal.image}
        diceSheet = normal.image
        diceFrameCount = #normal.quads
        if normal.meta[1] then
            diceSpriteSize = normal.meta[1].width
        end

        local border = parseTextureAtlasXML("asset/diceWhite_border.xml", "asset/diceWhite_border.png")
        if border and #border.quads > 0 then
            diceFrameSets.border = border.quads
            diceFrameMeta.border = border.meta
            diceFrameImages.border = border.image
        end

        return true
    end

    if not diceAtlasConfig or not diceAtlasConfig.image or not diceAtlasConfig.frames then
        return loadFromXml()
    end

    local imagePath = diceAtlasConfig.image
    if not love.filesystem.getInfo(imagePath) then
        local normalized = imagePath:gsub("^assets/", "asset/")
        if love.filesystem.getInfo(normalized) then
            imagePath = normalized
        else
            local altPath = "asset/" .. imagePath
            if love.filesystem.getInfo(altPath) then
                imagePath = altPath
            end
        end
    end

    if not love.filesystem.getInfo(imagePath) then
        return loadFromXml()
    end

    diceSheet = love.graphics.newImage(imagePath)
    diceSheet:setFilter("linear", "linear")

    local textureWidth, textureHeight = diceSheet:getDimensions()
    diceFrameSets = {}
    diceFrameMeta = {}
    diceFrameImages = {}

    for setName, frames in pairs(diceAtlasConfig.frames) do
        diceFrameSets[setName] = {}
        diceFrameMeta[setName] = {}
        diceFrameImages[setName] = diceSheet
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
    diceFrameImages = {normal = diceSheet}
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
    local selectionText
    if selection.dice > 0 then
        if selection.valid then
            selectionText = string.format("Selection: %d", selection.points)
        else
            selectionText = "Selection: 0 (invalid)"
        end
    else
        selectionText = "Selection: 0"
    end
    local lines = {
        string.format("Potential points: %d", scores.roll),
        selectionText,
        string.format("Turn points: %d", turn.temp),
        string.format("Banked total: %d", turn.banked),
    }
    if turn.bust then
        table.insert(lines, "BUST! No score")
    end
    local textWidth = 0
    for _, line in ipairs(lines) do
        textWidth = math.max(textWidth, fonts.score:getWidth(line))
    end
    local bgWidth = textWidth + panelPadding * 2
    local bgHeight = lineSpacing * #lines + panelPadding * 2 - 6
    local x = 32
    local y = 36

    love.graphics.setColor(0.05, 0.1, 0.18, 0.82)
    love.graphics.rectangle("fill", x - panelPadding, y - panelPadding, bgWidth, bgHeight, 18, 18)
    love.graphics.setColor(0.98, 0.78, 0.32, 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x - panelPadding, y - panelPadding, bgWidth, bgHeight, 18, 18)
    love.graphics.setLineWidth(1)

    for index, line in ipairs(lines) do
        drawShadowedText(fonts.score, line, x, y + (index - 1) * lineSpacing, {0.92, 0.94, 0.98, 1})
    end
end

function love.load()
    love.graphics.setBackgroundColor(0.04, 0.05, 0.08)
    love.graphics.setDefaultFilter("linear", "linear", 4)
    boardImage = love.graphics.newImage("asset/board.png")
    boardImage:setFilter("linear", "linear")

    diceImages = {}
    for value = 1, 6 do
        local path = string.format("asset/die%d.png", value)
        if love.filesystem.getInfo(path) then
            local image = love.graphics.newImage(path)
            image:setFilter("linear", "linear")
            table.insert(diceImages, image)
        end
    end

    if not loadDiceFramesFromAtlas() then
        buildDiceSpriteSheet()
    end

    love.window.setTitle("Neon Farkle Prototype")

    love.math.setRandomSeed(os.time())

    fonts.title = love.graphics.newFont(64)
    fonts.menu = love.graphics.newFont(30)
    fonts.body = love.graphics.newFont(22)
    fonts.help = love.graphics.newFont(18)
    fonts.score = love.graphics.newFont(28)
    love.graphics.setFont(fonts.help)

    updateLayout()
    startNewGame()
    setGameState("menu")
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
    globalTime = globalTime + dt
    if gameState ~= "game" then
        updateMenu(dt)
    end
    for _, die in ipairs(dice) do
        updateDie(die, dt)
    end
end

function love.draw()
    drawAmbientBackground()

    love.graphics.setColor(1, 1, 1, 0.92)
    love.graphics.draw(boardImage, boardX, boardY, 0, boardScale, boardScale)

    table.sort(dice, function(a, b)
        return (a.x + a.y + a.z) < (b.x + b.y + b.z)
    end)

    for _, die in ipairs(dice) do
        drawDie(die)
    end

    if gameState == "game" then
        drawHelp()
        drawScore()
    elseif gameState == "menu" then
        drawMainMenu()
    elseif gameState == "options" then
        drawOptionsScreen()
    elseif gameState == "guide" then
        drawGuideScreen()
    end
end

function rollAllDice()
    dicePositions = generateDicePositions(#dice)
    turn.bust = false
    for _, die in ipairs(dice) do
        die.locked = false
        die.spent = false
    end
    ensureSelectedDieValid()
    for idx, die in ipairs(dice) do
        startRoll(die, idx)
    end
    refreshScores()
    detectBust()
end

function love.keypressed(key)
    if gameState == "menu" then
        local total = #mainMenu.items
        if total == 0 then return end

        if key == "w" or key == "up" then
            mainMenu.selectedIndex = ((mainMenu.selectedIndex - 2) % total) + 1
        elseif key == "s" or key == "down" then
            mainMenu.selectedIndex = (mainMenu.selectedIndex % total) + 1
        elseif key == "return" or key == "space" or key == "f" then
            activateMenuItem(mainMenu.selectedIndex)
        elseif key == "escape" then
            love.event.quit()
        end
        return
    elseif gameState == "options" or gameState == "guide" then
        if key == "escape" or key == "backspace" or key == "space" or key == "return" then
            setGameState("menu")
        end
        return
    elseif key == "escape" then
        setGameState("menu")
        return
    end

    if key == "w" or key == "up" then
        moveSelection(-1)
    elseif key == "s" or key == "down" then
        moveSelection(1)
    elseif key == "a" or key == "left" then
        moveSelection(-1)
    elseif key == "d" or key == "right" then
        moveSelection(1)
    elseif key == "e" then
        local die = dice[selectedDie]
        if die and not die.isRolling and not die.spent then
            die.locked = not die.locked
            refreshScores()
        end
    elseif key == "f" or key == "space" or key == "return" then
        attemptRoll()
    elseif key == "q" then
        attemptBank()
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
            if not die.spent and not die.isRolling then
                die.locked = not die.locked
                clicked = true
                break
            end
        end
    end
    if clicked then
        refreshScores()
    end
    return clicked
end

local function pointInBounds(px, py, bounds)
    return px >= bounds.x and px <= bounds.x + bounds.w and py >= bounds.y and py <= bounds.y + bounds.h
end

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        if button == 1 then
            for index, bounds in ipairs(mainMenu.itemBounds or {}) do
                if pointInBounds(x, y, bounds) then
                    mainMenu.selectedIndex = index
                    activateMenuItem(index)
                    return
                end
            end
        elseif button == 2 then
            love.event.quit()
        end
        return
    elseif gameState == "options" or gameState == "guide" then
        if button == 1 or button == 2 then
            setGameState("menu")
        end
        return
    end

    if button == 1 then
        toggleDieLock(x, y)
    elseif button == 2 then
        attemptRoll()
    end
end

function love.mousemoved(x, y)
    if gameState ~= "menu" then return end
    for index, bounds in ipairs(mainMenu.itemBounds or {}) do
        if pointInBounds(x, y, bounds) then
            mainMenu.selectedIndex = index
            return
        end
    end
end
