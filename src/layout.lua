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
    
    -- Minimum window size for proper layout
    local minWindowW = 1000
    local minWindowH = 680
    
    -- Scaled dimensions for calculations
    local effectiveW = math.max(windowW, minWindowW * windowW/minWindowW)
    local effectiveH = math.max(windowH, minWindowH * windowH/minWindowH)
    
    -- Board image size
    local boardW, boardH = 1024, 1024
    if boardImage and boardImage.getWidth then
        boardW = boardImage:getWidth()
        boardH = boardImage:getHeight()
    end
    
    -- Scale board to fit window, ensuring minimum size
    local scale = math.min(windowW * 0.55 / boardW, windowH * 0.85 / boardH)
    local board = {
        x = (windowW - boardW * scale) / 2,
        y = (windowH - boardH * scale) / 2,
        w = boardW * scale,
        h = boardH * scale,
        scale = scale
    }
    
    -- Store the window dimensions for the renderer
    local windowDimensions = {
        w = windowW,
        h = windowH,
        minW = minWindowW,
        minH = minWindowH,
        isSmall = (windowW < minWindowW) or (windowH < minWindowH)
    }
    -- 1) Plancine traslucide: adattate all'area delimitata dalla cornice dorata interna
    local innerFrame = {
        left = 162 / 1024,
        right = 862 / 1024,
        topTop = 118 / 1024,
        topBottom = 474 / 1024,
        bottomTop = 545 / 1024,
        bottomBottom = 905 / 1024,
    }
    local trayW = board.w * (innerFrame.right - innerFrame.left)
    local trayX = board.x + board.w * innerFrame.left
    local trayY_ai = board.y + board.h * innerFrame.topTop
    local trayH_ai = board.h * (innerFrame.topBottom - innerFrame.topTop)
    local trayY_player = board.y + board.h * innerFrame.bottomTop
    local trayH_player = board.h * (innerFrame.bottomBottom - innerFrame.bottomTop)

    local trayClip_ai = {
        x = trayX,
        y = trayY_ai,
        w = trayW,
        h = trayH_ai,
    }

    local trayClip_player = {
        x = trayX,
        y = trayY_player,
        w = trayW,
        h = trayH_player,
    }
    -- Colonne dei dadi tenuti
    local keptW_ai = trayW * 0.13
    local keptW_player = keptW_ai
    local kept_ai = {
        x = trayX,
        y = trayY_ai,
        w = keptW_ai,
        h = trayH_ai,
    }
    local kept_player = {
        x = trayX + trayW - keptW_player,
        y = trayY_player,
        w = keptW_player,
        h = trayH_player,
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
            ai = {x = trayX, y = trayY_ai, w = trayW, h = trayH_ai},
            player = {x = trayX, y = trayY_player, w = trayW, h = trayH_player},
        },
        trayClips = {
            ai = trayClip_ai,
            player = trayClip_player,
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
