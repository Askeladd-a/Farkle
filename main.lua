-- main.lua  —  Isometric Starter (LÖVE 11.x)
-- tasti: WASD = pan,  + / - = zoom,  SPACE = toggle griglia/ombre,  mouse click = seleziona cella

local W, H
local cam = {x=0, y=0, z=0, zoom=1}
local showGrid = true

-- ====== PARAMETRI ISO ======
-- formula iso "diamante": 
--   sx = (x - y) * tileW/2
--   sy = (x + y) * tileH/2 - z*tileH
local tileW, tileH = 128, 64   -- rapporto 2:1 classico

-- proiezione mondo->schermo
local function worldToScreen(x, y, z)
  local sx = (x - y) * (tileW/2)
  local sy = (x + y) * (tileH/2) - z * tileH
  -- applica camera
  sx = (sx - cam.x) * cam.zoom + W/2
  sy = (sy - cam.y) * cam.zoom + H/2
  return sx, sy
end

-- inversa schermo->tile (z=0): ritorna coordinate "fra zioni" (non arrotondate)
local function screenToWorld(sx, sy)
  -- rimuovi camera
  sx = (sx - W/2)/cam.zoom + cam.x
  sy = (sy - H/2)/cam.zoom + cam.y
  -- inverti matrice iso 2D (z=0)
  local x =  sy/tileH + sx/tileW
  local y =  sy/tileH - sx/tileW
  return x, y
end

-- arrotonda alla cella intera più vicina
local function screenToCell(sx, sy)
  local x, y = screenToWorld(sx, sy)
  return math.floor(x+0.5), math.floor(y+0.5)
end

-- ====== GRIGLIA / TILE DRAW ======
local cols, rows = 10, 8
local function drawTile(ix, iy, colorFill, colorLine)
  local x, y = ix, iy
  local cx, cy = worldToScreen(x, y, 0)
  local hw, hh = (tileW/2)*cam.zoom, (tileH/2)*cam.zoom
  love.graphics.setColor(colorFill or {0.68,0.68,0.72, 0.9})
  love.graphics.polygon("fill",
    cx, cy-hh, cx+hw, cy, cx, cy+hh, cx-hw, cy
  )
  love.graphics.setColor(colorLine or {0,0,0,0.25})
  love.graphics.polygon("line",
    cx, cy-hh, cx+hw, cy, cx, cy+hh, cx-hw, cy
  )
end

local function drawGrid()
  for j=0, rows-1 do
    for i=0, cols-1 do
      local even = ((i+j)%2==0)
      drawTile(i, j,
        even and {0.70,0.70,0.74,0.95} or {0.66,0.66,0.70,0.95}
      )
    end
  end
end

-- ====== DADI SEMPLICI (icone piatte posizionate in iso) ======
-- se hai un foglio 3x2 puoi caricare le 6 facce; qui per semplicità userò cerchietti
local dice = {}
local function spawnDice()
  dice = {}
  -- sei posizioni comode
  local spots = {{2,2},{3,4},{5,3},{6,6},{7,2},{1,6}}
  for n=1,6 do
    local t = spots[n]
    table.insert(dice, {
      tx=t[1], ty=t[2], z=0, val=n,
      bobA=math.random()*6.283, bobS=0.06  -- micro oscillazione (feeling vivo)
    })
  end
end

local function drawDice()
  for _,d in ipairs(dice) do
    -- micro bobbing
    local z = d.z + math.sin(d.bobA + love.timer.getTime()*2)*d.bobS
    local sx, sy = worldToScreen(d.tx, d.ty, z)
    -- ombra
    love.graphics.setColor(0,0,0,0.18)
    love.graphics.ellipse("fill", sx, sy+10*cam.zoom, 24*cam.zoom, 10*cam.zoom)
    -- corpo dado
    love.graphics.setColor(0.96,0.96,0.98, 1)
    love.graphics.rectangle("fill", sx-22*cam.zoom, sy-22*cam.zoom, 44*cam.zoom, 44*cam.zoom, 8*cam.zoom, 8*cam.zoom)
    love.graphics.setColor(0,0,0,0.25)
    love.graphics.rectangle("line", sx-22*cam.zoom, sy-22*cam.zoom, 44*cam.zoom, 44*cam.zoom, 8*cam.zoom, 8*cam.zoom)
    -- pips (schema minimale)
    love.graphics.setColor(0.15,0.15,0.17, 0.95)
    local r = 4*cam.zoom
    local function pip(px,py) love.graphics.circle("fill", sx+px*cam.zoom, sy+py*cam.zoom, r) end
    local layout = {
      [1]={{0,0}},
      [2]={{-10,-10},{10,10}},
      [3]={{-12,-12},{0,0},{12,12}},
      [4]={{-12,-12},{12,-12},{12,12},{-12,12}},
      [5]={{-12,-12},{12,-12},{0,0},{12,12},{-12,12}},
      [6]={{-12,-12},{-12,0},{-12,12},{12,-12},{12,0},{12,12}},
    }
    for _,p in ipairs(layout[d.val]) do pip(p[1],p[2]) end
  end
end

-- ====== INPUT / CAMERA ======
function love.load()
  W, H = love.graphics.getDimensions()
  love.graphics.setBackgroundColor(0.07,0.07,0.09)
  spawnDice()
end

function love.update(dt)
  local pan = 600 * dt / cam.zoom
  if love.keyboard.isDown('a') then cam.x = cam.x - pan end
  if love.keyboard.isDown('d') then cam.x = cam.x + pan end
  if love.keyboard.isDown('w') then cam.y = cam.y - pan end
  if love.keyboard.isDown('s') then cam.y = cam.y + pan end
end

function love.wheelmoved(dx, dy)
  if dy~=0 then
    local before = cam.zoom
    cam.zoom = math.max(0.4, math.min(3.0, cam.zoom * (1 + dy*0.1)))
    -- zoom verso mouse (comodo)
    local mx,my = love.mouse.getPosition()
    local wx0,wy0 = screenToWorld(mx,my)
    local sx,sy = worldToScreen(wx0,wy0,0) -- dopo zoom
    cam.x = cam.x + (sx-mx)/cam.zoom
    cam.y = cam.y + (sy-my)/cam.zoom
  end
end

function love.mousepressed(mx, my, b)
  if b==1 then
    local cx, cy = screenToCell(mx, my)
    -- seleziona/muovi un dado sulla cella cliccata (demo)
    dice[1].tx, dice[1].ty = cx, cy
  end
end

function love.keypressed(k)
  if k=='space' then showGrid = not showGrid
  elseif k=='r' then spawnDice()
  elseif k=='escape' then love.event.quit()
  elseif k=='=' or k=='kp+' then cam.zoom = math.min(3, cam.zoom*1.1)
  elseif k=='-' or k=='kp-' then cam.zoom = math.max(0.4, cam.zoom/1.1)
  end
end

function love.draw()
  -- titolo
  love.graphics.setColor(1,1,1,0.9)
  love.graphics.print("Isometric Starter — WASD pan, mouse click pick, +/- zoom, SPACE grid", 12,12)

  -- board/griglia
  if showGrid then drawGrid() end

  -- dadi
  drawDice()

  -- feedback cella mouse
  local mx,my = love.mouse.getPosition()
  local cx,cy = screenToCell(mx,my)
  love.graphics.setColor(0.2,0.8,1.0,0.35)
  drawTile(cx, cy, {0.2,0.8,1.0,0.22}, {0.1,0.5,0.9,0.6})
end