-- Embedded Assets Module
-- Provides embedded image data for cursor and particle effects

local EmbeddedAssets = {}

-- Build cursor image data
function EmbeddedAssets.buildCursorImageData()
    -- Create a simple 16x16 cursor image
    local imageData = love.image.newImageData(16, 16)
    
    -- Fill with transparent pixels first
    for y = 0, 15 do
        for x = 0, 15 do
            imageData:setPixel(x, y, 0, 0, 0, 0) -- transparent
        end
    end
    
    -- Draw a simple arrow cursor
    -- Arrow shaft
    for y = 2, 12 do
        imageData:setPixel(7, y, 1, 1, 1, 1) -- white
        imageData:setPixel(8, y, 1, 1, 1, 1) -- white
    end
    
    -- Arrow head
    for i = 0, 3 do
        for j = 0, i do
            imageData:setPixel(7 + j, 1 + i, 1, 1, 1, 1) -- white
            imageData:setPixel(8 - j, 1 + i, 1, 1, 1, 1) -- white
        end
    end
    
    -- Add a black outline
    for y = 0, 15 do
        for x = 0, 15 do
            if imageData:getPixel(x, y) == {1, 1, 1, 1} then
                -- Check surrounding pixels for outline
                for dy = -1, 1 do
                    for dx = -1, 1 do
                        local nx, ny = x + dx, y + dy
                        if nx >= 0 and nx < 16 and ny >= 0 and ny < 16 then
                            local pixel = {imageData:getPixel(nx, ny)}
                            if pixel[4] == 0 then -- transparent
                                imageData:setPixel(nx, ny, 0, 0, 0, 1) -- black outline
                            end
                        end
                    end
                end
            end
        end
    end
    
    return imageData
end

-- Build light images for particle effects
function EmbeddedAssets.buildLightImages()
    local images = {}
    
    -- Create different sized light particles
    local sizes = {8, 12, 16, 20}
    
    for _, size in ipairs(sizes) do
        local imageData = love.image.newImageData(size, size)
        local center = size / 2
        
        -- Create a radial gradient light effect
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local dx = x - center
                local dy = y - center
                local distance = math.sqrt(dx * dx + dy * dy)
                local maxDistance = center
                
                if distance <= maxDistance then
                    local intensity = 1 - (distance / maxDistance)
                    intensity = intensity * intensity -- square for smoother falloff
                    
                    -- Golden light color
                    local r = 0.95 + intensity * 0.05
                    local g = 0.85 + intensity * 0.15
                    local b = 0.35 + intensity * 0.65
                    local a = intensity
                    
                    imageData:setPixel(x, y, r, g, b, a)
                else
                    imageData:setPixel(x, y, 0, 0, 0, 0) -- transparent
                end
            end
        end
        
        local image = love.graphics.newImage(imageData)
        table.insert(images, image)
    end
    
    return images
end

return EmbeddedAssets
