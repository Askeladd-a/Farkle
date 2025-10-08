local Dice = require("lib.dice")
local scoring = require("lib.scoring")
local AIController = require("lib.ai")
local EmbeddedAssets = require("lib.embedded_assets")
local CrashReporter = require("lib.crash_reporter")
local Layout = require("src.layout")
local Render = require("src.render")

local table_insert = table.insert
local table_remove = table.remove

local game = {
    state = "menu",
    players = {
        {id = "player", name = "You", banked = 0, isAI = false},
        {id = "ai", name = "Baron von Farkle", banked = 0, isAI = true},
    },
    active = 1,
    diceLeft = 6,
    roundScore = 0,
    trays = {},
    rolls = {},
    kept = {},
    message = "",
    selection = {points = 0, dice = 0, valid = false},
    rolling = false,
    rollTimer = 0,
    winner = nil,
    buttons = {},
    showGuide = false,
    buttonsNeedRefresh = true, -- Flag per ottimizzare rebuild pulsanti
}

game.rolls.player = {}
game.rolls.ai = {}
game.kept.player = {}
game.kept.ai = {}

game.ai = AIController.new()
game.selectionImages = {}

game.layout = {
    board = {},
    trays = {},
    kept = {},
    hud = {},
    hingeY = 0,
    buttons = {},
    message = {},
}

local BUTTON_LABELS = {"Roll Dice", "Bank Points", "Guide", "Main Menu"}

local fonts = {}
local winningScore = 10000
local backgroundStripes = {}
local customCursor
local boardImage = nil

local function copyRect(rect)
    if not rect then
        return nil
    end
    return {x = rect.x, y = rect.y, w = rect.w, h = rect.h}
end

local function snapshotLayout()
    return {
        trays = {
            ai = copyRect(game.layout.trays.ai),
            player = copyRect(game.layout.trays.player),
        },
    }
end

local function realignDiceAfterLayout(oldLayout)
    local trays = game.layout.trays
    local previous = oldLayout and oldLayout.trays or {}
    for id, tray in pairs(trays) do
        local roll = game.rolls[id]
        if roll then
            Dice.recenterDice(roll, previous[id], tray)
        end
    end
end

local function getActivePlayer()
    return game.players[game.active]
end

local function currentRoll()
    return game.rolls[getActivePlayer().id]
end

local function currentKept()
    return game.kept[getActivePlayer().id]
end

local function resetSelection()
    game.selection = {points = 0, dice = 0, valid = false}
end

-- Forward declaration
local startRoll

local function setupStripes(height)
    backgroundStripes = {}
    local stripeHeight = 48
    local stripes = math.ceil(height / stripeHeight)
    for i = 1, stripes do
        backgroundStripes[i] = (i % 2 == 0)
    end
end

-- === LAYOUT COMPUTATION ===
-- Layout logic now in src/layout.lua

local resolvedCustomFontPath = nil
local loggedFontFallback = false

local function safeLoadFont(path, size)
    local ok, font = pcall(love.graphics.newFont, path, size)
    if ok and font then
        return font
    end
    return nil
end

local function findCustomFontPath()
    if resolvedCustomFontPath ~= nil then
        return resolvedCustomFontPath
    end

    local filesystem = love and love.filesystem
    if filesystem then
        local function checkCandidate(candidate)
            if filesystem.getInfo and filesystem.getInfo(candidate, "file") then
                resolvedCustomFontPath = candidate
                return true
            end
            return false
        end

        local predefinedCandidates = {
            "images/rothenbg.ttf",
            "images/Rothenbg.ttf",
            "images/rothenbg.otf",
            "images/Rothenbg.otf",
        }

        for _, candidate in ipairs(predefinedCandidates) do
            if checkCandidate(candidate) then
                return resolvedCustomFontPath
            end
        end

        if filesystem.getDirectoryItems then
            local ok, items = pcall(filesystem.getDirectoryItems, "images")
            if ok and items then
                for _, item in ipairs(items) do
                    local lower = item:lower()
                    if lower:find("rothenbg", 1, true) then
                        if lower:sub(-4) == ".ttf" or lower:sub(-4) == ".otf" then
                            local candidate = "images/" .. item
                            if checkCandidate(candidate) then
                                return resolvedCustomFontPath
                            end
                        end
                    end
                end
            end
        end
    end

    resolvedCustomFontPath = "images/rothenbg.ttf"
    return resolvedCustomFontPath
end

