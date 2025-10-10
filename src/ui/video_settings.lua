-- Video Settings Window (Enhanced)
local VideoSettings = {}

local window = {
    open = false,
    x = 0, y = 0, w = 520, h = 480,
    title = "Video Settings",
    animation = 0,
    targetAnimation = 0
}

local settings = {
    resolutions = {
        {w = 800, h = 600, name = "800x600"},
        {w = 960, h = 640, name = "960x640 (Default)"},
        {w = 1280, h = 720, name = "1280x720 (HD)"},
        {w = 1920, h = 1080, name = "1920x1080 (Full HD)"},
        {w = 2560, h = 1440, name = "2560x1440 (QHD)"}
    },
    selectedResolution = 2,
    fullscreen = false,
    vsync = true,
    hoverElement = nil,
    previewMode = false
}

-- Enhanced color theme for better readability
local COLORS = {
    background = {0.05, 0.08, 0.12, 0.98},
    border = {0.35, 0.45, 0.65, 0.9},
    button = {0.15, 0.20, 0.30, 0.95},
    buttonHover = {0.25, 0.35, 0.50, 1.0},
    buttonActive = {0.2, 0.6, 0.9, 0.95},
    text = {0.95, 0.97, 1.0, 1},
    textActive = {1.0, 0.8, 0.4, 1},
    textSubtle = {0.75, 0.8, 0.9, 1},
    checkbox = {0.2, 0.8, 0.5, 1},
    checkboxUnchecked = {0.5, 0.5, 0.5, 1},
    accent = {0.4, 0.8, 1.0, 1},
    warning = {1.0, 0.8, 0.3, 1},
    shadow = {0, 0, 0, 0.4}
}

local function drawButton(x, y, w, h, text, isHover, isActive, font, alpha)
    alpha = alpha or 1
    
    -- Background with enhanced depth for hover
    local color = isActive and COLORS.buttonActive or (isHover and COLORS.buttonHover or COLORS.button)
    
    -- Button shadow for depth
    if isHover or isActive then
        love.graphics.setColor(COLORS.shadow[1], COLORS.shadow[2], COLORS.shadow[3], 0.3 * alpha)
        love.graphics.rectangle("fill", x + 2, y + 2, w, h, 6, 6)
    end
    
    love.graphics.setColor(color[1], color[2], color[3], color[4] * alpha)
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)
    
    -- Glow effect for hover (subtle)
    if isHover and not isActive then
        love.graphics.setColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.2 * alpha)
        love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2, 7, 7)
        love.graphics.setColor(color[1], color[2], color[3], color[4] * alpha)
        love.graphics.rectangle("fill", x, y, w, h, 6, 6)
    end
    
    -- Enhanced border
    love.graphics.setColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], (COLORS.border[4] + 0.2) * alpha)
    love.graphics.setLineWidth(isHover and 2 or 1)
    love.graphics.rectangle("line", x, y, w, h, 6, 6)
    
    -- Text with better contrast
    if font then
        love.graphics.setFont(font)
        local textColor = isActive and COLORS.textActive or COLORS.text
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight()
        
        -- Text shadow for better readability
        love.graphics.setColor(0, 0, 0, 0.6 * alpha)
        love.graphics.print(text, x + (w - textWidth) / 2 + 1, y + (h - textHeight) / 2 + 1)
        
        -- Main text
        love.graphics.setColor(textColor[1], textColor[2], textColor[3], textColor[4] * alpha)
        love.graphics.print(text, x + (w - textWidth) / 2, y + (h - textHeight) / 2)
    end
end

local function drawCheckbox(x, y, size, checked, font, label, alpha)
    alpha = alpha or 1
    
    -- Box
    local boxColor = checked and COLORS.checkbox or COLORS.checkboxUnchecked
    love.graphics.setColor(boxColor[1], boxColor[2], boxColor[3], boxColor[4] * alpha)
    love.graphics.rectangle("fill", x, y, size, size, 3, 3)
    
    -- Border
    love.graphics.setColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], COLORS.border[4] * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, size, size, 3, 3)
    
    -- Checkmark
    if checked then
        love.graphics.setColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], COLORS.text[4] * alpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(x + 3, y + size/2, x + size/2, y + size - 3)
        love.graphics.line(x + size/2, y + size - 3, x + size - 3, y + 3)
    end
    
    -- Label
    if font and label then
        love.graphics.setFont(font)
        love.graphics.setColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], COLORS.text[4] * alpha)
        love.graphics.print(label, x + size + 10, y + (size - font:getHeight()) / 2)
    end
