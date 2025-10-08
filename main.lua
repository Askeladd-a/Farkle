local Dice = require("lib.dice")
local scoring = require("lib.scoring")
local AIController = require("lib.ai")
local EmbeddedAssets = require("lib.embedded_assets")

local table_insert = table.insert
local table_remove = table.remove

local game = {
    state = "menu",
    players = {
        {id = "player", name = "You", banked = 0, isAI = false},
        {id = "ai", name = "Neon Bot", banked = 0, isAI = true},
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

local fonts = {}
local winningScore = 10000
local backgroundStripes = {}
local customCursor

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

local function setupStripes(height)
    backgroundStripes = {}
    local stripeHeight = 48
    local stripes = math.ceil(height / stripeHeight)
    for i = 1, stripes do
        backgroundStripes[i] = (i % 2 == 0)
    end
end

local function computeHudSpacing()
    local smallHeight = fonts.small and fonts.small:getHeight() or 22
    local titleHeight = fonts.h2 and fonts.h2:getHeight() or 48
    local paddingTop = math.max(24, smallHeight * 0.9)
    local paddingBottom = math.max(28, smallHeight * 0.9)
    local headerGap = math.max(18, smallHeight * 0.6)
    local rowGap = math.max(16, smallHeight * 0.55)

    local spacing = {
        paddingTop = paddingTop,
        paddingBottom = paddingBottom,
        headerGap = headerGap,
        rowGap = rowGap,
        titleHeight = titleHeight,
        headerHeight = smallHeight,
        rowHeight = smallHeight,
    }

    spacing.totalHeight = spacing.paddingTop + spacing.titleHeight + spacing.headerGap
        + spacing.headerHeight + spacing.rowHeight * 3 + spacing.rowGap * 3 + spacing.paddingBottom

    return spacing
end

local function setupLayout(width, height)
    -- Board centrata, ma lasciamo spazio sopra per HUD e sotto per pulsanti
    local marginY = math.max(32, height * 0.08)
    local marginX = math.max(24, width * 0.05)

    local hudSpacing = computeHudSpacing()
    local hudWidth = math.min(math.max(360, width * 0.42), width - marginX * 2)
    local hudY = marginY
    game.layout.hud = {
        x = (width - hudWidth) / 2,
        y = hudY,
        w = hudWidth,
        h = hudSpacing.totalHeight,
    }
    game.layout.hudSpacing = hudSpacing

    local hudToBoardSpacing = math.max(40, height * 0.04)
    local footerSpace = 180
    local usableHeight = height - marginY * 2 - hudSpacing.totalHeight - hudToBoardSpacing - footerSpace
    local maxBoardHeight = math.max(usableHeight, height * 0.3)

    local boardWidth = math.min(width - marginX * 2, maxBoardHeight * (4 / 3))
    local boardHeight = boardWidth * (3 / 4)
    if boardHeight > maxBoardHeight then
        boardHeight = maxBoardHeight
        boardWidth = boardHeight * (4 / 3)
        if boardWidth > width - marginX * 2 then
            boardWidth = width - marginX * 2
            boardHeight = boardWidth * (3 / 4)
        end
    end
    local boardX = (width - boardWidth) / 2
    local boardY = hudY + hudSpacing.totalHeight + hudToBoardSpacing

    game.layout.board = {x = boardX, y = boardY, w = boardWidth, h = boardHeight}
    game.layout.hingeY = boardY + boardHeight * 0.68

    local trayWidth = boardWidth * 0.72
    local trayHeight = boardHeight * 0.18
    local trayX = boardX + (boardWidth - trayWidth) / 2
    local traySpacing = math.max(32, boardHeight * 0.08)

    game.layout.trays.ai = {
        x = trayX,
        y = boardY + traySpacing,
        w = trayWidth,
        h = trayHeight,
    }
    game.layout.trays.player = {
        x = trayX,
        y = boardY + boardHeight - trayHeight - traySpacing,
        w = trayWidth,
        h = trayHeight,
    }

    local keptSpacing = math.max(96, trayWidth * 0.18)
    game.layout.kept.ai = {
        x = trayX - keptSpacing,
        y = game.layout.trays.ai.y,
        w = keptSpacing - 16,
        h = trayHeight,
    }
    game.layout.kept.player = {
        x = trayX + trayWidth + 16,
        y = game.layout.trays.player.y,
        w = keptSpacing - 16,
        h = trayHeight,
    }

    -- Messaggio centrato sotto la board
    game.layout.message = {
        x = boardX + 32,
        y = boardY + boardHeight + 16,
        w = boardWidth - 64,
        h = 90,
    }

    -- Pulsanti a destra della board, centrati verticalmente rispetto alla board
    local buttonPanelW = 200
    local buttonPanelH = 4 * 56 + 3 * 18
    local buttonPanelX = boardX + boardWidth + math.max(24, width * 0.03)
    local buttonPanelY = boardY + (boardHeight - buttonPanelH) / 2
    game.layout.buttons = {
        x = buttonPanelX,
        y = buttonPanelY,
        w = buttonPanelW,
        h = 56,
        spacing = 18,
    }
end

local function refreshFonts(width, height)
    local base = math.min(width, height)
    fonts.title = love.graphics.newFont(math.max(48, math.floor(base * 0.07)))
    fonts.h2 = love.graphics.newFont(math.max(28, math.floor(base * 0.04)))
    fonts.body = love.graphics.newFont(math.max(20, math.floor(base * 0.028)))
    fonts.small = love.graphics.newFont(math.max(16, math.floor(base * 0.022)))
    fonts.tiny = love.graphics.newFont(math.max(12, math.floor(base * 0.018)))
end

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
end

local function startNewGame()
    for _, player in ipairs(game.players) do
        player.banked = 0
    end
    game.active = 1
    resetTurn("Click Roll Dice to begin.")
    game.state = "playing"
    game.winner = nil
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
    if not game.winner then
        game.active = (game.active % #game.players) + 1
        local nextPlayer = getActivePlayer()
        if nextPlayer.isAI then
            nextPrompt = "Neon Bot is thinking..."
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
end

local function handleBust()
    local current = getActivePlayer()
    if current.isAI then
        endTurn("Bust! Neon Bot loses the round.")
    else
        endTurn("Bust! You lose the round points.")
    end
end

local function refreshSelection()
    local roll = currentRoll()
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
            game.message = string.format("Neon Bot keeps %d points.", game.selection.points)
        else
            game.message = string.format("Saved %d points. %d dice remain.", game.selection.points, game.diceLeft)
        end
    end

    resetSelection()
    return true, #removed
end

local function startRoll()
    if game.rolling or game.diceLeft <= 0 or game.winner then
        return false
    end

    local tray = game.layout.trays[getActivePlayer().id]
    local roll = currentRoll()
    for i = 1, game.diceLeft do
        local die = Dice.newDie(tray)
        die.locked = false
        die.isRolling = true
        die.particles = nil
        table_insert(roll, die)
    end
    game.rolling = true
    game.rollTimer = 0
    resetSelection()
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
            game.message = string.format("Neon Bot banks %d points.", game.roundScore)
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
    love.graphics.setColor(0.26, 0.16, 0.09)
    love.graphics.rectangle("fill", board.x, board.y, board.w, board.h, 36, 36)
    love.graphics.setColor(0.15, 0.1, 0.06)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", board.x + 4, board.y + 4, board.w - 8, board.h - 8, 32, 32)
    love.graphics.setColor(0.18, 0.12, 0.07)
    love.graphics.setLineWidth(6)
    local hingeY = game.layout.hingeY
    love.graphics.line(board.x + 60, hingeY, board.x + board.w - 60, hingeY)
end

local function drawTray(tray)
    love.graphics.setColor(0.19, 0.12, 0.07)
    love.graphics.rectangle("fill", tray.x, tray.y, tray.w, tray.h, 24, 24)
    love.graphics.setColor(0.12, 0.08, 0.05)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", tray.x, tray.y, tray.w, tray.h, 24, 24)
end

local function drawHUD()
    local hud = game.layout.hud
    local spacing = game.layout.hudSpacing or computeHudSpacing()
    love.graphics.setColor(0.13, 0.10, 0.08, 0.92)
    love.graphics.rectangle("fill", hud.x, hud.y, hud.w, hud.h, 18, 18)
    love.graphics.setColor(0.35, 0.27, 0.18)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", hud.x + 4, hud.y + 4, hud.w - 8, hud.h - 8, 14, 14)

    -- Titolo
    love.graphics.setFont(fonts.h2)
    love.graphics.setColor(0.98, 0.95, 0.85)
    local y = hud.y + spacing.paddingTop
    love.graphics.printf("SCOREBOARD", hud.x, y, hud.w, "center")

    -- Header
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

    -- Riga 1: Player
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

    -- Riga 2: AI
    rowY = rowY + spacing.rowHeight + spacing.rowGap
    love.graphics.setColor(1.0, 0.6, 0.55)
    love.graphics.print(game.players[2].name, colX[1], rowY)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(game.players[2].banked), colX[2], rowY, colWidths[2], "right")
    -- Round e Selected per AI lasciati vuoti

    local row2Bottom = rowY + spacing.rowHeight

    -- Riga 3: Goal
    rowY = rowY + spacing.rowHeight + spacing.rowGap
    love.graphics.setColor(0.95, 0.88, 0.45)
    love.graphics.print("Goal", colX[1], rowY)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(winningScore), colX[2], rowY, colWidths[2], "right")

    -- Separatore
    love.graphics.setColor(0.35, 0.27, 0.18, 0.7)
    love.graphics.setLineWidth(1)
    local line1Y = headerBottom + spacing.rowGap * 0.5
    local line2Y = row2Bottom + spacing.rowGap * 0.5
    love.graphics.line(hud.x + 12, line1Y, hud.x + hud.w - 12, line1Y)
    love.graphics.line(hud.x + 12, line2Y, hud.x + hud.w - 12, line2Y)
end

local function drawMessage()
    love.graphics.setFont(fonts.body)
    love.graphics.setColor(0.95, 0.92, 0.85)
    love.graphics.printf(game.message, game.layout.message.x, game.layout.message.y, game.layout.message.w, "center")
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
        return game.roundScore > 0
    elseif label == "Guide" then
        return true
    elseif label == "Main Menu" then
        return true
    end
    return false
end

local function executeButton(label)
    if label == "Roll Dice" then
        attemptRoll()
    elseif label == "Bank Points" then
        attemptBank()
    elseif label == "Guide" then
        game.showGuide = not game.showGuide
    elseif label == "Main Menu" then
        game.state = "menu"
    end
end

local function rebuildButtons()
    game.buttons = {}
    local layout = game.layout.buttons
    local labels = {"Roll Dice", "Bank Points", "Guide", "Main Menu"}
    local y = layout.y
    for _, label in ipairs(labels) do
        local enabled = buttonEnabled(label)
        table_insert(game.buttons, {
            label = label,
            x = layout.x,
            y = y,
            w = layout.w,
            h = layout.h,
            enabled = enabled,
        })
        y = y + layout.h + layout.spacing
    end
end

local function drawButtons()
    rebuildButtons()
    for _, button in ipairs(game.buttons) do
        if button.enabled then
            love.graphics.setColor(0.34, 0.48, 0.72)
        else
            love.graphics.setColor(0.18, 0.24, 0.3)
        end
        love.graphics.rectangle("fill", button.x, button.y, button.w, button.h, 12, 12)
        love.graphics.setColor(0.1, 0.12, 0.16)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", button.x, button.y, button.w, button.h, 12, 12)
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(0.95, 0.98, 1.0)
        love.graphics.printf(button.label, button.x, button.y + button.h / 2 - fonts.small:getHeight() / 2, button.w, "center")
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
                    game.message = "Neon Bot is choosing dice."
                else
                    game.message = "Select scoring dice, then Roll or Bank."
                end
            end
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
            if love.system and love.system.getOS() == "Windows" then
                love.event.quit()
            else
                love.event.quit()
            end
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

function love.load()
    love.math.setRandomSeed(os.time())
    local width, height = love.graphics.getDimensions()
    refreshFonts(width, height)
    setupLayout(width, height)
    setupStripes(height)
    decodeCursor()
    loadSelectionImages()
    game.message = "Welcome back!"
end

function love.update(dt)
    updateGame(dt)
end

function love.draw()
    drawBackground()

    if game.state == "menu" then
        drawMenu()
        return
    end

    drawBoard()
    drawTray(game.layout.trays.ai)
    drawTray(game.layout.trays.player)

    Dice.drawKeptColumn(game.layout.trays.ai, game.kept.ai, true, false)
    Dice.drawKeptColumn(game.layout.trays.player, game.kept.player, false, true)

    drawDice()
    drawHUD()
    drawButtons()
    drawMessage()
    drawGuide()
end

local function inRect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if game.state == "menu" then
        if game.menuOptions then
            for _, option in ipairs(game.menuOptions) do
                if x >= option.x and x <= option.x + option.w and y >= option.y and y <= option.y + option.h then
                    option.action()
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

    for _, btn in ipairs(game.buttons) do
        if btn.enabled and inRect(x, y, btn) then
            executeButton(btn.label)
            return
        end
    end

    if game.rolling or getActivePlayer().isAI or #currentRoll() == 0 then
        return
    end

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
end

function love.resize(width, height)
    refreshFonts(width, height)
    setupLayout(width, height)
    setupStripes(height)
end
