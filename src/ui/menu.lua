-- Menu principale singleton
local theme = require("src.ui.theme")
local utils = require("src.ui.utils")
local constants = require("src.core.constants")

-- I font vengono ora passati come argomento alle funzioni draw
local L = {w=1280, h=720, margin=32, gap=16, radius=14, bottomRowY=0, logoRect=nil, langRect=nil}
local buttons = {}
local hoverIdx, focusIdx = nil, 1

local function addButton(id, label, color, rect, onClick, enabled)
    table.insert(buttons, {
        id=id, label=label, color=color, x=rect.x, y=rect.y, w=rect.w, h=rect.h,
        onClick=onClick or function() print("CLICK:", id) end,
        enabled = (enabled ~= false)
    })
end

function Menu.computeLayout()
    L.w, L.h = love.graphics.getDimensions()
    local w,h = L.w, L.h
    local margin = math.max(24, math.floor(math.min(w,h)*0.02))
    local gap = math.max(12, math.floor(math.min(w,h)*0.012))
    local rowH = math.floor(h*0.11)
    local playW = math.min(420, math.floor(w*0.30))
    local smallW = math.min(220, math.floor(w*0.17))
    local rects = utils.computeRects(w, h, margin, gap, rowH, playW, smallW)
    local logoH = math.min(h*0.28, 260)
    L.logoRect = {x = math.floor(w*0.12), y = math.floor(h*0.12), w = math.floor(w*0.76), h = math.floor(logoH)}
    local langW, langH = math.floor(smallW*0.9), math.floor(rowH*0.55)
    L.langRect = {x = w - margin - langW, y = h - margin - rowH + rowH + gap*0.5 - langH, w = langW, h = langH}
    buttons = {}
    addButton("profile",   "PROFILE",   theme.COLORS.profile,    rects.profile)
    addButton("play",      "PLAY",      theme.COLORS.play,       rects.play, function() print("PLAY!") end)
    addButton("options",   "OPTIONS",   theme.COLORS.options,    rects.options)
    addButton("quit",      "QUIT",      theme.COLORS.quit,       rects.quit, function() love.event.quit() end)
    addButton("collection","COLLECTION",theme.COLORS.collection, rects.collection)
    for i,b in ipairs(buttons) do if b.id=="play" then focusIdx=i break end end
end

function Menu.draw()
    theme.setColor(theme.COLORS.bg)
    love.graphics.rectangle("fill", 0,0, L.w, L.h)
    theme.setColor(theme.COLORS.panel)
    local r = L.logoRect
    if r and r.x and r.y and r.w and r.h then
        love.graphics.rectangle("fill", r.x, r.y, r.w, r.h, 18,18)
        if fontTitle then
            theme.setColor(theme.COLORS.text)
            love.graphics.setFont(fontTitle)
            local title = "FARKLE 3D"
            local tw = fontTitle:getWidth(title)
            local th = fontTitle:getHeight()
            love.graphics.print(title, r.x+(r.w-tw)/2, r.y+(r.h-th)/2)
        end
    end
    for i,b in ipairs(buttons) do Menu.drawButton(b, hoverIdx==i, focusIdx==i) end
    local lg = L.langRect
    if lg and lg.x and lg.y and lg.w and lg.h then
        theme.setColor(theme.COLORS.panel)
        love.graphics.rectangle("fill", lg.x, lg.y, lg.w, lg.h, 10,10)
        if fontSmall then
            theme.setColor(theme.COLORS.text)
            love.graphics.setFont(fontSmall)
            local t = "Language: EN"
            love.graphics.print(t, lg.x + (lg.w - fontSmall:getWidth(t))/2, lg.y + (lg.h - fontSmall:getHeight())/2)
            theme.setColor({1,1,1,0.5})
            love.graphics.print("←/→ per cambiare focus • Invio per attivare • Click per selezionare", 16, L.h-28)
        end
    end
end

function Menu.drawButton(b, isHover, isFocus)
    theme.setColor(theme.COLORS.shadow)
    love.graphics.rectangle("fill", b.x+2, b.y+4, b.w, b.h, L.radius, L.radius)
    theme.setColor(b.enabled and b.color or theme.COLORS.disabled)
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, L.radius, L.radius)
    if isHover or isFocus then
        theme.setColor(theme.COLORS.hover)
        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, L.radius, L.radius)
    end
    theme.setColor(theme.COLORS.text)
    love.graphics.setFont(fontBtn)
    local tw = fontBtn:getWidth(b.label)
    local th = fontBtn:getHeight()
    love.graphics.print(b.label, b.x + (b.w-tw)/2, b.y + (b.h-th)/2 - 2)
end

function Menu.handleKey(key)
    if key == "return" or key == "space" then
        local b = buttons[focusIdx or 1]
        if b and b.enabled then b.onClick() end
    elseif key == "right" then
        focusIdx = math.min(#buttons, (focusIdx or 1) + 1)
    elseif key == "left" then
        focusIdx = math.max(1, (focusIdx or 1) - 1)
    end
end

function Menu.handleMouse(mx, my)
    for i,b in ipairs(buttons) do
        if theme.pointInRect(mx, my, b) and b.enabled then hoverIdx = i break end
    end
end

function Menu.getButtons() return buttons end
function Menu.getFocusIdx() return focusIdx end
function Menu.getHoverIdx() return hoverIdx end
local Menu = {}

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
