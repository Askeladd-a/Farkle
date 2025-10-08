local scoring = require("lib.scoring")
local table_unpack = table.unpack or unpack

local AIController = {}
AIController.__index = AIController

local function findBestSubset(dice)
    local available = {}
    for index, die in ipairs(dice) do
        if not die.spent and not die.locked and not die.isRolling then
            table.insert(available, {index = index, value = die.value})
        end
    end

    if #available == 0 then
        return nil
    end

    local best
    local subset = {}

    local function evaluate()
        if #subset == 0 then
            return
        end
        local values = {}
        local indices = {}
        for _, entry in ipairs(subset) do
            table.insert(values, entry.value)
            table.insert(indices, entry.index)
        end
        local result = scoring.scoreSelection(values)
        if result.valid then
            if not best or result.points > best.points or (result.points == best.points and #indices > #best.indices) then
                best = {
                    indices = {table_unpack(indices)},
                    points = result.points,
                }
            end
        end
    end

    local function search(start)
        if start > #available then
            evaluate()
            return
        end

        search(start + 1)

        table.insert(subset, available[start])
        search(start + 1)
        table.remove(subset)
    end

    search(1)
    return best
end

local function shouldBank(potential, remainingDice, currentTemp, playerBanked, winningScore)
    if playerBanked + potential >= winningScore then
        return true
    end

    -- Soglie più aggressive per Baron von Farkle
    local thresholds = {
        [0] = 2000,  -- Ridotto da 2600
        [1] = 400,   -- Ridotto da 650
        [2] = 500,   -- Ridotto da 900
        [3] = 600,   -- Ridotto da 1150
        [4] = 700,   -- Ridotto da 1400
        [5] = 800,   -- Ridotto da 1700
        [6] = 900,   -- Ridotto da 1900
    }
    local threshold = thresholds[remainingDice] or 1000  -- Ridotto da 1500

    if potential >= threshold then
        return true
    end

    -- Banking più aggressivo con meno punti
    if potential >= 600 and currentTemp >= 400 then  -- Ridotto da 1200/900
        return true
    end
    
    -- Banking molto aggressivo se siamo vicini alla vittoria
    if playerBanked >= winningScore * 0.8 and potential >= 300 then
        return true
    end
    
    -- Banking se l'avversario è molto avanti
    if currentTemp >= 500 and potential >= 400 then
        return true
    end

    return false
end

function AIController.new()
    return setmetatable({
        delay = 0,
        pending = nil,
    }, AIController)
end

function AIController:reset()
    self.delay = 0
    self.pending = nil
end

function AIController:clearPending()
    self.pending = nil
end

function AIController:delayFor(time)
    if time and time > self.delay then
        self.delay = time
    end
end

function AIController:update(dt, ctx)
    if not ctx or not ctx.isActive() then
        self:reset()
        return
    end

    if ctx.hasWinner() then
        self:clearPending()
        return
    end

    if ctx.isRollPending() then
        self:clearPending()
        return
    end

    self.delay = math.max(0, self.delay - dt)
    if self.delay > 0 then
        return
    end

    if not ctx.diceAreIdle() then
        return
    end

    local selection = ctx.getSelection()
    if self.pending == "evaluate" and selection.dice > 0 then
        local turnTemp = ctx.turnTemp()
        local potential = turnTemp + selection.points
        local remaining = ctx.countRemainingDice()
        if shouldBank(potential, remaining, turnTemp, ctx.playerBanked(), ctx.winningScore()) then
            ctx.attemptBank()
        else
            ctx.attemptRoll()
        end
        self.delay = 0.9
        self:clearPending()
        return
    end

    if selection.dice > 0 then
        self.pending = "evaluate"
        return
    end

    local best = findBestSubset(ctx.getDice())
    if not best then
        if ctx.turnTemp() > 0 then
            ctx.attemptBank()
            self.delay = 1.0
        end
        return
    end

    ctx.lockDice(best.indices)
    ctx.refreshScores()
    self.pending = "evaluate"
    self.delay = 0.45
end

return AIController
