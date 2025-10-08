local Menu = {}
Menu.__index = Menu

local function drawMenuCard(x, y, w, h, isSelected, accentPulse)
    love.graphics.setColor(0.06, 0.09, 0.14, 0.86)
    love.graphics.rectangle("fill", x, y, w, h, 18, 18)
    love.graphics.setColor(0.3, 0.4, 0.68, 0.55)
    love.graphics.rectangle("line", x, y, w, h, 18, 18)
    if isSelected then
        local glow = 0.6 + 0.3 * math.sin(accentPulse)
        love.graphics.setColor(0.98, 0.72 + 0.08 * glow, 0.28 + 0.1 * glow, 1)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", x - 6, y - 6, w + 12, h + 12, 22, 22)
        love.graphics.setLineWidth(1)
    end
end

local function drawOverlayBackground(alpha)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0.02, 0.03, 0.05, alpha or 0.82)
    love.graphics.rectangle("fill", 0, 0, w, h)
    return w, h
end

function Menu.new(items)
    local self = setmetatable({}, Menu)
    self.items = items or {}
    self.selectedIndex = (#self.items > 0) and 1 or 0
    self.pulse = 0
    self.itemBounds = {}
    return self
end

function Menu:setItems(items)
    self.items = items or {}
    if #self.items == 0 then
        self.selectedIndex = 0
    else
        self.selectedIndex = math.min(self.selectedIndex > 0 and self.selectedIndex or 1, #self.items)
    end
end

function Menu:reset()
    self.pulse = 0
    if #self.items > 0 then
        self.selectedIndex = 1
    else
        self.selectedIndex = 0
    end
end

function Menu:update(dt)
    self.pulse = (self.pulse or 0) + dt * 2
end

function Menu:getItem(index)
    return self.items[index]
end

function Menu:getItemCount()
    return #self.items
end

function Menu:getSelectedIndex()
    return self.selectedIndex
end

function Menu:getSelectedItem()
    return self.items[self.selectedIndex]
end

function Menu:moveSelection(delta)
    local total = #self.items
    if total == 0 then return end
    local current = self.selectedIndex
    if current < 1 then current = 1 end
    self.selectedIndex = ((current - 1 + delta) % total) + 1
end

function Menu:setSelection(index)
    local total = #self.items
    if total == 0 then
        self.selectedIndex = 0
        return
    end
    if index < 1 then
        self.selectedIndex = 1
    elseif index > total then
        self.selectedIndex = total
    else
        self.selectedIndex = index
    end
end

function Menu:hitTest(x, y)
    for index, bounds in ipairs(self.itemBounds or {}) do
        if x >= bounds.x and x <= bounds.x + bounds.w and y >= bounds.y and y <= bounds.y + bounds.h then
            return index
        end
    end
    return nil
end

function Menu:onMouseMoved(x, y)
    local index = self:hitTest(x, y)
    if index then
        self:setSelection(index)
        return true
    end
    return false
end

function Menu:draw(fonts, drawShadowedText)
    local w, h = drawOverlayBackground(0.78)

    local title = "Neon Farkle"
    local titleWidth = fonts.title:getWidth(title)
    local titleX = (w - titleWidth) * 0.5
    local titleY = h * 0.18
    drawShadowedText(fonts.title, title, titleX, titleY, {0.98, 0.78, 0.32, 1}, {0.02, 0.02, 0.02, 0.8})

    local subtitle = "Roll with style. Bank with nerve."
    local subtitleX = (w - fonts.help:getWidth(subtitle)) * 0.5
    drawShadowedText(fonts.help, subtitle, subtitleX, titleY + fonts.title:getHeight() + 12, {0.82, 0.86, 0.96, 1})

    local itemHeight = fonts.menu:getHeight() + 22
    local spacing = 16
    local totalHeight = #self.items * itemHeight + (#self.items - 1) * spacing
    local baseY = h * 0.45 - totalHeight * 0.5
    local cardWidth = math.max(360, w * 0.32)
    local cardX = (w - cardWidth) * 0.5

    self.itemBounds = {}
    for index, item in ipairs(self.items) do
        local itemY = baseY + (index - 1) * (itemHeight + spacing)
        local isSelected = index == self.selectedIndex
        drawMenuCard(cardX, itemY, cardWidth, itemHeight, isSelected, (self.pulse or 0) * 2 + index)
        self.itemBounds[index] = {x = cardX, y = itemY, w = cardWidth, h = itemHeight}

        local textY = itemY + (itemHeight - fonts.menu:getHeight()) * 0.5 - 2
        local textColor = isSelected and {0.98, 0.93, 0.85, 1} or {0.78, 0.82, 0.9, 1}
        drawShadowedText(fonts.menu, item.label, cardX + 28, textY, textColor)
    end

    local selectedItem = self:getSelectedItem()
    if selectedItem then
        local blurb = selectedItem.blurb
        local blurbWidth = fonts.body:getWidth(blurb)
        local blurbX = (w - blurbWidth) * 0.5
        drawShadowedText(fonts.body, blurb, blurbX, baseY + totalHeight + 42, {0.86, 0.88, 0.95, 1})
    end

    local hint = "Enter / Click to confirm    Esc to quit"
    drawShadowedText(fonts.help, hint, (w - fonts.help:getWidth(hint)) * 0.5, h - 86, {0.96, 0.78, 0.36, 1})
end

local function drawOverlayText(fonts, drawShadowedText, lines, baseY, lineSpacing)
    for i, line in ipairs(lines) do
        local textWidth = fonts.body:getWidth(line)
        local x = (love.graphics.getWidth() - textWidth) * 0.5
        local y = baseY + (i - 1) * lineSpacing
        drawShadowedText(fonts.body, line, x, y, {0.86, 0.88, 0.95, 1})
    end
end

function Menu:drawOptions(fonts, drawShadowedText)
    local w, h = drawOverlayBackground()

    local title = "Options"
    drawShadowedText(fonts.title, title, (w - fonts.title:getWidth(title)) * 0.5, h * 0.18, {0.98, 0.76, 0.3, 1})

    local lines = {
        "Audio sliders, visual filters, and accessibility toggles",
        "will live here soon. For now, enjoy the neon bones!",
    }
    local baseY = h * 0.4
    local lineSpacing = fonts.body:getHeight() + 12
    drawOverlayText(fonts, drawShadowedText, lines, baseY, lineSpacing)

    local hint = "Press ESC or Right Click to return"
    drawShadowedText(fonts.help, hint, (w - fonts.help:getWidth(hint)) * 0.5, h - 86, {0.96, 0.78, 0.36, 1})
end

function Menu:drawGuide(fonts, drawShadowedText)
    local w, h = drawOverlayBackground()

    local title = "How to Play"
    drawShadowedText(fonts.title, title, (w - fonts.title:getWidth(title)) * 0.5, h * 0.18, {0.98, 0.76, 0.3, 1})

    local lines = {
        "Roll six dice. Lock scoring dice to build your combo streak.",
        "Bank points with Q to keep them safe, but busting erases turn points.",
        "Hot dice! Score all dice in a roll and you'll throw all six again.",
        "Chase high scores like a Balatro run—risky plays pay the neon bills.",
    }
    local baseY = h * 0.38
    local lineSpacing = fonts.body:getHeight() + 10
    drawOverlayText(fonts, drawShadowedText, lines, baseY, lineSpacing)

    local hint = "Press ESC or Right Click to return"
    drawShadowedText(fonts.help, hint, (w - fonts.help:getWidth(hint)) * 0.5, h - 86, {0.96, 0.78, 0.36, 1})
end

return Menu
