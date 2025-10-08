local Dice = {}

local random = love.math.random

Dice.SIZE = 48
Dice.RADIUS = Dice.SIZE * 0.5

local function randomVelocity(range)
    return (random() - 0.5) * range
end

function Dice.newDie(tray)
    local cx = tray.x + tray.w * 0.5
    local cy = tray.y + tray.h * 0.5
    return {
        value = random(1, 6),
        x = cx,
        y = cy,
        angle = 0,
        vx = randomVelocity(520),
        vy = randomVelocity(420),
        av = randomVelocity(8),
        faceTimer = 0,
        locked = false,
        isRolling = true,
    }
end

local function clampDie(die, tray)
    local left = tray.x + Dice.RADIUS
    local right = tray.x + tray.w - Dice.RADIUS
    local top = tray.y + Dice.RADIUS
    local bottom = tray.y + tray.h - Dice.RADIUS

    if die.x < left then
        die.x = left
        die.vx = -die.vx * 0.75
    elseif die.x > right then
        die.x = right
        die.vx = -die.vx * 0.75
    end

    if die.y < top then
        die.y = top
        die.vy = -die.vy * 0.75
    elseif die.y > bottom then
        die.y = bottom
        die.vy = -die.vy * 0.75
    end
end

local function separateDice(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then
        dx, dy = random() - 0.5, random() - 0.5
        dist = math.sqrt(dx * dx + dy * dy)
    end
    local minDist = Dice.SIZE * 0.92
    if dist < minDist then
        local push = (minDist - dist) * 0.5
        local nx = dx / dist
        local ny = dy / dist
        a.x = a.x - nx * push
        a.y = a.y - ny * push
        b.x = b.x + nx * push
        b.y = b.y + ny * push
    end
end

function Dice.updateRoll(roll, tray, dt)
    for _, die in ipairs(roll) do
        die.faceTimer = die.faceTimer - dt
        if die.faceTimer <= 0 then
            die.value = random(1, 6)
            die.faceTimer = 0.08
        end

        die.x = die.x + die.vx * dt
        die.y = die.y + die.vy * dt
        die.angle = die.angle + die.av * dt

        die.vx = die.vx * 0.985
        die.vy = die.vy * 0.985
        die.av = die.av * 0.97

        clampDie(die, tray)
    end

    for i = 1, #roll do
        for j = i + 1, #roll do
            separateDice(roll[i], roll[j])
        end
    end
end

function Dice.arrangeScatter(tray, roll)
    if #roll == 0 then return end

    local cx = tray.x + tray.w * 0.5
    local cy = tray.y + tray.h * 0.5
    local n = #roll
    local minDist = Dice.SIZE + 6
    local angleStep = (math.pi * 2) / n
    local radius = math.min(tray.w, tray.h) * 0.38 - Dice.RADIUS
    if n == 1 then radius = 0 end

    for i, die in ipairs(roll) do
        local angle = angleStep * (i - 1)
        local dist = radius
        die.x = cx + math.cos(angle) * dist
        die.y = cy + math.sin(angle) * dist
        die.angle = (random() - 0.5) * 0.25
        die.isRolling = false
        die.locked = false
    end

    -- Migliora la separazione: se troppo vicini, sposta radialmente
    for _ = 1, 32 do
        for i = 1, n do
            for j = i + 1, n do
                local dx = roll[i].x - roll[j].x
                local dy = roll[i].y - roll[j].y
                local d = math.sqrt(dx * dx + dy * dy)
                if d < minDist then
                    local push = (minDist - d) / 2
                    local nx, ny = dx / (d + 0.01), dy / (d + 0.01)
                    roll[i].x = roll[i].x + nx * push
                    roll[i].y = roll[i].y + ny * push
                    roll[j].x = roll[j].x - nx * push
                    roll[j].y = roll[j].y - ny * push
                end
            end
        end
    end
end

local function drawPip(x, y, r)
    love.graphics.circle("fill", x, y, r)
end

local function drawPips(die)
    local r = Dice.RADIUS - 6
    local positions = {
        [1] = {{0, 0}},
        [2] = {{-0.6, -0.6}, {0.6, 0.6}},
        [3] = {{-0.65, -0.65}, {0, 0}, {0.65, 0.65}},
        [4] = {{-0.65, -0.65}, {0.65, -0.65}, {-0.65, 0.65}, {0.65, 0.65}},
        [5] = {{-0.65, -0.65}, {0.65, -0.65}, {0, 0}, {-0.65, 0.65}, {0.65, 0.65}},
        [6] = {{-0.65, -0.65}, {0.65, -0.65}, {-0.65, 0}, {0.65, 0}, {-0.65, 0.65}, {0.65, 0.65}},
    }
    love.graphics.setColor(0.18, 0.16, 0.14)
    for _, pos in ipairs(positions[die.value]) do
        drawPip(pos[1] * r, pos[2] * r, 3.5)
    end
end

function Dice.drawDie(die)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", die.x + 8, die.y + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)

    love.graphics.push()
    love.graphics.translate(die.x, die.y)
    love.graphics.rotate(die.angle)

    local w = Dice.SIZE
    local h = Dice.SIZE
    local round = 10

    love.graphics.setColor(0.96, 0.93, 0.82)
    love.graphics.rectangle("fill", -w / 2, -h / 2, w, h, round, round)

    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.polygon("fill", -w / 2, -h / 2, w / 2, -h / 2, w / 2 - 6, -h / 2 + 6, -w / 2 + 6, -h / 2 + 6)

    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.polygon("fill", -w / 2, h / 2, w / 2, h / 2, w / 2 - 6, h / 2 - 6, -w / 2 + 6, h / 2 - 6)

    drawPips(die)

    love.graphics.setColor(0.25, 0.22, 0.18)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", -w / 2, -h / 2, w, h, round, round)

    love.graphics.pop()

    if die.locked then
        love.graphics.setColor(0.95, 0.82, 0.35, 0.85)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", die.x - Dice.RADIUS - 4, die.y - Dice.RADIUS - 4, Dice.SIZE + 8, Dice.SIZE + 8, 14, 14)
    end
end

function Dice.drawKeptColumn(tray, kept, alignTop, alignRight)
    local spacing = Dice.SIZE + 8
    local startX
    if alignRight then
        startX = tray.x + tray.w + 16
    else
        startX = tray.x - 16 - Dice.SIZE
    end
    local startY
    if alignTop then
        startY = tray.y
    else
        startY = tray.y + tray.h - spacing * (#kept)
    end

    for index, value in ipairs(kept) do
        local x = startX
        local y = startY + (index - 0.5) * spacing
        Dice.drawDie({
            value = value,
            x = x,
            y = y,
            angle = 0,
            locked = false,
        })
    end
end

return Dice
