-- UI helper for displaying dice type info, roll stats and tooltips
-- This module is intentionally lightweight so render.lua can require it safely even if not used.
-- Functions are no-ops when passed nil arguments.

local M = {}
-- local constants = require("src.core.constants")
-- local WeightedRNG = require("src.core.weighted_rng")

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
--[[
function M.drawDiceTypeInfo(x, y, font)
    -- Disabilitato: dipende da constants/WeightedRNG
end
]]

-- Draw statistics for the current roll (values distribution & dice types used)
--[[
function M.drawRollStats(roll, x, y, font)
    -- Disabilitato: dipende da constants
end
]]

-- Draw a tooltip for a specific die (probabilities & description)
--[[
function M.drawDiceTooltip(die, x, y, font)
    -- Disabilitato: dipende da constants/WeightedRNG
end
]]

return M
