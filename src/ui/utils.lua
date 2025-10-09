-- Utility layout e bottoni menu
local function computeRects(w, h, margin, gap, rowH, playW, smallW)
    local y = h - margin - rowH
    local x = math.floor((w - (smallW + playW + smallW*4 + gap*4))/2)
    local rects = {}
    rects.profile    = {x=x, y=y, w=smallW, h=rowH}; x = x + smallW + gap
    rects.play       = {x=x, y=y, w=playW,  h=rowH}; x = x + playW  + gap
    rects.options    = {x=x, y=y, w=smallW, h=rowH}; x = x + smallW + gap
    rects.quit       = {x=x, y=y, w=smallW, h=rowH}; x = x + smallW + gap
    rects.collection = {x=x, y=y, w=smallW, h=rowH}
    return rects
end

return {
    computeRects = computeRects
}