local function loadGameFont(size)
    local fontPath = findCustomFontPath()
    local font = safeLoadFont(fontPath, size)
    if font then
        return font
    end

    if not loggedFontFallback then
        print(string.format("[Font] Unable to load Rothenbg font at '%s'. Using default Love2D font.", tostring(fontPath)))
        loggedFontFallback = true
    end

    return love.graphics.newFont(size)
end

local function refreshFonts(width, height)
    local base = math.min(width, height)

    fonts.title = loadGameFont(math.max(48, math.floor(base * 0.07)))
    fonts.h2 = loadGameFont(math.max(28, math.floor(base * 0.04)))
    fonts.body = loadGameFont(math.max(20, math.floor(base * 0.028)))
    fonts.small = loadGameFont(math.max(16, math.floor(base * 0.022)))
    fonts.tiny = loadGameFont(math.max(12, math.floor(base * 0.018)))
end

-- === GAME STATE MANAGEMENT ===
local function resetTurn(newMessage)
    resetSelection()
    game.roundScore = 0
    game.diceLeft = 6
    game.rolls.player = {}
    game.rolls.ai = {}
    game.kept.player = {}
    game.kept.ai = {}
    game.rolling = false
    game.rollTimer = 0
    game.winner = nil
    game.message = newMessage or "Click Roll Dice to begin."
    game.ai:reset()
    game.buttonsNeedRefresh = true
end

local function startNewGame()
    for _, player in ipairs(game.players) do
        player.banked = 0
    end
    game.active = 1
    resetTurn("Click Roll Dice to begin.")
    game.state = "playing"
    game.winner = nil
    game.buttonsNeedRefresh = true
    -- Forza il ricalcolo del layout per evitare crash
    if love.graphics and love.graphics.getWidth then
        love.resize(love.graphics.getWidth(), love.graphics.getHeight())
    end
end

