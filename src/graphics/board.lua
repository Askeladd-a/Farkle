-- board3d.lua
-- Simple isometric board renderer (tile diamond grid) for fake 3D look.
local Board3D = {}

function Board3D.new(opts)
  local b = {
    x = opts.x or love.graphics.getWidth()/2,
    y = opts.y or love.graphics.getHeight()/2,
    cols = opts.cols or 4,
    rows = opts.rows or 3,
    tileW = opts.tileW or 70,
    tileH = opts.tileH or 35,
    colorA = opts.colorA or {0.68,0.7,0.74},
    colorB = opts.colorB or {0.60,0.62,0.66},
    line = opts.line or {0,0,0,0.22},
    alpha = 1,
    scale = opts.scale or 1,
    open = 0,
    setOpen = function(self, v)
      self.open = v or 0
    end,
    animateTo = function(self, targetOpen, duration)
      -- No-op for now; could implement animation logic here
      self.open = targetOpen or self.open
    end,
    update = function(self, dt)
      -- No-op for now; could implement animation logic here
    end
  }
  return setmetatable(b, {__index = Board3D})
end

function Board3D:draw()
  local s = self.tileW/2 * self.scale
  love.graphics.push()
  love.graphics.translate(self.x, self.y)
  for r=1,self.rows do
    for c=1,self.cols do
      local x = (c - (self.cols+1)/2) * s
      local y = (r - (self.rows+1)/2) * s*0.5
      local p1x,p1y = x, y - s*0.5
      local p2x,p2y = x + s, y
      local p3x,p3y = x, y + s*0.5
      local p4x,p4y = x - s, y
      local even = ((c+r) % 2 == 0)
      local base = even and self.colorA or self.colorB
      love.graphics.setColor(base[1], base[2], base[3], (base[4] or 1)*self.alpha)
      love.graphics.polygon("fill", p1x,p1y, p2x,p2y, p3x,p3y, p4x,p4y)
      love.graphics.setColor(self.line)
      love.graphics.polygon("line", p1x,p1y, p2x,p2y, p3x,p3y, p4x,p4y)
    end
  end
  love.graphics.pop()
end

return Board3D
