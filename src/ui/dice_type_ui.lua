-- UI helper for displaying dice type info, roll stats and tooltips
-- This module is intentionally lightweight so render.lua can require it safely even if not used.
-- Functions are no-ops when passed nil arguments.

local M = {}
local constants = require("src.core.constants")
local WeightedRNG = require("src.core.weighted_rng")

-- Internal helper to draw a small shadowed text
local function shadowedPrint(font, text, x, y, color, shadow)
    if not font or not text then return end
    shadow = shadow or {0,0,0,0.55}
    color = color or {0.95,0.95,0.92,1}
    love.graphics.setFont(font)
    love.graphics.setColor(shadow)
    love.graphics.print(text, x+2, y+2)
    love.graphics.setColor(color)
    love.graphics.print(text, x, y)
end

-- Draw info about all available dice types (when there is no current roll)
function M.drawDiceTypeInfo(x, y, font)
    if not font then return end
    local lineH = font:getHeight() + 4
    local i = 0
    shadowedPrint(font, "Dice Types:", x, y, {0.98,0.96,0.88,1})
    i = i + 1
    for key, cfg in pairs(constants.DICE_TYPES) do
        local probs = WeightedRNG.getProbabilities(key)
        local avg = 0
        if probs then
            for face=1,6 do avg = avg + probs[face]*face end
        end
        local info = string.format("%s (avg %.2f)", cfg.name or key, avg)
        shadowedPrint(font, info, x+8, y + i*lineH, cfg.color or {1,1,1,1})
        i = i + 1
    end
end

-- Draw statistics for the current roll (values distribution & dice types used)
function M.drawRollStats(roll, x, y, font)
    if not (roll and font) then return end
    local counts = {0,0,0,0,0,0}
    local types = {}
    for _, die in ipairs(roll) do
        counts[die.value or 0] = (counts[die.value or 0] or 0) + 1
        local t = die.diceType or constants.DEFAULT_DICE_TYPE
        types[t] = (types[t] or 0) + 1
    end

    local lineH = font:getHeight() + 4
    local i = 0
    shadowedPrint(font, "Current Roll:", x, y, {0.98,0.96,0.88,1})
    i = i + 1
    -- Faces
    local faceLine = {}
    for face=1,6 do
        if counts[face] and counts[face] > 0 then
            table.insert(faceLine, face .. "x" .. counts[face])
        end
    end
    shadowedPrint(font, table.concat(faceLine, "  "), x+8, y + i*lineH, {0.9,0.92,0.98,1})
    i = i + 1
    -- Types
    local typeLine = {}
    for t, c in pairs(types) do
        local cfg = constants.DICE_TYPES[t]
        table.insert(typeLine, (cfg and cfg.name or t) .. "x" .. c)
    end
    shadowedPrint(font, table.concat(typeLine, "  "), x+8, y + i*lineH, {0.85,0.85,0.75,1})
end

-- Draw a tooltip for a specific die (probabilities & description)
function M.drawDiceTooltip(die, x, y, font)
    if not (die and font) then return end
    local dtype = die.diceType or constants.DEFAULT_DICE_TYPE
    local cfg = constants.DICE_TYPES[dtype]
    if not cfg then return end
    local probs = WeightedRNG.getProbabilities(dtype)

    local lineH = font:getHeight() + 2
    local lines = {}
    table.insert(lines, (cfg.name or dtype) .. " die")
    if cfg.description then table.insert(lines, cfg.description) end
    if probs then
        local probParts = {}
        for face=1,6 do
            probParts[#probParts+1] = string.format("%d:%.0f%%", face, probs[face]*100)
        end
        table.insert(lines, table.concat(probParts, "  "))
    end

    -- Compute box size
    local w = 0
    for _, line in ipairs(lines) do
        local lw = font:getWidth(line)
        if lw > w then w = lw end
    end
    local h = #lines * lineH + 10
    w = w + 16

    -- Background
    love.graphics.setColor(0,0,0,0.35)
    love.graphics.rectangle("fill", x+4, y+4, w, h, 8, 8)
    love.graphics.setColor(0.12,0.12,0.14,0.95)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(cfg.color or {0.9,0.9,0.9,1})
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)

    -- Text
    for i, line in ipairs(lines) do
        shadowedPrint(font, line, x+8, y + 5 + (i-1)*lineH, {0.95,0.96,0.98,1})
    end
    love.graphics.setLineWidth(1)
end

return M