local function endTurn(msg)
    resetSelection()
    local currentPlayer = getActivePlayer()
    game.rolls[currentPlayer.id] = {}
    game.kept[currentPlayer.id] = {}
    game.roundScore = 0
    game.diceLeft = 6
    game.rolling = false
    game.rollTimer = 0
    game.ai:reset()
    local nextPrompt = nil
    local aiTurn = false
    if not game.winner then
        game.active = (game.active % #game.players) + 1
        local nextPlayer = getActivePlayer()
        if nextPlayer.isAI then
            nextPrompt = "Baron von Farkle is thinking..."
            aiTurn = true
        else
            nextPrompt = "Click Roll Dice to start your turn."
        end
    end

    if msg and msg ~= "" then
        if nextPrompt then
            game.message = msg .. "\n" .. nextPrompt
        else
            game.message = msg
        end
    else
        game.message = nextPrompt or ""
    end

    game.buttonsNeedRefresh = true

    if aiTurn then
        startRoll()
    end
end

local function handleBust()
    local current = getActivePlayer()
    if current.isAI then
        endTurn("Bust! Baron von Farkle loses the round.")
    else
        endTurn("Bust! You lose the round points.")
    end
end

local function refreshSelection()
    local roll = currentRoll()
    if not roll then return end
    
    local values = {}
    for _, die in ipairs(roll) do
        if die.locked and not die.isRolling then
            table_insert(values, die.value)
        end
    end
    local result = scoring.scoreSelection(values)
    game.selection.points = result.points or 0
    game.selection.valid = result.valid or false
    game.selection.dice = #values
    game.buttonsNeedRefresh = true
end

local function consumeSelection()
    refreshSelection()
    if not (game.selection.valid and game.selection.points > 0) then
        return false, 0
    end

    local roll = currentRoll()
    local keptList = currentKept()
    local removed = {}
    for index = #roll, 1, -1 do
        local die = roll[index]
        if die.locked and not die.isRolling then
            table_insert(removed, die.value)
            table_insert(keptList, die.value)
            table_remove(roll, index)
        end
    end

    game.roundScore = game.roundScore + game.selection.points
    game.diceLeft = game.diceLeft - #removed

    if game.diceLeft <= 0 then
        game.diceLeft = 6
        game.rolls[getActivePlayer().id] = {}
        game.kept[getActivePlayer().id] = {}
        game.message = "Hot dice! Roll all six again."
    else
        if getActivePlayer().isAI then
            game.message = string.format("Baron von Farkle keeps %d points.", game.selection.points)
        else
            game.message = string.format("Saved %d points. %d dice remain.", game.selection.points, game.diceLeft)
        end
    end

    resetSelection()
    game.buttonsNeedRefresh = true
    return true, #removed
end

startRoll = function()
    if game.rolling or game.diceLeft <= 0 or game.winner then
        return false
    end

    local tray = game.layout.trays[getActivePlayer().id]
    local roll = currentRoll()

    if #roll == 0 then
        for i = 1, game.diceLeft do
            local die = Dice.newDie(tray)
            die.locked = false
            die.isRolling = true
            die.particles = nil
            table_insert(roll, die)
        end
    else
        for _, die in ipairs(roll) do
            if not die.locked then
                die.isRolling = true
                die.particles = nil
            end
        end
    end

    game.rolling = true
    game.rollTimer = 0
    resetSelection()
    game.buttonsNeedRefresh = true
    return true
end

local function attemptRoll()
    if game.rolling then
        return false
    end

    if #currentRoll() == 0 then
        return startRoll()
    end

    local ok = consumeSelection()
    if not ok then
        if not getActivePlayer().isAI then
            game.message = "Only scoring dice can be kept."
        end
        return false
    end
    return startRoll()
end

local function bankRound()
    local player = getActivePlayer()
    if game.roundScore <= 0 then
        return false
    end
    player.banked = player.banked + game.roundScore
    if player.banked >= winningScore then
        game.winner = player
        game.message = string.format("%s wins with %d points!", player.name, player.banked)
    else
        if player.isAI then
            game.message = string.format("Baron von Farkle banks %d points.", game.roundScore)
        else
            game.message = string.format("You banked %d points.", game.roundScore)
        end
    end
    endTurn(game.message)
    return true
end

local function attemptBank()
    if game.rolling then
        return false
    end

    if game.selection.valid and game.selection.points > 0 then
        consumeSelection()
    end

    if game.roundScore > 0 then
        return bankRound()
    end

    return false
end

-- === ASSET LOADING ===
local function decodeCursor()
    local imageData = EmbeddedAssets.buildCursorImageData()
    if imageData then
        local ok, cursor = pcall(love.mouse.newCursor, imageData, 4, 4)
        if ok then
            customCursor = cursor
            love.mouse.setCursor(customCursor)
        end
    end
end

local function loadSelectionImages()
    game.selectionImages = EmbeddedAssets.buildLightImages() or {}
end

-- === PARTICLE EFFECTS ===
local function ensureParticles(die)
    if #game.selectionImages == 0 then
        return
    end
    if die.particles then
        return
    end
    local image = game.selectionImages[love.math.random(1, #game.selectionImages)]
    local ps = love.graphics.newParticleSystem(image, 64)
    ps:setEmitterLifetime(-1)
    ps:setParticleLifetime(0.3, 0.6)
    ps:setSpeed(8, 24)
    ps:setSizeVariation(0.45)
    ps:setLinearAcceleration(-12, -12, 12, 12)
    ps:setEmissionRate(18)
    ps:setSpread(math.pi)
    ps:setSizes(0.3, 0.05)
    ps:setColors(0.95, 0.85, 0.35, 0.8, 0.3, 0.5, 1, 0.25)
    ps:stop()
    die.particles = ps
end

local function updateParticles(die, dt)
    if not die.particles then
        return
    end
    if die.locked and not game.rolling then
        if not die.particles:isActive() then
            die.particles:reset()
            die.particles:start()
        end
    else
        die.particles:stop()
    end
    die.particles:update(dt)
end

local function drawParticles(die)
    if not die.particles then
        return
    end
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.draw(die.particles, die.x, die.y)
    love.graphics.setBlendMode("alpha")
end

-- === RENDERING ===
local function drawBackground()
    local width, height = love.graphics.getDimensions()
    love.graphics.clear(0.07, 0.06, 0.08)
    love.graphics.setColor(0.09, 0.08, 0.11)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(0.12, 0.1, 0.14, 0.25)
    local stripeHeight = 48
    for i = 0, #backgroundStripes - 1 do
        if i % 2 == 0 then
            love.graphics.rectangle("fill", 0, i * stripeHeight, width, stripeHeight)
        end
    end
end

local function drawBoard()
    local board = game.layout.board
    if boardImage and board.scale then
        love.graphics.setColor(1,1,1)
        love.graphics.draw(boardImage, board.x, board.y, 0, board.scale, board.scale)
    else
        love.graphics.setColor(0.26, 0.16, 0.09)
        love.graphics.rectangle("fill", board.x, board.y, board.w, board.h, 36, 36)
        love.graphics.setColor(0.15, 0.1, 0.06)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", board.x + 4, board.y + 4, board.w - 8, board.h - 8, 32, 32)
        love.graphics.setColor(0.18, 0.12, 0.07)
        love.graphics.setLineWidth(6)
        local hingeY = board.y + board.h * 0.68
        love.graphics.line(board.x + 60, hingeY, board.x + board.w - 60, hingeY)
    end
end

local function withScissor(rect, drawFn)
    if not rect then
        drawFn()
        return
    end

    local prevX, prevY, prevW, prevH = love.graphics.getScissor()
    love.graphics.setScissor(rect.x, rect.y, rect.w, rect.h)
    drawFn()
    if prevX then
        love.graphics.setScissor(prevX, prevY, prevW, prevH)
    else
        love.graphics.setScissor()
    end
end

local function drawTray(tray, clip)
    if not tray then
        return
    end

    local function drawOverlay()
        -- Semi-transparent trays so the wooden board shows through
        love.graphics.setColor(0.12, 0.08, 0.05, 0.75)
        love.graphics.rectangle("fill", tray.x, tray.y, tray.w, tray.h, 18, 18)
        love.graphics.setColor(0.12, 0.08, 0.05, 0.95)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", tray.x + 1, tray.y + 1, tray.w - 2, tray.h - 2, 18, 18)
    end

    withScissor(clip or tray, drawOverlay)
end

local function drawHUD()
    local hud = game.layout.hud
    local spacing = game.layout.hudSpacing or computeHudSpacing()
    love.graphics.setColor(0.13, 0.10, 0.08, 0.92)
    love.graphics.rectangle("fill", hud.x, hud.y, hud.w, hud.h, 18, 18)
    love.graphics.setColor(0.35, 0.27, 0.18)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", hud.x + 4, hud.y + 4, hud.w - 8, hud.h - 8, 14, 14)

    love.graphics.setFont(fonts.h2)
    love.graphics.setColor(0.98, 0.95, 0.85)
    local y = hud.y + spacing.paddingTop
    love.graphics.printf("SCOREBOARD", hud.x, y, hud.w, "center")

    y = y + spacing.titleHeight + spacing.headerGap
    local headerY = y
    local paddingX = math.max(18, hud.w * 0.06)
    local availableWidth = hud.w - paddingX * 2
    local colWidths = {
        availableWidth * 0.38,
        availableWidth * 0.22,
        availableWidth * 0.20,
        availableWidth * 0.20,
    }
    local colX = {
        hud.x + paddingX,
        hud.x + paddingX + colWidths[1],
        hud.x + paddingX + colWidths[1] + colWidths[2],
        hud.x + paddingX + colWidths[1] + colWidths[2] + colWidths[3],
    }
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.85, 0.82, 0.7)
    love.graphics.print("Player", colX[1], headerY)
    love.graphics.printf("Banked", colX[2], headerY, colWidths[2], "right")
    love.graphics.printf("Round", colX[3], headerY, colWidths[3], "right")
    love.graphics.printf("Selected", colX[4], headerY, colWidths[4], "right")

    local headerBottom = headerY + spacing.headerHeight
    local rowY = headerBottom + spacing.rowGap
    love.graphics.setColor(0.7, 0.85, 1.0)
    love.graphics.print(game.players[1].name, colX[1], rowY)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(game.players[1].banked), colX[2], rowY, colWidths[2], "right")
    love.graphics.setColor(0.72, 0.9, 0.9)
    love.graphics.printf(tostring(game.roundScore), colX[3], rowY, colWidths[3], "right")
    love.graphics.setColor(0.9, 0.75, 0.4)
    love.graphics.printf(tostring(game.selection.points), colX[4], rowY, colWidths[4], "right")

    rowY = rowY + spacing.rowHeight + spacing.rowGap
    love.graphics.setColor(1.0, 0.6, 0.55)
    love.graphics.print(game.players[2].name, colX[1], rowY)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(game.players[2].banked), colX[2], rowY, colWidths[2], "right")

    local row2Bottom = rowY + spacing.rowHeight

    rowY = rowY + spacing.rowHeight + spacing.rowGap
    love.graphics.setColor(0.95, 0.88, 0.45)
    love.graphics.print("Goal", colX[1], rowY)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(winningScore), colX[2], rowY, colWidths[2], "right")

    love.graphics.setColor(0.35, 0.27, 0.18, 0.7)
    love.graphics.setLineWidth(1)
    local line1Y = headerBottom + spacing.rowGap * 0.5
    local line2Y = row2Bottom + spacing.rowGap * 0.5
    love.graphics.line(hud.x + 12, line1Y, hud.x + hud.w - 12, line1Y)
    love.graphics.line(hud.x + 12, line2Y, hud.x + hud.w - 12, line2Y)
