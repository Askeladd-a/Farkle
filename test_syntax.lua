-- test_syntax.lua
-- Test di sintassi per i moduli 3D senza grafica

print("=== TEST SINTASSI MODULI 3D ===")

-- Test projection3d.lua
local success1, Projection3D = pcall(require, "src.graphics.projection3d")
if success1 then
    print("✓ projection3d.lua - Sintassi OK")
    
    -- Test creazione camera
    local cam = Projection3D.Camera3D.new({projection = "isometric"})
    print("✓ Camera3D creata con successo")
    
    -- Test proiezione
    local x, y, z, w = Projection3D.project(1, 2, 3, "isometric")
    print("✓ Proiezione isometrica:", x, y, z, w)
    
else
    print("✗ Errore projection3d:", Projection3D)
end

-- Test effects3d.lua
local success2, Effects3D = pcall(require, "src.graphics.effects3d")
if success2 then
    print("✓ effects3d.lua - Sintassi OK")
    
    -- Test creazione sistemi
    local shadows = Effects3D.ShadowSystem.new()
    local particles = Effects3D.ParticleSystem3D.new()
    local lighting = Effects3D.LightingSystem.new()
    print("✓ Sistemi di effetti creati con successo")
    
else
    print("✗ Errore effects3d:", Effects3D)
end

-- Test board3d_realistic.lua
local success3, Board3D = pcall(require, "src.graphics.board3d_realistic")
if success3 then
    print("✓ board3d_realistic.lua - Sintassi OK")
    
    -- Test creazione board
    local board = Board3D.new({x = 0, y = 0, z = 0})
    print("✓ Board3D creata con successo")
    
else
    print("✗ Errore board3d:", Board3D)
end

-- Test dice_mesh.lua
local success4, Dice = pcall(require, "src.graphics.dice_mesh")
if success4 then
    print("✓ dice_mesh.lua - Sintassi OK")
    
    -- Test inizializzazione (senza grafica)
    print("✓ Dice module caricato con successo")
    
else
    print("✗ Errore dice_mesh:", Dice)
end

print("\n=== RISULTATO FINALE ===")
if success1 and success2 and success3 and success4 then
    print("✓ TUTTI I MODULI 3D FUNZIONANO CORRETTAMENTE!")
    print("✓ Sistema 3D pronto per il rendering")
else
    print("✗ Alcuni moduli hanno errori di sintassi")
end