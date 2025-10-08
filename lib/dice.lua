local Dice = {}
local DiceAnimations = require("lib.dice_animations")

local random = love.math.random

-- === COSTANTI ===
Dice.SIZE = 48
Dice.RADIUS = Dice.SIZE * 0.5
local COLLISION_THRESHOLD = Dice.SIZE * 0.92  -- Soglia per separazione dadi
local PIP_OFFSET = 6  -- Offset per i pip dal bordo

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
    
    if dist < COLLISION_THRESHOLD then
        local push = (COLLISION_THRESHOLD - dist) * 0.5
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
        -- Aggiorna la faccia del dado
        die.faceTimer = die.faceTimer - dt
        if die.faceTimer <= 0 then
            die.value = random(1, 6)
            die.faceTimer = 0.08
        end

        -- Fisica di base
        die.x = die.x + die.vx * dt
        die.y = die.y + die.vy * dt
        die.angle = die.angle + die.av * dt

        -- Frizione
        die.vx = die.vx * 0.985
        die.vy = die.vy * 0.985
        die.av = die.av * 0.97

        clampDie(die, tray)
    end

    -- Collision detection tra dadi
    for i = 1, #roll do
        for j = i + 1, #roll do
            separateDice(roll[i], roll[j])
        end
    end
end

function Dice.arrangeScatter(tray, roll, opts)
    opts = opts or {}
    if #roll == 0 then return end

    local cx = tray.x + tray.w * 0.5
    local cy = tray.y + tray.h * 0.5
    local n = #roll
    local minDist = Dice.SIZE + 4  -- Ridotto per permettere più vicinanza
    local maxRadius = math.min(tray.w, tray.h) * 0.35 - Dice.RADIUS
    
    -- Disposizione più realistica e casuale
    for i, die in ipairs(roll) do
        local attempts = 0
        local placed = false
        
        -- Prova a posizionare il dado in modo casuale
        while not placed and attempts < 50 do
            -- Posizione casuale con distribuzione più naturale
            local angle = random() * math.pi * 2
            local radius = random() * maxRadius * (0.3 + random() * 0.7)  -- Più concentrato al centro
            
            -- Aggiungi un po' di rumore per rendere più naturale
            local noiseX = (random() - 0.5) * Dice.SIZE * 0.3
            local noiseY = (random() - 0.5) * Dice.SIZE * 0.3
            
            die.x = cx + math.cos(angle) * radius + noiseX
            die.y = cy + math.sin(angle) * radius + noiseY
            
            -- Angolo più casuale per un aspetto più naturale
            die.angle = (random() - 0.5) * math.pi * 0.8  -- Fino a 72 gradi di rotazione
            
            -- Verifica che non si sovrapponga troppo con altri dadi
            local tooClose = false
            for j = 1, i - 1 do
                local dx = die.x - roll[j].x
                local dy = die.y - roll[j].y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < minDist then
                    tooClose = true
                    break
                end
            end
            
            if not tooClose then
                placed = true
            end
            
            attempts = attempts + 1
        end
        
        -- Se non è riuscito a posizionare, usa una posizione di fallback
        if not placed then
            local fallbackAngle = (i - 1) * (math.pi * 2 / n)
            local fallbackRadius = maxRadius * 0.6
            die.x = cx + math.cos(fallbackAngle) * fallbackRadius
            die.y = cy + math.sin(fallbackAngle) * fallbackRadius
            die.angle = (random() - 0.5) * 0.3
        end
        
        if not opts.keepRollingState then
            die.isRolling = false
        end
        if not opts.preserveLocks then
            die.locked = false
        end
    end

    -- Iterazioni di separazione più delicate per mantenere l'aspetto naturale
    for _ = 1, 15 do  -- Ridotto da 32 per mantenere più casualità
        for i = 1, n do
            for j = i + 1, n do
                local dx = roll[i].x - roll[j].x
                local dy = roll[i].y - roll[j].y
                local d = math.sqrt(dx * dx + dy * dy)
                if d < minDist then
                    local push = (minDist - d) * 0.3  -- Ridotto da 0.5 per movimento più delicato
                    local nx, ny = dx / (d + 0.01), dy / (d + 0.01)
                    roll[i].x = roll[i].x + nx * push
                    roll[i].y = roll[i].y + ny * push
                    roll[j].x = roll[j].x - nx * push
                    roll[j].y = roll[j].y - ny * push
                end
            end
        end
    end
    
    -- Assicurati che tutti i dadi siano dentro il tray
    for _, die in ipairs(roll) do
        clampDie(die, tray)
    end
end

local function drawPip(x, y, r)
    love.graphics.circle("fill", x, y, r)
end

