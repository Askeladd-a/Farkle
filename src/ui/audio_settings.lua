select-- Audio Settings Window
local AudioSettings = {}

local window = {
    open = false,
    x = 0, y = 0, w = 480, h = 420,
    title = "Audio Settings",
    animation = 0,
    targetAnimation = 0
}

local settings = {
    masterVolume = 0.8,
    sfxVolume = 0.7,
    musicVolume = 0.6,
    diceVolume = 0.8,
    uiVolume = 0.5,
    ambienceVolume = 0.3,
    hoverElement = nil,
    dragElement = nil
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
    slider = {0.4, 0.5, 0.6, 1},
    sliderTrack = {0.20, 0.25, 0.30, 1},
    sliderKnob = {0.7, 0.8, 0.9, 1},
    sliderKnobHover = {0.9, 0.95, 1.0, 1},
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

local function drawSlider(x, y, w, h, value, label, font, alpha, isHover, isDragging)
    alpha = alpha or 1
    
    -- Track
    love.graphics.setColor(COLORS.sliderTrack[1], COLORS.sliderTrack[2], COLORS.sliderTrack[3], COLORS.sliderTrack[4] * alpha)
    love.graphics.rectangle("fill", x, y + h/2 - 3, w, 6, 3, 3)
    
    -- Fill
    local fillWidth = w * value
    love.graphics.setColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.7 * alpha)
    love.graphics.rectangle("fill", x, y + h/2 - 3, fillWidth, 6, 3, 3)
    
    -- Knob
    local knobX = x + fillWidth - 8
    local knobColor = isDragging and COLORS.sliderKnobHover or (isHover and COLORS.sliderKnobHover or COLORS.sliderKnob)
    love.graphics.setColor(knobColor[1], knobColor[2], knobColor[3], knobColor[4] * alpha)
    love.graphics.circle("fill", knobX + 8, y + h/2, isDragging and 10 or (isHover and 9 or 8))
    
    -- Border
    love.graphics.setColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], COLORS.border[4] * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", knobX + 8, y + h/2, isDragging and 10 or (isHover and 9 or 8))
    
    -- Label and value
    if font and label then
        love.graphics.setFont(font)
        love.graphics.setColor(COLORS.text[1], COLORS.text[2], COLORS.text[3], COLORS.text[4] * alpha)
        love.graphics.print(label, x, y - 20)
        
        local valueText = string.format("%.0f%%", value * 100)
        local valueWidth = font:getWidth(valueText)
        love.graphics.setColor(COLORS.textSubtle[1], COLORS.textSubtle[2], COLORS.textSubtle[3], COLORS.textSubtle[4] * alpha)
        love.graphics.print(valueText, x + w - valueWidth, y - 20)
    end
end

function AudioSettings.open()
    window.open = true
    window.targetAnimation = 1
    
    -- Better window centering with visual balance
    local screenW, screenH = love.graphics.getDimensions()
    window.x = math.floor((screenW - window.w) / 2)
    window.y = math.floor((screenH - window.h) / 2.2) -- Slightly higher for better visual balance
    
    -- Disabilitato: caricamento settings
    settings.hoverElement = nil
    settings.dragElement = nil
end

function AudioSettings.close()
    window.targetAnimation = 0
end

function AudioSettings.update(dt)
    if window.open then
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

function AudioSettings.isOpen()
    return window.open
end

