-- Isometric projection utility
local function isoProject(x, y, z)
    local angle = math.rad(30)
    local x2d = (x - y) * math.cos(angle)
    local y2d = (x + y) * math.sin(angle) - (z or 0)
    return x2d, y2d
end
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

function M.setupLayout(windowW, windowH, fonts, BUTTON_LABELS, boardImage, overrideInnerFrame)
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
    if overrideInnerFrame then
        innerFrame.left = overrideInnerFrame.left or innerFrame.left
        innerFrame.right = overrideInnerFrame.right or innerFrame.right
        innerFrame.topTop = overrideInnerFrame.topTop or innerFrame.topTop
        innerFrame.topBottom = overrideInnerFrame.topBottom or innerFrame.topBottom
        innerFrame.bottomTop = overrideInnerFrame.bottomTop or innerFrame.bottomTop
        innerFrame.bottomBottom = overrideInnerFrame.bottomBottom or innerFrame.bottomBottom
    end
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
    -- HUD principale in stile Gwent
    local hudMarginX = math.floor(windowW * 0.06)
    local hudWidth = windowW - hudMarginX * 2
    local hudHeight = math.max(120, math.floor(windowH * 0.16))
    local hudGap = math.floor(windowH * 0.025)
    local hudTopY = math.max(24, board.y - hudHeight - hudGap)
    local hudBottomY = board.y + board.h + hudGap
    if hudBottomY + hudHeight + hudGap > windowH then
        hudBottomY = windowH - hudHeight - hudGap
        hudTopY = math.max(24, hudBottomY - hudHeight - hudGap)
    end
    local hud = {
        top = {
            x = hudMarginX,
            y = hudTopY,
            w = hudWidth,
            h = hudHeight
        },
        bottom = {
            x = hudMarginX,
            y = hudBottomY,
            w = hudWidth,
            h = hudHeight
        }
    }

    -- Pulsanti azione: disposti su barra dentro l'HUD inferiore
    local buttons = {}
    local buttonLabels = BUTTON_LABELS or {}
    local bodyFont = (fonts and fonts.body) or love.graphics.getFont()
    local paddingX = math.floor(math.max(28, hudWidth * 0.015))
    local paddingY = math.floor(math.max(16, hudHeight * 0.12))
    local buttonHeight = math.max(58, math.floor(hudHeight * 0.38))
    local gap = math.floor(math.max(18, hudWidth * 0.012))
    local totalWidth = -gap
    local buttonWidths = {}
    for i = 1, #buttonLabels do
        local label = buttonLabels[i] or ""
        local w = bodyFont:getWidth(label)
        local buttonW = math.min(math.max(w + paddingX * 2, 160), hud.bottom.w * 0.32)
        buttonWidths[i] = buttonW
        totalWidth = totalWidth + buttonW + gap
    end
    totalWidth = math.max(totalWidth, 0)
    local startX = hud.bottom.x + (hud.bottom.w - totalWidth) * 0.5
    local baseY = hud.bottom.y + hud.bottom.h - buttonHeight - paddingY
    for i = 1, #buttonLabels do
        buttons[i] = {
            x = round(startX),
            y = round(baseY),
            w = buttonWidths[i],
            h = buttonHeight,
            label = buttonLabels[i]
        }
        startX = startX + buttonWidths[i] + gap
    end

    -- Log (bianco): centrato sotto la board
    local logW = round(board.w * 0.62)
    local logH = round(math.max(72, board.h * 0.1))
    local logX = round(board.x + (board.w - logW) * 0.5)
    local logY = round(board.y + board.h + hudGap * 0.5)
    if logY + logH > hud.bottom.y - hudGap * 0.5 then
        logY = hud.bottom.y - logH - hudGap * 0.5
    end

    -- Pulsante opzioni rapido (in alto a destra)
    local optionsBtnSize = math.max(40, math.floor(windowW * 0.045))
    local optionsButton = {
        x = round(windowW - optionsBtnSize - math.floor(windowW * 0.035)),
        y = round(math.max(16, windowH * 0.045)),
        w = optionsBtnSize,
        h = optionsBtnSize
    }
    -- Provide hinge position for other renderers (center between inner trays)
    board.hingeRatio = (overrideInnerFrame and overrideInnerFrame.hingeRatio)
        or ((innerFrame.topBottom + innerFrame.bottomTop) * 0.5)
    -- Project tray and kept positions isometrically
    local trayIso_ai = {}
    local trayIso_player = {}
    local keptIso_ai = {}
    local keptIso_player = {}
    do
        local tx, ty = isoProject(trayX, trayY_ai, 0)
        trayIso_ai.x, trayIso_ai.y, trayIso_ai.w, trayIso_ai.h = tx, ty, trayW, trayH_ai
        tx, ty = isoProject(trayX, trayY_player, 0)
        trayIso_player.x, trayIso_player.y, trayIso_player.w, trayIso_player.h = tx, ty, trayW, trayH_player
        local kx, ky = isoProject(kept_ai.x, kept_ai.y, 0)
        keptIso_ai.x, keptIso_ai.y, keptIso_ai.w, keptIso_ai.h = kx, ky, kept_ai.w, kept_ai.h
        kx, ky = isoProject(kept_player.x, kept_player.y, 0)
        keptIso_player.x, keptIso_player.y, keptIso_player.w, keptIso_player.h = kx, ky, kept_player.w, kept_player.h
    end
    return {
        board = board,
        trays = {
            ai = trayIso_ai,
            player = trayIso_player,
        },
        trayClips = {
            ai = trayClip_ai,
            player = trayClip_player,
        },
        kept = {
            ai = keptIso_ai,
            player = keptIso_player,
        },
    buttons = buttons,
    hud = hud,
        log = {x = logX, y = logY, w = logW, h = logH},
        optionsButton = optionsButton,
        scale = scale,
        innerFrame = innerFrame
    }
end

return M
