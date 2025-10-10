-- Board 3D "a libro" per LOVE11.x
-- Dipendenze: nessuna esterna; usa meshes + proiezione prospettica semplice.
-- API:
--   local Board3D = require("src.graphics.board3d")
--   local board = Board3D.new{x=CX, y=CY, w=720, h=440, t=28, inset=18, bevel=8, tex="assets/UI/wooden_board.png"}
--   board:setOpen(0)         -- 0..1
--   board:animateTo(1, 0.7)  -- apri in 0.7s
--   board:update(dt); board:draw()

local Board3D = {}

--=== proiezione (allinea ai valori usati per i dadi) ===--
local FOV, CAM_Z = 500, 1200
local function screenCenter() local w,h=love.graphics.getWidth(),love.graphics.getHeight(); return w*0.5,h*0.5 end
local function project3D(x,y,z)
  local CX,CY = screenCenter()
  local Zc = CAM_Z - z
  return CX + (FOV*x)/Zc, CY - (FOV*y)/Zc, Zc
end

-- rotazioni minime (niente quaternioni: bastano X/Y)
local function rotX(p, a) local c,s=math.cos(a),math.sin(a); return p[1], c*p[2]-s*p[3], s*p[2]+c*p[3] end
local function rotY(p, a) local c,s=math.cos(a),math.sin(a); return c*p[1]+s*p[3], p[2], -s*p[1]+c*p[3] end
local function add(p,dx,dy,dz) return {p[1]+dx,p[2]+dy,p[3]+dz} end

-- costruisce una triangle strip tra due polilinee pA[i] (scalloped) e pB[i] (liscia)
local function cloneVerts(verts)
  local copy = {}
  for i, v in ipairs(verts) do
    copy[i] = {v[1], v[2], v[3], v[4]}
  end
  return copy
end

local function createMeshRecord(verts, img)
  local fmt = {{"VertexPosition","float",2},{"VertexTexCoord","float",2}}
  local mesh = love.graphics.newMesh(fmt, verts, "triangles", "stream")
  mesh:setTexture(img)
  return {mesh = mesh, base = cloneVerts(verts)}
end

local function stripToMesh(pA, pB, img)
  local verts = {}
  for i=1,#pA-1 do
    local a1,a2 = pA[i], pA[i+1]
    local b1,b2 = pB[i], pB[i+1]
    -- due triangoli per segmento
    table.insert(verts, {a1[1],a1[2], 0,0})
    table.insert(verts, {b1[1],b1[2], 1,0})
    table.insert(verts, {b2[1],b2[2], 1,1})

    table.insert(verts, {a1[1],a1[2], 0,0})
    table.insert(verts, {b2[1],b2[2], 1,1})
    table.insert(verts, {a2[1],a2[2], 0,1})
  end
  return createMeshRecord(verts, img)
end

-- genera punti lungo una retta con scallop sinusoidale verso l'interno
-- side: "top","bottom","left","right"
local function scallopPolyline(side, w, h, inset, frameW, r, segments)
  local ptsA, ptsB = {}, {}
  local innerL = -w*0.5 + inset
  local innerR =  w*0.5 - inset
  local innerT = -h*0.5 + inset
  local innerB =  h*0.5 - inset

  local function push(x,y)
    table.insert(ptsA, {x,y})
    table.insert(ptsB, {x + (side=="left" and -frameW or side=="right" and frameW or 0),
                        y + (side=="top" and -frameW or side=="bottom" and frameW or 0)})
  end

  local len, sx, sy, dx, dy
  if side=="top"    then len, sx,sy, dx,dy = innerR-innerL, innerL, innerT, 1,0
  elseif side=="bottom" then len, sx,sy, dx,dy = innerR-innerL, innerL, innerB, 1,0
  elseif side=="left"   then len, sx,sy, dx,dy = innerB-innerT, innerL, innerT, 0,1
  else -- right
    len, sx,sy, dx,dy = innerB-innerT, innerR, innerT, 0,1
  end

  local N = segments
  local waves = math.max(1, math.floor(len / (r*2.2))) -- quanti lobi lungo il lato
  local totalSamples = waves * N
  for i=0,totalSamples do
    local t = i/totalSamples
    local x = sx + (dx==1 and t*len or 0)
    local y = sy + (dy==1 and t*len or 0)
    -- fase: alterna "denti" regolari; ampiezza verso l'interno del rettangolo
    local phase = t * waves * math.pi*2
    local amp = math.sin(phase) * r
    local ix, iy = 0,0
    if side=="top"    then iy = -amp
    elseif side=="bottom" then iy = amp
    elseif side=="left"   then ix = -amp
    else ix = amp end
    push(x+ix, y+iy)
  end

  return ptsA, ptsB