end

function VideoSettings.open()
    window.open = true
    window.targetAnimation = 1
    
    -- Better window centering with padding
    local screenW, screenH = love.graphics.getDimensions()
    window.x = math.floor((screenW - window.w) / 2)
    window.y = math.floor((screenH - window.h) / 2.2) -- Slightly higher for better visual balance
    
    -- Load current settings from Settings system
    local Settings = require("src.core.settings")
    local videoSettings = Settings.getCategory("video")
    
    -- Find matching resolution
    for i, res in ipairs(settings.resolutions) do
        if res.w == videoSettings.width and res.h == videoSettings.height then
            settings.selectedResolution = i
            break
        end
    end
    
    settings.fullscreen = videoSettings.fullscreen
    settings.vsync = videoSettings.vsync
    settings.hoverElement = nil
    
    print("[VideoSettings] Loaded settings - Resolution:", videoSettings.width .. "x" .. videoSettings.height, "Fullscreen:", videoSettings.fullscreen)
end

function VideoSettings.close()
    window.targetAnimation = 0
end

function VideoSettings.update(dt)
    if window.open then
        -- Animation
        if window.animation < window.targetAnimation then
            window.animation = math.min(window.targetAnimation, window.animation + dt * 4)
        elseif window.animation > window.targetAnimation then
            window.animation = math.max(window.targetAnimation, window.animation - dt * 4)
            if window.animation <= 0 then
                window.open = false
            end
        end
    end
end

function VideoSettings.isOpen()
    return window.open
end

function VideoSettings.mousemoved(x, y)
    if not window.open then return false end
    
    settings.hoverElement = nil
    
    -- Check resolution buttons
    for i, res in ipairs(settings.resolutions) do
        if res.clickArea and x >= res.clickArea.x and x <= res.clickArea.x + res.clickArea.w and
           y >= res.clickArea.y and y <= res.clickArea.y + res.clickArea.h then
            settings.hoverElement = "resolution_" .. i
            return true
        end
    end
    
    -- Check apply/cancel buttons
    if settings.applyArea and x >= settings.applyArea.x and x <= settings.applyArea.x + settings.applyArea.w and
       y >= settings.applyArea.y and y <= settings.applyArea.y + settings.applyArea.h then
        settings.hoverElement = "apply"
        return true
    end
    
    if settings.cancelArea and x >= settings.cancelArea.x and x <= settings.cancelArea.x + settings.cancelArea.w and
       y >= settings.cancelArea.y and y <= settings.cancelArea.y + settings.cancelArea.h then
        settings.hoverElement = "cancel"
        return true
    end
    
    return false
end

