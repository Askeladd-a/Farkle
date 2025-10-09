-- DiceMesh: dado 3D con mesh, proiezione, fisica ibrida e texture atlas
local DiceMesh = {}
local qmul, qnorm, rotate_vec, project

-- Quaternion math
function qmul(a,b)
  return {
    w = a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z,
    x = a.w*b.x + a.x*b.w + a.y*b.z - a.z*b.y,
    y = a.w*b.y - a.x*b.z + a.y*b.w + a.z*b.x,
    z = a.w*b.z + a.x*b.y - a.y*b.x + a.z*b.w
  }
end
function qnorm(q)
  local s = math.sqrt(q.w*q.w+q.x*q.x+q.y*q.y+q.z*q.z)
  q.w,q.x,q.y,q.z = q.w/s,q.x/s,q.y/s,q.z/s
end
function rotate_vec(v, q)
  local p = {w=0,x=v[1],y=v[2],z=v[3]}
  local qi = {w=q.w, x=-q.x, y=-q.y, z=-q.z}
  local r = qmul(qmul(q,p), qi)
  return {r.x, r.y, r.z}
end

-- Proiezione prospettica semplice
function project(pt, FOV, CAM_Z, CX, CY)
  local Zc = CAM_Z - pt[3]
  local sx = CX + (FOV * pt[1]) / Zc
  local sy = CY - (FOV * pt[2]) / Zc
  return sx, sy, Zc
end

-- Costruzione mesh faccia
local function buildFaceMesh(face, worldVerts, uvMap, tex)
  local i1,i2,i3,i4 = face.v[1], face.v[2], face.v[3], face.v[4]
  local p1,p2,p3,p4 = worldVerts[i1],worldVerts[i2],worldVerts[i3],worldVerts[i4]
  local r = uvMap[face.pip]
  local fmt = {
    {"VertexPosition","float",2},
    {"VertexTexCoord","float",2},
  }
  local verts2D = {
    {p1.sx,p1.sy, r.u0,r.v0},
    {p2.sx,p2.sy, r.u1,r.v0},
    {p3.sx,p3.sy, r.u1,r.v1},
    {p1.sx,p1.sy, r.u0,r.v0},
    {p3.sx,p3.sy, r.u1,r.v1},
    {p4.sx,p4.sy, r.u0,r.v1},
  }
  local mesh = love.graphics.newMesh(fmt, verts2D, "triangles", "stream")
  mesh:setTexture(tex)
  return mesh
end

local function faceDepth(face, worldVerts)
  local zsum=0; for _,i in ipairs(face.v) do zsum = zsum + worldVerts[i].Zc end
  return zsum/#face.v
end

-- Costruttore
function DiceMesh.new(params)
  local self = {}
  -- Stato fisico
  self.x = params.x or 400
  self.y = params.y or 200
  self.z = params.z or 0
  self.vx = params.vx or 0
  self.vy = params.vy or 0
  self.vz = params.vz or 0
  self.omega = params.omega or {x=0,y=0,z=0}
  self.q = params.q or {w=1,x=0,y=0,z=0}
  self.ax = 0; self.ay = 0
  self.g = params.g or 1600
  self.bounce = params.bounce or 0.45
  self.friction_lin = params.friction_lin or 0.995
  self.friction_ang = params.friction_ang or 0.985
  self.tray = params.tray or {x=100,y=100,w=600,h=400}
  self.CX = params.CX or 512
  self.CY = params.CY or 360
  self.FOV = params.FOV or 500
  self.CAM_Z = params.CAM_Z or 1200
  self.verts = params.verts
  self.faces = params.faces
  self.uvMap = params.uvMap
  self.tex = params.tex

  function self:update(dt)
    self.vx = self.vx + self.ax*dt; self.vy = self.vy + self.ay*dt
    self.x  = self.x + self.vx*dt;  self.y  = self.y + self.vy*dt
    self.vz = self.vz - self.g*dt
    self.z  = self.z + self.vz*dt
    if self.z < 0 then self.z=0; if math.abs(self.vz)>60 then self.vz=-self.vz*self.bounce else self.vz=0 end end
    if self.x < self.tray.x then self.x=self.tray.x; self.vx=-self.vx*self.bounce end
    if self.x > self.tray.x+self.tray.w then self.x=self.tray.x+self.tray.w; self.vx=-self.vx*self.bounce end
    if self.y < self.tray.y then self.y=self.tray.y; self.vy=-self.vy*self.bounce end
    if self.y > self.tray.y+self.tray.h then self.y=self.tray.y+self.tray.h; self.vy=-self.vy*self.bounce end
    self.vx = self.vx*self.friction_lin; self.vy = self.vy*self.friction_lin
    self.omega.x = self.omega.x*self.friction_ang; self.omega.y = self.omega.y*self.friction_ang; self.omega.z = self.omega.z*self.friction_ang
    local halfdt = 0.5*dt
    local wq = {w=0,x=self.omega.x,y=self.omega.y,z=self.omega.z}
    local dq = qmul(self.q, wq)
    self.q.w = self.q.w + halfdt*dq.w; self.q.x = self.q.x + halfdt*dq.x; self.q.y = self.q.y + halfdt*dq.y; self.q.z = self.q.z + halfdt*dq.z
    qnorm(self.q)
  end

  function self:draw()
    local shadowScale = 1.0 - math.min(self.z/600, 0.6)
    love.graphics.setColor(0,0,0,0.25)
    love.graphics.ellipse("fill", self.x, self.y+18, 34*shadowScale, 16*shadowScale)
    love.graphics.setColor(1,1,1,1)
    local worldVerts = {}
    for i,v in ipairs(self.verts) do
      local r = rotate_vec(v, self.q)
      local world = { r[1] + (self.x-self.CX), r[2] + (self.y-self.CY) + self.z*0.15, r[3] }
      local sx,sy,Zc = project(world, self.FOV, self.CAM_Z, self.CX, self.CY)
      worldVerts[i] = {sx=sx, sy=sy, Zc=Zc}
    end
    table.sort(self.faces, function(a,b) return faceDepth(a,worldVerts) < faceDepth(b,worldVerts) end)
    for _,f in ipairs(self.faces) do
      local mesh = buildFaceMesh(f, worldVerts, self.uvMap, self.tex)
      love.graphics.draw(mesh)
    end
  end

  return self
end

return DiceMesh
