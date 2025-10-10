local M = {}

local Dice = require("src.graphics.dice")
local DiceTypeUI = require("src.ui.dice_type_ui")

local function isoProject(x, y, z)
    local angle = math.rad(30)
    local x2d = (x - y) * math.cos(angle)
    local y2d = (x + y) * math.sin(angle) - (z or 0)
    return x2d, y2d
end

local BUTTON_KEY_HINTS = {
    ["Roll Dice"] = "Space / R",
    ["Bank Points"] = "B",
    ["Keep Dice"] = "K",
    ["Options"] = "O",
    ["Main Menu"] = "Esc"
}

function M.drawIsometricTray(tray)
    love.graphics.setColor(0.18, 0.12, 0.07, 0.18)
    love.graphics.rectangle("fill", tray.x, tray.y, tray.w, tray.h, 18, 18)
    love.graphics.setColor(0.35, 0.27, 0.18, 0.32)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", tray.x, tray.y, tray.w, tray.h, 14, 14)
end

function M.drawIsometricKeptColumn(kept, area)
    if not area or #kept == 0 then return end
    local spacing = math.min(Dice.SIZE + 16, math.floor(area.h / #kept))
    local startY = area.y + spacing * 0.5
    local centerX = area.x + area.w * 0.5
    for i, value in ipairs(kept) do
        local y = startY + (i - 1) * spacing
        Dice.drawDie({ value = value, x = centerX, y = y, z = 0, angle = 0, locked = true })
    end
end

function M.drawIsometricDice(roll)
    for _, die in ipairs(roll) do
        Dice.drawDie(die)
    end
end

function M.safeDrawBoard(boardImage, layout)
    local Dice = require("src.graphics.dice")
    if Dice.RENDER_MODE == "3d" and layout and layout.board3D then
        layout.board3D:draw()
    else
        if not boardImage or not layout or not layout.board then return end
        local board = layout.board
        if board.w < 50 or board.h < 50 or board.x < 0 or board.y < 0 then
            love.graphics.setColor(0.2,0.2,0.2,1)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            love.graphics.print("Finestra troppo piccola!", 10, 10)
            return
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(boardImage, board.x, board.y, 0, board.scale, board.scale)
    end
end

function M.drawScoreboard(layout, fonts, game)
    if not layout or not layout.hud or not game or not game.players then return end

    local topPanel = layout.hud.top
    local bottomPanel = layout.hud.bottom
    local playerHero = game.players[1]
    local playerVillain = game.players[2] or playerHero
    local activePlayer = game.players[game.active]

    local function drawPanel(panel, player, flavor, orientation)
        if not player or not panel then return end

        local isActive = (activePlayer == player)
        local panelBg = orientation == "bottom" and {0.06, 0.09, 0.14, 0.94} or {0.09, 0.07, 0.08, 0.94}
        local accent = orientation == "bottom" and {0.28, 0.52, 0.86, 0.9} or {0.82, 0.28, 0.28, 0.9}

        love.graphics.setColor(panelBg)
        love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 24, 24)

        love.graphics.setLineWidth(3)
        love.graphics.setColor(accent)
        love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, 24, 24)

        if isActive then
            love.graphics.setColor(accent[1], accent[2], accent[3], 0.25)
            love.graphics.setLineWidth(10)
            love.graphics.rectangle("line", panel.x + 6, panel.y + 6, panel.w - 12, panel.h - 12, 20, 20)
        end

        local portraitSize = math.min(panel.h * 0.68, 120)
        local portraitX = panel.x + panel.w * 0.035
        local portraitY = panel.y + panel.h * 0.5
        love.graphics.setColor(accent[1], accent[2], accent[3], 0.65)
        love.graphics.circle("fill", portraitX + portraitSize * 0.5, portraitY, portraitSize * 0.52)
        love.graphics.setColor(0, 0, 0, 0.35)
        love.graphics.circle("line", portraitX + portraitSize * 0.5, portraitY, portraitSize * 0.52)
        love.graphics.setColor(0.95, 0.9, 0.78, 0.9)
        love.graphics.circle("fill", portraitX + portraitSize * 0.5, portraitY, portraitSize * 0.42)

        local nameFont = fonts and fonts.h2 or love.graphics.getFont()
        local bodyFont = fonts and fonts.body or love.graphics.getFont()
        local smallFont = fonts and fonts.small or love.graphics.getFont()

        local textX = portraitX + portraitSize + panel.w * 0.04
        local textTop = panel.y + panel.h * 0.18

    -- Ombra per nome giocatore
    love.graphics.setFont(nameFont)
    love.graphics.setColor(0,0,0,0.55)
    love.graphics.print(player.name, textX+2, textTop+2)
    love.graphics.setColor(0.96, 0.93, 0.86)
    love.graphics.print(player.name, textX, textTop)

    -- Ombra per flavor
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0,0,0,0.45)
    love.graphics.print(flavor or "", textX+2, textTop + (smallFont:getHeight() + 8))
    love.graphics.setColor(0.68, 0.64, 0.98)
    love.graphics.print(flavor or "", textX, textTop + (smallFont:getHeight() + 6))

        -- Score column
        local scoreLabel = "Banked"
        local scoreValue = tostring(player.banked or 0)
    -- Prepara variabili per stampa
    local scoreLabelY = panel.y + panel.h * 0.18
    local scoreValueW = nameFont:getWidth(scoreValue)
    -- Ombra per score label
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.print(scoreLabel, panel.x + panel.w * 0.72 + 2, scoreLabelY + 2)
    love.graphics.setColor(0.78, 0.74, 0.96)
    love.graphics.print(scoreLabel, panel.x + panel.w * 0.72, scoreLabelY)

    -- Ombra per score value
    love.graphics.setFont(nameFont)
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.print(scoreValue, panel.x + panel.w * 0.72 + (panel.w * 0.24 - scoreValueW) * 0.5 + 2, scoreLabelY + smallFont:getHeight() + 10)
    love.graphics.setColor(0.98, 0.95, 0.81)
    love.graphics.print(scoreValue, panel.x + panel.w * 0.72 + (panel.w * 0.24 - scoreValueW) * 0.5, scoreLabelY + smallFont:getHeight() + 8)

        -- Secondary stats
        love.graphics.setFont(bodyFont)
        love.graphics.setColor(0.92, 0.88, 0.82)
        local statX = textX
        local statY = panel.y + panel.h * 0.55

        local stats = {}
        if isActive then
            table.insert(stats, {"Round Points", game.roundScore or 0})
            table.insert(stats, {"Dice Left", game.diceLeft or 0})
            if not player.isAI and game.selection and game.selection.valid then
                table.insert(stats, {"Selected", game.selection.points or 0})
            end
        else
            local keptCount = (game.kept and game.kept[player.id]) and #game.kept[player.id] or 0
            table.insert(stats, {"Kept Dice", keptCount})
            table.insert(stats, {"To Win", math.max(0, (game.winningScore or 0) - (player.banked or 0))})
        end

        love.graphics.setFont(smallFont)
        local valueBaseX = panel.x + panel.w * 0.52
        for i, pair in ipairs(stats) do
            local label, value = pair[1], pair[2]
            local lineY = statY + (i - 1) * (smallFont:getHeight() + 6)
            -- Ombra per label
            love.graphics.setColor(0,0,0,0.45)
            love.graphics.print(label, statX+2, lineY+2)
            love.graphics.setColor(0.72, 0.98, 0.6)
            love.graphics.print(label, statX, lineY)
            love.graphics.setFont(bodyFont)
            -- Ombra per value
            local valueText = tostring(value)
            love.graphics.setColor(0,0,0,0.45)
            love.graphics.print(valueText, valueBaseX+2, lineY - (bodyFont:getHeight() - smallFont:getHeight()) * 0.5 + 2)
            love.graphics.setColor(0.95, 0.92, 0.86)
            love.graphics.print(valueText, valueBaseX, lineY - (bodyFont:getHeight() - smallFont:getHeight()) * 0.5)
            love.graphics.setFont(smallFont)
        end

        -- Turn badge
        love.graphics.setFont(smallFont)
        local badgeText
        if isActive then
            badgeText = player.isAI and "AI TURN" or "YOUR TURN"
            love.graphics.setColor(accent[1], accent[2], accent[3], 0.9)
        else
            badgeText = "STANDBY"
            love.graphics.setColor(0.4, 0.38, 0.34, 0.9)
        end
        local badgeW = smallFont:getWidth(badgeText) + 24
        local badgeH = smallFont:getHeight() + 12
        local badgeX = panel.x + panel.w - badgeW - panel.w * 0.04
        local badgeY = panel.y + panel.h - badgeH - panel.h * 0.18
        love.graphics.rectangle("fill", badgeX, badgeY, badgeW, badgeH, 10, 10)
        love.graphics.setColor(0.05, 0.05, 0.06, 0.85)
        love.graphics.rectangle("line", badgeX, badgeY, badgeW, badgeH, 10, 10)
        love.graphics.setColor(0.98, 0.96, 0.9)
        love.graphics.print(badgeText, badgeX + 12, badgeY + (badgeH - smallFont:getHeight()) * 0.5)
        love.graphics.setLineWidth(1)
    end

    local topFlavor = playerVillain.isAI and "Dice Master" or "Challenger"
    local bottomFlavor = playerHero.isAI and "Automaton" or "Adventurer"
    drawPanel(topPanel, playerVillain, topFlavor, "top")
    drawPanel(bottomPanel, playerHero, bottomFlavor, "bottom")
