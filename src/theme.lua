-- Theme tokens for unified styling
local Theme = {}

Theme.colors = {
  darkBG    = {0.08, 0.07, 0.09},
  panel     = {0.13, 0.10, 0.08},
  panelEdge = {0.35, 0.27, 0.18},
  text      = {0.96, 0.92, 0.85},
  mutedText = {0.85, 0.82, 0.7},
  
  gold      = {0.84, 0.71, 0.42},  -- #D7B46A approx
  brass     = {0.60, 0.48, 0.25},  -- #9A7A3F approx
  brassEdge = {0.74, 0.60, 0.30},
  infoBlue  = {0.29, 0.44, 0.65},
  disabled  = {0.22, 0.18, 0.12, 0.42},
}

function Theme.setColor(c)
  if not c then return end
  if #c == 3 then love.graphics.setColor(c[1], c[2], c[3])
  else love.graphics.setColor(c[1], c[2], c[3], c[4]) end
end

return Theme
