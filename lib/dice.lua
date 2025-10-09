local Dice = {}
local DiceAnimations = require("lib.dice_animations")

local random = love.math.random

-- === COSTANTI ===
Dice.SIZE = 48
Dice.RADIUS = Dice.SIZE * 0.5
local COLLISION_THRESHOLD = Dice.SIZE * 1.02  -- Soglia per separazione (>= diametro)
local PIP_OFFSET = 6  -- Offset per i pip dal bordo

local function randomVelocity(range)
    return (random() - 0.5) * range
end

-- Arcade physics parameters (top-down)
local REST_THRESHOLD = 16
local ANGULAR_REST = 0.5
local BOUNCE = 0.92
local BOUNCE_JITTER = 0.08

local function biasedUpwardSpeed(range)
    -- Always upwards (negative y), with a minimum kick
    local v = -math.abs(randomVelocity(range)) - range * 0.2
    return v
end

function Dice.newDie(tray)
    -- Spawn verso la parte bassa del tray, X casuale sicura
    local cx = tray.x + Dice.RADIUS + random() * (math.max(0, tray.w - 2 * Dice.RADIUS))
    local cy = tray.y + tray.h * (0.78 + 0.12 * random())
    return {
        value = random(1, 6),
        x = cx,
        y = cy,
        angle = 0,
        vx = randomVelocity(1400),
        vy = biasedUpwardSpeed(1600),
        av = randomVelocity(20),
        faceTimer = 0,
        locked = false,
        isRolling = true,
    }
end

function Dice.applyThrowImpulse(die, tray)
    -- Reimposta una spinta obliqua verso l'alto con rotazione
    die.vx = randomVelocity(1400)
    die.vy = biasedUpwardSpeed(1600)
    die.av = die.av + randomVelocity(20)
    -- Sposta leggermente verso il basso, così il primo movimento è chiaramente in su
    die.y = math.min(tray.y + tray.h - Dice.RADIUS - 2, die.y + 4)
end

local function clampDie(die, tray)
    local left = tray.x + Dice.RADIUS
    local right = tray.x + tray.w - Dice.RADIUS
    local top = tray.y + Dice.RADIUS
    local bottom = tray.y + tray.h - Dice.RADIUS

    if die.x < left then
        die.x = left
        local b = BOUNCE * (1 - BOUNCE_JITTER + (random() * 2 - 1) * BOUNCE_JITTER)
        die.vx = -die.vx * b
        die.vy = die.vy * (0.94 + 0.12 * random()) + randomVelocity(80)
        die.av = die.av + randomVelocity(3)
    elseif die.x > right then
        die.x = right
        local b = BOUNCE * (1 - BOUNCE_JITTER + (random() * 2 - 1) * BOUNCE_JITTER)
        die.vx = -die.vx * b
        die.vy = die.vy * (0.94 + 0.12 * random()) + randomVelocity(80)
        die.av = die.av + randomVelocity(3)
    end

    if die.y < top then
        die.y = top
        local b = BOUNCE * (1 - BOUNCE_JITTER + (random() * 2 - 1) * BOUNCE_JITTER)
        die.vy = -die.vy * b
        die.vx = die.vx * (0.94 + 0.12 * random()) + randomVelocity(80)
        die.av = die.av + randomVelocity(3)
    elseif die.y > bottom then
        die.y = bottom
        local b = BOUNCE * (1 - BOUNCE_JITTER + (random() * 2 - 1) * BOUNCE_JITTER)
        die.vy = -die.vy * b
        die.vx = die.vx * (0.94 + 0.12 * random()) + randomVelocity(80)
        die.av = die.av + randomVelocity(3)
    end
end