end

function M.drawLog(layout, fonts, game)
    if not layout or not layout.log then return end
    local msgWidth = layout.log.w
    local msgHeight = layout.log.h
    local msgX = layout.log.x
    local msgY = layout.log.y

    love.graphics.setColor(0.07, 0.08, 0.1, 0.92)
    love.graphics.rectangle("fill", msgX, msgY, msgWidth, msgHeight, 16, 16)
    love.graphics.setColor(0.74, 0.6, 0.3, 0.85)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", msgX, msgY, msgWidth, msgHeight, 16, 16)

    local iconSize = math.min(36, msgHeight - 20)
    local ix = msgX + 16
    local iy = msgY + (msgHeight - iconSize) * 0.5
    love.graphics.setColor(0.94, 0.91, 0.82)
    love.graphics.rectangle("fill", ix, iy, iconSize, iconSize, 8, 8)
    love.graphics.setColor(0.18, 0.16, 0.14)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", ix, iy, iconSize, iconSize, 8, 8)
    love.graphics.circle("fill", ix + iconSize * 0.35, iy + iconSize * 0.35, iconSize * 0.1)
    love.graphics.circle("fill", ix + iconSize * 0.65, iy + iconSize * 0.65, iconSize * 0.1)

    local bodyFont = fonts and fonts.body or love.graphics.getFont()
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(0.97, 0.95, 0.9)
    local paddingLeft = 16 + iconSize + 18
    love.graphics.printf(game.message or "Press Roll Dice to begin.", msgX + paddingLeft, msgY + (msgHeight - bodyFont:getHeight()) / 2, msgWidth - paddingLeft - 24, "left")
    love.graphics.setLineWidth(1)
