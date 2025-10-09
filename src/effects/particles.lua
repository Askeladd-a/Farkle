-- Particle utilities estratti da main.lua

local Particles = {}

function Particles.ensure(die, game)
    if not game.selectionImages or #game.selectionImages == 0 then return end
    if die.particles then return end
    local image = game.selectionImages[love.math.random(1, #game.selectionImages)]
    local ps = love.graphics.newParticleSystem(image, 64)
    ps:setEmitterLifetime(-1)
    ps:setParticleLifetime(0.3, 0.6)
    ps:setSpeed(8, 24)
    ps:setSizeVariation(0.45)
    ps:setLinearAcceleration(-12, -12, 12, 12)
    ps:setEmissionRate(18)
    ps:setSpread(math.pi)
    ps:setSizes(0.3, 0.05)
    ps:setColors(0.95, 0.85, 0.35, 0.8, 0.3, 0.5, 1, 0.25)
    ps:stop()
    die.particles = ps
end

function Particles.update(die, dt, game)
    if not die.particles then return end
    if die.locked and not game.rolling then
        if not die.particles:isActive() then
            die.particles:reset(); die.particles:start()
        end
    else
        die.particles:stop()
    end
    die.particles:update(dt)
end

function Particles.draw(die)
    if not die.particles then return end
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1,1,1,0.9)
    love.graphics.draw(die.particles, die.x, die.y)
    love.graphics.setBlendMode("alpha")
end

return Particles
