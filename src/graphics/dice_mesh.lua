-- dice_mesh.lua — Enhanced 3D dice with realistic physics and animations
-- Uses the new Projection3D system for consistent rendering
local Dice = {}
local Projection3D = require("src.graphics.projection3d")
local Effects3D = require("src.graphics.effects3d")

-- ======= config =======
local ATLAS_PATH = "assets/dice/dice_atlas.png"
local ATLAS_COLS, ATLAS_ROWS = 3, 2
Dice.mode = "isometric"  -- "perspective", "isometric", "orthographic"
Dice.board = nil -- Reference to the board for physics constraints

-- fisica super-semplice
local GRAVITY = -22
local RESTITUTION = 0.35
local FRICTION_XY = 0.98
local ANG_FRICTION = 0.985

-- ======= modello cubo =======
local CUBE_VERTICES = {
  Projection3D.Vec3.new(-1,-1,-1), Projection3D.Vec3.new(1,-1,-1), 
  Projection3D.Vec3.new(1,1,-1), Projection3D.Vec3.new(-1,1,-1), -- back face 1-4
  Projection3D.Vec3.new(-1,-1, 1), Projection3D.Vec3.new(1,-1, 1), 
  Projection3D.Vec3.new(1,1, 1), Projection3D.Vec3.new(-1,1, 1), -- front face 5-8
}

-- facce del cubo con normali e numeri
local CUBE_FACES = {
  {indices={5,6,7,8}, num=1, normal=Projection3D.Vec3.new(0,0, 1)}, -- front +Z
  {indices={2,1,4,3}, num=6, normal=Projection3D.Vec3.new(0,0,-1)}, -- back  -Z
  {indices={1,5,8,4}, num=2, normal=Projection3D.Vec3.new(-1,0,0)}, -- left  -X
  {indices={6,2,3,7}, num=5, normal=Projection3D.Vec3.new( 1,0,0)}, -- right +X
  {indices={4,8,7,3}, num=3, normal=Projection3D.Vec3.new(0, 1,0)}, -- top   +Y
  {indices={1,2,6,5}, num=4, normal=Projection3D.Vec3.new(0,-1,0)}, -- bottom -Y
}

-- ======= texture atlas UV =======
local atlas, faceMesh = nil, {}

local function uvRectForFace(num)
  local col = ((num-1) % ATLAS_COLS)
  local row = math.floor((num-1) / ATLAS_COLS)
  local u0 = col / ATLAS_COLS
  local v0 = row / ATLAS_ROWS
  local u1 = (col+1) / ATLAS_COLS
  local v1 = (row+1) / ATLAS_ROWS
  return u0,v0,u1,v1
end

local function makeFaceMesh(num)
  local u0,v0,u1,v1 = uvRectForFace(num)
  local verts = {
    {0,0,  u0,v0, 1,1,1,1},
    {0,0,  u1,v0, 1,1,1,1},
    {0,0,  u1,v1, 1,1,1,1},
    {0,0,  u0,v1, 1,1,1,1},
  }
  local m = love.graphics.newMesh(verts, "fan", "dynamic")
  if atlas then m:setTexture(atlas) end
  return m
end

-- ======= dado oggetto =======
local function makeDie(cx, cy, size)
  return {
    pos = Projection3D.Vec3.new(cx, cy, 0),
    vel = Projection3D.Vec3.new(love.math.random(-10,10), love.math.random(-10,10), love.math.random(14,20)),
    ang = {x=love.math.random()*6.283, y=love.math.random()*6.283, z=love.math.random()*6.283},
    angVel = {x=love.math.random(-6,6), y=love.math.random(-6,6), z=love.math.random(-6,6)},
    size = size or 1,
    resting = false,
    value = love.math.random(1,6), -- current face showing
    bounceCount = 0,
    lastCollisionTime = 0,
  }
end

local function snap90(a) 
  local q = math.pi/2
  return math.floor((a+q/2)/q)*q 
end

-- ======= API =======
function Dice.load()
  -- Setup projection system
  Projection3D.setCamera(Dice.mode)
  Effects3D.setProjectionMode(Dice.mode)
  
  -- Load atlas
  local success, img = pcall(love.graphics.newImage, ATLAS_PATH)
  if success then
    atlas = img
    print("[Dice] Atlas loaded:", ATLAS_PATH)
  else
    print("[Dice] Failed to load atlas, using colored faces")
  end
  
  -- Create face meshes
  for i = 1, 6 do 
    faceMesh[i] = makeFaceMesh(i) 
  end
  
  Dice.list = {}
end

