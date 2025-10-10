-- Menu principale moderno in stile Balatro
local M = {}
local VideoSettings = require("src.ui.video_settings")
local AudioSettings = require("src.ui.audio_settings")

local hoverIdx, focusIdx = nil, 1
local buttons = {}
local accentPulse = 0
local optionsDropdown = {
    open = false,
    items = {
        {id = "game", label = "GAME", onClick = function() print("GAME OPTIONS") end},
        {id = "video", label = "VIDEO", onClick = function() VideoSettings.open() end},
        {id = "graphics", label = "GRAPHICS", onClick = function() print("GRAPHICS OPTIONS") end},
        {id = "audio", label = "AUDIO", onClick = function() AudioSettings.open() end}
    },
    selectedIndex = 1,
    x = 0, y = 0, w = 150, h = 0
}

-- Colori del tema
local COLORS = {
    background = {0.05, 0.07, 0.12, 1},
    card = {0.08, 0.12, 0.18, 0.9},
    cardBorder = {0.25, 0.35, 0.55, 0.8},
    cardHover = {0.12, 0.16, 0.24, 0.95},
    accent = {0.98, 0.75, 0.32, 1},
    accentGlow = {0.98, 0.85, 0.45, 1},
    text = {0.92, 0.94, 0.98, 1},
    textShadow = {0.02, 0.02, 0.05, 0.8},
    play = {0.2, 0.5, 0.8, 1},         -- Blu
    options = {0.8, 0.5, 0.2, 1},      -- Arancione
    quit = {0.8, 0.2, 0.2, 1},         -- Rosso
    collectibles = {0.2, 0.7, 0.4, 1}, -- Verde
    dropdown = {0.1, 0.15, 0.22, 0.95},
    dropdownBorder = {0.3, 0.4, 0.6, 1},
    dropdownHover = {0.15, 0.2, 0.28, 1}
}

local function drawShadowedText(font, text, x, y, color, shadowColor)
    shadowColor = shadowColor or COLORS.textShadow
    -- Ombra
    love.graphics.setColor(shadowColor)
    love.graphics.setFont(font)
    love.graphics.print(text, x + 2, y + 2)
    -- Testo principale
    love.graphics.setColor(color or COLORS.text)
    love.graphics.print(text, x, y)
end

local function drawMenuCard(x, y, w, h, color, isHover, isFocus)
    -- Ombra della carta
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", x + 4, y + 6, w, h, 12, 12)
    
    -- Sfondo della carta
    love.graphics.setColor(isHover and COLORS.cardHover or COLORS.card)
    love.graphics.rectangle("fill", x, y, w, h, 12, 12)
    
    -- Bordo colorato
    love.graphics.setColor(color)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", x, y, w, h, 12, 12)
    
    -- Glow per focus/hover
    if isFocus or isHover then
        local glowAlpha = 0.6 + 0.3 * math.sin(accentPulse * 3)
        love.graphics.setColor(COLORS.accentGlow[1], COLORS.accentGlow[2], COLORS.accentGlow[3], glowAlpha * 0.5)
        love.graphics.setLineWidth(6)
        love.graphics.rectangle("line", x - 3, y - 3, w + 6, h + 6, 15, 15)
    end
    love.graphics.setLineWidth(1)
end

local function drawDropdown(fonts)
    if not optionsDropdown.open then return end
    
    -- Dimensioni dinamiche per il dropdown
    local width, height = love.graphics.getDimensions()
    local scale = math.min(width / 960, height / 640)
    local itemHeight = math.floor(40 * scale)
    optionsDropdown.h = #optionsDropdown.items * itemHeight
    optionsDropdown.w = math.floor(150 * scale)
    
    -- Sfondo dropdown
    love.graphics.setColor(COLORS.dropdown)
    love.graphics.rectangle("fill", optionsDropdown.x, optionsDropdown.y, optionsDropdown.w, optionsDropdown.h, 8, 8)
    
    -- Bordo dropdown
    love.graphics.setColor(COLORS.dropdownBorder)
    love.graphics.setLineWidth(math.max(1, scale))
    love.graphics.rectangle("line", optionsDropdown.x, optionsDropdown.y, optionsDropdown.w, optionsDropdown.h, 8, 8)
    
    -- Items del dropdown
    for i, item in ipairs(optionsDropdown.items) do
        local itemY = optionsDropdown.y + (i - 1) * itemHeight
        local isHover = (i == optionsDropdown.selectedIndex)
        
        -- Sfondo item se hover
        if isHover then
            love.graphics.setColor(COLORS.dropdownHover)
            love.graphics.rectangle("fill", optionsDropdown.x + 2, itemY + 2, optionsDropdown.w - 4, itemHeight - 4, 6, 6)
        end
        
        -- Testo item con padding dinamico
        if fonts and fonts.small then
            local textColor = isHover and COLORS.accentGlow or COLORS.text
            love.graphics.setColor(textColor)
            love.graphics.setFont(fonts.small)
            local textX = optionsDropdown.x + math.floor(10 * scale)
            local textY = itemY + (itemHeight - fonts.small:getHeight()) * 0.5
            love.graphics.print(item.label, textX, textY)
        end
    end
    
    love.graphics.setLineWidth(1)