end

local function drawMessage()
    local messageLayout = game.layout.message
    love.graphics.setColor(0.1, 0.08, 0.06, 0.88)
    love.graphics.rectangle("fill", messageLayout.x, messageLayout.y, messageLayout.w, messageLayout.h, 14, 14)
    love.graphics.setColor(0.35, 0.27, 0.18)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", messageLayout.x + 4, messageLayout.y + 4, messageLayout.w - 8, messageLayout.h - 8, 12, 12)

    love.graphics.setFont(fonts.body)
    love.graphics.setColor(0.95, 0.92, 0.85)
    local padding = messageLayout.padding or 18
    love.graphics.printf(game.message, messageLayout.x + padding, messageLayout.y + padding, messageLayout.w - padding * 2, "center")
end

local function buttonEnabled(label)
    if game.state ~= "playing" or game.winner then
        return label == "Main Menu" or label == "Guide"
    end
    local player = getActivePlayer()
    if player.isAI then
        return label == "Guide" or label == "Main Menu"
    end
    if label == "Roll Dice" then
        if game.rolling then
            return false
        end
        if #currentRoll() == 0 then
            return game.diceLeft > 0
        end
        return game.selection.valid and game.selection.points > 0
    elseif label == "Bank Points" then
        if game.rolling then
            return false
        end
        if game.selection.valid and game.selection.points > 0 then
            return true
        end
        local function drawHUD()
            local spacing = game.layout.hudSpacing or computeHudSpacing()
            local huds = {game.layout.hudLeft, game.layout.hudRight}
            for _, hud in ipairs(huds) do
                if hud then
                    love.graphics.setColor(0.13, 0.10, 0.08, 0.92)
                    love.graphics.rectangle("fill", hud.x, hud.y, hud.w, hud.h, 18, 18)
                    love.graphics.setColor(0.35, 0.27, 0.18)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", hud.x + 4, hud.y + 4, hud.w - 8, hud.h - 8, 14, 14)

                    love.graphics.setFont(fonts.h2)
                    love.graphics.setColor(0.98, 0.95, 0.85)
                    local y = hud.y + spacing.paddingTop
                    love.graphics.printf("SCOREBOARD", hud.x, y, hud.w, "center")

                    y = y + spacing.titleHeight + spacing.headerGap
                    local headerY = y
                    local paddingX = math.max(18, hud.w * 0.06)
                    local availableWidth = hud.w - paddingX * 2
                    local colWidths = {
                        availableWidth * 0.38,
                        availableWidth * 0.22,
                        availableWidth * 0.20,
                        availableWidth * 0.20,
                    }
                    local colX = {
                        hud.x + paddingX,
                        hud.x + paddingX + colWidths[1],
                        hud.x + paddingX + colWidths[1] + colWidths[2],
                        hud.x + paddingX + colWidths[1] + colWidths[2] + colWidths[3],
                    }
                    love.graphics.setFont(fonts.small)
                    love.graphics.setColor(0.85, 0.82, 0.7)
                    love.graphics.print("Player", colX[1], headerY)
                    love.graphics.printf("Banked", colX[2], headerY, colWidths[2], "right")
                    love.graphics.printf("Round", colX[3], headerY, colWidths[3], "right")
                    love.graphics.printf("Selected", colX[4], headerY, colWidths[4], "right")

                    local headerBottom = headerY + spacing.headerHeight
                    local rowY = headerBottom + spacing.rowGap
                    love.graphics.setColor(0.7, 0.85, 1.0)
                    love.graphics.print(game.players[1].name, colX[1], rowY)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf(tostring(game.players[1].banked), colX[2], rowY, colWidths[2], "right")
                    love.graphics.setColor(0.72, 0.9, 0.9)
                    love.graphics.printf(tostring(game.roundScore), colX[3], rowY, colWidths[3], "right")
                    love.graphics.setColor(0.9, 0.75, 0.4)
                    love.graphics.printf(tostring(game.selection.points), colX[4], rowY, colWidths[4], "right")

                    rowY = rowY + spacing.rowHeight + spacing.rowGap
                    love.graphics.setColor(1.0, 0.6, 0.55)
                    love.graphics.print(game.players[2].name, colX[1], rowY)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf(tostring(game.players[2].banked), colX[2], rowY, colWidths[2], "right")

                    local row2Bottom = rowY + spacing.rowHeight

                    rowY = rowY + spacing.rowHeight + spacing.rowGap
                    love.graphics.setColor(0.95, 0.88, 0.45)
                    love.graphics.print("Goal", colX[1], rowY)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.printf(tostring(winningScore), colX[2], rowY, colWidths[2], "right")

                    love.graphics.setColor(0.35, 0.27, 0.18, 0.7)
                    love.graphics.setLineWidth(1)
                    local line1Y = headerBottom + spacing.rowGap * 0.5
                    local line2Y = row2Bottom + spacing.rowGap * 0.5
                    love.graphics.line(hud.x + 12, line1Y, hud.x + hud.w - 12, line1Y)
                    love.graphics.line(hud.x + 12, line2Y, hud.x + hud.w - 12, line2Y)
                end
            end
        end
    end
