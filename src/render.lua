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
    
    -- Gwent-style scoreboard
    local player1 = game.players[1] -- Human player
    local player2 = game.players[2] -- AI opponent
    
            -- Player's scoreboard positioned on the left side of the board
    local playerScore = {
        x = math.max(20, layout.board.x - layout.board.w * 0.30), -- Move further left of the board with minimum padding
        y = layout.board.y + layout.board.h * 0.65, -- Position in the lower part but not at the very bottom
        w = layout.board.w * 0.25,
        h = layout.board.h * 0.12
    }
    
    -- Semi-transparent dark background
    love.graphics.setColor(0.08, 0.06, 0.04, 0.85)
    love.graphics.rectangle("fill", playerScore.x, playerScore.y, playerScore.w, playerScore.h, 12, 12)
    
    -- Portrait background (darker circle)
    local portraitSize = playerScore.h * 0.8
    local portraitX = playerScore.x + portraitSize * 0.3
    local portraitY = playerScore.y + (playerScore.h - portraitSize) / 2
    
    love.graphics.setColor(0.05, 0.04, 0.03, 0.9)
    love.graphics.circle("fill", portraitX, portraitY + portraitSize/2, portraitSize/2)
    
    -- Player icon (simple silhouette)
    love.graphics.setColor(0.8, 0.75, 0.6)
    love.graphics.circle("fill", portraitX, portraitY + portraitSize/2, portraitSize/2 - 2)
    love.graphics.setColor(0.35, 0.3, 0.25)
    love.graphics.circle("line", portraitX, portraitY + portraitSize/2, portraitSize/2 - 2)
    
    -- Draw name and faction
    love.graphics.setFont(fonts.body)
    love.graphics.setColor(0.92, 0.84, 0.62) -- warm gold name
    love.graphics.print(player1.name, portraitX + portraitSize * 0.7, playerScore.y + playerScore.h * 0.2)
    
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.82, 0.78, 0.72) -- subtle light for role label
    love.graphics.print("Dice Roller", portraitX + portraitSize * 0.7, playerScore.y + playerScore.h * 0.6)
    
    -- Draw score in a fancy medallion
    local scoreX = playerScore.x + playerScore.w - portraitSize * 0.7
    local scoreY = playerScore.y + playerScore.h * 0.5 - portraitSize * 0.3
    
    -- Score background
    love.graphics.setColor(0.58, 0.42, 0.22, 0.92) -- bronze fill
    love.graphics.circle("fill", scoreX, scoreY, portraitSize * 0.35)
    love.graphics.setColor(0.86, 0.7, 0.36) -- bronze edge
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", scoreX, scoreY, portraitSize * 0.35)
    
    -- Draw the actual score
    love.graphics.setFont(fonts.h2)
    love.graphics.setColor(1, 1, 1)
    local scoreText = tostring(player1.banked)
    local textW = fonts.h2:getWidth(scoreText)
    love.graphics.print(scoreText, scoreX - textW/2, scoreY - fonts.h2:getHeight()/2)
    
    -- Current round score indicator
    if game.roundScore > 0 then
        local roundScoreX = scoreX - portraitSize * 0.5
        local roundScoreY = scoreY + portraitSize * 0.4
        
        love.graphics.setColor(0.98, 0.86, 0.38, 0.9) -- Gold tag
        love.graphics.circle("fill", roundScoreX, roundScoreY, portraitSize * 0.2)
        love.graphics.setColor(0.99, 0.92, 0.6) -- lighter gold edge
        love.graphics.circle("line", roundScoreX, roundScoreY, portraitSize * 0.2)
        
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(1, 1, 1)
        local roundText = tostring(game.roundScore)
        local roundW = fonts.small:getWidth(roundText)
        love.graphics.print(roundText, roundScoreX - roundW/2, roundScoreY - fonts.small:getHeight()/2)
    end
    
            -- AI's scoreboard positioned on the left side of the board, above the player's
    local aiScore = {
        x = math.max(20, layout.board.x - layout.board.w * 0.30), -- Match player's x-position
        y = layout.board.y + layout.board.h * 0.15, -- Position higher to avoid overlaps
        w = layout.board.w * 0.25,
        h = layout.board.h * 0.12
    }
    
    -- Semi-transparent dark background
    love.graphics.setColor(0.08, 0.06, 0.04, 0.85)
    love.graphics.rectangle("fill", aiScore.x, aiScore.y, aiScore.w, aiScore.h, 12, 12)
    
    -- Portrait background (darker circle)
    local aiPortraitX = aiScore.x + portraitSize * 0.3
    local aiPortraitY = aiScore.y + (aiScore.h - portraitSize) / 2
    
    love.graphics.setColor(0.05, 0.04, 0.03, 0.9)
    love.graphics.circle("fill", aiPortraitX, aiPortraitY + portraitSize/2, portraitSize/2)
    
    -- AI icon (simple silhouette - slightly different)
    love.graphics.setColor(0.7, 0.3, 0.3) -- Reddish for opponent
    love.graphics.circle("fill", aiPortraitX, aiPortraitY + portraitSize/2, portraitSize/2 - 2)
    love.graphics.setColor(0.4, 0.2, 0.2)
    love.graphics.circle("line", aiPortraitX, aiPortraitY + portraitSize/2, portraitSize/2 - 2)
    
    -- Draw name and faction
    love.graphics.setFont(fonts.body)
    love.graphics.setColor(0.92, 0.84, 0.62)
    love.graphics.print(player2.name, aiPortraitX + portraitSize * 0.7, aiScore.y + aiScore.h * 0.2)
    
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(0.82, 0.78, 0.72)
    love.graphics.print("Dice Master", aiPortraitX + portraitSize * 0.7, aiScore.y + aiScore.h * 0.6)
    
    -- Draw score in a fancy medallion
    local aiScoreX = aiScore.x + aiScore.w - portraitSize * 0.7
    local aiScoreY = aiScore.y + aiScore.h * 0.5 - portraitSize * 0.3
    
    -- Score background
    love.graphics.setColor(0.58, 0.42, 0.22, 0.92)
    love.graphics.circle("fill", aiScoreX, aiScoreY, portraitSize * 0.35)
    love.graphics.setColor(0.86, 0.7, 0.36)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", aiScoreX, aiScoreY, portraitSize * 0.35)
    
    -- Draw the actual score
    love.graphics.setFont(fonts.h2)
    love.graphics.setColor(1, 1, 1)
    local aiScoreText = tostring(player2.banked)
    local aiTextW = fonts.h2:getWidth(aiScoreText)
    love.graphics.print(aiScoreText, aiScoreX - aiTextW/2, aiScoreY - fonts.h2:getHeight()/2)
