-- Test minimale per identificare il crash
print("=== STARTING TEST ===")

function love.load()
    print("love.load() called")
    
    -- Test 1: verifica che i moduli base esistano
    print("Testing basic requires...")
    
    local ok, err = pcall(function()
        local GameState = require("src.game.state")
        print("✓ GameState loaded")
    end)
    if not ok then
        print("✗ GameState failed:", err)
        return
    end
    
    local ok, err = pcall(function()
        local Audio = require("src.audio.audio")
        print("✓ Audio loaded")
    end)
    if not ok then
        print("✗ Audio failed:", err)
        return
    end
    
    local ok, err = pcall(function()
        local Assets = require("src.assets")
        print("✓ Assets loaded")
    end)
    if not ok then
        print("✗ Assets failed:", err)
        return
    end
    
    print("All basic modules loaded successfully!")
    print("Testing game module...")
    
    local ok, err = pcall(function()
        local Game = require("src.game")
        print("✓ Game module loaded")
        
        Game.init()
        print("✓ Game.init() completed")
    end)
    if not ok then
        print("✗ Game module failed:", err)
        return
    end
    
    print("=== ALL TESTS PASSED ===")
end

function love.update(dt)
    -- Vuoto per ora
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Test running... check console for details", 10, 10)
end