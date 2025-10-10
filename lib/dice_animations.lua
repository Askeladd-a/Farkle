-- Dice Animations Module

local DiceAnimations = {}

local diceImage = nil
local borderImage = nil

-- Isometric projection
local function isoProject(x, y, z)
    local angle = math.rad(30)
    local x2d = (x - y) * math.cos(angle)
    local y2d = (x + y) * math.sin(angle) - z
    return x2d, y2d
end

function DiceAnimations.init()
    local diceCandidates = {
        "images/dice/dice_spritesheet.png",
        "images/dice_spritesheet.png",
    }
    local success, image
    for _, path in ipairs(diceCandidates) do
        local ok, img = pcall(love.graphics.newImage, path)
        if ok and img then
            success, image = true, img
            break
        end
    end
    if not success then
        success, image = pcall(love.graphics.newImage, "images/dice_spritesheet.png")
    end
    if success and image then
        diceImage = image
    else
        diceImage = DiceAnimations.createFallbackImage()
    end
end

function DiceAnimations.drawDie(die, scale, angleOverride)
    if not diceImage then return false end
    local px, py = isoProject(die.x, die.y, die.z or 0)
    love.graphics.push()
    love.graphics.translate(px, py)
    love.graphics.rotate(angleOverride or die.angle or 0)
    love.graphics.scale(scale or 1, scale or 1)
    -- Draw face (use value 1-6)
    local frame = math.max(1, math.min(6, die.value or 1))
    love.graphics.setColor(1,1,1,1)
    local fw, fh = 64, 64
    local quad = love.graphics.newQuad((frame-1)*fw, 0, fw, fh, diceImage:getDimensions())
    love.graphics.draw(diceImage, quad, 0, 0, 0, 1, 1, fw/2, fh/2)
    love.graphics.pop()
    return true
end