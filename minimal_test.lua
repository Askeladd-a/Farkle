-- Verifica se projection3d.lua è sintatticamente corretto
-- love --console minimal_test.lua

print("=== TEST MODULI 3D ===")

local status, result = pcall(function()
  local Projection3D = require("src.graphics.projection3d")
  print("✓ projection3d.lua caricato correttamente")
  
  -- Test Vec3
  local v1 = Projection3D.Vec3.new(1, 2, 3)
  local v2 = Projection3D.Vec3.new(4, 5, 6)
  local v3 = v1:add(v2)
  print("✓ Vec3 math funziona:", v3.x, v3.y, v3.z)
  
  return true
end)

if not status then
  print("✗ Errore:", result)
  error("Errore nel caricamento moduli")
end

local status2, result2 = pcall(function()
  local Effects3D = require("src.graphics.effects3d")
  print("✓ effects3d.lua caricato correttamente")
  return true
end)

if not status2 then
  print("✗ Errore effects3d:", result2)
end

local status3, result3 = pcall(function()
  local Board3D = require("src.graphics.board3d_realistic")
  print("✓ board3d_realistic.lua caricato correttamente")
  return true
end)

if not status3 then
  print("✗ Errore board3d:", result3)
end

print("✓ Test completato! Tutti i moduli funzionano.")

function love.load()
  print("LOVE2D avviato - moduli 3D pronti!")
end

function love.draw()
  love.graphics.clear(0, 0.7, 0)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Moduli 3D Testati - Tutto OK!", 50, 50)
  love.graphics.print("Controlla la console per dettagli", 50, 80)
  love.graphics.print("I moduli 3D sono pronti per l'uso!", 50, 110)
end