function Dice.spawn(n, center, spread, size, trayName)
  center = center or Projection3D.Vec3.new(0, 0, 0)
  spread = spread or 8
  
  -- If board is available and tray specified, use tray center
  if Dice.board and trayName then
    local tray = Dice.board.trays[trayName]
    if tray then
      center = tray.center
      spread = math.min(spread, tray.width/3, tray.height/3)
    end
  end
  
  -- Clear or create dice list
  Dice.list = Dice.list or {}
  
  for i = 1, (n or 6) do
    local offset = Projection3D.Vec3.new(
      love.math.random(-spread, spread), 
      love.math.random(-spread, spread), 
      love.math.random(2, 5) -- Start slightly above surface
    )
    local pos = center:add(offset)
    local die = makeDie(pos.x, pos.y, size or 1)
    die.assignedTray = trayName -- Remember which tray this die belongs to
    table.insert(Dice.list, die)
  end
end

function Dice.setBoard(board)
  Dice.board = board
end

local function updateDie(d, dt)
  if d.resting then return end
  
  -- Physics
  d.vel = d.vel:add(Projection3D.Vec3.new(0, 0, GRAVITY * dt))
  d.pos = d.pos:add(d.vel:mul(dt))
  
  -- Board constraints - keep dice in assigned tray
  if Dice.board and d.assignedTray then
    local constrainedPos = Dice.board:constrainDiceToTray(d.pos, d.assignedTray)
    if constrainedPos then
      -- Check if dice hit tray walls
      if math.abs(constrainedPos.x - d.pos.x) > 0.1 or math.abs(constrainedPos.y - d.pos.y) > 0.1 then
        -- Bounce off walls
        if math.abs(constrainedPos.x - d.pos.x) > 0.1 then
          d.vel.x = -d.vel.x * RESTITUTION
        end
        if math.abs(constrainedPos.y - d.pos.y) > 0.1 then
          d.vel.y = -d.vel.y * RESTITUTION
        end
      end
      d.pos = constrainedPos
    end
  end
  
  -- Ground collision with particle effects
  if d.pos.z < 0 then
    d.pos.z = 0
    d.vel.z = -d.vel.z * RESTITUTION
    d.vel.x, d.vel.y = d.vel.x * FRICTION_XY, d.vel.y * FRICTION_XY
    d.angVel.x = d.angVel.x * ANG_FRICTION
    d.angVel.y = d.angVel.y * ANG_FRICTION
    d.angVel.z = d.angVel.z * ANG_FRICTION
    
    -- Emit particles on bounce
    local currentTime = love.timer.getTime()
    if currentTime - d.lastCollisionTime > 0.1 then -- Prevent spam
      local intensity = math.min(1, math.abs(d.vel.z) / 10)
      if intensity > 0.3 then
        Effects3D.emitParticles(d.pos, math.floor(intensity * 5), {
          color = {1, 0.8, 0.3, 1},
          spread = 8,
          upwardVel = 3,
          size = 1 + intensity,
          lifetime = 0.5 + intensity
        })
      end
      d.lastCollisionTime = currentTime
      d.bounceCount = d.bounceCount + 1
    end
    
    -- Check if at rest
    if math.abs(d.vel.z) < 1.2 and 
       (math.abs(d.vel.x) + math.abs(d.vel.y)) < 1.2 and
       (math.abs(d.angVel.x) + math.abs(d.angVel.y) + math.abs(d.angVel.z)) < 0.8 then
      d.vel = Projection3D.Vec3.new(0, 0, 0)
      d.ang.x, d.ang.y, d.ang.z = snap90(d.ang.x), snap90(d.ang.y), snap90(d.ang.z)
      d.resting = true
      
      -- Final particle burst when coming to rest
      Effects3D.emitParticles(d.pos, 3, {
        color = {0.8, 1, 0.8, 1},
        spread = 5,
        upwardVel = 2,
        size = 0.5,
        lifetime = 1.0
      })
    end
  end
  
  -- Update rotation
  d.ang.x = d.ang.x + d.angVel.x * dt
  d.ang.y = d.ang.y + d.angVel.y * dt
  d.ang.z = d.ang.z + d.angVel.z * dt
end

function Dice.update(dt)
  for _, d in ipairs(Dice.list) do 
    updateDie(d, dt) 
  end
  Effects3D.update(dt)
end

-- Transform vertex based on die position and rotation
local function transformVertex(vertex, die)
  local s = die.size
  
  -- Apply rotation matrices
  local rotX = Projection3D.Matrix4.rotationX(die.ang.x)
  local rotY = Projection3D.Matrix4.rotationY(die.ang.y)
  local rotZ = Projection3D.Matrix4.rotationZ(die.ang.z)
  local rotation = rotZ:mul(rotY:mul(rotX))
  
  -- Scale, rotate, translate
  local scaled = vertex:mul(s)
  local rotated, _ = rotation:transform(scaled)
  return rotated:add(die.pos)
end

