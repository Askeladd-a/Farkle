local anim8 = require("lib.anim8")
local Menu = require("lib.menu")
local AIController = require("lib.ai")

local table_unpack = table.unpack or unpack

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
local diceSpriteSize = 64
local selectionParticleImages = {}

local function loadSelectionParticleImages()
    selectionParticleImages = {}
    local names = {"light_01.png", "light_02.png", "light_03.png"}
    for _, filename in ipairs(names) do
        local path = "asset/" .. filename
        if love.filesystem.getInfo(path) then
            local image = love.graphics.newImage(path)
            image:setFilter("linear", "linear")
            table.insert(selectionParticleImages, image)
        end
    end
end

local function createSelectionParticleSystem()
    if #selectionParticleImages == 0 then
        return nil
    end
    local ps = love.graphics.newParticleSystem(selectionParticleImages[1], 128)
    if #selectionParticleImages > 1 then
        ps:setImages(table.unpack(selectionParticleImages))
    end
    ps:setEmitterLifetime(-1)
    ps:setParticleLifetime(0.35, 0.85)
    ps:setEmissionRate(90)
    ps:setSizeVariation(0.8)
    ps:setSizes(0.45, 0.1)
    ps:setSpeed(22, 60)
    ps:setLinearAcceleration(-28, -28, 28, 28)
    ps:setRadialAcceleration(-18, 18)
    ps:setTangentialAcceleration(-26, 26)
    ps:setSpin(-1.2, 1.2)
    ps:setSpinVariation(1)
    ps:setColors(
        0.95, 0.85, 0.35, 0.82,
        0.4, 0.65, 1.0, 0.35
    )
    ps:setEmissionArea("uniform", diceSpriteSize * 0.25, diceSpriteSize * 0.25, 0, true)
    ps:setRelativeRotation(true)
    ps:stop()
    return ps
end

local function updateSelectionParticles(die, dt)
    if not die.particles then
        return
    end
    local shouldBeActive = die.locked and not die.spent and not die.isRolling
    if shouldBeActive then
        if not die.selectionParticlesActive then
            die.selectionParticlesActive = true
            die.particles:reset()
            die.particles:start()
            die.particles:emit(28)
        end
    elseif die.selectionParticlesActive then
        die.selectionParticlesActive = false
        die.particles:stop()
    end
    die.particles:update(dt)
end
local scores = {roll = 0, selection = 0}

local players = {
    {id = "human", name = "You", banked = 0, isAI = false},
    {id = "ai", name = "Neon Bot", banked = 0, isAI = true},
}

local winningScore = 10000
local winnerIndex = nil

local turn = {
    player = 1,
    temp = 0,   -- points accumulated during the current turn
    bust = false, -- true if the last roll was a bust
    canContinue = false, -- true if there is a valid selection to keep rolling
    canPass = false,     -- true if banking is allowed
    lastOutcome = nil,
    pendingRoll = false,
    pendingRollDelay = 0,
}

local aiController = AIController.new()

local customCursor
local function installCustomCursor()
    if customCursor then
        love.mouse.setCursor(customCursor)
    end
end

local gameState = "menu"
local globalTime = 0
local selectedDie = 1 -- index of the die selected for keyboard input
local selection = {points = 0, valid = false, dice = 0}
local uiScale = 1
local currentFontScale = nil
local baseFontSizes = {
    title = 64,
    menu = 30,
    body = 22,
    help = 18,
    score = 28,
}

local function refreshFontsForScale(scale)
    scale = math.max(0.75, math.min(scale, 1.6))
    if currentFontScale and math.abs(currentFontScale - scale) < 0.02 then
        return
    end
    currentFontScale = scale

    local function sized(size)
        return math.max(12, math.floor(size * scale + 0.5))
    end

    fonts.title = love.graphics.newFont(sized(baseFontSizes.title))
    fonts.menu = love.graphics.newFont(sized(baseFontSizes.menu))
    fonts.body = love.graphics.newFont(sized(baseFontSizes.body))
    fonts.help = love.graphics.newFont(sized(baseFontSizes.help))
    fonts.score = love.graphics.newFont(sized(baseFontSizes.score))
