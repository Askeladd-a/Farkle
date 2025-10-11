-- board_iso.lua — board a due ante in isometrica (LÖVE 11.x)
local iso = require("src.iso_utils")
local Board = {}
Board.__index = Board

function Board.new(pos, size, woodImage)
  local self = setmetatable({}, Board)
  self.pos  = pos  or {x=0,y=0,z=0}
  self.size = size or {w=10, h=7, t=0.25}
  self.open_t = 1.0
  self.bevel  = 0.35
  self.wood   = woodImage
  self.tintWood  = {0.58,0.36,0.18}
  self.hingeTint = {0.75,0.58,0.20}
  return self
end

local function quad_to_screen(q)
  local v = {}
  for i=1,4 do
    local x,y = iso.worldToScreen(q[i].x, q[i].y, q[i].z or 0)
    v[#v+1] = x; v[#v+1] = y
  end
  return v
end

local function make_leaf(cx,cy,z,w,h)
  return {
    {x=cx-w/2, y=cy+h/2, z=z},
    {x=cx+w/2, y=cy+h/2, z=z},
    {x=cx+w/2, y=cy-h/2, z=z},
    {x=cx-w/2, y=cy-h/2, z=z},
  }
end

local function inset(quad, d)
  local cx = (quad[1].x + quad[2].x + quad[3].x + quad[4].x)/4
  local cy = (quad[1].y + quad[2].y + quad[3].y + quad[4].y)/4
  local out = {}
  for i=1,4 do
    local vx,vy = quad[i].x-cx, quad[i].y-cy
    local len = math.sqrt(vx*vx+vy*vy)
    local nx,ny = vx/len, vy/len
    out[i] = {x=quad[i].x - nx*d, y=quad[i].y - ny*d, z=quad[i].z}
  end
  return out
end

local function fill_quad(quad, wood, color)
  if wood then
    local function uv(p) return p.x/2, p.y/2 end
    local verts = {}
    for i=1,4 do
      local x,y = iso.worldToScreen(quad[i].x, quad[i].y, quad[i].z or 0)
      local u,v = uv(quad[i])
      verts[i] = {x,y,u,v, 1,1,1,1}
    end
    local m = love.graphics.newMesh(verts, "fan", "stream")
    wood:setWrap("repeat","repeat")
    m:setTexture(wood)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(m)
  else
    love.graphics.setColor(color)
    love.graphics.polygon("fill", quad_to_screen(quad))
  end
end

function Board:draw()
  local w,h,t = self.size.w, self.size.h, self.size.t
  local gap = 0.08
  local half = (h-gap)/2
  local cx, cy, z = self.pos.x, self.pos.y, self.pos.z
  local cTop    = {x=cx, y=cy + (half/2)+gap/2, z=z}
  local cBottom = {x=cx, y=cy - (half/2)-gap/2, z=z}
  local lift = (1 - self.open_t) * (t*6)
  local top    = make_leaf(cTop.x, cTop.y, z,     w, half)
  local bottom = make_leaf(cBottom.x, cBottom.y, z, w, half)
  for _,p in ipairs(top) do if p.y < cTop.y then p.z = p.z + lift end end
  for _,p in ipairs(bottom) do if p.y > cBottom.y then p.z = p.z + lift end end
  love.graphics.setColor(0,0,0,0.12)
  local function shadow(q)
    local x1,y1 = iso.worldToScreen(q[1].x,q[1].y,0)
    local x3,y3 = iso.worldToScreen(q[3].x,q[3].y,0)
    local cxm=(x1+x3)/2; local cym=(y1+y3)/2
    love.graphics.ellipse("fill", cxm, cym+12, math.abs(x3-x1)/2, 16)
  end
  shadow(top); shadow(bottom)
  fill_quad(top,    self.wood, self.tintWood)
  fill_quad(bottom, self.wood, self.tintWood)
  local t1,t2 = self.bevel, self.bevel*1.9
  local top1, top2 = inset(top,t1), inset(top,t2)
  local bot1, bot2 = inset(bottom,t1), inset(bottom,t2)
  love.graphics.setColor(0,0,0,0.10); love.graphics.polygon("fill", quad_to_screen(top1))
  love.graphics.setColor(0,0,0,0.10); love.graphics.polygon("fill", quad_to_screen(bot1))
  love.graphics.setColor(1,1,1,0.06); love.graphics.polygon("fill", quad_to_screen(top2))
  love.graphics.setColor(1,1,1,0.06); love.graphics.polygon("fill", quad_to_screen(bot2))
  love.graphics.setColor(0,0,0,0.28)
  love.graphics.polygon("line", quad_to_screen(top))
  love.graphics.polygon("line", quad_to_screen(bottom))
  love.graphics.setColor(self.hingeTint)
  local function hinge(xoff)
    local q = make_leaf(cx + xoff, cy, z + t + 0.02, 0.9, 0.18)
    fill_quad(q, nil, self.hingeTint)
  end
  hinge(-w*0.25); hinge(w*0.25)
end

return Board
