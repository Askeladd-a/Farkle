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
  if #vals == 0 then
    return {points = 0, valid = false}
  end

  local c = S.counts(vals)
  local used = {0,0,0,0,0,0,0}
  local points = 0

  local function use(face, amount)
    used[face] = used[face] + amount
  end

  if #vals == 6 then
    if hasFaces(c, {1,2,3,4,5,6}) then
      return {points = 1500, valid = true}
    end

    local pairFaces = {}
    local invalidThreePairs = false
    for face = 1, 6 do
      if c[face] == 2 then
        pairFaces[#pairFaces + 1] = face
      elseif c[face] ~= 0 and c[face] ~= 2 then
        invalidThreePairs = true
      end
    end
    if not invalidThreePairs and #pairFaces == 3 then
      for _, face in ipairs(pairFaces) do
        use(face, 2)
      end
      return {points = 1500, valid = true}
    end

    local tripFaces = {}
    for face = 1, 6 do
      if c[face] == 3 then
        tripFaces[#tripFaces + 1] = face
      end
    end
    if #tripFaces == 2 then
      for _, face in ipairs(tripFaces) do
        use(face, 3)
      end
      return {points = 2500, valid = true}
    end

    local fourFace, pairFace
    for face = 1, 6 do
      if c[face] == 4 then
        fourFace = face
      elseif c[face] == 2 then
        pairFace = face
      end
    end
    if fourFace and pairFace then
      use(fourFace, 4)
      use(pairFace, 2)
      points = points + 1500
    end
  end

  for face = 1, 6 do
    local available = c[face] - used[face]
    if available >= 3 then
      local base = (face == 1) and 1000 or face * 100
      local mult = 2 ^ (available - 3)
      points = points + base * mult
      use(face, available)
    end
  end

  for _, single in ipairs({1, 5}) do
    local available = c[single] - used[single]
    if available > 0 then
      local value = single == 1 and 100 or 50
      points = points + value * available
      use(single, available)
    end
  end

  local valid = points > 0
  for face = 1, 6 do
    if c[face] ~= used[face] then
      valid = false
      break
    end
  end

  return {points = points, valid = valid}
end

function S.hasAnyScoring(roll)
  if #roll == 0 then return false end
  local c = S.counts(roll)

  if #roll >= 6 then
    if hasFaces(c, {1,2,3,4,5,6}) then return true end

    local pairTotal = 0
    local tripFaces = 0
    local hasFour = false
    local hasPair = false

    for face = 1, 6 do
      if c[face] >= 2 then
        pairTotal = pairTotal + math.floor(c[face] / 2)
        hasPair = true
      end
      if c[face] >= 3 then
        tripFaces = tripFaces + 1
      end
      if c[face] >= 4 then
        hasFour = true
      end
    end

    if pairTotal >= 3 then return true end
    if tripFaces >= 2 then return true end
    if hasFour and hasPair then return true end
  end

  if c[1] > 0 or c[5] > 0 then return true end
  for f = 1, 6 do if c[f] >= 3 then return true end end
  return false
end

return S
