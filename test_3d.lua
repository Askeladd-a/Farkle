-- test_3d.lua  
-- Test semplice per verificare i moduli 3D

function love.load()
  -- Test caricamento moduli
  print("=== TEST MODULI 3D ===")
  
  local success, Projection3D = pcall(require, "src.graphics.projection3d")
  if success then
    print("✓ projection3d.lua caricato")
  else
    print("✗ Errore projection3d:", Projection3D)
    return
  end
  
  local success2, Effects3D = pcall(require, "src.graphics.effects3d")
  if success2 then
    print("✓ effects3d.lua caricato")
  else
    print("✗ Errore effects3d:", Effects3D)
    return
  end
  
  local success3, Board3D = pcall(require, "src.graphics.board3d_realistic")
  if success3 then
    print("✓ board3d_realistic.lua caricato")
  else
    print("✗ Errore board3d:", Board3D)
    return
  end
  
  local success4, Dice = pcall(require, "src.graphics.dice_mesh")
  if success4 then
    print("✓ dice_mesh.lua caricato")
  else
    print("✗ Errore dice_mesh:", Dice)
    return
  end
  
  print("✓ Tutti i moduli 3D caricati con successo!")
  print("✓ Sistema 3D pronto per il test completo")
  
  love.window.setTitle("Test Moduli 3D - Successo!")
end

function love.draw()
  love.graphics.clear(0.1, 0.5, 0.1)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Test Moduli 3D Completato!", 50, 50)
  love.graphics.print("Controlla la console per i risultati", 50, 80)
  love.graphics.print("Premi ESC per uscire", 50, 110)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end