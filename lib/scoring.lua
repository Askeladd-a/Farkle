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
  if #vals==0 then return {points=0, valid=false} end
  local c0 = S.counts(vals)
  local best={points=0,valid=false}
  if #vals==6 and hasFaces(c0,{1,2,3,4,5,6}) then return {points=1500,valid=true} end
  if #vals>=5 and hasFaces(c0,{2,3,4,5,6}) then
    local c=S.counts(vals) for _,f in ipairs({2,3,4,5,6}) do c[f]=c[f]-1 end
    local r=basePoints(c); if r.valid then best={points=750+r.points,valid=true} end
  end
  if #vals>=5 and hasFaces(c0,{1,2,3,4,5}) then
    local c=S.counts(vals) for _,f in ipairs({1,2,3,4,5}) do c[f]=c[f]-1 end
    local r=basePoints(c); if r.valid and 500+r.points>best.points then best={points=500+r.points,valid=true} end
  end
  local r2 = basePoints(c0); if r2.valid and r2.points>best.points then best=r2 end
  return best
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