function VideoSettings.draw(fonts)
    if not window.open then return end
    
    local animScale = window.animation
    local animAlpha = window.animation
    
    -- Animated overlay
    love.graphics.setColor(0, 0, 0, 0.7 * animAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    
    -- Calculate animated position (scale from center)
    local centerX = window.x + window.w / 2
    local centerY = window.y + window.h / 2
    local scaledW = window.w * animScale
    local scaledH = window.h * animScale
    local scaledX = centerX - scaledW / 2
    local scaledY = centerY - scaledH / 2
    
    -- Enhanced window shadow with blur effect
    for i = 1, 4 do
        local offset = i * 2
        local shadowAlpha = (0.2 - i * 0.04) * animAlpha
        love.graphics.setColor(COLORS.shadow[1], COLORS.shadow[2], COLORS.shadow[3], shadowAlpha)
        love.graphics.rectangle("fill", scaledX + offset, scaledY + offset, scaledW, scaledH, 8, 8)
    end
    
    -- Main window with enhanced background
    love.graphics.setColor(COLORS.background[1], COLORS.background[2], COLORS.background[3], COLORS.background[4] * animAlpha)
    love.graphics.rectangle("fill", scaledX, scaledY, scaledW, scaledH, 8, 8)
    
    -- Enhanced window border
    love.graphics.setColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], COLORS.border[4] * animAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", scaledX, scaledY, scaledW, scaledH, 8, 8)
    
    -- Content (only if animation is advanced enough)
    if animScale > 0.3 then
        local contentAlpha = math.min(1, (animScale - 0.3) / 0.7)
        
        -- Title with glow effect
        if fonts and fonts.h2 then
            love.graphics.setFont(fonts.h2)
            
            -- Glow effect
            love.graphics.setColor(COLORS.textActive[1], COLORS.textActive[2], COLORS.textActive[3], 0.3 * contentAlpha)
            local titleW = fonts.h2:getWidth(window.title)
            local titleX = scaledX + (scaledW - titleW) / 2
            local titleY = scaledY + 20
            for dx = -1, 1 do
                for dy = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        love.graphics.print(window.title, titleX + dx, titleY + dy)
                    end
                end
            end
            
            -- Main text
            love.graphics.setColor(COLORS.textActive[1], COLORS.textActive[2], COLORS.textActive[3], contentAlpha)
            love.graphics.print(window.title, titleX, titleY)
        end
        
        local yOffset = scaledY + 70
        
        -- Resolution section
        if fonts and fonts.body then
            love.graphics.setFont(fonts.body)
            love.graphics.setColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], contentAlpha)
            love.graphics.print("Risoluzione:", scaledX + 20, yOffset)
            yOffset = yOffset + 35
            
            -- Resolution buttons
            for i, res in ipairs(settings.resolutions) do
                local btnX = scaledX + 30
                local btnY = yOffset + (i - 1) * 45
                local btnW = scaledW - 60
                local btnH = 35
                local isSelected = (i == settings.selectedResolution)
                local isHover = (settings.hoverElement == "resolution_" .. i)
                
                -- Animated selection effect
                if isSelected then
                    love.graphics.setColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.2 * contentAlpha)
                    love.graphics.rectangle("fill", btnX - 5, btnY - 2, btnW + 10, btnH + 4, 8, 8)
                end
                
                drawButton(btnX, btnY, btnW, btnH, res.name, isHover, isSelected, fonts.small, contentAlpha)
                
                -- Store click area
                res.clickArea = {x = btnX, y = btnY, w = btnW, h = btnH}
            end
            
            yOffset = yOffset + #settings.resolutions * 45 + 35
            
            -- Fullscreen checkbox
            local checkboxSize = 22
            drawCheckbox(scaledX + 20, yOffset, checkboxSize, settings.fullscreen, fonts.body, "Schermo Intero", contentAlpha)
            settings.fullscreenArea = {x = scaledX + 20, y = yOffset, w = checkboxSize + fonts.body:getWidth("Schermo Intero") + 10, h = checkboxSize}
            
            yOffset = yOffset + 40
            
            -- VSync checkbox
            drawCheckbox(scaledX + 20, yOffset, checkboxSize, settings.vsync, fonts.body, "VSync", contentAlpha)
            settings.vsyncArea = {x = scaledX + 20, y = yOffset, w = checkboxSize + fonts.body:getWidth("VSync") + 10, h = checkboxSize}
            
            yOffset = yOffset + 60
            
            -- Info box with current resolution
            local currentW, currentH = love.graphics.getDimensions()
            local infoText = string.format("Attuale: %dx%d", currentW, currentH)
            love.graphics.setFont(fonts.small)
            love.graphics.setColor(COLORS.textSubtle[1], COLORS.textSubtle[2], COLORS.textSubtle[3], contentAlpha)
            local infoW = fonts.small:getWidth(infoText)
            love.graphics.print(infoText, scaledX + (scaledW - infoW) / 2, yOffset - 35)
            
            -- Apply and Cancel buttons
            local btnW = 110
            local btnH = 40
            local spacing = 30
            local totalWidth = btnW * 2 + spacing
            local startX = scaledX + (scaledW - totalWidth) / 2
            
            local applyHover = (settings.hoverElement == "apply")
            local cancelHover = (settings.hoverElement == "cancel")
            
            -- Apply button
            drawButton(startX, yOffset, btnW, btnH, "Applica", applyHover, false, fonts.small, contentAlpha)
            settings.applyArea = {x = startX, y = yOffset, w = btnW, h = btnH}
            
            -- Cancel button
            drawButton(startX + btnW + spacing, yOffset, btnW, btnH, "Annulla", cancelHover, false, fonts.small, contentAlpha)
            settings.cancelArea = {x = startX + btnW + spacing, y = yOffset, w = btnW, h = btnH}
        end
    end