end

local function drawGuide()
    if not game.showGuide then
        return
    end
    local width, height = love.graphics.getDimensions()
    local panelWidth = math.min(520, width * 0.8)
    local panelHeight = math.min(420, height * 0.7)
    local x = (width - panelWidth) / 2
    local y = (height - panelHeight) / 2

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(0.15, 0.11, 0.08)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight, 16, 16)
    love.graphics.setColor(0.4, 0.3, 0.18)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x + 6, y + 6, panelWidth - 12, panelHeight - 12, 14, 14)

    love.graphics.setFont(fonts.h2)
    love.graphics.setColor(0.96, 0.92, 0.8)
    love.graphics.print("How to play", x + 24, y + 24)

    love.graphics.setFont(fonts.body)
    local lines = {
        "Roll Dice: throw the remaining dice for your turn.",
        "Select dice with scoring value, then use Roll Dice to keep them and throw again.",
        "Bank Points saves your accumulated round points and passes the turn.",
        "If you roll with no scoring dice you bust and lose the round's points.",
        "Score 10,000 points before Neon Bot to win.",
    }
    local ty = y + 80
    for _, line in ipairs(lines) do
        love.graphics.printf(line, x + 24, ty, panelWidth - 48, "left")
        ty = ty + fonts.body:getHeight() + 8
    end
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.9, 0.85, 0.75)
    love.graphics.printf("Click Guide again to close this panel.", x + 24, y + panelHeight - 48, panelWidth - 48, "center")
