local Game = require("src.game")

function love.load()
    Game.load()
end

function love.update(dt)
    Game.update(dt)
end

function love.draw()
    Game.draw()
end

function love.mousepressed(x, y, button)
    Game.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    Game.mousereleased(x, y, button)
end

function love.keypressed(key)
    Game.keypressed(key)
end

function love.mousemoved(x, y)
    Game.mousemoved(x, y)
end

function love.resize(w, h)
    Game.resize(w, h)
end
