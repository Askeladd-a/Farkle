local Game = require("src.game")

function love.load()
    print("=== LOVE2D GAME STARTING ===")
    local ok, err = pcall(function()
        Game.init()
    end)
    if not ok then
        print("ERRORE in Game.init():", err)
        love.event.quit()
    else
        print("✓ Game.init() completato con successo")
    end
end

function love.update(dt)
    local ok, err = pcall(function()
        Game.update(dt)
    end)
    if not ok then
        print("ERRORE in Game.update():", err)
        love.event.quit()
    end
end

function love.draw()
    local ok, err = pcall(function()
        Game.draw()
    end)
    if not ok then
        print("ERRORE in Game.draw():", err)
        -- Non faccio quit qui, provo a disegnare almeno un messaggio di errore
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("ERRORE: " .. tostring(err), 10, 10)
        love.graphics.setColor(1, 1, 1)
    end
end

function love.mousepressed(x, y, button)
    local ok, err = pcall(function()
        Game.mousepressed(x, y, button)
    end)
    if not ok then
        print("ERRORE in mousepressed:", err)
    end
end

function love.keypressed(key)
    local ok, err = pcall(function()
        Game.keypressed(key)
    end)
    if not ok then
        print("ERRORE in keypressed:", err)
    end
end

function love.mousemoved(x, y)
    local ok, err = pcall(function()
        Game.mousemoved(x, y)
    end)
    if not ok then
        print("ERRORE in mousemoved:", err)
    end
end