end

function M.drawLog(layout, fonts, game)
    -- Compact banner centered with left dice icon and brass frame
    local msgWidth = layout.board.w * 0.56
    local msgHeight = math.max(layout.board.h * 0.085, fonts.body:getHeight() + 24)
    local msgX = layout.board.x + (layout.board.w - msgWidth) / 2
    local msgY = layout.board.y + layout.board.h * 0.88

    -- Background and brass frame
    love.graphics.setColor(0.08, 0.07, 0.06, 0.95)
    love.graphics.rectangle("fill", msgX, msgY, msgWidth, msgHeight, 12, 12)
    love.graphics.setColor(0.60, 0.48, 0.25)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", msgX, msgY, msgWidth, msgHeight, 12, 12)
    love.graphics.setColor(0.74, 0.60, 0.30)
    love.graphics.rectangle("line", msgX+2, msgY+2, msgWidth-4, msgHeight-4, 10, 10)

    -- Dice icon (simple)
    local iconSize = math.min(22, msgHeight - 14)
    local ix = msgX + 12
    local iy = msgY + (msgHeight - iconSize) / 2
    love.graphics.setColor(0.96, 0.93, 0.82)
    love.graphics.rectangle("fill", ix, iy, iconSize, iconSize, 6, 6)
    love.graphics.setColor(0.25, 0.22, 0.18)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", ix, iy, iconSize, iconSize, 6, 6)
    love.graphics.circle("fill", ix + iconSize*0.35, iy + iconSize*0.35, 2.5)
    love.graphics.circle("fill", ix + iconSize*0.65, iy + iconSize*0.65, 2.5)

    -- Message text
    love.graphics.setFont(fonts.body)
    love.graphics.setColor(0.96, 0.92, 0.85)
    local paddingLeft = 12 + iconSize + 10
    love.graphics.printf(game.message or "Click Roll Dice to begin.", msgX + paddingLeft, msgY + (msgHeight - fonts.body:getHeight())/2, msgWidth - paddingLeft - 12, "left")
end

return M
