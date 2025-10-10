-- Options dropdown UI module
-- Encapsulates geometry, hover, draw, and click handling for the anchored options menu

local Options = {}

local function getButtonsBounds(layout)
  local buttons = layout and layout.buttons
  if not buttons or #buttons == 0 then return nil end
  local minX, minY = math.huge, math.huge
  local maxX, maxY = -math.huge, -math.huge
  for _, b in ipairs(buttons) do
    if b.x < minX then minX = b.x end
    if b.y < minY then minY = b.y end
    if b.x + b.w > maxX then maxX = b.x + b.w end
    if b.y + b.h > maxY then maxY = b.y + b.h end
  end
  return {x = minX, y = minY, w = maxX - minX, h = maxY - minY}
end

local function rectsIntersect(ax, ay, aw, ah, bx, by, bw, bh)
  return not (ax + aw <= bx or bx + bw <= ax or ay + ah <= by or by + bh <= ay)
end

local function computeMenuRect(game)
  local layout = game.layout
  local btn = game.uiOptions.anchor
  if not layout or not btn then return nil end
  local ui = game.uiOptions
  local width, height = love.graphics.getDimensions()
  local menuW, itemH = ui.menuW, ui.itemH
  local menuH = #ui.items * itemH

  local menuX = btn.x + btn.w - menuW
  local menuY = btn.y + btn.h + 6
  local grid = getButtonsBounds(layout)
  local intersectsDown = grid and rectsIntersect(menuX, menuY, menuW, menuH, grid.x, grid.y, grid.w, grid.h)

  if intersectsDown or (menuY + menuH > height - 8) then
    local upY = btn.y - 6 - menuH
    local intersectsUp = grid and rectsIntersect(menuX, upY, menuW, menuH, grid.x, grid.y, grid.w, grid.h)
    if not intersectsUp and upY >= 8 then
      return {x = menuX, y = upY, w = menuW, h = menuH}
    end
    if grid then
      local leftX = grid.x - menuW - 8
      local bestY = (btn.y + btn.h + 6 + menuH <= height - 8) and (btn.y + btn.h + 6)
        or (btn.y - 6 - menuH >= 8 and (btn.y - 6 - menuH)) or 8
      return {x = math.max(8, leftX), y = bestY, w = menuW, h = menuH}
    end
    return {x = menuX, y = math.max(8, upY), w = menuW, h = menuH}
  end

  return {x = menuX, y = menuY, w = menuW, h = menuH}
end

function Options.updateHover(game)
  local ui = game.uiOptions
  if not (game.layout and ui and ui.anchor and ui.open) then
    ui.hoverIndex = nil
    return
  end
  local mx, my = love.mouse.getPosition()
  local rect = computeMenuRect(game)
  if not rect then return end
  ui.hoverIndex = nil
  for i = 1, #ui.items do
    local iy = rect.y + (i - 1) * ui.itemH
    if mx >= rect.x and mx <= rect.x + ui.menuW and my >= iy and my <= iy + ui.itemH then
      ui.hoverIndex = i
      break
    end
  end
end

function Options.draw(game, fonts)
  local ui = game.uiOptions
  if not (ui and ui.open) then return end
  local rect = computeMenuRect(game)
  if not rect then return end
  local menuX, menuY, menuH = rect.x, rect.y, rect.h

  love.graphics.setColor(0, 0, 0, 0.25)
  love.graphics.rectangle("fill", menuX + 2, menuY + 3, ui.menuW, menuH, 8, 8)
  love.graphics.setColor(0.12, 0.12, 0.14, 0.98)
  love.graphics.rectangle("fill", menuX, menuY, ui.menuW, menuH, 8, 8)

  for i, item in ipairs(ui.items) do
    local iy = menuY + (i - 1) * ui.itemH
    if ui.hoverIndex == i then
      love.graphics.setColor(0.20, 0.20, 0.24, 1.0)
      love.graphics.rectangle("fill", menuX, iy, ui.menuW, ui.itemH, 8, 8)
    end
    love.graphics.setColor(0.95, 0.98, 1.0)
    if fonts and fonts.body then
      love.graphics.setFont(fonts.body)
      love.graphics.print(item.label, menuX + 12, iy + (ui.itemH - fonts.body:getHeight()) / 2)
    end
  end
end

-- Returns true if the click was handled here
function Options.handleMousePressed(game, x, y, requestQuit)
  local ui = game.uiOptions
  if not (ui and ui.anchor) then return false end

  if not ui.open then
    -- let caller handle toggling
    return false
  end

  local rect = computeMenuRect(game)
  if not rect then
    ui.open = false
    ui.anchor = nil
    return false
  end

  for i = 1, #ui.items do
    local iy = rect.y + (i - 1) * ui.itemH
    if x >= rect.x and x <= rect.x + ui.menuW and y >= iy and y <= iy + ui.itemH then
      local item = ui.items[i]
      ui.open = false
      ui.anchor = nil
      
      -- Gestisci azioni specifiche
      if item.action == "toggle3d" then
        local Dice = require("src.graphics.dice")
        local DiceMesh = require("src.graphics.dice_mesh")
        local newMode = Dice.RENDER_MODE == "3d" and "2d" or "3d"
        Dice.setRenderMode(newMode)
        if DiceMesh and DiceMesh.setRenderMode then
          DiceMesh.setRenderMode(newMode)
        end
        
        -- Aggiorna label per riflettere stato attuale
        item.label = newMode == "3d" and "Switch to 2D Dice" or "Switch to 3D Dice"
        
      elseif item.action == "stats" then
        game.show3DStats = not game.show3DStats
        item.label = game.show3DStats and "Hide Dice Stats" or "Show Dice Stats"
        
      elseif item.action == "game" then
        print("[Options] Game settings selected")
        
      elseif item.action == "video" then
        print("[Options] Video settings selected")
        
      elseif item.action == "audio" then
        print("[Options] Audio settings selected")
        
      elseif item.label == "Exit Game" or item.label == "Quit" then
        if requestQuit then requestQuit() end
        
      else
        if item.action then item.action() end
      end
      
      return true
    end
  end

  -- click outside menu: close and let other handlers proceed
  ui.open = false
  ui.anchor = nil
  return false
end

return Options
