local anim8 = {}

-- Simple stub implementation to avoid crashes
function anim8.newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)
    local grid = {}
    function grid:getFrames(...)
        return {}
    end
    return setmetatable(grid, {__call = function() return nil end})
end

function anim8.newAnimation(frames, durations, onLoop)
    local animation = {
        frames = frames or {},
        durations = durations or {},
        timer = 0,
        position = 1,
        status = "playing"
    }
    
    function animation:update(dt)
        -- Simple animation update
    end
    
    function animation:draw(image, x, y, r, sx, sy, ox, oy, kx, ky)
        -- Simple draw function
        if image and self.frames[self.position] then
            love.graphics.draw(image, self.frames[self.position], x, y, r, sx, sy, ox, oy, kx, ky)
        end
    end
    
    function animation:clone()
        return anim8.newAnimation(self.frames, self.durations, onLoop)
    end
    
    function animation:flipH()
        return self
    end
    
    function animation:flipV()
        return self
    end
    
    return animation
end

return anim8
