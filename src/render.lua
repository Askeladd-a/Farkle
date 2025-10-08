-- Rendering logic for Farkle
local M = {}

function M.safeDrawBoard(boardImage, layout)
    if not boardImage or not layout or not layout.board then return end
    local board = layout.board
    if board.w < 50 or board.h < 50 or board.x < 0 or board.y < 0 then
        love.graphics.setColor(0.2,0.2,0.2,1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("Finestra troppo piccola!", 10, 10)
        return
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(boardImage, board.x, board.y, 0, board.scale, board.scale)
end

function M.drawScoreboard(layout, fonts, game)
    local sb = layout.scoreboard
    if not sb then return end
    love.graphics.setFont(fonts.h2)
    -- AI
    love.graphics.setColor(0.18, 0.14, 0.09, 0.92)
    love.graphics.rectangle("fill", sb.x - sb.w/2, sb.y_ai, sb.w, sb.h, 18, 18)
    love.graphics.setColor(0.98, 0.95, 0.85)
    love.graphics.printf(game.players[2].name .. "  " .. tostring(game.players[2].banked), sb.x - sb.w/2 + 18, sb.y_ai + 18, sb.w - 36, "left")
    -- Player
    love.graphics.setColor(0.18, 0.14, 0.09, 0.92)
    love.graphics.rectangle("fill", sb.x - sb.w/2, sb.y_player, sb.w, sb.h, 18, 18)
    love.graphics.setColor(0.98, 0.95, 0.85)
    love.graphics.printf(game.players[1].name .. "  " .. tostring(game.players[1].banked), sb.x - sb.w/2 + 18, sb.y_player + 18, sb.w - 36, "left")
end

function M.drawLog(layout, fonts, game)
    local log = layout.log
    if not log then return end
    love.graphics.setColor(0.8,0.8,0.6,0.7)
    love.graphics.rectangle("fill", log.x, log.y, log.w, log.h, 8, 8)
    love.graphics.setColor(0,0,0,1)
    love.graphics.setFont(fonts.tiny)
    love.graphics.printf(game.message or "Log", log.x + 8, log.y + 8, log.w - 16, "left")
end

return M
