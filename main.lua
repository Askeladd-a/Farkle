-- main.lua  —  Isometric Starter (LÖVE 11.x)
-- tasti: WASD = pan,  + / - = zoom,  SPACE = toggle griglia,  R = respawn dadi

-- main.lua — Starter (LÖVE 11.x)
local Menu = require("src.ui.menu")
local Cursor = require("src.ui.cursor")
-- local diceSprites = require("src.dice_sprites")
local gameState = "menu"
local fonts = {}

function love.load()
  love.window.setMode(1920, 1080, {resizable=true})
  love.graphics.setBackgroundColor(0.07,0.07,0.09)
  fonts.title = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 64)
  fonts.h2    = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 36)
  fonts.body  = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 28)
  fonts.small = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 18)
  Menu.init()
  Cursor.init()
  love.mouse.setVisible(false)
end

function love.update(dt)
  if gameState == "menu" then
    Menu.update(dt)
    Cursor.update(dt)
    if Menu.requestStartGame then
      Menu.requestStartGame = false
      gameState = "playing"
  -- diceSprites.spawn(6)
    end
  elseif gameState == "playing" then
    Cursor.update(dt)
  end
end

function love.mousepressed(mx, my, b)
  Cursor.mousepressed(mx, my, b)
  if gameState == "menu" then
    Menu.mousepressed(mx,my,b,{state=gameState})
  end
end

function love.mousereleased(x,y,b)
  if gameState == 'menu' then
    if Menu.mousereleased then Menu.mousereleased(x,y,b) end
  end
end

function love.mousemoved(x,y,dx,dy,istouch)
  if gameState == 'menu' then
    if Menu.mousemoved then Menu.mousemoved(x,y) end
  end
  Cursor.mousemoved(x,y,dx,dy)
end

function love.keypressed(k)
  if gameState == "menu" then
    if Menu.keypressed then Menu.keypressed(k, {state=gameState}) end
    if k=='return' then
      gameState = "playing"
      diceSprites.spawn(6)
    elseif k=='escape' then
      love.event.quit()
    end
    return
  end
  if k=='r' then
  -- diceSprites.spawn(6)
  elseif k=='escape' then
    gameState = "menu"
  end
end

function love.draw()
  if gameState == "menu" then
    Menu.draw(fonts)
    Cursor.draw()
    return
  end
  love.graphics.setColor(1,1,1,0.9)
  love.graphics.print("Board — R to spawn dice, ESC to menu", 12,12)
  -- diceSprites.draw()
  Cursor.draw()
end