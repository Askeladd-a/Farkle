-- src/graphics/effects3d.lua
-- Advanced 3D visual effects for pseudo-3D games in LOVE2D
-- Includes shadows, particles, lighting, and post-processing effects

local Effects3D = {}
local Projection3D = require("src.graphics.projection3d")

-- ===== SHADOW SYSTEM =====
local ShadowSystem = {}

function ShadowSystem.new(opts)
  opts = opts or {}
  local self = {
    lightDirection = Projection3D.Vec3.new(opts.lightX or -1, opts.lightY or 1, opts.lightZ or 1):normalize(),
    shadowColor = {opts.shadowR or 0, opts.shadowG or 0, opts.shadowB or 0, opts.shadowA or 0.3},
    groundPlane = opts.groundZ or 0,
    shadowOffset = opts.offset or 2,
    softness = opts.softness or 1.5
  }
  setmetatable(self, {__index = ShadowSystem})
  return self
end

function ShadowSystem:castShadow(worldPos, size, projectionMode)
  -- Calculate shadow position based on light direction
  local lightDir = self.lightDirection
  local heightAboveGround = worldPos.z - self.groundPlane
  
  -- Project object position onto ground plane along light direction
  local t = heightAboveGround / math.abs(lightDir.z)
  local shadowPos = Projection3D.Vec3.new(
    worldPos.x + lightDir.x * t,
    worldPos.y + lightDir.y * t,
    self.groundPlane
  )
  
  -- Convert to screen coordinates
  local sx, sy = Projection3D.project(shadowPos.x, shadowPos.y, shadowPos.z, projectionMode)
  
  -- Shadow gets larger and softer with height
  local shadowSize = size * (1 + heightAboveGround * 0.1)
  local alpha = self.shadowColor[4] * math.max(0.1, 1 - heightAboveGround * 0.05)
  
  return sx, sy + self.shadowOffset, shadowSize, alpha
end

function ShadowSystem:drawShadow(worldPos, size, projectionMode)
  local sx, sy, shadowSize, alpha = self:castShadow(worldPos, size, projectionMode)
  
  love.graphics.setColor(self.shadowColor[1], self.shadowColor[2], self.shadowColor[3], alpha)
  love.graphics.ellipse("fill", sx, sy, shadowSize * self.softness, shadowSize * 0.6)
end

-- ===== PARTICLE SYSTEM =====
local ParticleSystem3D = {}

function ParticleSystem3D.new(opts)
  opts = opts or {}
  local self = {
    particles = {},
    projectionMode = opts.projectionMode or "isometric"
  }
  setmetatable(self, {__index = ParticleSystem3D})
  return self
end

function ParticleSystem3D:emit(position, velocity, color, size, lifetime)
  if #self.particles >= self.maxParticles then
    table.remove(self.particles, 1) -- Remove oldest particle
  end
  
  table.insert(self.particles, {
    pos = position,
    vel = velocity,
    color = color or {1, 1, 1, 1},
    size = size or 2,
    life = lifetime or 1.0,
    maxLife = lifetime or 1.0
  })
end

function ParticleSystem3D:update(dt)
  if not self.particles then return end
  for i, p in ipairs(self.particles) do
    p.pos = p.pos:add(p.vel:scale(dt))
    p.life = (p.life or 1) - dt
    if p.life <= 0 then self.particles[i] = nil end
  end
end

function ParticleSystem3D:draw()
  for _, p in ipairs(self.particles) do
    local sx, sy = Projection3D.project(p.pos.x, p.pos.y, p.pos.z, self.projectionMode)
    love.graphics.setColor(p.color)
    love.graphics.circle("fill", sx, sy, p.size)
  end
end

-- ===== LIGHTING SYSTEM =====
local LightingSystem = {}

function LightingSystem.new(opts)
  opts = opts or {}
  local self = {
    ambientLight = {opts.ambientR or 0.3, opts.ambientG or 0.3, opts.ambientB or 0.3},
    directionalLight = {
      direction = Projection3D.Vec3.new(opts.lightX or -1, opts.lightY or 1, opts.lightZ or 1):normalize(),
      color = {opts.lightR or 1, opts.lightG or 1, opts.lightB or 1},
      intensity = opts.intensity or 0.7
    }
  }
  setmetatable(self, {__index = LightingSystem})
  return self
end

function LightingSystem:calculateLighting(normal, baseColor)
  -- Ambient lighting
  local ambient = {
    baseColor[1] * self.ambientLight[1],
    baseColor[2] * self.ambientLight[2],
    baseColor[3] * self.ambientLight[3],
    baseColor[4] or 1
  }
  
  -- Directional lighting
  local lightIntensity = math.max(0, normal:dot(self.directionalLight.direction)) * self.directionalLight.intensity
  local diffuse = {
    baseColor[1] * self.directionalLight.color[1] * lightIntensity,
    baseColor[2] * self.directionalLight.color[2] * lightIntensity,
    baseColor[3] * self.directionalLight.color[3] * lightIntensity,
    baseColor[4] or 1
  }
  
  -- Combine ambient and diffuse
  return {
    math.min(1, ambient[1] + diffuse[1]),
    math.min(1, ambient[2] + diffuse[2]),
    math.min(1, ambient[3] + diffuse[3]),
    baseColor[4] or 1
  }
end

-- ===== 3D SHAPE PRIMITIVES =====
local Shape3D = {}

