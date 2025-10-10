-- Palette colori e costanti UI
local COLORS = {
    bg        = {0.06,0.06,0.08},
    panel     = {0.10,0.10,0.14,0.85},
    text      = {0.94,0.94,0.96},
    shadow    = {0,0,0,0.35},
    play      = {0.20,0.52,0.92},
    options   = {0.97,0.58,0.19},
    quit      = {0.90,0.22,0.27},
    collection= {0.20,0.72,0.48},
    profile   = {0.50,0.58,0.68},
    disabled  = {0.5,0.5,0.5,0.4},
    hover     = {1,1,1,0.12},
}

local function setColor(c)
    love.graphics.setColor(c[1],c[2],c[3],c[4] or 1)
end

local function pointInRect(px,py, r)
    return px>=r.x and px<=r.x+r.w and py>=r.y and py<=r.y+r.h
end

return {
    COLORS = COLORS,
    setColor = setColor,
    pointInRect = pointInRect
}

-- Questo modulo UI non dipende da moduli rimossi.