end

local function drawDice()
    local drawList = {}
    for _, die in ipairs(game.rolls.ai) do
        table_insert(drawList, die)
    end
    for _, die in ipairs(game.rolls.player) do
        table_insert(drawList, die)
    end
    table.sort(drawList, function(a, b)
        return a.y < b.y
    end)

    for _, die in ipairs(drawList) do
        if die.particles then
            drawParticles(die)
        end
        Dice.drawDie(die)
    end
end

-- === AI CONTEXT INTERFACE ===
local aiContext = {}

function aiContext.isActive()
    local player = getActivePlayer()
    return game.state == "playing" and player.isAI and not game.winner
end

function aiContext.hasWinner()
    return game.winner ~= nil
end

function aiContext.isRollPending()
    return game.rolling
end

function aiContext.diceAreIdle()
    if game.rolling then
        return false
    end
    for _, die in ipairs(currentRoll()) do
        if die.isRolling then
            return false
        end
    end
    return true
end

function aiContext.getSelection()
    refreshSelection()
    return game.selection
end

function aiContext.turnTemp()
    return game.roundScore
end

function aiContext.countRemainingDice()
    return game.diceLeft
end

function aiContext.playerBanked()
    return getActivePlayer().banked
end

function aiContext.winningScore()
    return winningScore
end

function aiContext.attemptRoll()
    attemptRoll()
end

function aiContext.attemptBank()
    attemptBank()
end

function aiContext.getDice()
    return currentRoll()
end

function aiContext.lockDice(indices)
    local roll = currentRoll()
    for _, index in ipairs(indices) do
        local die = roll[index]
        if die and not die.isRolling then
            die.locked = true
            ensureParticles(die)
        end
    end
    refreshSelection()
end

function aiContext.refreshScores()
    refreshSelection()
end

