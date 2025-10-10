-- src/graphics/board3d_realistic.lua
-- Realistic wooden board with dice trays, based on traditional game board design
-- Integrates with Projection3D system for consistent 3D rendering

local Board3D = {}
local Projection3D = require("src.graphics.projection3d")
local Effects3D = require("src.graphics.effects3d")

-- ===== BOARD CONFIGURATION =====
local BOARD_CONFIG = {
  -- Overall dimensions
  width = 32,
  height = 20,
  thickness = 0.8,
  
  -- Tray dimensions
  trayWidth = 10,
  trayHeight = 3,
  trayDepth = 0.6,
  trayInset = 0.3,
  
  -- Visual details
  edgeRadius = 0.4,
  hingeWidth = 0.3,
  decorativeBorder = 0.2,
  
  -- Colors
  woodColor = {0.6, 0.4, 0.25, 1},
  woodDark = {0.45, 0.3, 0.18, 1},
  woodLight = {0.75, 0.55, 0.35, 1},
  hingeColor = {0.7, 0.6, 0.3, 1}, -- Brass hinges
  feltColor = {0.1, 0.4, 0.1, 1},  -- Green felt in trays
}

-- ===== BOARD OBJECT =====
function Board3D.new(opts)
  opts = opts or {}
  
  local board = {
    -- Position and orientation
    position = Projection3D.Vec3.new(
      opts.x or 0,
      opts.y or 0,
      opts.z or 0
    ),
    rotation = {x = 0, y = 0, z = 0},
    
    -- Animation state
    openAmount = opts.openAmount or 1.0, -- 0 = closed, 1 = fully open
    targetOpen = 1.0,
    animationSpeed = 2.0,
    
    -- Configuration
    config = BOARD_CONFIG,
    projectionMode = opts.projectionMode or "isometric",
    
    -- Tray areas for dice physics
    trays = {},
    
    -- Visual components
    woodTexture = nil, -- Can be loaded later
    feltTexture = nil,
  }
  
  -- Imposta la metatable PRIMA di chiamare metodi
  setmetatable(board, {__index = Board3D})
  -- Ora i metodi sono disponibili
  board:calculateTrayAreas()
  return board
end

-- ===== TRAY CALCULATION =====
function Board3D:calculateTrayAreas()
  local cfg = self.config
  local boardPos = self.position
  -- Top tray (when board is open)
  local topTrayY = boardPos.y + cfg.height/4
  local bottomTrayY = boardPos.y - cfg.height/4
  self.trays = {
    top = {
      center = Projection3D.Vec3.new(boardPos.x, topTrayY, boardPos.z + cfg.trayDepth/2),
      width = cfg.trayWidth,
      height = cfg.trayHeight,
      depth = cfg.trayDepth,
      worldBounds = self:getTrayWorldBounds("top"),
    },
    bottom = {
      center = Projection3D.Vec3.new(boardPos.x, bottomTrayY, boardPos.z + cfg.trayDepth/2),
      width = cfg.trayWidth,
      height = cfg.trayHeight,
      depth = cfg.trayDepth,
      worldBounds = self:getTrayWorldBounds("bottom"),
    }
  }
end

-- Stub per world bounds delle vasche
function Board3D:getTrayWorldBounds(tray)
  local cfg = self.config
  local boardPos = self.position
  if tray == "top" then
    return {
      minX = boardPos.x - cfg.trayWidth/2,
      maxX = boardPos.x + cfg.trayWidth/2,
      minY = boardPos.y + cfg.height/4 - cfg.trayHeight/2,
      maxY = boardPos.y + cfg.height/4 + cfg.trayHeight/2,
      minZ = boardPos.z,
      maxZ = boardPos.z + cfg.trayDepth
    }
  else
    return {
      minX = boardPos.x - cfg.trayWidth/2,
      maxX = boardPos.x + cfg.trayWidth/2,
      minY = boardPos.y - cfg.height/4 - cfg.trayHeight/2,
      maxY = boardPos.y - cfg.height/4 + cfg.trayHeight/2,
      minZ = boardPos.z,
      maxZ = boardPos.z + cfg.trayDepth
    }
  end
end

-- ===== ANIMATION SYSTEM =====
function Board3D:setOpen(amount)
  self.targetOpen = math.max(0, math.min(1, amount))
end

function Board3D:animateTo(targetOpen, duration)
  self.targetOpen = math.max(0, math.min(1, targetOpen))
  if duration and duration > 0 then
    self.animationSpeed = math.abs(targetOpen - self.openAmount) / duration
  end
end

function Board3D:update(dt)
  -- Animate opening/closing
  if math.abs(self.openAmount - self.targetOpen) > 0.01 then
    local direction = self.targetOpen > self.openAmount and 1 or -1
    self.openAmount = self.openAmount + direction * self.animationSpeed * dt
    self.openAmount = math.max(0, math.min(1, self.openAmount))
    
    -- Recalculate tray areas during animation
    self:calculateTrayAreas()
  end