end

local refreshScores

local actionButtonMetrics = {
    width = 200,
    height = 64,
    spacing = 24,
    marginX = 40,
    marginY = 36,
}

local function getCurrentPlayer()
    return players[turn.player]
end

local function getNextPlayerIndex(index)
    return (index % #players) + 1
end

local function isAITurn()
    local player = getCurrentPlayer()
    return gameState == "game" and not winnerIndex and player and player.isAI
end

local function isHumanTurn()
    local player = getCurrentPlayer()
    return gameState == "game" and (not winnerIndex) and player and not player.isAI
end

local function diceAreIdle()
    for _, die in ipairs(dice) do
        if die.isRolling or die.animTime < die.animDuration then
            return false
        end
    end
    return true
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
local generateDicePositions
local attemptRoll
local attemptBank

local mainMenu = Menu.new({
    {id = "start", label = "Start Game", blurb = "Roll the bones and chase a streak."},
    {id = "options", label = "Options", blurb = "Tune the experience (coming soon)."},
    {id = "guide", label = "How to Play", blurb = "Learn the flow of Farkle."},
    {id = "exit", label = "Exit", blurb = "Leave the table."},
})

local function setGameState(state)
    gameState = state
    if state == "menu" then
        mainMenu:reset()
        turn.pendingRoll = false
        aiController:reset()
    end
    installCustomCursor()
end

local function getAvailableFaceCount()
    if diceFrameSets.normal and #diceFrameSets.normal > 0 then
        return math.min(6, #diceFrameSets.normal)
    end
    return 6
end

local function declareWinner(bankedAmount)
    local player = getCurrentPlayer()
    if not player then return end

    winnerIndex = turn.player
    turn.pendingRoll = false
    turn.pendingRollDelay = 0
    aiController:reset()
    turn.canContinue = false
    turn.canPass = false
    turn.temp = 0
    selection.points = 0
    selection.valid = false
    selection.dice = 0

    for _, die in ipairs(dice) do
        die.locked = false
        die.spent = true
    end

    ensureSelectedDieValid()

    local message = string.format("%s wins with %d!", player.name, player.banked)
    if bankedAmount and bankedAmount > 0 then
        message = string.format("%s banked %d and reached %d!", player.name, bankedAmount, player.banked)
    end
    turn.lastOutcome = message

    refreshScores()
end

local function endCurrentTurn(opts)
    opts = opts or {}
    local player = getCurrentPlayer()
    if not player then return end

    if opts.message then
        turn.lastOutcome = opts.message
    elseif opts.bust then
        turn.lastOutcome = string.format("%s busted!", player.name)
    elseif opts.banked and opts.banked > 0 then
        turn.lastOutcome = string.format("%s banked %d", player.name, opts.banked)
    else
        turn.lastOutcome = string.format("%s ended the turn", player.name)
    end

    turn.temp = 0
    turn.bust = false
    turn.canContinue = false
    turn.canPass = false
    selection.points = 0
    selection.valid = false
    selection.dice = 0

    for _, die in ipairs(dice) do
        die.locked = false
        die.spent = true
    end

    ensureSelectedDieValid()

    local previous = turn.player
    turn.player = getNextPlayerIndex(previous)
    turn.pendingRoll = true
    turn.pendingRollDelay = opts.delay or (opts.bust and 1.1 or 0.9)
    aiController:clearPending()
    aiController:delayFor(turn.pendingRollDelay)

    refreshScores()
end

-- Rolls only dice that are not locked
local function rollUnlockedDice()
    if winnerIndex then return end
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
    local player = getCurrentPlayer()
    if not player then return end

    local banked = turn.temp
    player.banked = player.banked + banked

    if player.banked >= winningScore then
        declareWinner(banked)
        return
    end

    endCurrentTurn({banked = banked})
end

-- Resets the turn after a bust
local function bustTurn()
    turn.bust = true
    endCurrentTurn({bust = true})
end

local tileWidth, tileHeight = 96, 48
local diceSize = 64
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
        return table_unpack(dicePositions[idx])
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

refreshScores = function()
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
    end
end

local function countRemainingAfterSelection()
    local remaining = 0
    for _, die in ipairs(dice) do
        if not die.spent and not die.locked then
            remaining = remaining + 1
        end
    end
    return remaining
end

local function buildAIContext()
    return {
        isActive = function() return isAITurn() end,
        hasWinner = function() return winnerIndex ~= nil end,
        isRollPending = function() return turn.pendingRoll end,
        diceAreIdle = diceAreIdle,
        getSelection = function() return selection end,
        turnTemp = function() return turn.temp end,
        playerBanked = function()
            local player = getCurrentPlayer()
            return player and player.banked or 0
        end,
        winningScore = function() return winningScore end,
        countRemainingDice = countRemainingAfterSelection,
        attemptBank = attemptBank,
        attemptRoll = attemptRoll,
        getDice = function() return dice end,
        lockDice = function(indices)
            for _, index in ipairs(indices) do
                local die = dice[index]
                if die and not die.spent then
                    die.locked = true
                end
            end
        end,
        refreshScores = refreshScores,
    }
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
    if winnerIndex or turn.pendingRoll then
        return false
    end
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
    if winnerIndex or turn.pendingRoll then
        return false
    end
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


local function isRollActionEnabled()
    if not isHumanTurn() or winnerIndex or turn.pendingRoll then
        return false
    end
    if selection.dice > 0 then
        return selection.valid
    end
    return turn.temp == 0
end

local function isBankActionEnabled()
    if not isHumanTurn() or winnerIndex or turn.pendingRoll then
        return false
    end
    if selection.dice > 0 then
        return selection.valid
    end
    return turn.temp > 0
end

local function buildGameActionTemplates()
    local templates = {}
    if winnerIndex then
        table.insert(templates, {
            id = "playAgain",
            label = "Play Again",
            description = "Start a fresh duel",
            enabled = true,
            action = function()
                startNewGame()
            end,
        })
        table.insert(templates, {
            id = "mainMenu",
            label = "Main Menu",
            description = "Return to the lobby",
            enabled = true,
            action = function()
                setGameState("menu")
            end,
        })
        return templates
    end

    table.insert(templates, {
        id = "roll",
        label = "Roll Dice",
        description = "Reroll remaining dice",
        enabled = isRollActionEnabled(),
        action = function()
            attemptRoll()
        end,
    })

    table.insert(templates, {
        id = "bank",
        label = "Bank Points",
        description = "Save turn total",
        enabled = isBankActionEnabled(),
        action = function()
            attemptBank()
        end,
    })

    table.insert(templates, {
        id = "mainMenu",
        label = "Main Menu",
        description = "Leave the table",
        enabled = true,
        action = function()
            setGameState("menu")
        end,
    })

    return templates
end

local function getActionButtons()
    if gameState ~= "game" then
        return {}
    end

    local templates = buildGameActionTemplates()
    local total = #templates
    if total == 0 then
        return {}
    end

    local metrics = actionButtonMetrics
    local scale = uiScale
    local width = metrics.width * scale
    local height = metrics.height * scale
    local spacing = metrics.spacing * scale
    local marginX = metrics.marginX * scale
    local marginY = metrics.marginY * scale

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local totalWidth = width * total + spacing * (total - 1)
    local startX = screenWidth - totalWidth - marginX
    local y = screenHeight - height - marginY

    local buttons = {}
    for index, template in ipairs(templates) do
        local x = startX + (index - 1) * (width + spacing)
        buttons[index] = {
            id = template.id,
            label = template.label,
            description = template.description,
            enabled = template.enabled,
            action = template.action,
            x = x,
            y = y,
            width = width,
            height = height,
        }
    end

    return buttons
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
        animationImages = {},
        particles = createSelectionParticleSystem(),
        selectionParticlesActive = false,
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

local function startNewGame()
    dicePositions = nil
    dice = {}
    for i = 1, numDice do
        table.insert(dice, createDie())
    end

    for _, player in ipairs(players) do
        player.banked = 0
    end

    winnerIndex = nil
    turn.player = 1
    turn.temp = 0
    turn.bust = false
    turn.canContinue = false
    turn.canPass = false
    turn.lastOutcome = nil
    turn.pendingRoll = false
    turn.pendingRollDelay = 0

    aiController:reset()

    selection.points = 0
    selection.valid = false
    selection.dice = 0

    selectedDie = 1
    ensureSelectedDieValid()
    rollAllDice()
end

local function updateLayout()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local minDim = math.min(sw, sh)
    local margin = math.max(12, minDim * 0.04)
    local scaleX = (sw - margin * 2) / boardImage:getWidth()
    local scaleY = (sh - margin * 2) / boardImage:getHeight()
    boardScale = math.min(scaleX, scaleY)
    boardX = (sw - boardImage:getWidth() * boardScale) * 0.5
    boardY = (sh - boardImage:getHeight() * boardScale) * 0.5

    local referenceW, referenceH = 1280, 720
    local scaleW = sw / referenceW
    local scaleH = sh / referenceH
    uiScale = math.max(0.75, math.min(math.max(scaleW, scaleH), 1.5))
end

local function drawDie(die)
    local isoX, isoY = isoToScreen(die.x, die.y, die.z)
    local x = boardX + boardImage:getWidth() * boardScale * boardAnchorX + isoX * boardScale
    local y = boardY + boardImage:getHeight() * boardScale * boardAnchorY + isoY * boardScale

    local size = diceSize * boardScale
    local half = size * 0.5
    local scale = size / diceSpriteSize

    die.screenX, die.screenY = x, y

    if die.particles and (die.selectionParticlesActive or die.particles:getCount() > 0) then
        love.graphics.push()
        love.graphics.translate(x, y)
        local prevBlendMode, prevAlphaMode = love.graphics.getBlendMode()
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.draw(die.particles, 0, 0, 0, boardScale, boardScale)
        love.graphics.setBlendMode(prevBlendMode or "alpha", prevAlphaMode or "alphamultiply")
        love.graphics.pop()
    end

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
    local text
    if winnerIndex then
        text = "Click Play Again to restart or Main Menu to leave the table."
    elseif isAITurn() then
        if turn.pendingRoll then
            text = "Neon Bot prepares the next roll..."
        else
            text = "Neon Bot is weighing the odds..."
        end
    elseif isHumanTurn() then
        if selection.dice > 0 and not selection.valid then
            text = "Click dice to adjust your set. Roll and Bank are disabled until it scores."
        elseif selection.dice > 0 then
            text = "Click Roll Dice to continue or Bank Points to cash out."
        else
            text = "Click dice to lock scoring sets, then use the buttons below to act."
        end
    else
        text = "Preparing the next shooter..."
    end
    love.graphics.setFont(fonts.help)
    local width = fonts.help:getWidth(text)
    local height = fonts.help:getHeight()
    local margin = 28 * uiScale
    local paddingX = 22 * uiScale
    local paddingY = 12 * uiScale
    local x = love.graphics.getWidth() * 0.5 - width * 0.5
    local y = love.graphics.getHeight() - height - margin
    love.graphics.setColor(0.03, 0.07, 0.12, 0.78)
    love.graphics.rectangle("fill", x - paddingX, y - paddingY, width + paddingX * 2, height + paddingY * 2, 16 * uiScale, 16 * uiScale)
    love.graphics.setColor(0.98, 0.8, 0.3, 0.9)
    love.graphics.rectangle("line", x - paddingX, y - paddingY, width + paddingX * 2, height + paddingY * 2, 16 * uiScale, 16 * uiScale)
    drawShadowedText(fonts.help, text, x, y, {0.92, 0.94, 0.98, 1})
end

local function drawActionButtons()
    if gameState ~= "game" then return end

    local buttons = getActionButtons()
    if #buttons == 0 then return end

    local mouseX, mouseY = love.mouse.getPosition()

    for _, button in ipairs(buttons) do
        local hovered = mouseX >= button.x and mouseX <= button.x + button.width and mouseY >= button.y and mouseY <= button.y + button.height
        local baseColor = {0.07, 0.12, 0.21, 0.82}
        local borderColor = {0.95, 0.78, 0.28, 0.95}
        local textColor = {0.93, 0.95, 0.99, 1}
        local subTextColor = {0.82, 0.86, 0.95, 0.92}

        if not button.enabled then
            baseColor = {0.04, 0.06, 0.1, 0.6}
            borderColor = {0.3, 0.36, 0.5, 0.8}
            textColor = {0.6, 0.68, 0.82, 0.9}
            subTextColor = {0.52, 0.58, 0.72, 0.85}
        elseif hovered then
            baseColor = {0.11, 0.18, 0.3, 0.9}
            borderColor = {1, 0.83, 0.36, 1}
        end

        local corner = 18 * uiScale
        love.graphics.setColor(baseColor)
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, corner, corner)

        love.graphics.setColor(borderColor)
        love.graphics.setLineWidth(2 * uiScale)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, corner, corner)
        love.graphics.setLineWidth(1)

        local labelFont = fonts.body
        local helpFont = fonts.help
        love.graphics.setFont(labelFont)
        local labelWidth = labelFont:getWidth(button.label)
        local labelX = button.x + (button.width - labelWidth) * 0.5
        local labelY = button.y + 14 * uiScale
        drawShadowedText(labelFont, button.label, labelX, labelY, textColor, {0, 0, 0, 0.55})

        if button.description then
            love.graphics.setFont(helpFont)
            local descWidth = helpFont:getWidth(button.description)
            local descHeight = helpFont:getHeight()
            local descX = button.x + (button.width - descWidth) * 0.5
            local descY = button.y + button.height - descHeight - 12 * uiScale
            drawShadowedText(helpFont, button.description, descX, descY, subTextColor, {0, 0, 0, 0.45})
        end
    end
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

