-- DiceMesh - 3D dice rendering system
local DiceMesh = {}

-- Configuration
local FOV = 400
local CAM_Z = 5
local PHYSICS_SCALE = 48

-- Quaternion functions
local function qmul(a, b)
    return {
        w = a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z,
        x = a.w*b.x + a.x*b.w + a.y*b.z - a.z*b.y,
        y = a.w*b.y - a.x*b.z + a.y*b.w + a.z*b.x,
        z = a.w*b.z + a.x*b.y - a.y*b.x + a.z*b.w
    }
end

local function qnormalize(q)
    local len = math.sqrt(q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z)
    if len == 0 then return {w=1, x=0, y=0, z=0} end
    return {w=q.w/len, x=q.x/len, y=q.y/len, z=q.z/len}
end

-- 3D mesh system
function DiceMesh.init()
    print("[DiceMesh] 3D system initialized")
end

function DiceMesh.project3D(x, y, z, isometric)
    if isometric then
        local angle = math.rad(30)
        local x2d = (x - y) * math.cos(angle)
        local y2d = (x + y) * math.sin(angle) - z
        return x2d, y2d
    else
        local perspective = FOV / (CAM_Z + z)
        return x * perspective, y * perspective
    end
end

function DiceMesh.renderDie3D(die, isometric)
    -- True 3D cube rendering with perspective, animated rotation, shadows, and pips/values on all faces
    local size = 48
    local half = size / 2
    -- Cube vertices (local space)
    local verts = {
        {-half, -half, -half}, -- 1: left-top-back
        { half, -half, -half}, -- 2: right-top-back
        { half,  half, -half}, -- 3: right-bottom-back
        {-half,  half, -half}, -- 4: left-bottom-back
        {-half, -half,  half}, -- 5: left-top-front
        { half, -half,  half}, -- 6: right-top-front
        { half,  half,  half}, -- 7: right-bottom-front
        {-half,  half,  half}, -- 8: left-bottom-front
    }

    -- Animated rotation: update die.ax, die.ay, die.angle (Z)
    die.ax = tonumber(die.ax) or 0
    die.ay = tonumber(die.ay) or 0
    die.angle = tonumber(die.angle) or 0
    die.rotSpeedX = tonumber(die.rotSpeedX) or 0.01
    die.rotSpeedY = tonumber(die.rotSpeedY) or 0.013
    die.rotSpeedZ = tonumber(die.rotSpeedZ) or 0.017
    die.ax = die.ax + die.rotSpeedX
    die.ay = die.ay + die.rotSpeedY
    die.angle = die.angle + die.rotSpeedZ

    local ax = die.ax or 0
    local ay = die.ay or 0
    local az = die.angle or 0
    local function rotate(v)
        local x, y, z = v[1], v[2], v[3]
        -- X axis
        local cy, sy = math.cos(ax), math.sin(ax)
        y, z = y * cy - z * sy, y * sy + z * cy
        -- Y axis
        local cz, sz = math.cos(ay), math.sin(ay)
        x, z = x * cz + z * sz, -x * sz + z * cz
        -- Z axis
        local cx, sx = math.cos(az), math.sin(az)
        x, y = x * cx - y * sx, x * sx + y * cx
        return x, y, z
    end

    -- Project vertices to screen
    local px, py = DiceMesh.project3D(die.x, die.y, die.z or 0, false)
    local projected = {}
    local rotatedVerts = {}
    for i, v in ipairs(verts) do
        local x, y, z = rotate(v)
        rotatedVerts[i] = {x, y, z}
        local sx, sy = DiceMesh.project3D(x, y, z + (die.z or 0) + 100, false)
        projected[i] = {px + sx, py + sy, z}
    end

    -- Cube faces (each as 4 indices)
    local faces = {
        {5,6,7,8}, -- front
        {1,2,3,4}, -- back
        {1,5,8,4}, -- left
        {2,6,7,3}, -- right
        {1,2,6,5}, -- top
        {4,3,7,8}, -- bottom
    }
    local faceColors = {
        {0.95,0.95,1.0,1}, -- front
        {0.85,0.85,0.95,1}, -- back
        {0.9,0.9,1.0,1}, -- left
        {0.9,0.9,1.0,1}, -- right
        {1.0,1.0,1.0,1}, -- top
        {0.8,0.8,0.9,1}, -- bottom
    }
    local faceValues = {
        die.value or 1, -- front
        DiceMesh.getOppositeValue(die.value or 1), -- back
        DiceMesh.getLeftValue(die.value or 1), -- left
        DiceMesh.getRightValue(die.value or 1), -- right
        DiceMesh.getTopValue(die.value or 1), -- top
        DiceMesh.getBottomValue(die.value or 1), -- bottom
    }

    -- Draw shadow ellipse under die
    love.graphics.push()
    love.graphics.setColor(0,0,0,0.18)
    love.graphics.ellipse("fill", px, py + half + 8, half * 0.85, half * 0.35)
    love.graphics.pop()

    -- Painter's order: sort faces by average Z (draw farthest first)
    local faceOrder = {}
    for i, face in ipairs(faces) do
        local zsum = 0
        for j=1,4 do zsum = zsum + rotatedVerts[face[j]][3] end
        faceOrder[i] = {i=i, z=zsum/4}
    end
    table.sort(faceOrder, function(a,b) return a.z < b.z end)

    love.graphics.push()
    for _, fo in ipairs(faceOrder) do
        local i = fo.i
        local face = faces[i]
        love.graphics.setColor(faceColors[i])
        love.graphics.polygon("fill",
            projected[face[1]][1], projected[face[1]][2],
            projected[face[2]][1], projected[face[2]][2],
            projected[face[3]][1], projected[face[3]][2],
            projected[face[4]][1], projected[face[4]][2]
        )
        love.graphics.setColor(0.3,0.3,0.4,1)
        love.graphics.setLineWidth(2)
        love.graphics.polygon("line",
            projected[face[1]][1], projected[face[1]][2],
            projected[face[2]][1], projected[face[2]][2],
            projected[face[3]][1], projected[face[3]][2],
            projected[face[4]][1], projected[face[4]][2]
        )
        -- Draw value/pips on face (center)
        local cx = (projected[face[1]][1] + projected[face[2]][1] + projected[face[3]][1] + projected[face[4]][1]) / 4
        local cy = (projected[face[1]][2] + projected[face[2]][2] + projected[face[3]][2] + projected[face[4]][2]) / 4
        love.graphics.setColor(0,0,0,1)
        love.graphics.setFont(love.graphics.getFont())
        DiceMesh.drawPipsOrValue(faceValues[i], cx, cy, size * 0.32)
    end
    love.graphics.pop()