function AudioSettings.mousemoved(x, y)
    if not window.open then return false end
    
    settings.hoverElement = nil
    
    local animScale = window.animation
    local centerX = window.x + window.w / 2
    local centerY = window.y + window.h / 2
    local scaledW = window.w * animScale
    local scaledH = window.h * animScale
    local scaledX = centerX - scaledW / 2
    local scaledY = centerY - scaledH / 2
    
    -- Handle slider dragging
    if settings.dragElement then
        local sliders = {
            {"masterVolume", scaledY + 80},
            {"sfxVolume", scaledY + 130},
            {"musicVolume", scaledY + 180},
            {"diceVolume", scaledY + 230},
            {"uiVolume", scaledY + 280}
        }
        
        for _, slider in ipairs(sliders) do
            if settings.dragElement == slider[1] then
                local sliderX = scaledX + 30
                local sliderW = scaledW - 60
                local newValue = math.max(0, math.min(1, (x - sliderX) / sliderW))
                settings[slider[1]] = newValue
                
                -- Disabilitato: feedback audio
                return true
            end
        end
    end
    
    -- Check slider hover
    local sliders = {
        {"masterVolume", scaledY + 80},
        {"sfxVolume", scaledY + 130},
        {"musicVolume", scaledY + 180},
        {"diceVolume", scaledY + 230},
        {"uiVolume", scaledY + 280}
    }
    
    for _, slider in ipairs(sliders) do
        local sliderX = scaledX + 30
        local sliderY = slider[2]
        local sliderW = scaledW - 60
        local sliderH = 30
        
        if x >= sliderX and x <= sliderX + sliderW and y >= sliderY - 10 and y <= sliderY + sliderH then
            settings.hoverElement = slider[1]
            return true
        end
    end
    
    -- Check buttons
    local btnW = 100
    local btnH = 35
    local spacing = 20
    local totalWidth = btnW * 3 + spacing * 2
    local startX = scaledX + (scaledW - totalWidth) / 2
    local btnY = scaledY + scaledH - 60
    
    if y >= btnY and y <= btnY + btnH then
        if x >= startX and x <= startX + btnW then
            settings.hoverElement = "apply"
        elseif x >= startX + btnW + spacing and x <= startX + btnW * 2 + spacing then
            settings.hoverElement = "reset"
        elseif x >= startX + btnW * 2 + spacing * 2 and x <= startX + btnW * 3 + spacing * 2 then
            settings.hoverElement = "cancel"
        end
    end
    
    return false
end

function AudioSettings.draw(fonts)
    if not window.open then return end
    
    local animScale = window.animation
    local animAlpha = window.animation
    
    -- Animated overlay
    love.graphics.setColor(0, 0, 0, 0.7 * animAlpha)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    
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
    
    -- Content
    if animScale > 0.3 then
        local contentAlpha = math.min(1, (animScale - 0.3) / 0.7)
        
        -- Title with enhanced readability
        if fonts and fonts.h2 then
            love.graphics.setFont(fonts.h2)
            local titleW = fonts.h2:getWidth(window.title)
            local titleX = scaledX + (scaledW - titleW) / 2
            local titleY = scaledY + 20
            
            -- Title shadow for better readability
            love.graphics.setColor(0, 0, 0, 0.7 * contentAlpha)
            love.graphics.print(window.title, titleX + 2, titleY + 2)
            
            -- Main title text
            love.graphics.setColor(COLORS.textActive[1], COLORS.textActive[2], COLORS.textActive[3], contentAlpha)
            love.graphics.print(window.title, titleX, titleY)
        end
        
        -- Sliders
        if fonts and fonts.body then
            local sliders = {
                {"masterVolume", "Master Volume", scaledY + 80},
                {"sfxVolume", "Sound Effects", scaledY + 130},
                {"musicVolume", "Music", scaledY + 180},
                {"diceVolume", "Dice Sounds", scaledY + 230},
                {"uiVolume", "UI Sounds", scaledY + 280}
            }
            
            for _, slider in ipairs(sliders) do
                local key, label, y = slider[1], slider[2], slider[3]
                local isHover = (settings.hoverElement == key)
                local isDragging = (settings.dragElement == key)
                
                drawSlider(scaledX + 30, y, scaledW - 60, 30, settings[key], label, fonts.small, contentAlpha, isHover, isDragging)
            end
        end
        
        -- Test audio button
        local testBtnW = 120
        local testBtnH = 25
        local testBtnX = scaledX + (scaledW - testBtnW) / 2
        local testBtnY = scaledY + 325
        local testHover = (settings.hoverElement == "test")
        drawButton(testBtnX, testBtnY, testBtnW, testBtnH, "Test Audio", testHover, false, fonts.small, contentAlpha)
        settings.testArea = {x = testBtnX, y = testBtnY, w = testBtnW, h = testBtnH}
        
        -- Action buttons
        local btnW = 100
        local btnH = 35
        local spacing = 20
        local totalWidth = btnW * 3 + spacing * 2
        local startX = scaledX + (scaledW - totalWidth) / 2
        local btnY = scaledY + scaledH - 60
        
        local applyHover = (settings.hoverElement == "apply")
        local resetHover = (settings.hoverElement == "reset")
        local cancelHover = (settings.hoverElement == "cancel")
        
        drawButton(startX, btnY, btnW, btnH, "Apply", applyHover, false, fonts.small, contentAlpha)
        settings.applyArea = {x = startX, y = btnY, w = btnW, h = btnH}
        
        drawButton(startX + btnW + spacing, btnY, btnW, btnH, "Reset", resetHover, false, fonts.small, contentAlpha)
        settings.resetArea = {x = startX + btnW + spacing, y = btnY, w = btnW, h = btnH}
        
        drawButton(startX + btnW * 2 + spacing * 2, btnY, btnW, btnH, "Cancel", cancelHover, false, fonts.small, contentAlpha)
        settings.cancelArea = {x = startX + btnW * 2 + spacing * 2, y = btnY, w = btnW, h = btnH}
    end