end

function M.drawActionButtons(layout, fonts, game)
    if not layout or not layout.buttons then return end
    local bodyFont = fonts and fonts.body or love.graphics.getFont()
    local smallFont = fonts and fonts.small or love.graphics.getFont()

    for _, btn in ipairs(layout.buttons) do
        local enabled = btn.enabled ~= false
        local bgColor = enabled and {0.18, 0.24, 0.32, 0.92} or {0.12, 0.12, 0.14, 0.7}
        local borderColor = enabled and {0.54, 0.62, 0.82, 0.95} or {0.32, 0.32, 0.36, 0.6}
        love.graphics.setColor(bgColor)
        love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 12, 12)
        love.graphics.setColor(borderColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 12, 12)

        love.graphics.setFont(bodyFont)
        love.graphics.setColor(0.95, 0.94, 0.92, enabled and 1 or 0.6)
        local textWidth = bodyFont:getWidth(btn.label)
        local textX = btn.x + (btn.w - textWidth) * 0.5
        local textY = btn.y + btn.h * 0.45 - bodyFont:getHeight() * 0.5
        love.graphics.print(btn.label, textX, textY)

        local hint = BUTTON_KEY_HINTS[btn.label]
        if hint then
            love.graphics.setFont(smallFont)
            love.graphics.setColor(0.78, 0.76, 0.7, enabled and 0.85 or 0.5)
            love.graphics.print(hint, btn.x + (btn.w - smallFont:getWidth(hint)) * 0.5, btn.y + btn.h - smallFont:getHeight() - 8)
        end
    end
    love.graphics.setLineWidth(1)
end

-- Disegna le statistiche dei tipi di dado (opzionale, per debug/info)
function M.drawDiceTypeStats(game, fonts, x, y, showStats)
    if not showStats or not fonts or not fonts.small then return end
    
    -- Trova il roll del giocatore attivo
    local activePlayer = game.players[game.active]
    if not activePlayer then return end
    
    local roll = game.rolls[activePlayer.id]
    if not roll or #roll == 0 then
        -- Mostra informazioni sui tipi di dado disponibili
        DiceTypeUI.drawDiceTypeInfo(x, y, fonts.small)
    else
        -- Mostra statistiche del roll corrente
        DiceTypeUI.drawRollStats(roll, x, y, fonts.small)
    end
end

-- Disegna tooltip per dado specifico (quando il mouse è sopra)
function M.drawDiceTooltip(die, mouseX, mouseY, fonts)
    if not die or not fonts or not fonts.tiny then return end
    
    DiceTypeUI.drawDiceTooltip(die, mouseX + 10, mouseY - 30, fonts.tiny)
end

return M
