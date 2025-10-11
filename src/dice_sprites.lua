-- dice_sprites.lua — 6 dadi semplici su griglia isometrica
local iso = require("src.iso_utils")
local M = {}
local layout = { -- pips
  [1]={{0,0}},
  [2]={{-10,-10},{10,10}},
  [3]={{-12,-12},{0,0},{12,12}},
  [4]={{-12,-12},{12,-12},{12,12},{-12,12}},
  [5]={{-12,-12},{12,-12},{0,0},{12,12},{-12,12}},
  [6]={{-12,-12},{-12,0},{-12,12},{12,-12},{12,0},{12,12}},
}
local dice = {}

function M.spawn(n)
  dice = {}
  local spots = {{2,2},{3,4},{5,3},{6,6},{7,2},{1,6}}
  for i=1, math.min(n,#spots) do
    table.insert(dice, {tx=spots[i][1], ty=spots[i][2], z=0, val=i, bob=math.random()*6.283})
  end
end

function M.update(dt)
  -- futuro: animazioni, bobbing temporizzato, ecc.
end

function M.draw()
  for _,d in ipairs(dice) do
    local sx,sy = iso.worldToScreen(d.tx,d.ty,0)
    -- ombra
    love.graphics.setColor(0,0,0,0.18)
    love.graphics.ellipse("fill", sx, sy+10*iso.cam.zoom, 24*iso.cam.zoom, 10*iso.cam.zoom)
    -- corpo
    love.graphics.setColor(0.96,0.96,0.98,1)
    love.graphics.rectangle("fill", sx-22*iso.cam.zoom, sy-22*iso.cam.zoom, 44*iso.cam.zoom, 44*iso.cam.zoom, 8*iso.cam.zoom, 8*iso.cam.zoom)
    love.graphics.setColor(0,0,0,0.25)
    love.graphics.rectangle("line", sx-22*iso.cam.zoom, sy-22*iso.cam.zoom, 44*iso.cam.zoom, 44*iso.cam.zoom, 8*iso.cam.zoom, 8*iso.cam.zoom)
    -- pips
    love.graphics.setColor(0.15,0.15,0.17,0.95)
    for _,p in ipairs(layout[d.val]) do
      love.graphics.circle("fill", sx+p[1]*iso.cam.zoom, sy+p[2]*iso.cam.zoom, 4*iso.cam.zoom)
    end
  end
end

return M