end

-- ===== RENDERING HELPERS =====
local function drawWoodenPanel(vertices, normal, woodColor, lighting)
  -- Apply lighting to wood color
  local litColor = woodColor
  if lighting then
    litColor = Effects3D.calculateLighting(normal, woodColor)
  end
  
  -- Convert 3D vertices to screen coordinates
  local screenPoints = {}
  for _, vertex in ipairs(vertices) do
    local sx, sy = Projection3D.project(vertex.x, vertex.y, vertex.z, "isometric")
    table.insert(screenPoints, {sx, sy})
  end
  
  -- Draw filled polygon
  love.graphics.setColor(litColor)
  local points = {}
  for _, point in ipairs(screenPoints) do
    table.insert(points, point[1])
    table.insert(points, point[2])
  end
  -- Fix: depth nil protection
  local depth = 0
  if vertices and vertices[1] and vertices[1].z then depth = vertices[1].z end
  -- Se c'è una sottrazione, confronto o operazione su depth, usa sempre (depth or 0)
  -- Ad esempio:
  -- local d = (face.depth or 0) - (other.depth or 0)
  -- table.sort(faces, function(a, b) return (a.depth or 0) > (b.depth or 0) end)
  love.graphics.polygon("fill", points)
  
  -- Add wood grain effect (subtle lines)
  love.graphics.setColor(litColor[1] * 0.9, litColor[2] * 0.9, litColor[3] * 0.9, 0.3)
  love.graphics.setLineWidth(1)
  love.graphics.polygon("line", points)
end

local function drawDecorativeEdge(vertices, edgeColor)
  local screenPoints = {}
  for _, vertex in ipairs(vertices) do
    local sx, sy = Projection3D.project(vertex.x, vertex.y, vertex.z, "isometric")
    table.insert(screenPoints, {sx, sy})
  end
  
  love.graphics.setColor(edgeColor)
  love.graphics.setLineWidth(3)
  local points = {}
  for _, point in ipairs(screenPoints) do
    table.insert(points, point[1])
    table.insert(points, point[2])
  end
  love.graphics.polygon("line", points)
end

