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
    
    -- Scale board to fit window, prioritizing width ≈ 70–80% for stronger focus
    -- Use generous height cap to keep it tall when possible
    local targetBoardWidth = windowW * 0.76
    local targetBoardHeight = windowH * 0.9
    local scale = math.min(targetBoardWidth / boardW, targetBoardHeight / boardH)
    local function round(n) return math.floor(n + 0.5) end
    local board = {
        x = round((windowW - boardW * scale) / 2),
        y = round((windowH - boardH * scale) / 2),
        w = round(boardW * scale),
        h = round(boardH * scale),
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
        x = round(trayX),
        y = round(trayY_ai),
        w = round(trayW),
        h = round(trayH_ai),
    }

    local trayClip_player = {
        x = round(trayX),
        y = round(trayY_player),
        w = round(trayW),
        h = round(trayH_player),
    }
    -- Colonne dei dadi tenuti
    local keptW_ai = trayW * 0.13
    local keptW_player = keptW_ai
    local kept_ai = {
        x = round(trayX),
        y = round(trayY_ai),
        w = round(keptW_ai),
        h = round(trayH_ai),
    }
    local kept_player = {
        x = round(trayX + trayW - keptW_player),
        y = round(trayY_player),
        w = round(keptW_player),
        h = round(trayH_player),
    }
    -- 2) Tasti: 2x2 grid a destra della board
        -- Calcola dimensioni pulsanti in base alle etichette per evitare wrapping
        local bodyFont = (fonts and fonts.body) or love.graphics.newFont(20)
        local labelPaddingX = math.floor(math.max(24, windowW * 0.012))
        local labelPaddingY = math.floor(math.max(12, windowH * 0.008))
        local maxLabelW = 0
        for i = 1, 4 do
            local w = bodyFont:getWidth(BUTTON_LABELS[i] or "")
            if w > maxLabelW then maxLabelW = w end
        end
        local buttonW = math.ceil(math.min(math.max(maxLabelW + labelPaddingX * 2, 220 * scale), windowW * 0.2))
        local buttonH = math.ceil(math.min(math.max(bodyFont:getHeight() + labelPaddingY * 2, 56 * scale), windowH * 0.1))
        -- Gaps coerenti e allineamento su griglia
        local buttonGapX = math.floor(buttonW * 0.22)
        local buttonGapY = math.floor(buttonH * 0.22)
        local buttons = {}
        local paddingRight = math.floor(windowW * 0.04)
        local paddingBottom = math.floor(windowH * 0.06)
        -- Allinea il blocco dei pulsanti al bordo destro con margine costante
        local gridW = buttonW * 2 + buttonGapX
        local gridH = buttonH * 2 + buttonGapY
        local btnStartX = round(windowW - gridW - paddingRight)
        -- Centra verticalmente il blocco attorno al centro visivo della board
        local boardCenterY = board.y + board.h * 0.5
        local btnStartY = round(boardCenterY - gridH * 0.5)
        -- Garantisci che resti su schermo con padding inferiore
        btnStartY = math.min(btnStartY, windowH - gridH - paddingBottom)
        btnStartY = math.max(btnStartY, math.floor(windowH * 0.08))
        for i = 1, 4 do
            local col = ((i-1) % 2)
            local row = math.floor((i-1) / 2)
            buttons[i] = {
                x = round(btnStartX + col * (buttonW + buttonGapX)),
                y = round(btnStartY + row * (buttonH + buttonGapY)),
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
    local logW = round(board.w * 0.42)
    local logH = round(board.h * 0.12)
    local logX = round(board.x - logW * 0.08 - 480)    -- Sposta 12 cm (240px) a sinistra
    local logY = round(board.y + board.h * 0.82)
    -- Small options button (top-right corner)
    local optionsBtnSize = math.max(36, math.floor(windowW * 0.045))
    local optionsButton = {
        x = round(windowW - optionsBtnSize - paddingRight),
        y = round(math.max(12, windowH * 0.04)),
        w = optionsBtnSize,
        h = optionsBtnSize
    }
    -- Provide hinge position for other renderers (center between inner trays)
    board.hingeRatio = (innerFrame.topBottom + innerFrame.bottomTop) * 0.5
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
        optionsButton = optionsButton,
        scale = scale
    }
end

return M
