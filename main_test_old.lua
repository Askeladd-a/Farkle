-- Test file per identificare il problema
local Game = require("src.game")

function love.load()
    print("Love2D started successfully!")
    local ok, err = pcall(function()
        Game.init()
        print("Game.init() completed successfully!")
    end)
    if not ok then
        print("ERROR in Game.init():", err)
        love.event.quit()
    end
end

function love.update(dt)
    local ok, err = pcall(function()
        Game.update(dt)
    end)
    if not ok then
        print("ERROR in Game.update():", err)
        love.event.quit()
    end
end

function love.draw()
    local ok, err = pcall(function()
        Game.draw()
    end)
    if not ok then
        print("ERROR in Game.draw():", err)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("ERROR: " .. tostring(err), 10, 10)
    end
end

function love.mousepressed(x, y, button)
    local ok, err = pcall(function()
        Game.mousepressed(x, y, button)
    end)
    if not ok then
        print("ERROR in mousepressed:", err)
    end
end

function love.keypressed(key)
    local ok, err = pcall(function()
        Game.keypressed(key)
    end)
    if not ok then
        print("ERROR in keypressed:", err)
    end
end

function love.mousemoved(x, y)
    local ok, err = pcall(function()
        Game.mousemoved(x, y)
    end)
    if not ok then
        print("ERROR in mousemoved:", err)
    end
end