-- conf_headless.lua
-- Configurazione LOVE2D per demo headless

function love.conf(t)
    t.title = "Farkle 3D System Demo"
    t.author = "Farkle 3D Team"
    t.version = "11.5"
    
    -- Configurazione finestra
    t.window.width = 1200
    t.window.height = 800
    t.window.resizable = true
    t.window.vsync = 1
    t.window.fullscreen = false
    
    -- Configurazione grafica
    t.graphics.antialiasing = true
    
    -- Configurazione audio
    t.audio.mixwithsystem = true
    
    -- Configurazione per headless (se necessario)
    t.console = true
end