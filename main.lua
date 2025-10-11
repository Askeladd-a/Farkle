-- main.lua  —  Isometric Starter (LÖVE 11.x)
-- tasti: WASD = pan,  + / - = zoom,  SPACE = toggle griglia,  R = respawn dadi

-- main.lua — Starter (LÖVE 11.x)
local Menu = require("src.ui.menu")
local Cursor = require("src.ui.cursor")
-- local diceSprites = require("src.dice_sprites")
local gameState = "menu"
local fonts = {}
local mouseX, mouseY = 0, 0

-- Background shader with radial gradient, vignette, and subtle parallax
local bgShader = love.graphics.newShader[[
uniform vec2 u_mouse;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px){
    // Centro leggermente sopra il board con parallasse soft
    vec2 center = vec2(0.5, 0.42) + u_mouse * 0.01;
    float d = distance(uv, center);

    // Gradiente radiale scuro
    float g = smoothstep(0.95, 0.25, d);
    vec3 base = mix(vec3(0.054,0.058,0.078), vec3(0.094,0.101,0.133), g);

    // Vignettatura
    float vig = smoothstep(0.9, 0.4, d);

    // Rumore fine economico
    float n = fract(sin(dot(uv*love_ScreenSize.xy*0.01, vec2(12.9898,78.233))) * 43758.5453);
    n = (n - 0.5) * 0.025; // ±2.5%

    vec3 col = base * (0.92 + n) * mix(1.0, 0.85, vig);
    return vec4(col, 1.0) * color;
}
]]

function love.load()
  love.window.setMode(1920, 1080, {resizable=true})
  -- Rimuovo setBackgroundColor perché useremo lo shader per il background
  fonts.title = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 64)
  fonts.h2    = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 36)
  fonts.body  = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 28)
  fonts.small = love.graphics.newFont("fonts/MedievalSharp-Regular.ttf", 18)
  Menu.init()
  Cursor.init()
  love.mouse.setVisible(false)
end

function drawBackground()
  love.graphics.push("all")
  love.graphics.setShader(bgShader)
  -- Passa coordinate mouse normalizzate allo shader
  local w, h = love.graphics.getDimensions()
  bgShader:send("u_mouse", {(mouseX/w - 0.5) * 2, (mouseY/h - 0.5) * 2})
  love.graphics.rectangle("fill", 0, 0, w, h)
  love.graphics.setShader()
  love.graphics.pop()
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
  mouseX, mouseY = x, y -- Aggiorna posizione mouse per parallasse
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
      -- diceSprites.spawn(6) -- commentato perché non implementato
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
  -- Disegna background con shader per tutti gli stati
  drawBackground()
  
  if gameState == "menu" then
    Menu.draw(fonts)
    Cursor.draw()
    return
  end
  -- Removed board instructions text
  -- diceSprites.draw()
  Cursor.draw()
end