-- Test super base per Love2D
print("Starting Love2D test...")

function love.load()
    print("love.load() eseguito")
    love.window.setTitle("Farkle Test")
end

function love.update(dt)
    -- Vuoto per ora
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Test funzionante! Premi ESC per uscire.", 10, 10)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end