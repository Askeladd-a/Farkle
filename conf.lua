-- conf.lua
-- Configurazione LOVE2D per Farkle 3D

function love.conf(t)
    t.title = "Farkle 3D - Sistema di Proiezione Matematica"
    t.author = "Farkle 3D Team"
    t.version = "11.5"
    
    -- Configurazione finestra
    t.window.width = 1200
    t.window.height = 800
    t.window.resizable = true
    t.window.vsync = 1
    t.window.fullscreen = false
    t.window.minwidth = 800
    t.window.minheight = 600
    
    -- Configurazione grafica
    t.graphics.antialiasing = true
    t.graphics.linear = true
    
    -- Configurazione audio
    t.audio.mixwithsystem = true
    
    -- Configurazione console (per debug)
    t.console = true
    
    -- Configurazione moduli
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.thread = false
    t.modules.touch = false
    t.modules.video = false
end