-- === GAME UPDATE LOOP ===
local function updateGame(dt)
    if game.state ~= "playing" then
        return
    end

    if game.rolling then
        game.rollTimer = game.rollTimer + dt
        Dice.updateRoll(currentRoll(), game.layout.trays[getActivePlayer().id], dt)
        if game.rollTimer >= 0.8 then
            local roll = currentRoll()
            local faces = {}
            for _, die in ipairs(roll) do
                die.isRolling = false
                table_insert(faces, die.value)
                ensureParticles(die)
            end
            Dice.arrangeScatter(game.layout.trays[getActivePlayer().id], roll)
            game.rolling = false
            game.rollTimer = 0
            resetSelection()
            if not scoring.hasAnyScoring(faces) then
                handleBust()
            else
                local player = getActivePlayer()
                if player.isAI then
                    game.message = "Baron von Farkle is thinking..."
                else
                    game.message = "Select scoring dice, then Roll or Bank."
                end
            end
            game.buttonsNeedRefresh = true
        end
    else
        for _, die in ipairs(currentRoll()) do
            updateParticles(die, dt)
        end
    end

    if getActivePlayer().isAI then
        game.ai:update(dt, aiContext)
    end
end

-- === MENU RENDERING ===
local function drawMenu()
    local width, height = love.graphics.getDimensions()
    love.graphics.setFont(fonts.title)
    love.graphics.setColor(0.95, 0.92, 0.85)
    love.graphics.printf("Farkle", 0, height * 0.25, width, "center")

    local options = {
        {label = "Start Game", action = startNewGame},
        {label = game.showGuide and "Close Guide" or "Guide", action = function()
            game.showGuide = not game.showGuide
        end},
        {label = "Quit", action = function()
            love.event.quit()
        end},
    }

    local buttonWidth = math.min(260, width * 0.4)
    local buttonHeight = 60
    local x = (width - buttonWidth) / 2
    local y = height * 0.45
    love.graphics.setFont(fonts.body)
    for _, option in ipairs(options) do
        love.graphics.setColor(0.32, 0.46, 0.7)
        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 12, 12)
        love.graphics.setColor(0.1, 0.12, 0.16)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, buttonWidth, buttonHeight, 12, 12)
        love.graphics.setColor(0.95, 0.98, 1.0)
        love.graphics.printf(option.label, x, y + buttonHeight / 2 - fonts.body:getHeight() / 2, buttonWidth, "center")
        option.x, option.y, option.w, option.h = x, y, buttonWidth, buttonHeight
        y = y + buttonHeight + 20
    end
    game.menuOptions = options
    if game.showGuide then
        drawGuide()
    end
end

-- === LOVE2D CALLBACKS ===
function love.load()
    local ok, err = pcall(function()
        CrashReporter.init()
        love.math.setRandomSeed(os.time())
        local width, height = love.graphics.getDimensions()
        refreshFonts(width, height)
        local ok_img, img = pcall(love.graphics.newImage, "images/wooden_board.png")
        if ok_img and img then
            boardImage = img
            print("Loaded wooden_board image: " .. img:getWidth() .. "x" .. img:getHeight())
        else
            print("wooden_board.png non trovato, useremo la board renderizzata")
        end
        game.layout = Layout.setupLayout(width, height, fonts, BUTTON_LABELS, boardImage)
        setupStripes(height)
        decodeCursor()
        loadSelectionImages()
        Dice.initAnimations()
        game.message = "Welcome back!"
    end)
    if not ok then
        print("[CRASH] love.load: " .. tostring(err))
        local f = io.open("crash_report.txt", "a")
        if f then f:write(os.date() .. " [love.load] " .. tostring(err) .. "\n"); f:close() end
    end
end

function love.update(dt)
    local ok, err = pcall(function()
        Dice.updateAnimations(dt)
        updateGame(dt)
    end)
    if not ok then
        print("[CRASH] love.update: " .. tostring(err))
        local f = io.open("crash_report.txt", "a")
        if f then f:write(os.date() .. " [love.update] " .. tostring(err) .. "\n"); f:close() end
    end
end