end

-- helper mesh quad -> 2 triangoli
local function buildQuad(p1,p2,p3,p4, u0,v0,u1,v1, u2,v2,u3,v3)
  return {
    {p1[1],p1[2],u0,v0}, {p2[1],p2[2],u1,v1}, {p3[1],p3[2],u2,v2},
    {p1[1],p1[2],u0,v0}, {p3[1],p3[2],u2,v2}, {p4[1],p4[2],u3,v3},
  }
end

local function newMesh(verts, img)
  return createMeshRecord(verts, img)
end

-- costruisce una "lid" (coperchio) piano con cornice rialzata e pannello incassato
local function buildLidMeshes(w,h,t,inset,img)
  -- w,h dimensioni in pianta; t spessore totale
  local zTop, zBot = t*0.5, -t*0.5
  local ix,iy = inset,inset
  -- UV semplici (tutta la texture per pannello; cornice riusa la stessa)
  local U = {0,0, 1,0, 1,1, 0,1}

  local function rectVerts(x0,y0,x1,y1,z)
    return { {x0,y0,z}, {x1,y0,z}, {x1,y1,z}, {x0,y1,z} }
  end

  -- top face cornice (anello: fuori meno dentro)
  local outer = rectVerts(-w*0.5,-h*0.5, w*0.5, h*0.5, zTop)
  local inner = rectVerts(-w*0.5+ix,-h*0.5+iy, w*0.5-ix, h*0.5-iy, zTop)

  -- pannello incassato
  local panelZ = zTop - math.max(2, t*0.35)
  local panel = rectVerts(-w*0.5+ix*1.2,-h*0.5+iy*1.2, w*0.5-ix*1.2, h*0.5-iy*1.2, panelZ)

  -- lati (semplici): quattro pareti verticali esterne
  local walls = {
    -- sinistra
    { {-w*0.5,-h*0.5,zTop}, {-w*0.5+0,-h*0.5, zBot}, {-w*0.5+0,h*0.5, zBot}, {-w*0.5, h*0.5, zTop} },
    -- destra
    { { w*0.5,-h*0.5,zTop}, { w*0.5+0,-h*0.5, zBot}, { w*0.5+0,h*0.5, zBot}, { w*0.5, h*0.5, zTop} },
    -- alto
    { {-w*0.5,-h*0.5,zTop}, {-w*0.5,-h*0.5, zBot}, { w*0.5,-h*0.5, zBot}, { w*0.5,-h*0.5, zTop} },
    -- basso
    { {-w*0.5, h*0.5,zTop}, {-w*0.5, h*0.5, zBot}, { w*0.5, h*0.5, zBot}, { w*0.5, h*0.5, zTop} },
  }

  local verts = {}

  -- anello cornice = outer quad meno inner (dissegniamo 4 strisce)
  local o, i = outer, inner
  local strips = {
    {o[1],o[2], {i[2][1],i[2][2],i[2][3]}, {i[1][1],i[1][2],i[1][3]}}, -- top
    {o[2],o[3], {i[3][1],i[3][2],i[3][3]}, {i[2][1],i[2][2],i[2][3]}}, -- right
    {o[3],o[4], {i[4][1],i[4][2],i[4][3]}, {i[3][1],i[3][2],i[3][3]}}, -- bottom
    {o[4],o[1], {i[1][1],i[1][2],i[1][3]}, {i[4][1],i[4][2],i[4][3]}}, -- left
  }
  for _,q in ipairs(strips) do
    local v = buildQuad(q[1],q[2],q[3],q[4],  U[1],U[2],U[3],U[4],U[3],U[4],U[1],U[2])
    for _,p in ipairs(v) do table.insert(verts, p) end
  end

  -- pannello
  do
    local p = panel
    local v = buildQuad(p[1],p[2],p[3],p[4], U[1],U[2],U[3],U[4],U[3],U[4],U[1],U[2])
    for _,pt in ipairs(v) do table.insert(verts, pt) end
  end

  -- pareti
  for _,wq in ipairs(walls) do
    local v = buildQuad(wq[1],wq[2],wq[3],wq[4], U[1],U[2],U[1],U[4],U[3],U[4],U[3],U[2])
    for _,pt in ipairs(v) do table.insert(verts, pt) end
  end

  return newMesh(verts, img)