end

function M.init()
    buttons = {
        {id = "play", label = "PLAY", color = COLORS.play, onClick = function(game) 
            print("[Menu] Starting new game...")
            if game then
                game.state = "playing"
                -- Inizializza una nuova partita
                M.startNewGame(game)
            end
        end},
        {id = "options", label = "OPTIONS", color = COLORS.options, onClick = function() 
            optionsDropdown.open = not optionsDropdown.open
        end},
        {id = "quit", label = "QUIT", color = COLORS.quit, onClick = function() love.event.quit() end},
        {id = "collectibles", label = "COLLECTIBLES", color = COLORS.collectibles, onClick = function() print("COLLECTION") end}
    }
    focusIdx = 1
end

function M.startNewGame(game)
    print("[Menu] Initializing new game state...")
    if not game then return end

    local GameState = require("src.game.state")
    if GameState and GameState.startNewGame then
        GameState.startNewGame()
    else
        game.state = "playing"
        game.message = "Your turn! Roll the dice!"
    end

    if game.board3D then
        game.board3D:setOpen(0)
        game.board3D:animateTo(1, 1.2)
        print("[Menu] Opening game board...")
    end

    game.buttonsNeedRefresh = true
    print("[Menu] Game initialized - Player starts first")
end

function M.update(dt)
    accentPulse = accentPulse + dt
    
    -- Update video settings animations
    VideoSettings.update(dt)
    
    -- Update audio settings animations
    AudioSettings.update(dt)
end

function M.draw(fonts)
    local width, height = love.graphics.getDimensions()
    
    -- Sfondo
    love.graphics.setColor(COLORS.background)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Titolo principale
    local title = "FARKLE"
    if fonts and fonts.title then
        local titleWidth = fonts.title:getWidth(title)
        local titleX = (width - titleWidth) * 0.5
        local titleY = height * 0.2
        drawShadowedText(fonts.title, title, titleX, titleY, COLORS.accent)
    end
    
    -- Sottotitolo
    local subtitle = "Dadi, rischio & fortuna"
    if fonts and fonts.h2 then
        local subtitleWidth = fonts.h2:getWidth(subtitle)
        local subtitleX = (width - subtitleWidth) * 0.5
        local subtitleY = height * 0.28
        drawShadowedText(fonts.h2, subtitle, subtitleX, subtitleY, COLORS.textSubtle)
    end
    
    -- Calcola layout responsivo
    local scale = math.min(width / 960, height / 640)
    local cardWidth = math.floor(180 * scale)
    local cardHeight = math.floor(60 * scale)
    local spacing = math.floor(25 * scale)
    local totalWidth = #buttons * cardWidth + (#buttons - 1) * spacing
    local startX = (width - totalWidth) * 0.5
    local startY = height * 0.45
    
    -- Disegna pulsanti principali
    for i, btn in ipairs(buttons) do
        local x = startX + (i - 1) * (cardWidth + spacing)
        local y = startY
        local isHover = (hoverIdx == i)
        local isFocus = (focusIdx == i)
        
        drawMenuCard(x, y, cardWidth, cardHeight, btn.color, isHover, isFocus)
        
        if fonts and fonts.body then
            local textColor = (isHover or isFocus) and COLORS.accentGlow or COLORS.text
            drawShadowedText(fonts.body, btn.label, x + 10, y + (cardHeight - fonts.body:getHeight()) * 0.5, textColor)
        end
        
        -- Memorizza posizione per click detection
        btn.x, btn.y, btn.w, btn.h = x, y, cardWidth, cardHeight
    end
    
    -- Disegna dropdown opzioni se aperto
    if optionsDropdown.open then
        drawDropdown(fonts)
    end
    
    -- Disegna finestre impostazioni
    VideoSettings.draw(fonts)
    AudioSettings.draw(fonts)
end

