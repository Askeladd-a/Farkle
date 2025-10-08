-- Layout logic for Farkle
local M = {}

function M.computeHudSpacing(fonts)
    local smallHeight = fonts.small and fonts.small:getHeight() or 22
    local titleHeight = fonts.h2 and fonts.h2:getHeight() or 48
    local paddingTop = math.max(24, smallHeight * 0.9)
    local paddingBottom = math.max(28, smallHeight * 0.9)
    local headerGap = math.max(18, smallHeight * 0.6)
    local rowGap = math.max(16, smallHeight * 0.55)
    local headerHeight = titleHeight + headerGap
    local rowHeight = smallHeight + rowGap
    local totalHeight = paddingTop + headerHeight + rowHeight * 2 + rowGap * 2 + paddingBottom
    return {
        paddingTop = paddingTop,
        paddingBottom = paddingBottom,
        headerGap = headerGap,
        rowGap = rowGap,
        headerHeight = headerHeight,
        rowHeight = rowHeight,
        totalHeight = totalHeight
    }
end

function M.setupLayout(windowW, windowH, fonts, BUTTON_LABELS, boardImage)
    local hudSpacing = M.computeHudSpacing(fonts)
    -- Board image size
    local boardW, boardH = 1024, 1024
    if boardImage and boardImage.getWidth then
        boardW = boardImage:getWidth()
        boardH = boardImage:getHeight()
    end
    -- Scale board to fit window
    local scale = math.min(windowW / boardW, windowH / boardH)
    local board = {
        x = (windowW - boardW * scale) / 2,
        y = (windowH - boardH * scale) / 2,
        w = boardW * scale,
        h = boardH * scale,
        scale = scale
    }
    -- 1) Plancine traslucide: centrati e dentro la cornice dorata interna
    local frameMarginX = board.w * 0.015
    local frameMarginY = board.h * 0.015
    local trayW = board.w * 0.82
    local trayH = (board.h * 0.5) * 0.7
    local trayX = board.x + frameMarginX
    local trayY_ai = board.y + frameMarginY
    local trayY_player = board.y + board.h * 0.5 + frameMarginY * 0.5
    -- Colonne dei dadi tenuti
    local keptW, keptH = trayW * 0.13, trayH
    local kept_ai = {
        x = trayX,
        y = trayY_ai,
        w = keptW,
        h = keptH,
    }
    local kept_player = {
        x = trayX + trayW - keptW,
        y = trayY_player,
        w = keptW,
        h = keptH,
    }
    -- 2) Tasti: 2x2 grid a destra della board
        local buttonW = math.min(200 * scale, windowW * 0.13)
        local buttonH = math.min(70 * scale, windowH * 0.09)
        local buttonGapX = buttonW * 0.25
        local buttonGapY = buttonH * 0.25
        local buttons = {}
        local paddingRight = windowW * 0.04
        local paddingBottom = windowH * 0.06
        local btnStartX = windowW - (buttonW * 2 + buttonGapX) - paddingRight
        local btnStartY = windowH - (buttonH * 2 + buttonGapY) - paddingBottom
        for i = 1, 4 do
            local col = ((i-1) % 2)
            local row = math.floor((i-1) / 2)
            buttons[i] = {
                x = btnStartX + col * (buttonW + buttonGapX),
                y = btnStartY + row * (buttonH + buttonGapY),
                w = buttonW,
                h = buttonH,
                label = BUTTON_LABELS[i]
            }
        end
        -- Scoreboard overlays (verde): centrato orizzontalmente, padding verticale, overlay nei rettangoli verdi
        local scoreboard = {
            x = board.x + board.w * 0.5,
            y_ai = board.y + board.h * 0.04,
            y_player = board.y + board.h * 0.62,
            w = board.w * 0.7,
            h = board.h * 0.13
        }
        -- Log (bianco): in basso a sinistra, fuori dalla board
    local logW = board.w * 0.42
    local logH = board.h * 0.12
    local logX = board.x - logW * 0.08 - 480    -- Sposta 12 cm (240px) a sinistra
    local logY = board.y + board.h * 0.82
    return {
        board = board,
        trays = {
            ai = {x = trayX, y = trayY_ai, w = trayW, h = trayH},
            player = {x = trayX, y = trayY_player, w = trayW, h = trayH},
        },
        kept = {
            ai = kept_ai,
            player = kept_player,
        },
        buttons = buttons,
        scoreboard = scoreboard,
        log = {x = logX, y = logY, w = logW, h = logH},
        scale = scale
    }
end

return M
