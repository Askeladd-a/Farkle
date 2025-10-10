-- graphics/dice.lua
-- 2D / fake 3D dice abstraction
local Dice = {}
local WeightedRNG = require("src.core.weighted_rng")
local constants = require("src.core.constants")

Dice.SIZE = 48
Dice.RADIUS = Dice.SIZE * 0.5
Dice.RENDER_MODE = "2d" -- "2d" | "3d"

local function isoProject(x, y, z)
  local angle = math.rad(30)
  local x2d = (x - y) * math.cos(angle)
  local y2d = (x + y) * math.sin(angle) - (z or 0)
  return x2d, y2d
end

function Dice.newDie(tray, diceType)
  diceType = diceType or constants.DEFAULT_DICE_TYPE
  local cx = tray.x + Dice.RADIUS + love.math.random() * math.max(0, tray.w - 2 * Dice.RADIUS)
  local cy = tray.y + tray.h * (0.78 + 0.12 * love.math.random())
  local cz = love.math.random() * 16
  return {
    value = WeightedRNG.rollDiceValue(diceType),
    finalValue = nil,
    diceType = diceType,
    x = cx, y = cy, z = cz,
    angle = 0,
    yaw = 0, pitch = 0, roll = 0,
    vx = (love.math.random() - 0.5) * 1400,
    vy = -(math.abs((love.math.random() - 0.5) * 1600) + 1600 * 0.2),
    vz = (love.math.random() - 0.5) * 120,
    av = (love.math.random() - 0.5) * 20,
    faceTimer = 0,
    locked = false,
    isRolling = true,
  }
end

function Dice.updateRoll(roll, tray, dt)
  for _, die in ipairs(roll) do
    if die.isRolling then
      die.x = die.x + die.vx * dt
      die.y = die.y + die.vy * dt
      die.z = math.max(0, die.z + (die.vz or 0) * dt)
      die.angle = die.angle + die.av * dt
      -- simple angular motion for fake 3D mode
      die.yaw = die.yaw + 1.2 * dt
      die.pitch = die.pitch + 0.9 * dt
      die.roll = die.roll + 0.7 * dt
      die.vx = die.vx * 0.99
      die.vy = die.vy * 0.99
      die.vz = die.vz * 0.98
      die.av = die.av * 0.99
      if die.z <= 0 then
        die.z = 0
        die.vz = 0
      end
      die.faceTimer = die.faceTimer + dt
      if die.faceTimer > 0.1 then
        die.value = love.math.random(1, 6)
        die.faceTimer = 0
      end
      local speed = math.sqrt(die.vx * die.vx + die.vy * die.vy)
      if speed < 50 and math.abs(die.av) < 2 and die.z <= 0 then
        die.isRolling = false
        die.value = die.finalValue or WeightedRNG.rollDiceValue(die.diceType)
      end
    end
  end
end

local function draw2D(die)
  local px, py = isoProject(die.x, die.y, die.z)
  love.graphics.setColor(0, 0, 0, 0.35)
  love.graphics.ellipse("fill", px + 8, py + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)
  love.graphics.push()
  love.graphics.translate(px, py)
  love.graphics.rotate(die.angle)
  local w, h, round = Dice.SIZE, Dice.SIZE, 10
  love.graphics.setColor(0.96, 0.93, 0.82)
  love.graphics.rectangle("fill", -w/2, -h/2, w, h, round, round)
  love.graphics.setColor(0.3,0.3,0.3)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", -w/2, -h/2, w, h, round, round)
  love.graphics.setColor(0.1,0.1,0.1)
  love.graphics.print(tostring(die.value), -8, -12)
  love.graphics.pop()
end

function Dice.drawDie(die)
  if Dice.RENDER_MODE == "3d" then
    local Dice3D = require("src.graphics.dice3d")
    Dice3D.drawDie({
      x = (die.x - love.graphics.getWidth()/2)/140,
      y = (die.y - love.graphics.getHeight()/2)/140,
      z = (die.z or 0)/80,
      yaw = die.yaw, pitch = die.pitch, roll = die.roll,
      scale = 0.5
    })
  else
    draw2D(die)
  end
end

function Dice.createMixedRoll(tray, diceCount)
  local roll = {}
  for i=1,diceCount do
    roll[i] = Dice.newDie(tray, "fair")
  end
  return roll
end

function Dice.setRenderMode(m)
  if m == "2d" or m == "3d" then
    Dice.RENDER_MODE = m
  end
end

return Dice