local function handleDicePairCollision(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then
        dx, dy = random() - 0.5, random() - 0.5
        dist = math.sqrt(dx * dx + dy * dy)
    end
    if dist >= COLLISION_THRESHOLD then return end

    local nx = dx / dist
    local ny = dy / dist
    local push = (COLLISION_THRESHOLD - dist) * 0.55
    a.x = a.x - nx * push
    a.y = a.y - ny * push
    b.x = b.x + nx * push
    b.y = b.y + ny * push

    -- Impulso elastico semplificato lungo la normale
    local rvx = a.vx - b.vx
    local rvy = a.vy - b.vy
    local rel = rvx * nx + rvy * ny
    if rel < 0 then
        local e = 0.72 + (random() - 0.5) * 0.25 -- coefficiente con caos
        local j = -(1 + e) * rel * 0.52
        a.vx = a.vx + j * nx
        a.vy = a.vy + j * ny
        b.vx = b.vx - j * nx
        b.vy = b.vy - j * ny
        -- Piccolo torque casuale
        a.av = a.av + (random() - 0.5) * 2.2
        b.av = b.av + (random() - 0.5) * 2.2
    end
end

function Dice.updateRoll(roll, tray, dt)
    for _, die in ipairs(roll) do
        -- Aggiorna la faccia del dado (velocità -> frequenza cambio)
        die.faceTimer = die.faceTimer - dt
        if die.faceTimer <= 0 then
            local speed = math.sqrt((die.vx or 0)^2 + (die.vy or 0)^2) + math.abs(die.av or 0) * Dice.SIZE
            die.value = random(1, 6)
            local period = 0.18 - math.min(0.14, speed / 3200)
            die.faceTimer = math.max(0.03, period)
        end

        -- Fisica di base (top-down)
        die.x = die.x + die.vx * dt
        die.y = die.y + die.vy * dt
        die.angle = die.angle + die.av * dt

        -- Frizione dipendente dalla velocità: alta energia -> meno attrito; bassa -> si ferma
        local speed = math.sqrt(die.vx * die.vx + die.vy * die.vy)
        local linFric
        if speed > 1000 then
            linFric = 0.997
        elseif speed > 500 then
            linFric = 0.994
        else
            linFric = 0.985
        end
        die.vx = die.vx * linFric
        die.vy = die.vy * linFric
        local angFric = speed > 400 and 0.991 or 0.982
        die.av = die.av * angFric

        clampDie(die, tray)
    end

    -- Collision detection tra dadi (più passaggi per robustezza)
    for pass = 1, 3 do
        for i = 1, #roll do
            for j = i + 1, #roll do
                handleDicePairCollision(roll[i], roll[j])
            end
        end
    end

    -- Arresta dolcemente i dadi quando l'energia è bassa
    local allRest = true
    for _, die in ipairs(roll) do
        local speed = math.sqrt(die.vx * die.vx + die.vy * die.vy)
        if speed < REST_THRESHOLD and math.abs(die.av) < ANGULAR_REST then
            die.vx, die.vy, die.av = 0, 0, 0
        else
            allRest = false
        end
    end
    if allRest then
        -- Quando tutti sono a riposo, inchioda l'ultima faccia mostrata e termina rotolamento
        for _, die in ipairs(roll) do
            die.isRolling = false
            die.faceTimer = math.huge
            -- Non riposizionare (niente griglia), restano dove si sono fermati
        end
    end
end

-- Scatter iniziale per evitare sovrapposizioni alla creazione
function Dice.initialScatter(tray, roll)
    if not roll or #roll == 0 then return end
    for _ = 1, 6 do
        for i = 1, #roll do
            clampDie(roll[i], tray)
        end
        for i = 1, #roll do
            for j = i + 1, #roll do
                handleDicePairCollision(roll[i], roll[j])
            end
        end
    end
end

function Dice.arrangeScatter(tray, roll, opts)
    opts = opts or {}
    if #roll == 0 then return end

    local cx = tray.x + tray.w * 0.5
    local cy = tray.y + tray.h * 0.5
    local n = #roll
    
    -- ALGORITMO SEMPLICE E AFFIDABILE: Griglia con rumore casuale
    local gridCols = 3
    local gridRows = 2
    local gridSpacing = Dice.SIZE + 24  -- Spaziatura generosa
    
    -- Calcola la griglia centrata
    local gridStartX = cx - (gridCols - 1) * gridSpacing / 2
    local gridStartY = cy - (gridRows - 1) * gridSpacing / 2
    
    for i, die in ipairs(roll) do
        local col = ((i - 1) % gridCols) + 1
        local row = math.floor((i - 1) / gridCols) + 1
        
        -- Posizione base della griglia
        local baseX = gridStartX + (col - 1) * gridSpacing
        local baseY = gridStartY + (row - 1) * gridSpacing
        
        -- Aggiungi rumore casuale per rendere più naturale
        local noiseX = (random() - 0.5) * 16  -- Rumore limitato
        local noiseY = (random() - 0.5) * 16
        
        die.x = baseX + noiseX
        die.y = baseY + noiseY
        die.angle = (random() - 0.5) * 0.4  -- Rotazione limitata
        
        if not opts.keepRollingState then
            die.isRolling = false
        end
        if not opts.preserveLocks then
            die.locked = false
        end
    end
    
    -- Assicurati che tutti i dadi siano dentro il tray
    for _, die in ipairs(roll) do
        clampDie(die, tray)
    end
    
    print("Dadi disposti in griglia 2x3 con rumore casuale")
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

-- Draws a rotated selection outline with soft glow around the die
local function drawSelectionOverlay(die)
    love.graphics.push()
    love.graphics.translate(die.x, die.y)
    love.graphics.rotate(die.angle or 0)
    local w = Dice.SIZE + 8
    local h = Dice.SIZE + 8
    -- Soft outer glow
    love.graphics.setColor(0.98, 0.86, 0.28, 0.25)
    love.graphics.setLineWidth(8)
    love.graphics.rectangle("line", -w/2, -h/2, w, h, 14, 14)
    -- Crisp inner outline
    love.graphics.setColor(0.98, 0.86, 0.28, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", -w/2, -h/2, w, h, 14, 14)
    love.graphics.pop()
end

function Dice.drawDie(die)
    -- Ombra sempre visibile
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", die.x + 8, die.y + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)
    
    -- Prova prima a usare le animazioni, altrimenti usa il rendering tradizionale
    if DiceAnimations.isInitialized() and die.pose ~= "iso" then
        local scale = Dice.SIZE / 64  -- Scala da 64px (spritesheet) a 48px (Dice.SIZE)
        
        -- Disegna il dado con animazione
        local success = DiceAnimations.drawDie(die, die.x, die.y, scale, die.angle)
        
        if success then
            if die.locked then drawSelectionOverlay(die) end
            return
        end
    end
    
    -- Fallback al rendering tradizionale se le animazioni non sono disponibili
    -- Ombra
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.ellipse("fill", die.x + 8, die.y + Dice.RADIUS + 6, Dice.RADIUS, Dice.RADIUS * 0.55)

    love.graphics.push()
    love.graphics.translate(die.x, die.y)
    if die.pose == "iso" then
        love.graphics.rotate(math.pi / 4)
        love.graphics.scale(1, 0.7)
    else
        love.graphics.rotate(die.angle)
    end

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

    if die.locked then drawSelectionOverlay(die) end
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

    -- Spaziatura più generosa per evitare sovrapposizioni
    -- Adaptive spacing: try to fit all kept dice vertically inside the area
    local maxSpacing = Dice.SIZE + 16
    local spacing = maxSpacing
    if area.h > 0 then
        spacing = math.min(maxSpacing, math.floor(area.h / #kept))
    end
    local totalHeight = spacing * #kept
    local startY
    if alignTop then
        startY = area.y + spacing * 0.5
    else
        startY = area.y + area.h - totalHeight + spacing * 0.5
    end
    -- Center X with a small inward padding so dice sit inside the recessed area visually
    local paddingX = math.max(8, math.min(20, area.w * 0.08))
    local centerX = area.x + area.w * 0.5
    if centerX < area.x + paddingX then centerX = area.x + paddingX end
    if centerX > area.x + area.w - paddingX then centerX = area.x + area.w - paddingX end

    for index, value in ipairs(kept) do
        local y = startY + (index - 1) * spacing
        Dice.drawDie({
            value = value,
            x = centerX,
            y = y,
            angle = 0,
            locked = true, -- visually indicate kept dice
        })
    end
end

-- Disegna i dadi tenuti in fila lungo l'asse delle cerniere (orizzontale)
function Dice.drawKeptOnHinge(board, kept, isTopRow)
    if not board or not kept or #kept == 0 then
        return
    end
    local marginX = 60
    local startX = board.x + marginX
    local endX = board.x + board.w - marginX
    if endX <= startX then return end

    local hingeRatio = board.hingeRatio or 0.68
    local hingeY = board.y + board.h * hingeRatio
    local y = hingeY + (isTopRow and -(Dice.RADIUS + 8) or (Dice.RADIUS + 8))

    local availableW = endX - startX
    local defaultSpacing = Dice.SIZE + 16
    local spacing
    if #kept <= 1 then
        spacing = 0
    else
        spacing = math.min(defaultSpacing, availableW / (#kept - 1))
    end

    local totalW = spacing * math.max(0, #kept - 1)
    local x0 = startX + (availableW - totalW) * 0.5

    for i, value in ipairs(kept) do
        local x = (#kept == 1) and (startX + availableW * 0.5) or (x0 + (i - 1) * spacing)
        Dice.drawDie({
            value = value,
            x = x,
            y = y,
            angle = 0,
            locked = true,
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