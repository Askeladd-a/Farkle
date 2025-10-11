-- iso_utils.lua — modulo di utilità per proiezione isometrica semplice
local M = {}

local W,H = 1,1
M.cam = {x=0,y=0,zoom=1}
local tileW, tileH = 128, 64

function M.init(w,h)
  W = w or love.graphics.getWidth()
  H = h or love.graphics.getHeight()
end

function M.resize(w,h)
  W,H = w,h
end

-- Converte coordinate mondo (x,y,z) in schermo
function M.worldToScreen(x,y,z)
  local sx = (x - y) * (tileW/2)
  local sy = (x + y) * (tileH/2) - (z or 0) * tileH
  sx = (sx - M.cam.x)*M.cam.zoom + W/2
  sy = (sy - M.cam.y)*M.cam.zoom + H/2
  return sx, sy
end

-- Inversa (z=0)
local function screenToWorld(sx,sy)
  sx = (sx - W/2)/M.cam.zoom + M.cam.x
  sy = (sy - H/2)/M.cam.zoom + M.cam.y
  local x =  sy/tileH + sx/tileW
  local y =  sy/tileH - sx/tileW
  return x,y
end

function M.screenToCell(sx,sy)
  local x,y = screenToWorld(sx,sy)
  return math.floor(x+0.5), math.floor(y+0.5)
end

function M.drawTile(ix,iy,fill,line)
  local cx,cy = M.worldToScreen(ix,iy,0)
  local hw,hh = (tileW/2)*M.cam.zoom, (tileH/2)*M.cam.zoom
  love.graphics.setColor(fill or {0.7,0.7,0.74,0.95})
  love.graphics.polygon("fill", cx,cy-hh, cx+hw,cy, cx,cy+hh, cx-hw,cy)
  love.graphics.setColor(line or {0,0,0,0.25})
  love.graphics.polygon("line", cx,cy-hh, cx+hw,cy, cx,cy+hh, cx-hw,cy)
end

function M.drawGrid(cols,rows)
  for j=0,rows-1 do for i=0,cols-1 do
    local even=((i+j)%2==0)
    M.drawTile(i,j, even and {0.70,0.70,0.74,0.95} or {0.66,0.66,0.70,0.95})
  end end
end

function M.drawMouseCell()
  local mx,my = love.mouse.getPosition()
  local cx,cy = M.screenToCell(mx,my)
  love.graphics.setColor(0.2,0.8,1.0,0.3)
  M.drawTile(cx,cy, {0.2,0.8,1.0,0.18}, {0.1,0.5,0.9,0.6})
end

function M.update(dt)
  local pan = 600*dt/M.cam.zoom
  if love.keyboard.isDown('a') then M.cam.x = M.cam.x - pan end
  if love.keyboard.isDown('d') then M.cam.x = M.cam.x + pan end
  if love.keyboard.isDown('w') then M.cam.y = M.cam.y - pan end
  if love.keyboard.isDown('s') then M.cam.y = M.cam.y + pan end
end

function M.wheelmoved(dx,dy)
  if dy==0 then return end
  local mx,my = love.mouse.getPosition()
  local wx0,wy0 = screenToWorld(mx,my)
  M.cam.zoom = math.max(0.4, math.min(3.0, M.cam.zoom*(1+dy*0.1)))
  -- zoom pivot verso mouse
  local sx,sy = M.worldToScreen(wx0,wy0,0)
  M.cam.x = M.cam.x + (sx-mx)/M.cam.zoom
  M.cam.y = M.cam.y + (sy-my)/M.cam.zoom
end

function M.keypressed(k)
  if k=='=' or k=='kp+' then M.cam.zoom = math.min(3, M.cam.zoom*1.1)
  elseif k=='-' or k=='kp-' then M.cam.zoom = math.max(0.4, M.cam.zoom/1.1) end
end

return M
