-- anim8 (minimal embed) - based on anim8 v2.3.1 by Enrique García Cota
-- MIT License
-- https://github.com/kikito/anim8

local anim8 = {
  _VERSION = 'anim8 v2.3.1',
  _DESCRIPTION = 'An animation library for LÖVE',
  _URL = 'https://github.com/kikito/anim8',
  _LICENSE = [[
    MIT License

    Copyright (c) 2011-2020 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]]
}

local Grid = {}
Grid.__index = Grid
anim8.Grid = Grid

local Animation = {}
Animation.__index = Animation
anim8.Animation = Animation

local function assertPositiveInteger(value, name)
  if type(value) ~= 'number' or value <= 0 or value % 1 ~= 0 then
    error(string.format('anim8: %s should be a positive integer, got %s', name, tostring(value)))
  end
end

local function parseInterval(str)
  local startStr, finishStr = str:match('^(%d+)%s*-%s*(%d+)$')
  if not startStr then return tonumber(str) end
  return tonumber(startStr), tonumber(finishStr)
end

local function framesToNumbers(self, frames)
  local numbers = {}
  for _, value in ipairs(frames) do
    local t = type(value)
    if t == 'number' then
      numbers[#numbers + 1] = value
    elseif t == 'string' then
      local startFrame, finishFrame = parseInterval(value)
      if finishFrame then
        local step = startFrame <= finishFrame and 1 or -1
        for frame = startFrame, finishFrame, step do
          numbers[#numbers + 1] = frame
        end
      else
        error('anim8: invalid interval string "' .. value .. '"')
      end
    elseif t == 'table' then
      local inner = framesToNumbers(self, value)
      for i = 1, #inner do
        numbers[#numbers + 1] = inner[i]
      end
    else
      error('anim8: invalid frame type ' .. t)
    end
  end
  return numbers
end

local function sliceGrid(grid, x, y)
  local frames = {}
  local columns = type(x) == 'table' and x or { x }
  local rows = type(y) == 'table' and y or { y }

  for _, row in ipairs(rows) do
    local startRow, finishRow
    if type(row) == 'number' then
      startRow, finishRow = row, row
    else
      startRow, finishRow = parseInterval(row)
      startRow, finishRow = startRow or row, finishRow or row
    end
    for rowIndex = startRow, finishRow do
      for _, column in ipairs(framesToNumbers(grid, columns)) do
        frames[#frames + 1] = grid[rowIndex][column]
      end
    end
  end

  return frames
end

local function newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)
  left = left or 0
  top = top or 0
  border = border or 0

  assertPositiveInteger(frameWidth, 'frameWidth')
  assertPositiveInteger(frameHeight, 'frameHeight')
  assertPositiveInteger(imageWidth, 'imageWidth')
  assertPositiveInteger(imageHeight, 'imageHeight')

  local cols = math.floor((imageWidth - left + border) / (frameWidth + border))
  local rows = math.floor((imageHeight - top + border) / (frameHeight + border))

  local grid = {
    frameWidth = frameWidth,
    frameHeight = frameHeight,
    width = cols,
    height = rows,
    imageWidth = imageWidth,
    imageHeight = imageHeight,
    left = left,
    top = top,
    border = border,
    quads = {}
  }

  for y = 1, rows do
    grid[y] = {}
    for x = 1, cols do
      local quadX = left + (x - 1) * (frameWidth + border)
      local quadY = top + (y - 1) * (frameHeight + border)
      grid[y][x] = love.graphics.newQuad(quadX, quadY, frameWidth, frameHeight, imageWidth, imageHeight)
    end
  end

  return setmetatable(grid, Grid)
end

function Grid:getFrames(x, y)
  if type(x) == 'number' and type(y) == 'number' then
    return { self[y][x] }
  end
  return sliceGrid(self, x, y)
end

function Grid:__call(...)
  return self:getFrames(...)
end

local function cloneArray(array)
  local newArray = {}
  for i = 1, #array do newArray[i] = array[i] end
  return newArray
end

local function newAnimation(frames, durations, onLoop)
  if #frames == 0 then error('anim8: no frames supplied to newAnimation') end

  local animation = {
    frames = cloneArray(frames),
    durations = {},
    timer = 0,
    position = 1,
    status = 'playing',
    onLoop = onLoop
  }

  if type(durations) == 'number' then
    for i = 1, #frames do animation.durations[i] = durations end
  else
    for i = 1, #frames do
      local duration = durations[i]
      if not duration then
        error('anim8: missing duration for frame ' .. i)
      end
      animation.durations[i] = duration
    end
  end

  return setmetatable(animation, Animation)
end

function Animation:update(dt)
  if self.status ~= 'playing' then return end
  self.timer = self.timer + dt
  while self.timer >= self.durations[self.position] do
    self.timer = self.timer - self.durations[self.position]
    self.position = self.position + 1
    if self.position > #self.frames then
      if self.onLoop then self.onLoop(self) end
      self.position = 1
    end
  end
end

function Animation:draw(image, x, y, r, sx, sy, ox, oy, kx, ky)
  love.graphics.draw(image, self.frames[self.position], x, y, r, sx, sy, ox, oy, kx, ky)
end

function Animation:clone()
  local animation = newAnimation(self.frames, self.durations, self.onLoop)
  animation.status = self.status
  animation.timer = self.timer
  animation.position = self.position
  return animation
end

function Animation:gotoFrame(position)
  position = math.max(1, math.min(#self.frames, position))
  self.position = position
  self.timer = 0
  return self
end

function Animation:pause()
  self.status = 'paused'
  return self
end

function Animation:resume()
  self.status = 'playing'
  return self
end

function Animation:pauseAtEnd()
  self.position = #self.frames
  self.timer = 0
  return self:pause()
end

function Animation:pauseAtStart()
  self.position = 1
  self.timer = 0
  return self:pause()
end

function Animation:setDurations(durations)
  if type(durations) == 'number' then
    for i = 1, #self.frames do self.durations[i] = durations end
  else
    for i = 1, #self.frames do
      local duration = durations[i]
      if not duration then
        error('anim8: missing duration for frame ' .. i)
      end
      self.durations[i] = duration
    end
  end
  return self
end

function Animation:onLoop(callback)
  self.onLoop = callback
  return self
end

anim8.newGrid = newGrid
anim8.newAnimation = newAnimation

return anim8