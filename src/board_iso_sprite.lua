-- board_iso_sprite.lua — disegna una sprite "frontale" deformata sul piano isometrico
local M = {}

-- ===== proiezione isometrica base (tile 2:1) =====
local tileW, tileH = 128, 64
local cam = {x=0, y=0, zoom=1}
local W, H = love.graphics.getDimensions()

local function worldToScreen(x,y,z)
  local sx = (x - y) * (tileW/2)
  local sy = (x + y) * (tileH/2) - (z or 0)*tileH
  sx = (sx - cam.x)*cam.zoom + W/2
  sy = (sy - cam.y)*cam.zoom + H/2
  return sx, sy
end

-- crea una board iso "sdraiando" l'immagine su un quad isometrico w×h (in tiles)
function M.new(imagePath, w_tiles, h_tiles, z)
  local self = {}
  self.img = love.graphics.newImage(imagePath)
  self.img:setFilter("linear", "linear")
  self.w, self.h = w_tiles, h_tiles
  self.z = z or 0
  self.cx, self.cy = 0, 0  -- centro (in coordinate iso)

  -- mesh 4 vertici con UV pieni
  self.mesh = love.graphics.newMesh({
    {0,0, 0,1, 1,1,1,1},
    {0,0, 1,1, 1,1,1,1},
    {0,0, 1,0, 1,1,1,1},
    {0,0, 0,0, 1,1,1,1},
  }, "fan", "dynamic")
  self.mesh:setTexture(self.img)

  function self:setCenter(x,y) self.cx, self.cy = x,y end
  function self:setCam(nx,ny,zoom) cam.x,cam.y,cam.zoom = nx,ny,zoom or cam.zoom end

  function self:updateVertices()
    local hw, hh = self.w/2, self.h/2
    -- 4 angoli del rettangolo iso (ordine CCW: alto, dx, basso, sx)
    local p1x,p1y = worldToScreen(self.cx,         self.cy+hh, self.z) -- top
    local p2x,p2y = worldToScreen(self.cx+hw,      self.cy,    self.z) -- right
    local p3x,p3y = worldToScreen(self.cx,         self.cy-hh, self.z) -- bottom
    local p4x,p4y = worldToScreen(self.cx-hw,      self.cy,    self.z) -- left

    self.mesh:setVertex(1, p1x,p1y, 0,1)  -- uv (0,1)
    self.mesh:setVertex(2, p2x,p2y, 1,1)
    self.mesh:setVertex(3, p3x,p3y, 1,0)
    self.mesh:setVertex(4, p4x,p4y, 0,0)
  end

  function self:draw()
    self:updateVertices()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(self.mesh)
  end

  return self
end

return M