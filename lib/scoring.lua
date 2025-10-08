local S = {}

function S.counts(arr)
  local c={0,0,0,0,0,0,0}
  for _,v in ipairs(arr) do c[v]=c[v]+1 end
  return c
end

local function deepcopy(t) local r={}; for k,v in pairs(t) do r[k]=type(v)=='table' and deepcopy(v) or v end; return r end

local function hasFaces(c, faces)
  for _,f in ipairs(faces) do if c[f]==0 then return false end end
  return true
end
S.hasFaces = hasFaces

local function basePoints(c)
  c = deepcopy(c)
  local pts=0
  for f=1,6 do
    if c[f]>=3 then
      local base = (f==1) and 1000 or f*100
      local mult = 2^(c[f]-3)
      pts = pts + base*mult
      c[f]=0
    end
  end
  pts = pts + c[1]*100; c[1]=0
  pts = pts + c[5]*50;  c[5]=0
  local leftovers = c[2]+c[3]+c[4]+c[6]
  return {points=pts, valid=(leftovers==0)}
end
S.basePoints = basePoints

function S.scoreSelection(vals)
  local c = S.counts(vals)
  local used = {0,0,0,0,0,0,0}
  local points = 0

  -- 1+2+3+4+5+6 = 1500
  if #vals == 6 and c[1]==1 and c[2]==1 and c[3]==1 and c[4]==1 and c[5]==1 and c[6]==1 then
    points = points + 1500
    for i=1,6 do used[i]=used[i]+1 end
  end

  -- 1+2+3+4+5 = 500
  if c[1]>=1 and c[2]>=1 and c[3]>=1 and c[4]>=1 and c[5]>=1 then
    points = points + 500
    for i=1,5 do used[i]=used[i]+1 end
  end

  -- 2+3+4+5+6 = 750
  if c[2]>=1 and c[3]>=1 and c[4]>=1 and c[5]>=1 and c[6]>=1 then
    points = points + 750
    for i=2,6 do used[i]=used[i]+1 end
  end

  -- Tre o più uguali (1X3 = 1000, 1X4 = 2000, ...)
  for face=1,6 do
    if c[face] >= 3 then
      local base = (face==1) and 1000 or face*100
      local mult = 2^(c[face]-3)
      points = points + base*mult
      used[face] = used[face] + c[face] -- segna tutti come usati
    end
  end

  -- 1 = 100, 5 = 50 (solo quelli non già usati da combinazioni sopra)
  if c[1] > used[1] then
    points = points + 100 * (c[1] - used[1])
    used[1] = c[1]
  end
  if c[5] > used[5] then
    points = points + 50 * (c[5] - used[5])
    used[5] = c[5]
  end

  return {points=points, valid=points>0}
end

function S.hasAnyScoring(roll)
  if #roll==0 then return false end
  local c=S.counts(roll)
  if #roll>=6 and hasFaces(c,{1,2,3,4,5,6}) then return true end
  if #roll>=5 and (hasFaces(c,{1,2,3,4,5}) or hasFaces(c,{2,3,4,5,6})) then return true end
  if c[1]>0 or c[5]>0 then return true end
  for f=1,6 do if c[f]>=3 then return true end end
  return false
end

return S