end

function AudioSettings.mousepressed(x, y, button)
    if not window.open or button ~= 1 then return false end
    
    local animScale = window.animation
    local centerX = window.x + window.w / 2
    local centerY = window.y + window.h / 2
    local scaledW = window.w * animScale
    local scaledH = window.h * animScale
    local scaledX = centerX - scaledW / 2
    local scaledY = centerY - scaledH / 2
    
    -- Check sliders
    local sliders = {
        {"masterVolume", scaledY + 80},
        {"sfxVolume", scaledY + 130},
        {"musicVolume", scaledY + 180},
        {"diceVolume", scaledY + 230},
        {"uiVolume", scaledY + 280}
    }
    
    for _, slider in ipairs(sliders) do
        local sliderX = scaledX + 30
        local sliderY = slider[2]
        local sliderW = scaledW - 60
        local sliderH = 30
        
        if x >= sliderX and x <= sliderX + sliderW and y >= sliderY - 10 and y <= sliderY + sliderH then
            settings.dragElement = slider[1]
            local newValue = math.max(0, math.min(1, (x - sliderX) / sliderW))
            settings[slider[1]] = newValue
            return true
        end
    end
    
    -- Disabilitato: test audio
    
    -- Check Apply
    if settings.applyArea and x >= settings.applyArea.x and x <= settings.applyArea.x + settings.applyArea.w and
       y >= settings.applyArea.y and y <= settings.applyArea.y + settings.applyArea.h then
        AudioSettings.apply()
        return true
    end
    
    -- Check Reset
    if settings.resetArea and x >= settings.resetArea.x and x <= settings.resetArea.x + settings.resetArea.w and
       y >= settings.resetArea.y and y <= settings.resetArea.y + settings.resetArea.h then
        AudioSettings.reset()
        return true
    end
    
    -- Check Cancel
    if settings.cancelArea and x >= settings.cancelArea.x and x <= settings.cancelArea.x + settings.cancelArea.w and
       y >= settings.cancelArea.y and y <= settings.cancelArea.y + settings.cancelArea.h then
        AudioSettings.close()
        return true
    end
    
    -- Click outside window
    if x < scaledX or x > scaledX + scaledW or y < scaledY or y > scaledY + scaledH then
        AudioSettings.close()
        return true
    end
    
    return true
end

function AudioSettings.mousereleased(x, y, button)
    if settings.dragElement and button == 1 then
        settings.dragElement = nil
        return true
    end
    return false
end

function AudioSettings.apply()
    -- Disabilitato: salvataggio settings
    AudioSettings.close()
end

function AudioSettings.reset()
    -- Reset to defaults
    settings.masterVolume = 0.8
    settings.sfxVolume = 0.7
    settings.musicVolume = 0.6
    settings.diceVolume = 0.8
    settings.uiVolume = 0.5
    settings.ambienceVolume = 0.3
    
    print("[AudioSettings] Reset to default values")
end

function AudioSettings.keypressed(key)
    if not window.open then return false end
    
    if key == "escape" then
        AudioSettings.close()
        return true
    elseif key == "return" then
        AudioSettings.apply()
        return true
    end
    
    return true
end

return AudioSettings