end

function Board3D.new(opts)
  local self = setmetatable({}, {__index=Board3D})
  self.x, self.y = opts.x or 0, opts.y or 0
  self.w, self.h = opts.w or 720, opts.h or 440
  self.t        = opts.t or 28
  self.inset    = opts.inset or 18
  self.tex      = love.graphics.newImage(opts.tex or "assets/UI/wooden_board.png")
  self.tex:setFilter("linear","linear")

  -- due lids: TOP (ruota intorno alla cerniera in basso) e BOTTOM (ruota intorno alla cerniera in alto)
  self.top  = { ang = 0.0, target=0.0, speed=0.0 }
  self.bot  = { ang = 0.0, target=0.0, speed=0.0 }
  self.hingeGap = 6

  -- crea le mesh dei due coperchi
  self.meshTop = buildLidMeshes(self.w, self.h*0.5 - self.hingeGap, self.t, self.inset, self.tex)
  self.meshBot = buildLidMeshes(self.w, self.h*0.5 - self.hingeGap, self.t, self.inset, self.tex)

  -- opzionale: cornice scalloped
  self.scallop = (opts.scallop == true)
  self.scallop_r = opts.scallop_r or 14
  self.scallop_segments = opts.scallop_segments or 8
  self.frameW = opts.frameW or (self.inset * 0.65)

  if self.scallop then
    local w, h2 = self.w, (self.h*0.5 - self.hingeGap)
    -- generiamo 4 strisce per ciascun coperchio (usiamo la stessa geometria e texture)
    local function buildScallopedSet(hh)
      local topA, topB = scallopPolyline("top", w, hh*2, self.inset, self.frameW, self.scallop_r, self.scallop_segments)
      local botA, botB = scallopPolyline("bottom", w, hh*2, self.inset, self.frameW, self.scallop_r, self.scallop_segments)
      local lefA, lefB = scallopPolyline("left", w, hh*2, self.inset, self.frameW, self.scallop_r, self.scallop_segments)
      local rigA, rigB = scallopPolyline("right", w, hh*2, self.inset, self.frameW, self.scallop_r, self.scallop_segments)
      return {
  stripToMesh(topA, topB, self.tex),
  stripToMesh(botA, botB, self.tex),
  stripToMesh(lefA, lefB, self.tex),
  stripToMesh(rigA, rigB, self.tex),
      }
    end
  self.scallopTop = buildScallopedSet(self.h*0.5 - self.hingeGap)
  self.scallopBot = buildScallopedSet(self.h*0.5 - self.hingeGap)
  end

  return self
end