local function activateMenuItem(index)
    local item = mainMenu:getItem(index)
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
    local panelPadding = 16 * uiScale
    local lineSpacing = fonts.score:getHeight() + 6 * uiScale

    local current = getCurrentPlayer()
    local lines = {}

    table.insert(lines, string.format("Turn: %s%s", current.name, current.isAI and " (AI)" or ""))
    table.insert(lines, string.format("Roll potential: %d", scores.roll))
    if selection.dice > 0 then
        if selection.valid then
            table.insert(lines, string.format("Selection: %d (%d dice)", selection.points, selection.dice))
        else
            table.insert(lines, string.format("Selection: invalid (%d dice)", selection.dice))
        end
    else
        table.insert(lines, "Selection: none")
    end

    table.insert(lines, string.format("Turn points: %d", turn.temp))
    table.insert(lines, string.format("Potential bank: %d", turn.temp + selection.points))
    table.insert(lines, "")

    for index, player in ipairs(players) do
        local marker
        if winnerIndex and index == winnerIndex then
            marker = "★"
        elseif not winnerIndex and index == turn.player then
            marker = "➤"
        else
            marker = " "
        end
        table.insert(lines, string.format("%s %s: %d", marker, player.name, player.banked))
    end

    if turn.lastOutcome then
        table.insert(lines, "")
        table.insert(lines, "Last: " .. turn.lastOutcome)
    end

    if winnerIndex then
        table.insert(lines, "")
        table.insert(lines, string.format("Goal: %d points", winningScore))
        table.insert(lines, "Click Play Again or Main Menu to decide your next move")
    end

    local textWidth = 0
    for _, line in ipairs(lines) do
        textWidth = math.max(textWidth, fonts.score:getWidth(line))
    end
    local bgWidth = textWidth + panelPadding * 2
    local bgHeight = lineSpacing * #lines + panelPadding * 2 - 6 * uiScale
    local x = 32 * uiScale
    local y = 36 * uiScale

    love.graphics.setColor(0.05, 0.1, 0.18, 0.82)
    love.graphics.rectangle("fill", x - panelPadding, y - panelPadding, bgWidth, bgHeight, 18 * uiScale, 18 * uiScale)
    love.graphics.setColor(0.98, 0.78, 0.32, 0.9)
    love.graphics.setLineWidth(2 * uiScale)
    love.graphics.rectangle("line", x - panelPadding, y - panelPadding, bgWidth, bgHeight, 18 * uiScale, 18 * uiScale)
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

    local ok, cursorOrErr = pcall(function()
        local hotspotX, hotspotY = 0, 0
        return love.mouse.newCursor("asset/cursorGauntlet.png", hotspotX, hotspotY)
    end)
    if ok and cursorOrErr then
        customCursor = cursorOrErr
        installCustomCursor()
    else
        customCursor = nil
    end

    diceImages = {}
    for value = 1, 6 do
        local path = string.format("asset/die%d.png", value)
        if love.filesystem.getInfo(path) then
            local image = love.graphics.newImage(path)
            image:setFilter("linear", "linear")
            table.insert(diceImages, image)
        end
    end

    loadSelectionParticleImages()

    if not loadDiceFramesFromAtlas() then
        buildDiceSpriteSheet()
    end

    love.window.setTitle("Neon Farkle Prototype")

    love.math.setRandomSeed(os.time())

    updateLayout()
    refreshFontsForScale(uiScale)
    love.graphics.setFont(fonts.help)
    startNewGame()
    setGameState("menu")