local function drawPips(die)
    local r = Dice.RADIUS - PIP_OFFSET
    -- Configurazione posizioni pip per ogni faccia
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
    -- Prova prima a usare le animazioni, altrimenti usa il rendering tradizionale
    if DiceAnimations.isInitialized() then
        local scale = Dice.SIZE / 64  -- Scala da 64px (spritesheet) a 48px (Dice.SIZE)
        
        -- Ombra
        love.graphics.setColor(0, 0, 0, 0.35)
        love.graphics.ellipse("fill", die.x + 8, die.y + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)
        
        -- Disegna il dado con animazione
        local success = DiceAnimations.drawDie(die, die.x, die.y, scale, die.angle)
        
        if success then
            -- Indicatore selezione
            if die.locked then
                love.graphics.setColor(0.95, 0.82, 0.35, 0.85)
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", die.x - Dice.RADIUS - 4, die.y - Dice.RADIUS - 4, Dice.SIZE + 8, Dice.SIZE + 8, 14, 14)
            end
            return
        end
    end
    
    -- Fallback al rendering tradizionale se le animazioni non sono disponibili
    -- Ombra
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", die.x + 8, die.y + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)

    love.graphics.push()
    love.graphics.translate(die.x, die.y)
    love.graphics.rotate(die.angle)

    local w = Dice.SIZE
    local h = Dice.SIZE
    local round = 10

    -- Corpo del dado
    love.graphics.setColor(0.96, 0.93, 0.82)
    love.graphics.rectangle("fill", -w / 2, -h / 2, w, h, round, round)

    -- Highlight superiore
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.polygon("fill", -w / 2, -h / 2, w / 2, -h / 2, w / 2 - 6, -h / 2 + 6, -w / 2 + 6, -h / 2 + 6)

    -- Ombra inferiore
    love.graphics.setColor(0, 0, 0, 0.18)
    love.graphics.polygon("fill", -w / 2, h / 2, w / 2, h / 2, w / 2 - 6, h / 2 - 6, -w / 2 + 6, h / 2 - 6)

    -- Pip
    drawPips(die)

    -- Bordo
    love.graphics.setColor(0.25, 0.22, 0.18)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", -w / 2, -h / 2, w, h, round, round)

    love.graphics.pop()

    -- Indicatore selezione
    if die.locked then
        love.graphics.setColor(0.95, 0.82, 0.35, 0.85)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", die.x - Dice.RADIUS - 4, die.y - Dice.RADIUS - 4, Dice.SIZE + 8, Dice.SIZE + 8, 14, 14)
    end
end

function Dice.recenterDice(roll, oldTray, newTray)
    if not newTray or not roll then
        return
    end

    local newWidth = math.max(newTray.w, Dice.SIZE)
    local newHeight = math.max(newTray.h, Dice.SIZE)
    local marginX = math.min(0.45, Dice.RADIUS / newWidth)
    local marginY = math.min(0.45, Dice.RADIUS / newHeight)

    for _, die in ipairs(roll) do
        -- Calcola posizione relativa nel vecchio tray
        local relX = 0.5
        local relY = 0.5
        if oldTray and oldTray.w and oldTray.w > 0 then
            relX = (die.x - oldTray.x) / oldTray.w
        end
        if oldTray and oldTray.h and oldTray.h > 0 then
            relY = (die.y - oldTray.y) / oldTray.h
        end
        
        -- Applica margini di sicurezza
        relX = math.max(marginX, math.min(1 - marginX, relX))
        relY = math.max(marginY, math.min(1 - marginY, relY))

        -- Posiziona nel nuovo tray
        die.x = newTray.x + relX * newTray.w
        die.y = newTray.y + relY * newTray.h
        clampDie(die, newTray)
    end
end

function Dice.drawKeptColumn(area, kept, alignTop)
    if not area or #kept == 0 then
        return
    end

    local spacing = Dice.SIZE + 8
    if area.h > 0 then
        spacing = math.min(spacing, area.h / #kept)
    end
    local totalHeight = spacing * #kept
    local startY
    if alignTop then
        startY = area.y + spacing * 0.5
    else
        startY = area.y + area.h - totalHeight + spacing * 0.5
    end
    local centerX = area.x + area.w * 0.5

    for index, value in ipairs(kept) do
        local y = startY + (index - 1) * spacing
        Dice.drawDie({
            value = value,
            x = centerX,
            y = y,
            angle = 0,
            locked = false,
        })
    end
end

-- Funzione per inizializzare le animazioni
function Dice.initAnimations()
    DiceAnimations.init()
end

-- Funzione per aggiornare le animazioni
function Dice.updateAnimations(dt)
    if DiceAnimations.isInitialized() then
        DiceAnimations.update(dt)
    end
end

return Dice