function M.mousepressed(x, y, button, game)
    if button ~= 1 then return end
    
    -- Priorità alle finestre impostazioni se aperte
    if VideoSettings.isOpen() then
        return VideoSettings.mousepressed(x, y, button)
    end
    
    if AudioSettings.isOpen() then
        return AudioSettings.mousepressed(x, y, button)
    end
    
    -- Controlla click sul dropdown se aperto
    if optionsDropdown.open then
        if optionsDropdown.x and optionsDropdown.y and optionsDropdown.w and optionsDropdown.h and
           x >= optionsDropdown.x and x <= optionsDropdown.x + optionsDropdown.w and 
           y >= optionsDropdown.y and y <= optionsDropdown.y + optionsDropdown.h then
            local width, height = love.graphics.getDimensions()
            local scale = math.min(width / 960, height / 640)
            local itemHeight = math.floor(40 * scale)
            local clickedIndex = math.floor((y - optionsDropdown.y) / itemHeight) + 1
            if clickedIndex >= 1 and clickedIndex <= #optionsDropdown.items then
                local item = optionsDropdown.items[clickedIndex]
                if item.onClick then item.onClick() end
                optionsDropdown.open = false
                return true
            end
        else
            -- Click fuori dal dropdown, chiudilo
            optionsDropdown.open = false
        end
    end
    
    -- Controlla click sui pulsanti principali
    for i, btn in ipairs(buttons) do
        if btn.x and btn.y and btn.w and btn.h and
           x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            focusIdx = i
            if btn.onClick then 
                btn.onClick(game) -- Pass game parameter to onClick
            end
            return true
        end
    end
    return false
end

function M.keypressed(key, game)
    -- Priorità alle finestre impostazioni se aperte
    if VideoSettings.isOpen() then
        return VideoSettings.keypressed(key)
    end
    
    if AudioSettings.isOpen() then
        return AudioSettings.keypressed(key)
    end
    
    if optionsDropdown.open then
        -- Navigazione nel dropdown
        if key == "up" then
            optionsDropdown.selectedIndex = math.max(1, optionsDropdown.selectedIndex - 1)
        elseif key == "down" then
            optionsDropdown.selectedIndex = math.min(#optionsDropdown.items, optionsDropdown.selectedIndex + 1)
        elseif key == "return" or key == "space" then
            local item = optionsDropdown.items[optionsDropdown.selectedIndex]
            if item and item.onClick then
                item.onClick()
            end
            optionsDropdown.open = false
        elseif key == "escape" then
            optionsDropdown.open = false
        end
        return
    end
    
    -- Navigazione menu principale
    if key == "return" or key == "space" then
        local btn = buttons[focusIdx]
        if btn and btn.onClick then btn.onClick(game) end
    elseif key == "right" then
        focusIdx = math.min(#buttons, focusIdx + 1)
    elseif key == "left" then
        focusIdx = math.max(1, focusIdx - 1)
    elseif key == "escape" then
        love.event.quit()
    end
end

function M.mousemoved(x, y)
    -- Priorità alle finestre impostazioni se aperte
    if VideoSettings.isOpen() then
        VideoSettings.mousemoved(x, y)
        return
    end
    
    if AudioSettings.isOpen() then
        AudioSettings.mousemoved(x, y)
        return
    end
    
    -- Aggiorna hover per dropdown se aperto
    if optionsDropdown.open then
        if optionsDropdown.x and optionsDropdown.y and optionsDropdown.w and optionsDropdown.h and
           x >= optionsDropdown.x and x <= optionsDropdown.x + optionsDropdown.w and 
           y >= optionsDropdown.y and y <= optionsDropdown.y + optionsDropdown.h then
            local width, height = love.graphics.getDimensions()
            local scale = math.min(width / 960, height / 640)
            local itemHeight = math.floor(40 * scale)
            local hoverIndex = math.floor((y - optionsDropdown.y) / itemHeight) + 1
            if hoverIndex >= 1 and hoverIndex <= #optionsDropdown.items then
                optionsDropdown.selectedIndex = hoverIndex
            end
        end
        return
    end
    
    -- Aggiorna hover per pulsanti principali
    hoverIdx = nil
    for i, btn in ipairs(buttons) do
        if btn.x and btn.y and btn.w and btn.h and
           x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            hoverIdx = i
            break
        end
    end
end

function M.mousereleased(x, y, button)
    -- Gestisci rilascio mouse per audio settings (slider)
    if AudioSettings.isOpen() then
        return AudioSettings.mousereleased(x, y, button)
    end
    return false
end

return M