-- ===== MAIN DRAWING FUNCTION =====
function Board3D:draw()
  local cfg = self.config
  local pos = self.position
  
  -- Calculate hinge rotation based on open amount
  local hingeAngle = (1 - self.openAmount) * math.pi/2
  
  -- Board shadow
  Effects3D.drawShadow(pos, cfg.width, self.projectionMode)
  
  -- === BOTTOM PANEL (always flat) ===
  local bottomPanel = {
    Projection3D.Vec3.new(pos.x - cfg.width/2, pos.y - cfg.height/4, pos.z),
    Projection3D.Vec3.new(pos.x + cfg.width/2, pos.y - cfg.height/4, pos.z),
    Projection3D.Vec3.new(pos.x + cfg.width/2, pos.y + cfg.height/4, pos.z),
    Projection3D.Vec3.new(pos.x - cfg.width/2, pos.y + cfg.height/4, pos.z),
  }
  drawWoodenPanel(bottomPanel, Projection3D.Vec3.new(0, 0, 1), cfg.woodColor, true)
  
  -- Bottom tray (carved area)
  local bottomTray = self.trays.bottom
  local trayDepth = bottomTray.depth or 0
  local trayVertices = {
    Projection3D.Vec3.new(bottomTray.center.x - bottomTray.width/2, bottomTray.center.y - bottomTray.height/2, bottomTray.center.z - trayDepth),
    Projection3D.Vec3.new(bottomTray.center.x + bottomTray.width/2, bottomTray.center.y - bottomTray.height/2, bottomTray.center.z - trayDepth),
    Projection3D.Vec3.new(bottomTray.center.x + bottomTray.width/2, bottomTray.center.y + bottomTray.height/2, bottomTray.center.z - trayDepth),
    Projection3D.Vec3.new(bottomTray.center.x - bottomTray.width/2, bottomTray.center.y + bottomTray.height/2, bottomTray.center.z - trayDepth),
  }
  drawWoodenPanel(trayVertices, Projection3D.Vec3.new(0, 0, -1), cfg.feltColor, true)
  
  -- === TOP PANEL (rotates based on openAmount) ===
  if self.openAmount > 0 then
    -- Calculate rotation matrix for top panel
    local rotMatrix = Projection3D.Matrix4.rotationX(-hingeAngle)
    
    -- Top panel vertices (before rotation)
    local topPanelLocal = {
      Projection3D.Vec3.new(-cfg.width/2, -cfg.height/4, cfg.thickness),
      Projection3D.Vec3.new(cfg.width/2, -cfg.height/4, cfg.thickness),
      Projection3D.Vec3.new(cfg.width/2, cfg.height/4, cfg.thickness),
      Projection3D.Vec3.new(-cfg.width/2, cfg.height/4, cfg.thickness),
    }
    
    -- Apply rotation and translation
    local topPanelWorld = {}
    for _, vertex in ipairs(topPanelLocal) do
      local rotated, _ = rotMatrix:transform(vertex)
      table.insert(topPanelWorld, rotated:add(pos))
    end
    
    drawWoodenPanel(topPanelWorld, Projection3D.Vec3.new(0, 0, 1), cfg.woodColor, true)
    
    -- Top tray (inside top panel)
    if self.openAmount > 0.7 then -- Only show when mostly open
      local topTray = self.trays.top or {}
      local topTrayDepth = topTray.depth or 0
      local topTrayCenter = topTray.center or Projection3D.Vec3.new(0,0,0)
      local topTrayWidth = topTray.width or 0
      local topTrayHeight = topTray.height or 0
      local topTrayVertices = {
        Projection3D.Vec3.new(topTrayCenter.x - topTrayWidth/2, topTrayCenter.y - topTrayHeight/2, topTrayCenter.z - topTrayDepth),
        Projection3D.Vec3.new(topTrayCenter.x + topTrayWidth/2, topTrayCenter.y - topTrayHeight/2, topTrayCenter.z - topTrayDepth),
        Projection3D.Vec3.new(topTrayCenter.x + topTrayWidth/2, topTrayCenter.y + topTrayHeight/2, topTrayCenter.z - topTrayDepth),
        Projection3D.Vec3.new(topTrayCenter.x - topTrayWidth/2, topTrayCenter.y + topTrayHeight/2, topTrayCenter.z - topTrayDepth),
      }
      
      -- Apply same rotation as top panel
      local topTrayWorld = {}
      for _, vertex in ipairs(topTrayVertices) do
        local localVert = vertex:sub(pos) -- Convert to local space
        local rotated, _ = rotMatrix:transform(localVert)
        table.insert(topTrayWorld, rotated:add(pos))
      end
      
      drawWoodenPanel(topTrayWorld, Projection3D.Vec3.new(0, 0, -1), cfg.feltColor, true)
    end
  end
  
  -- === HINGES ===
  local hingePositions = {
    Projection3D.Vec3.new(pos.x - cfg.width/3, pos.y, pos.z + cfg.thickness/2),
    Projection3D.Vec3.new(pos.x + cfg.width/3, pos.y, pos.z + cfg.thickness/2),
  }
  
  for _, hingePos in ipairs(hingePositions) do
    local sx, sy = Projection3D.project(hingePos.x, hingePos.y, hingePos.z, self.projectionMode)
    love.graphics.setColor(cfg.hingeColor)
    love.graphics.rectangle("fill", sx - 8, sy - 4, 16, 8, 2)
    love.graphics.setColor(cfg.hingeColor[1] * 0.7, cfg.hingeColor[2] * 0.7, cfg.hingeColor[3] * 0.7, 1)
    love.graphics.rectangle("line", sx - 8, sy - 4, 16, 8, 2)
  end
  
  -- === DECORATIVE EDGES ===
  if self.openAmount > 0.5 then
    -- Add decorative border around panels
    drawDecorativeEdge(bottomPanel, cfg.woodLight)
    if self.openAmount > 0.7 then
      -- Only show top decorative edge when mostly open
      love.graphics.setColor(cfg.woodLight)
      love.graphics.setLineWidth(2)
    end
  end
end

-- ===== PHYSICS INTEGRATION =====
function Board3D:getTrayForDice(dicePosition)
  -- Determine which tray a dice position belongs to
  for trayName, tray in pairs(self.trays) do
    local bounds = tray.worldBounds
    if bounds and 
       dicePosition.x >= bounds.minX and dicePosition.x <= bounds.maxX and
       dicePosition.y >= bounds.minY and dicePosition.y <= bounds.maxY then
      return trayName, tray
    end
  end
  return nil, nil
end

function Board3D:constrainDiceToTray(dicePosition, trayName)
  local tray = self.trays[trayName]
  if not tray or not tray.worldBounds then return dicePosition end
  
  local bounds = tray.worldBounds
  if not bounds.minX or not bounds.maxX or not bounds.minY or not bounds.maxY or not bounds.minZ then
    return dicePosition
  end
  
  return Projection3D.Vec3.new(
    math.max(bounds.minX, math.min(bounds.maxX, dicePosition.x)),
    math.max(bounds.minY, math.min(bounds.maxY, dicePosition.y)),
    math.max(bounds.minZ, dicePosition.z) -- Don't constrain Z upward
  )
end

-- ===== API COMPATIBILITY =====
function Board3D:setProjectionMode(mode)
  self.projectionMode = mode
end

function Board3D:getPosition()
  return self.position
end

function Board3D:setPosition(x, y, z)
  self.position = Projection3D.Vec3.new(x, y, z)
  self:calculateTrayAreas()
end

return Board3D