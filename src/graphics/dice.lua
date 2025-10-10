-- Dice graphics module
local Dice = {}
local Audio = require("src.audio")
local WeightedRNG = require("src.core.weighted_rng")
local constants = require("src.core.constants")

Dice.SIZE = 48
Dice.RADIUS = Dice.SIZE * 0.5
Dice.RENDER_MODE = "2d"

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
        vx = (love.math.random() - 0.5) * 1400,
        vy = -(math.abs((love.math.random() - 0.5) * 1600) + 1600 * 0.2),
        vz = (love.math.random() - 0.5) * 120,
        av = (love.math.random() - 0.5) * 20,
        faceTimer = 0,
        locked = false,
        isRolling = true,
        isSnapping = false,
        snapTimer = 0,
    }
end

function Dice.updateRoll(roll, tray, dt)
    for _, die in ipairs(roll) do
        if die.isRolling then
            die.x = die.x + die.vx * dt
            die.y = die.y + die.vy * dt
            die.z = math.max(0, die.z + (die.vz or 0) * dt)
            die.angle = die.angle + die.av * dt
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

function Dice.drawDie(die)
    if Dice.RENDER_MODE == "3d" then
        local DiceMesh = require("src.graphics.dice_mesh")
        DiceMesh.renderDie3D(die, false)
    else
        local px, py = isoProject(die.x, die.y, die.z)
        love.graphics.setColor(0, 0, 0, 0.35)
        love.graphics.ellipse("fill", px + 8, py + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)
        love.graphics.push()
        love.graphics.translate(px, py)
        love.graphics.rotate(die.angle)
        local w, h, round = Dice.SIZE, Dice.SIZE, 10
        local diceInfo = WeightedRNG.getDiceTypeInfo(die.diceType)
        local diceColor = diceInfo and diceInfo.color or {0.96, 0.93, 0.82}
        love.graphics.setColor(diceColor)
        love.graphics.rectangle("fill", -w/2, -h/2, w, h, round, round)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", -w/2, -h/2, w, h, round, round)
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.print(tostring(die.value), -8, -12)
        if die.locked then
            love.graphics.setColor(0.2, 0.8, 0.2, 0.4)
            love.graphics.rectangle("fill", -w/2, -h/2, w, h, round, round)
        end
        love.graphics.pop()
    end
end

function Dice.createMixedRoll(tray, diceCount, typeDistribution)
    local roll = {}
    typeDistribution = typeDistribution or {fair = 1.0}
    for i = 1, diceCount do
        local diceType = "fair"
        local rand = love.math.random()
        local cumulative = 0
        for typeName, probability in pairs(typeDistribution) do
            cumulative = cumulative + probability
            if rand <= cumulative then
                diceType = typeName
                break
            end
        end
        table.insert(roll, Dice.newDie(tray, diceType))
    end
    return roll
end

function Dice.getRollStats(roll)
    local stats = {
        total = #roll,
        byType = {},
        values = {}
    }
    for _, die in ipairs(roll) do
        stats.byType[die.diceType] = (stats.byType[die.diceType] or 0) + 1
        if not die.isRolling then
            stats.values[die.value] = (stats.values[die.value] or 0) + 1
        end
    end
    return stats
end

function Dice.setRenderMode(mode)
    Dice.RENDER_MODE = mode
    print("[Dice] Render mode changed to:", mode)
end

function Dice.setScale(newSize)
    Dice.SIZE = newSize
    Dice.RADIUS = Dice.SIZE * 0.5
    print("[Dice] Scale updated - Size:", Dice.SIZE, "Radius:", Dice.RADIUS)
end

function Dice.getScale()
    return Dice.SIZE, Dice.RADIUS
end

return Dice