function Shape3D.drawCube(position, size, color, projectionMode, lightingSystem)
  local vertices = {
    Projection3D.Vec3.new(-size, -size, -size), Projection3D.Vec3.new( size, -size, -size),
    Projection3D.Vec3.new( size,  size, -size), Projection3D.Vec3.new(-size,  size, -size),
    Projection3D.Vec3.new(-size, -size,  size), Projection3D.Vec3.new( size, -size,  size),
    Projection3D.Vec3.new( size,  size,  size), Projection3D.Vec3.new(-size,  size,  size),
  }
  
  local faces = {
    {indices={5,6,7,8}, normal=Projection3D.Vec3.new(0,0, 1), color={color[1]*1.0, color[2]*1.0, color[3]*1.0}},
    {indices={2,1,4,3}, normal=Projection3D.Vec3.new(0,0,-1), color={color[1]*0.7, color[2]*0.7, color[3]*0.7}},
    {indices={1,5,8,4}, normal=Projection3D.Vec3.new(-1,0,0), color={color[1]*0.8, color[2]*0.8, color[3]*0.8}},
    {indices={6,2,3,7}, normal=Projection3D.Vec3.new( 1,0,0), color={color[1]*0.9, color[2]*0.9, color[3]*0.9}},
    {indices={4,8,7,3}, normal=Projection3D.Vec3.new(0, 1,0), color={color[1]*1.1, color[2]*1.1, color[3]*1.1}},
    {indices={1,2,6,5}, normal=Projection3D.Vec3.new(0,-1,0), color={color[1]*0.6, color[2]*0.6, color[3]*0.6}},
  }
  
  -- Transform vertices to world space
  local worldVertices = {}
  for i, vertex in ipairs(vertices) do
    worldVertices[i] = vertex:add(position)
  end
  
  -- Build visible faces
  local visibleFaces = {}
  for _, face in ipairs(faces) do
    local v1, v2, v3 = worldVertices[face.indices[1]], worldVertices[face.indices[2]], worldVertices[face.indices[3]]
    local edge1, edge2 = v2:sub(v1), v3:sub(v1)
    local normal = edge1:cross(edge2):normalize()
    
    -- Check if face is visible
    local viewDir = Projection3D.Vec3.new(0, 0, -1)
    if projectionMode == "isometric" then viewDir = Projection3D.Vec3.new(0, 0, 1) end
    
    if normal:dot(viewDir) < 0 then
      local screenPoints = {}
      local totalZ = 0
      
      for _, vertIdx in ipairs(face.indices) do
        local worldVert = worldVertices[vertIdx]
        local sx, sy, sz = Projection3D.project(worldVert.x, worldVert.y, worldVert.z, projectionMode)
        table.insert(screenPoints, {sx, sy})
        totalZ = totalZ + sz
      end
      
      -- Apply lighting if available
      local faceColor = face.color
      if lightingSystem then
        faceColor = lightingSystem:calculateLighting(normal, face.color)
      end
      
      table.insert(visibleFaces, {
        points = screenPoints,
        color = faceColor,
        depth = totalZ / 4
      })
    end
  end
  
  -- Sort and draw faces
  table.sort(visibleFaces, function(a, b) return a.depth > b.depth end)
  
  for _, face in ipairs(visibleFaces) do
    love.graphics.setColor(face.color)
    local points = {}
    for _, point in ipairs(face.points) do
      table.insert(points, point[1])
      table.insert(points, point[2])
    end
    love.graphics.polygon("fill", points)
    
    -- Optional wireframe
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.polygon("line", points)
  end
end

function Shape3D.drawSphere(position, radius, color, projectionMode, segments)
  segments = segments or 8
  local points = {}
  
  -- Generate sphere points (simplified as circles at different heights)
  for i = 0, segments do
    local theta = (i / segments) * math.pi
    local y = math.cos(theta) * radius
    local r = math.sin(theta) * radius
    
    for j = 0, segments do
      local phi = (j / segments) * 2 * math.pi
      local x = math.cos(phi) * r
      local z = math.sin(phi) * r
      
      local worldPos = position:add(Projection3D.Vec3.new(x, y, z))
      local sx, sy = Projection3D.project(worldPos.x, worldPos.y, worldPos.z, projectionMode)
      table.insert(points, {sx, sy, worldPos.z})
    end
  end
  
  -- Sort by depth and draw as circles
  table.sort(points, function(a, b) return a[3] > b[3] end)
  
  for _, point in ipairs(points) do
    local alpha = math.max(0.1, 1 - (point[3] - position.z) / radius * 0.5)
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.circle("fill", point[1], point[2], 2)
  end
end

-- ===== MAIN EFFECTS3D API =====
Effects3D.ShadowSystem = ShadowSystem
Effects3D.ParticleSystem3D = ParticleSystem3D
Effects3D.LightingSystem = LightingSystem
Effects3D.Shape3D = Shape3D

-- Default instances
local defaultShadows = ShadowSystem.new()
local defaultLighting = LightingSystem.new()
local defaultParticles = ParticleSystem3D.new()

function Effects3D.setProjectionMode(mode)
  defaultParticles.projectionMode = mode
end

function Effects3D.update(dt)
  defaultParticles:update(dt)
end

function Effects3D.drawShadow(position, size, projectionMode)
  defaultShadows:drawShadow(position, size, projectionMode)
end

function Effects3D.emitParticles(position, count, options)
  options = options or {}
  for i = 1, count do
    local vel = Projection3D.Vec3.new(
      (love.math.random() - 0.5) * (options.spread or 10),
      (love.math.random() - 0.5) * (options.spread or 10),
      love.math.random() * (options.upwardVel or 5)
    )
    defaultParticles:emit(
      position,
      vel,
      options.color or {1, 1, 1, 1},
      options.size or 2,
      options.lifetime or 1.0
    )
  end
end

function Effects3D.drawParticles()
  defaultParticles:draw()
end

function Effects3D.calculateLighting(normal, baseColor)
  return defaultLighting:calculateLighting(normal, baseColor)
end

return Effects3D