end

function love.resize()
    updateLayout()
    refreshFontsForScale(uiScale)
end

function love.focus(focused)
    if focused then
        installCustomCursor()
    end
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
    updateSelectionParticles(die, dt)
end

function love.update(dt)
    globalTime = globalTime + dt
    if gameState ~= "game" then
        mainMenu:update(dt)
    else
        if turn.pendingRoll and not winnerIndex then
            turn.pendingRollDelay = math.max(0, turn.pendingRollDelay - dt)
            if turn.pendingRollDelay <= 0 and diceAreIdle() then
                rollAllDice()
                if isAITurn() then
                    aiController:delayFor(0.6)
                end
            end
        end
        aiController:update(dt, buildAIContext())
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
        drawActionButtons()
    elseif gameState == "menu" then
        mainMenu:draw(fonts, drawShadowedText)
    elseif gameState == "options" then
        mainMenu:drawOptions(fonts, drawShadowedText)
    elseif gameState == "guide" then
        mainMenu:drawGuide(fonts, drawShadowedText)
    end
end

local function rollAllDice()
    if winnerIndex then return end
    turn.pendingRoll = false
    turn.pendingRollDelay = 0
    aiController:clearPending()
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
        local total = mainMenu:getItemCount()
        if total == 0 then return end

        if key == "w" or key == "up" then
            mainMenu:moveSelection(-1)
        elseif key == "s" or key == "down" then
            mainMenu:moveSelection(1)
        elseif key == "return" or key == "space" or key == "f" then
            activateMenuItem(mainMenu:getSelectedIndex())
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

    if winnerIndex then
        if key == "return" or key == "space" then
            startNewGame()
            return
        elseif key == "escape" then
            return
        else
            return
        end
    end

    if not isHumanTurn() then
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
    if turn.pendingRoll or winnerIndex then
        return false
    end
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

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        if button == 1 then
            local index = mainMenu:hitTest(x, y)
            if index then
                mainMenu:setSelection(index)
                activateMenuItem(index)
                return
            end
        end
        return
    elseif gameState == "options" or gameState == "guide" then
        if button == 1 or button == 2 then
            setGameState("menu")
        end
        return
    end

    if winnerIndex or not isHumanTurn() then
        return
    end

    if button ~= 1 then
        return
    end

    local buttons = getActionButtons()
    for _, actionButton in ipairs(buttons) do
        local inside = x >= actionButton.x and x <= actionButton.x + actionButton.width and y >= actionButton.y and y <= actionButton.y + actionButton.height
        if inside then
            if actionButton.enabled and actionButton.action then
                actionButton.action()
            end
            return
        end
    end

    toggleDieLock(x, y)
end

function love.mousemoved(x, y)
    if gameState ~= "menu" then return end
    mainMenu:onMouseMoved(x, y)
end
