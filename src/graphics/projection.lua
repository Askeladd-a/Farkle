-- projection.lua
-- Math + projection helpers for fake 3D rendering in LOVE2D
local P = {}

-- Vec3 constructor
function P.vec3(x,y,z) return {x=x or 0, y=y or 0, z=z or 0} end

-- Basic ops
function P.add(a,b) return P.vec3(a.x+b.x, a.y+b.y, a.z+b.z) end
function P.sub(a,b) return P.vec3(a.x-b.x, a.y-b.y, a.z-b.z) end
function P.muls(v,s) return P.vec3(v.x*s, v.y*s, v.z*s) end
function P.dot(a,b) return a.x*b.x + a.y*b.y + a.z*b.z end
function P.cross(a,b)
  return P.vec3(
    a.y*b.z - a.z*b.y,
    a.z*b.x - a.x*b.z,
    a.x*b.y - a.y*b.x
  )
end
function P.normalize(v)
  local m = math.sqrt(P.dot(v,v))
  if m == 0 then return P.vec3(0,0,0) end
  return P.muls(v, 1/m)
end

-- Rotation helpers (return transform functions)
function P.rotX(a)
  local c,s = math.cos(a), math.sin(a)
  return function(v) return P.vec3(v.x, c*v.y - s*v.z, s*v.y + c*v.z) end
end
function P.rotY(a)
  local c,s = math.cos(a), math.sin(a)
  return function(v) return P.vec3(c*v.x + s*v.z, v.y, -s*v.x + c*v.z) end
end
function P.rotZ(a)
  local c,s = math.cos(a), math.sin(a)
  return function(v) return P.vec3(c*v.x - s*v.y, s*v.x + c*v.y, v.z) end
end
function P.compose(f,g) return function(v) return f(g(v)) end end

-- Screen center helper (call after getDimensions each frame if dynamic)
function P.center(v)
  local W,H = love.graphics.getWidth(), love.graphics.getHeight()
  return v.x + W/2, v.y + H/2
end

-- Isometric projection (classic 35.264/45)
local ISO_A = math.rad(35.264)
local ISO_B = math.rad(45)
local isoRot = P.compose(P.rotX(ISO_A), P.rotY(ISO_B))
function P.project_iso(v3, scale)
  local v = isoRot(v3)
  return v.x*scale, v.y*scale, v.z
end

-- Simple perspective projection (camera at (0,0,cz), looking toward origin)
function P.project_persp(v3, fov_deg, cz)
  local f = 1 / math.tan(math.rad(fov_deg) / 2)
  local vz = v3.z + cz
  if vz < 0.1 then vz = 0.1 end
  local x = (v3.x * f) / vz
  local y = (v3.y * f) / vz
  return x, y, vz
end

return P