end

function VideoSettings.mousepressed(x, y, button)
    if not window.open or button ~= 1 then return false end
    
    -- Check resolution buttons
    for i, res in ipairs(settings.resolutions) do
        if res.clickArea and x >= res.clickArea.x and x <= res.clickArea.x + res.clickArea.w and
           y >= res.clickArea.y and y <= res.clickArea.y + res.clickArea.h then
            settings.selectedResolution = i
            return true
        end
    end
    
    -- Check fullscreen
    if settings.fullscreenArea and x >= settings.fullscreenArea.x and x <= settings.fullscreenArea.x + settings.fullscreenArea.w and
       y >= settings.fullscreenArea.y and y <= settings.fullscreenArea.y + settings.fullscreenArea.h then
        settings.fullscreen = not settings.fullscreen
        return true
    end
    
    -- Check VSync
    if settings.vsyncArea and x >= settings.vsyncArea.x and x <= settings.vsyncArea.x + settings.vsyncArea.w and
       y >= settings.vsyncArea.y and y <= settings.vsyncArea.y + settings.vsyncArea.h then
        settings.vsync = not settings.vsync
        return true
    end
    
    -- Check Apply
    if settings.applyArea and x >= settings.applyArea.x and x <= settings.applyArea.x + settings.applyArea.w and
       y >= settings.applyArea.y and y <= settings.applyArea.y + settings.applyArea.h then
        VideoSettings.apply()
        return true
    end
    
    -- Check Cancel
    if settings.cancelArea and x >= settings.cancelArea.x and x <= settings.cancelArea.x + settings.cancelArea.w and
       y >= settings.cancelArea.y and y <= settings.cancelArea.y + settings.cancelArea.h then
        VideoSettings.close()
        return true
    end
    
    -- Click outside window, close
    local animScale = window.animation
    local centerX = window.x + window.w / 2
    local centerY = window.y + window.h / 2
    local scaledW = window.w * animScale
    local scaledH = window.h * animScale
    local scaledX = centerX - scaledW / 2
    local scaledY = centerY - scaledH / 2
    
    if x < scaledX or x > scaledX + scaledW or y < scaledY or y > scaledY + scaledH then
        VideoSettings.close()
        return true
    end
    
    return true
end

function VideoSettings.apply()
    local selectedRes = settings.resolutions[settings.selectedResolution]
    if selectedRes then
        -- Save to Settings system
        local Settings = require("src.core.settings")
        Settings.setCategory("video", {
            width = selectedRes.w,
            height = selectedRes.h,
            fullscreen = settings.fullscreen,
            vsync = settings.vsync
        })
        
        -- Apply settings immediately
        Settings.applyVideoSettings()
        
        print("[VideoSettings] Applied and saved:", selectedRes.name, "Fullscreen:", settings.fullscreen, "VSync:", settings.vsync)
    end
    VideoSettings.close()
end

function VideoSettings.keypressed(key)
    if not window.open then return false end
    
    if key == "escape" then
        VideoSettings.close()
        return true
    elseif key == "return" then
        VideoSettings.apply()
        return true
    end
    
    return true
end

-- Disabilitato: eventuali funzioni che richiedono moduli rimossi vanno commentate manualmente se necessario.

return VideoSettings
