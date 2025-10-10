local Dice = {}
local Audio = require("src.audio")
local DiceAnimations = require("lib.dice_animations")

local random = love.math.random

-- === COSTANTI ===
Dice.SIZE = 48
Dice.RADIUS = Dice.SIZE * 0.5
local COLLISION_THRESHOLD = Dice.SIZE * 1.02
local FINAL_SEPARATION_MARGIN = 8

-- Isometric projection
local function isoProject(x, y, z)
    local angle = math.rad(30)
    local x2d = (x - y) * math.cos(angle)
    local y2d = (x + y) * math.sin(angle) - z
    return x2d, y2d
end

function Dice.newDie(tray)
    local cx = tray.x + Dice.RADIUS + random() * (math.max(0, tray.w - 2 * Dice.RADIUS))
    local cy = tray.y + tray.h * (0.78 + 0.12 * random())
    local cz = random() * 16
    return {
        value = random(1, 6),
        x = cx,
        y = cy,
        z = cz,
        angle = 0,
        vx = (random() - 0.5) * 1400,
        vy = -(math.abs((random() - 0.5) * 1600) + 1600 * 0.2),
        vz = (random() - 0.5) * 120,
        av = (random() - 0.5) * 20,
        faceTimer = 0,
        locked = false,
        isRolling = true,
    }
end

function Dice.updateRoll(roll, tray, dt)
    for _, die in ipairs(roll) do
        die.x = die.x + die.vx * dt
        die.y = die.y + die.vy * dt
        die.z = math.max(0, die.z + (die.vz or 0) * dt)
        die.angle = die.angle + die.av * dt
        die.vx = die.vx * 0.99
        die.vy = die.vy * 0.99
        die.vz = die.vz * 0.98
        die.av = die.av * 0.99
        if die.z <= 0 then die.z = 0; die.vz = 0 end
    end
    -- ...collision and rest logic can be adapted here...
end

function Dice.drawDie(die)
    local px, py = isoProject(die.x, die.y, die.z)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", px + 8, py + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)
    love.graphics.push()
    love.graphics.translate(px, py)
    love.graphics.rotate(die.angle)
    local w, h, round = Dice.SIZE, Dice.SIZE, 10
    love.graphics.setColor(0.96, 0.93, 0.82)
    love.graphics.rectangle("fill", -w/2, -h/2, w, h, round, round)
    -- ...draw pips, border, selection overlay as before...
    love.graphics.pop()
end

return Dice