local S = {}

function S.counts(arr)
  local c={0,0,0,0,0,0,0}
  for _,v in ipairs(arr) do c[v]=c[v]+1 end
  return c
end

local function deepcopy(t) local r={}; for k,v in pairs(t) do r[k]=type(v)=='table' and deepcopy(v) or v end; return r end

local function basePoints(c)
  c = deepcopy(c)
  local pts = 0

  for face = 1, 6 do
    local count = c[face]
    if count >= 3 then
      local base = (face == 1) and 1000 or face * 100
      pts = pts + base * (count - 2)
      c[face] = 0
    end
  end

  if c[1] > 0 then
    pts = pts + c[1] * 100
    c[1] = 0
  end

  if c[5] > 0 then
    pts = pts + c[5] * 50
    c[5] = 0
  end

  local leftovers = c[2] + c[3] + c[4] + c[6]
  return {points = pts, valid = leftovers == 0}
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

  for face = 1, 6 do
    local available = c[face] - used[face]
    if available >= 3 then
      local base = (face == 1) and 1000 or face * 100
      points = points + base * (available - 2)
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

  if c[1] > 0 or c[5] > 0 then
    return true
  end

  for face = 1, 6 do
    if c[face] >= 3 then
      return true
    end
  end

  return false
end

return S