function love.draw()
    local ok, err = pcall(function()
        drawBackground()
        if game.state == "menu" then
            drawMenu()
            return
        end
        local layout = game.layout
        if not layout or not layout.board or layout.board.w < 50 or layout.board.h < 50 or layout.board.x < 0 or layout.board.y < 0 then
            love.graphics.setColor(0.2,0.2,0.2,1)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            love.graphics.setColor(1,1,1,1)
            love.graphics.print("Finestra troppo piccola!", 10, 10)
            return
        end
        Render.safeDrawBoard(boardImage, layout)
        -- Scoreboard overlay stile Gwent
        Render.drawScoreboard(layout, fonts, game)
        -- Log in angolo sinistro
        Render.drawLog(layout, fonts, game)
        -- Plancine traslucide centrati
        if layout.trays and layout.trays.ai and layout.trays.player then
            drawTray(layout.trays.ai, layout.trayClips and layout.trayClips.ai)
            drawTray(layout.trays.player, layout.trayClips and layout.trayClips.player)
        end
        -- Colonne dadi tenuti
        if layout.kept and layout.kept.ai and layout.kept.player then
            Dice.drawKeptColumn(layout.kept.ai, game.kept.ai, true)
            Dice.drawKeptColumn(layout.kept.player, game.kept.player, false)
        end
        -- Dadi
        drawDice()
        -- Tasti 2x2 grid a destra della board
        if layout.buttons then
            for _, btn in ipairs(layout.buttons) do
                btn.enabled = buttonEnabled(btn.label)
                local color = btn.enabled and {0.32, 0.46, 0.7, 0.92} or {0.32, 0.46, 0.7, 0.35}
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 12, 12)
                love.graphics.setColor(0.1, 0.12, 0.16)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 12, 12)
                love.graphics.setColor(0.95, 0.98, 1.0)
                love.graphics.setFont(fonts.body)
                love.graphics.printf(btn.label, btn.x, btn.y + btn.h / 2 - fonts.body:getHeight() / 2, btn.w, "center")
            end
        end
        drawGuide()
    end)
    if not ok then
        print("[CRASH] love.draw: " .. tostring(err))
        local f = io.open("crash_report.txt", "a")
        if f then f:write(os.date() .. " [love.draw] " .. tostring(err) .. "\n"); f:close() end
    end
end

local function inRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function love.mousepressed(x, y, button)
    local ok, err = pcall(function()
        if button ~= 1 then return end
        if game.state == "menu" then
            if game.menuOptions then
                for _, option in ipairs(game.menuOptions) do
                    if x >= option.x and x <= option.x + option.w and y >= option.y and y <= option.y + option.h then
                        local okBtn, errBtn = pcall(option.action)
                        if not okBtn then
                            print("[CRASH] menu button: " .. tostring(errBtn))
                            local f = io.open("crash_report.txt", "a")
                            if f then f:write(os.date() .. " [menu button] " .. tostring(errBtn) .. "\n"); f:close() end
                        end
                        return
                    end
                end
            end
            return
        end
        if game.showGuide then
            game.showGuide = false
            return
        end
        if game.layout and game.layout.buttons then
            for _, btn in ipairs(game.layout.buttons) do
                btn.enabled = buttonEnabled(btn.label)
                if btn.enabled and inRect(x, y, btn) then
                    if btn.label == "Roll Dice" then
                        attemptRoll()
                    elseif btn.label == "Bank Points" then
                        attemptBank()
                    elseif btn.label == "Guide" then
                        game.showGuide = not game.showGuide
                    elseif btn.label == "Main Menu" then
                        game.state = "menu"
                    end
                    return
                end
            end
        end
        if game.rolling or getActivePlayer().isAI or #currentRoll() == 0 then return end
        for _, die in ipairs(currentRoll()) do
            local dx = x - die.x
            local dy = y - die.y
            if dx * dx + dy * dy <= Dice.RADIUS * Dice.RADIUS then
                die.locked = not die.locked
                ensureParticles(die)
                refreshSelection()
                return
            end
        end
    end)
    if not ok then
        print("[CRASH] love.mousepressed: " .. tostring(err))
        local f = io.open("crash_report.txt", "a")
        if f then f:write(os.date() .. " [love.mousepressed] " .. tostring(err) .. "\n"); f:close() end
    end
end

function love.resize(width, height)
    local ok, err = pcall(function()
        local previousLayout = snapshotLayout()
        refreshFonts(width, height)
        game.layout = Layout.setupLayout(width, height, fonts, BUTTON_LABELS, boardImage)
        setupStripes(height)
        realignDiceAfterLayout(previousLayout)
    end)
    if not ok then
        print("[CRASH] love.resize: " .. tostring(err))
        local f = io.open("crash_report.txt", "a")
        if f then f:write(os.date() .. " [love.resize] " .. tostring(err) .. "\n"); f:close() end
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        -- Test del crash reporter (solo per debug)
        print("Test crash reporter...")
        CrashReporter.testCrash()
    elseif key == "f2" then
        -- Pulisci i log files (solo per debug)
        print("Pulizia log files...")
        CrashReporter.cleanupLogs()
    end
end