local function drawDie(d)
  -- Draw shadow first (behind the die)
  Effects3D.drawShadow(d.pos, d.size * 15, Dice.mode)
  
  -- Transform all vertices
  local transformedVerts = {}
  for i, vertex in ipairs(CUBE_VERTICES) do
    transformedVerts[i] = transformVertex(vertex, d)
  end
  
  -- Build visible faces list with depth sorting
  local visibleFaces = {}
  for _, face in ipairs(CUBE_FACES) do
    local v1, v2, v3, v4 = transformedVerts[face.indices[1]], 
                          transformedVerts[face.indices[2]], 
                          transformedVerts[face.indices[3]], 
                          transformedVerts[face.indices[4]]
    
    -- Calculate face normal in world space
    local edge1 = v2:sub(v1)
    local edge2 = v3:sub(v1)
    local normal = edge1:cross(edge2):normalize()
    
    -- View direction depends on projection mode
    local viewDir = Projection3D.Vec3.new(0, 0, -1)
    if Dice.mode == "isometric" then
      viewDir = Projection3D.Vec3.new(0, 0, 1)
    end
    
    -- Back-face culling
    if normal:dot(viewDir) < 0 then
      local screenPoints = {}
      local totalZ = 0
      
      for _, vertIdx in ipairs(face.indices) do
        local worldVert = transformedVerts[vertIdx]
        local sx, sy, sz = Projection3D.project(worldVert.x, worldVert.y, worldVert.z, Dice.mode)
        table.insert(screenPoints, {sx, sy})
        totalZ = totalZ + sz
      end
      
      -- Calculate lighting for this face
      local baseColor = {0.9, 0.9, 0.85, 1} -- Dice base color
      local litColor = Effects3D.calculateLighting(normal, baseColor)
      
      table.insert(visibleFaces, {
        face = face,
        points = screenPoints,
        depth = totalZ / 4,
        color = litColor,
        normal = normal
      })
    end
  end
  
  -- Sort by depth (painter's algorithm)
  table.sort(visibleFaces, function(a, b) return a.depth > b.depth end)
  
  -- Draw faces
  for _, visibleFace in ipairs(visibleFaces) do
    local mesh = faceMesh[visibleFace.face.num]
    if mesh then
      -- Update mesh vertices with screen coordinates
      for i = 1, 4 do
        local sx, sy = visibleFace.points[i][1], visibleFace.points[i][2]
        local u, v, r, g, b, a = mesh:getVertex(i)
        mesh:setVertex(i, sx, sy, u, v, 
                      visibleFace.color[1], visibleFace.color[2], visibleFace.color[3], visibleFace.color[4])
      end
      
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(mesh)
      
      -- Optional: Add subtle edge highlight for 3D effect
      love.graphics.setColor(1, 1, 1, 0.2)
      love.graphics.setLineWidth(1)
      local points = {}
      for _, point in ipairs(visibleFace.points) do
        table.insert(points, point[1])
        table.insert(points, point[2])
      end
      love.graphics.polygon("line", points)
    else
      -- Fallback: draw colored face if no texture
      love.graphics.setColor(visibleFace.color)
      local points = {}
      for _, point in ipairs(visibleFace.points) do
        table.insert(points, point[1])
        table.insert(points, point[2])
      end
      love.graphics.polygon("fill", points)
      
      -- Draw face number
      if #visibleFace.points > 0 then
        local centerX = (visibleFace.points[1][1] + visibleFace.points[3][1]) / 2
        local centerY = (visibleFace.points[1][2] + visibleFace.points[3][2]) / 2
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(tostring(visibleFace.face.num), centerX - 8, centerY - 8)
      end
    end
  end
  
  -- Add floating particles if die is moving
  if not d.resting and love.math.random() < 0.1 then
    Effects3D.emitParticles(d.pos:add(Projection3D.Vec3.new(0, 0, d.size)), 1, {
      color = {0.9, 0.9, 1, 0.8},
      spread = 2,
      upwardVel = 1,
      size = 0.8,
      lifetime = 0.8
    })
  end
end

function Dice.draw()
  -- Draw all dice
  for _, d in ipairs(Dice.list) do 
    drawDie(d) 
  end
  
  -- Draw particle effects on top
  Effects3D.drawParticles()
end

function Dice.setMode(mode)
  Dice.mode = mode
  Projection3D.setCamera(mode)
  Effects3D.setProjectionMode(mode)
end

-- Reroll dice (reset physics and randomize orientation)
function Dice.reroll()
  for _, d in ipairs(Dice.list) do
    d.resting = false
    d.pos.z = 0
    d.vel = Projection3D.Vec3.new(love.math.random(-10,10), love.math.random(-10,10), love.math.random(14,20))
    d.ang.x, d.ang.y, d.ang.z = love.math.random()*6.283, love.math.random()*6.283, love.math.random()*6.283
    d.angVel.x, d.angVel.y, d.angVel.z = love.math.random(-6,6), love.math.random(-6,6), love.math.random(-6,6)
    d.bounceCount = 0
    d.lastCollisionTime = 0
    
    -- Emit initial particles
    Effects3D.emitParticles(d.pos, 8, {
      color = {1, 0.9, 0.5, 1},
      spread = 15,
      upwardVel = 8,
      size = 1.5,
      lifetime = 1.2
    })
  end
end

return Dice
