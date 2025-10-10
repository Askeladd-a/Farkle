-- dice3d.lua
-- Fake 3D dice rendering (isometric + perspective) using pure 2D primitives.
local P = require("src.graphics.projection")

local Dice3D = {}

Dice3D.mode = "persp" -- or "iso"
Dice3D.FOV = 70
Dice3D.CAM_Z = 5
Dice3D.SCALE_ISO = 100
Dice3D.SCALE_PERSP = 220

-- Cube geometry (unit cube centered at origin)
local cube = {
  verts = {
    P.vec3(-1,-1,-1), P.vec3( 1,-1,-1), P.vec3( 1, 1,-1), P.vec3(-1, 1,-1), -- back 1..4
    P.vec3(-1,-1, 1), P.vec3( 1,-1, 1), P.vec3( 1, 1, 1), P.vec3(-1, 1, 1), -- front 5..8
  },
  faces = {
    {idx={5,6,7,8},  color={0.92,0.92,0.92}, num=1, normal=P.vec3(0,0, 1)}, -- front
    {idx={2,1,4,3},  color={0.88,0.88,0.88}, num=6, normal=P.vec3(0,0,-1)}, -- back
    {idx={1,5,8,4},  color={0.90,0.90,0.90}, num=2, normal=P.vec3(-1,0,0)}, -- left
    {idx={6,2,3,7},  color={0.90,0.90,0.90}, num=5, normal=P.vec3( 1,0,0)}, -- right
    {idx={4,8,7,3},  color={0.95,0.95,0.95}, num=3, normal=P.vec3(0, 1,0)}, -- top
    {idx={1,2,6,5},  color={0.85,0.85,0.85}, num=4, normal=P.vec3(0,-1,0)}, -- bottom
  }
}

local pipLayouts = {
  [1]={{0,0}},
  [2]={{-0.5,-0.5},{0.5,0.5}},
  [3]={{-0.6,-0.6},{0,0},{0.6,0.6}},
  [4]={{-0.6,-0.6},{0.6,-0.6},{0.6,0.6},{-0.6,0.6}},
  [5]={{-0.6,-0.6},{0.6,-0.6},{0,0},{0.6,0.6},{-0.6,0.6}},
  [6]={{-0.6,-0.6},{0.6,-0.6},{-0.6,0},{0.6,0},{-0.6,0.6},{0.6,0.6}},
}

local function applyRotation(v, yaw, pitch, roll)
  local R = P.compose(P.rotY(yaw), P.compose(P.rotX(pitch), P.rotZ(roll)))
  return R(v)
end

local function projectPoint(v)
  if Dice3D.mode == "iso" then
    local x,y = P.project_iso(v, Dice3D.SCALE_ISO)
    local sx, sy = P.center(P.vec3(x,y,0))
    return sx, sy, v.z
  else
    local x,y,z = P.project_persp(v, Dice3D.FOV, Dice3D.CAM_Z)
    x = x * Dice3D.SCALE_PERSP
    y = y * Dice3D.SCALE_PERSP
    local sx, sy = P.center(P.vec3(x,y,0))
    return sx, sy, z
  end
end

-- Draw a single die given state {x,y,z, yaw,pitch,roll, scale}
function Dice3D.drawDie(state)
  local yaw = state.yaw or 0
  local pitch = state.pitch or 0
  local roll = state.roll or 0
  local scale = state.scale or 1
  local offset = P.vec3(state.x or 0, state.y or 0, state.z or 0)

  -- transform cube vertices
  local tv = {}
  for i,v in ipairs(cube.verts) do
    local r = applyRotation(v, yaw, pitch, roll)
    tv[i] = P.add(P.muls(r, scale), offset)
  end

  -- choose faces to draw (back-face culling)
  local drawFaces = {}
  local viewdir = (Dice3D.mode == "iso") and P.vec3(0,0,1) or P.vec3(0,0,-1)
  for _,f in ipairs(cube.faces) do
    local a,b,c,d = tv[f.idx[1]], tv[f.idx[2]], tv[f.idx[3]], tv[f.idx[4]]
    local n = P.normalize(P.cross(P.sub(b,a), P.sub(c,a)))
    if P.dot(n, viewdir) < 0 then
      local poly, zsum = {}, 0
      for _,ii in ipairs(f.idx) do
        local sx,sy,zz = projectPoint(tv[ii]); zsum = zsum + zz
        table.insert(poly, sx); table.insert(poly, sy)
      end
      table.insert(drawFaces, {poly=poly, z=zsum/#f.idx, face=f, verts={a,b,c,d}})
    end
  end
  table.sort(drawFaces, function(A,B) return A.z > B.z end)

  -- draw faces + pips
  for _,F in ipairs(drawFaces) do
    local col = F.face.color
    love.graphics.setColor(col)
    love.graphics.polygon("fill", F.poly)
    love.graphics.setColor(0,0,0,0.25)
    love.graphics.polygon("line", F.poly)

    -- pips: build local basis
    local idx = F.face.idx
    local v1,v2,v3,v4 = tv[idx[1]], tv[idx[2]], tv[idx[3]], tv[idx[4]]
    local center = P.muls(P.add(P.add(v1,v2), P.add(v3,v4)), 0.25)
    local ux = P.muls(P.normalize(P.sub(v2,v1)), 0.8*scale)
    local uy = P.muls(P.normalize(P.sub(v3,v2)), 0.8*scale)
    local layout = pipLayouts[F.face.num]
    love.graphics.setColor(0.12,0.12,0.12,0.9)
    for _,p in ipairs(layout) do
      local world = P.add(P.add(center, P.muls(ux, p[1])), P.muls(uy, p[2]))
      local sx,sy = projectPoint(world)
      love.graphics.circle("fill", sx, sy, 6*scale)
    end
  end
end

function Dice3D.setMode(m)
  if m == "iso" or m == "persp" then Dice3D.mode = m end
end

return Dice3D