-- Helper: get opposite, left, right, top, bottom values for a die
function DiceMesh.getOppositeValue(v)
    -- Standard d6: 1-6, opposite faces sum to 7
    return 7 - v
end
function DiceMesh.getLeftValue(v)
    -- Arbitrary mapping for d6
    local map = {3,4,1,2,5,6}
    return map[v] or v
end
function DiceMesh.getRightValue(v)
    local map = {4,3,2,1,6,5}
    return map[v] or v
end
function DiceMesh.getTopValue(v)
    local map = {5,6,3,4,2,1}
    return map[v] or v
end
function DiceMesh.getBottomValue(v)
    local map = {2,1,4,3,6,5}
    return map[v] or v
end

-- Helper: draw pips or value at (cx,cy) with radius r
function DiceMesh.drawPipsOrValue(val, cx, cy, r)
    -- For d6, draw pips, else print value
    if val >= 1 and val <= 6 then
        local pip = function(dx,dy)
            love.graphics.circle("fill", cx+dx*r, cy+dy*r, r*0.18)
        end
        if val == 1 then pip(0,0)
        elseif val == 2 then pip(-0.4,-0.4); pip(0.4,0.4)
        elseif val == 3 then pip(-0.4,-0.4); pip(0,0); pip(0.4,0.4)
        elseif val == 4 then pip(-0.4,-0.4); pip(0.4,-0.4); pip(-0.4,0.4); pip(0.4,0.4)
        elseif val == 5 then pip(-0.4,-0.4); pip(0.4,-0.4); pip(0,0); pip(-0.4,0.4); pip(0.4,0.4)
        elseif val == 6 then pip(-0.4,-0.4); pip(0.4,-0.4); pip(-0.4,0); pip(0.4,0); pip(-0.4,0.4); pip(0.4,0.4)
        end
    else
        love.graphics.print(tostring(val), cx-8, cy-12)
    end
end
end

function DiceMesh.setRenderMode(mode)
    print("[DiceMesh] Render mode set to:", mode)
end

-- Stub functions for compatibility
function DiceMesh.updatePhysics(dice, dt)
    -- Basic physics handled by dice.lua
end

function DiceMesh.createCubeMesh()
    return {}
end

return DiceMesh