-- 0 chiusa, 1 aperta (apre entrambe verso l'esterno ~110°)
function Board3D:setOpen(alpha)
  local a = math.max(0, math.min(1, alpha))
  self.top.ang = -a * math.rad(110)
  self.bot.ang =  a * math.rad(110)
  self.top.target, self.bot.target = self.top.ang, self.bot.ang
  self.top.speed,  self.bot.speed  = 0,0
end

-- animazione dolce
function Board3D:animateTo(alpha, duration)
  local a = math.max(0, math.min(1, alpha))
  local tgtTop = -a * math.rad(110)
  local tgtBot =  a * math.rad(110)
  self.top.target, self.bot.target = tgtTop, tgtBot
  local d = math.max(0.001, duration or 0.6)
  self.top.speed  = (tgtTop - self.top.ang)/d
  self.bot.speed  = (tgtBot - self.bot.ang)/d
end

function Board3D:update(dt)
  -- integra angoli verso target
  local function step(h,dt)
    if math.abs(h.target - h.ang) > 1e-3 then
      h.ang = h.ang + h.speed*dt
    else
      h.ang = h.target; h.speed=0
    end
  end
  step(self.top, dt); step(self.bot, dt)
end

-- disegna una metà (con rotazione attorno alla cerniera)
local function drawHalf(meshRec, x,y, w,h2, t, ang, up, extra)
  -- costruiamo 4 punti di riferimento (cornice) per applicare rotazione X attorno all'asse cerniera
  -- origin locale al centro del semitavolo; spostiamo poi a (x,y)
  local mesh = meshRec.mesh
  local verts = meshRec.base or {}
  local out = {}
  for i=1,#verts do
    local vx,vy = verts[i][1], verts[i][2]
    -- alziamo/abbassiamo il semitavolo:
    local px,py,pz = vx, vy + (up and -h2*0.5 or h2*0.5), 0
    -- ruota attorno all'asse della cerniera (X)
    local rx,ry,rz = rotX({px,py,pz}, ang)
    -- trasla in mondo
    rx,ry,rz = rx + x, ry + y, rz
    local sx,sy = project3D(rx,ry,rz)
    out[i] = {sx,sy, verts[i][3], verts[i][4]}
  end
  mesh:setVertices(out)
  love.graphics.draw(mesh)
  
  -- disegna mesh scalloped extra
  if extra then
    for _,rec in ipairs(extra) do
      local v = rec.base or {}
      local vout = {}
      for i=1,#v do
        local vx,vy = v[i][1], v[i][2]
        local px,py,pz = vx, vy + (up and -h2*0.5 or h2*0.5), 0
        local rx,ry,rz = rotX({px,py,pz}, ang)
        rx,ry,rz = rx + x, ry + y, rz
        local sx,sy = project3D(rx,ry,rz)
        vout[i] = {sx,sy, v[i][3], v[i][4]}
      end
      rec.mesh:setVertices(vout)
      love.graphics.draw(rec.mesh)
    end
  end
end

function Board3D:draw()
  local CX,CY = screenCenter()
  -- BOTTOM (sotto alla cerniera)
  local h2 = self.h*0.5 - self.hingeGap
  drawHalf(self.meshBot, self.x, self.y + h2 + self.hingeGap, self.w, h2, self.t, self.bot.ang, false, self.scallop and self.scallopBot or nil)
  -- TOP (sopra alla cerniera)
  drawHalf(self.meshTop, self.x, self.y - h2 - self.hingeGap, self.w, h2, self.t, self.top.ang, true,  self.scallop and self.scallopTop or nil)

  -- cerniera (due rettangolini semplici)
  love.graphics.setColor(0.55,0.45,0.25,0.8)
  local hw = 36; local hh = 8
  love.graphics.rectangle("fill", self.x-hw, self.y-hh, hw*2, hh*2, 6,6)
  love.graphics.setColor(1,1,1,1)
end

return Board3D