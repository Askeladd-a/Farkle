-- Game state module: encapsula logica di turno, roll, banca e selezione
-- Estrae dal main.lua per ridurre complessità

local Dice = require("src.graphics.dice")
local scoring = require("src.core.scoring")

local State = {}

function State.init(game, audio)
    -- mantiene riferimento a game table esistente
    State.game = game
    State.Audio = audio
end

local function getActivePlayer()
    return State.game.players[State.game.active]
end

function State.getActivePlayer()
    return getActivePlayer()
end

local function currentRoll()
    return State.game.rolls[getActivePlayer().id]
end

local function currentKept()
    return State.game.kept[getActivePlayer().id]
end

function State.resetSelection()
    State.game.selection = {points = 0, dice = 0, valid = false}
end

function State.resetTurn(newMessage)
    State.resetSelection()
    State.game.roundScore = 0
    State.game.diceLeft = 6
    State.game.rolls.player = {}
    State.game.rolls.ai = {}
    State.game.kept.player = {}
    State.game.kept.ai = {}
    State.game.rolling = false
    State.game.rollTimer = 0
    State.game.winner = nil
    State.game.message = newMessage or "Press Roll Dice to begin."
    if State.game.ai and State.game.ai.reset then State.game.ai:reset() end
    State.game.buttonsNeedRefresh = true
end

function State.startNewGame()
    for _, player in ipairs(State.game.players) do
        player.banked = 0
    end
    State.game.active = 1
    State.resetTurn("Your turn. Press Roll Dice to begin.")
    State.game.state = "playing"
    State.game.winner = nil
    State.game.buttonsNeedRefresh = true
end

function State.refreshSelection()
    local roll = currentRoll()
    if not roll then return end
    local values = {}
    for _, die in ipairs(roll) do
        if die.locked and not die.isRolling then
            table.insert(values, die.value)
        end
    end
    local result = scoring.scoreSelection(values)
    State.game.selection.points = result.points or 0
    State.game.selection.valid = result.valid or false
    State.game.selection.dice = #values
    State.game.buttonsNeedRefresh = true
end

local function consumeSelection()
    State.refreshSelection()
    if not (State.game.selection.valid and State.game.selection.points > 0) then
        return false, 0
    end
    local roll = currentRoll()
    local keptList = currentKept()
    local removed = {}
    for index = #roll, 1, -1 do
        local die = roll[index]
        if die.locked and not die.isRolling then
            table.insert(removed, die.value)
            table.insert(keptList, die.value)
            table.remove(roll, index)
        end
    end
    State.game.roundScore = State.game.roundScore + State.game.selection.points
    State.game.diceLeft = State.game.diceLeft - #removed
    if State.game.diceLeft <= 0 then
        State.game.diceLeft = 6
        State.game.rolls[getActivePlayer().id] = {}
        State.game.kept[getActivePlayer().id] = {}
        State.game.message = "Hot dice! Roll all six again."
    else
        if getActivePlayer().isAI then
            State.game.message = string.format("Baron von Farkle keeps %d points.", State.game.selection.points)
        else
            State.game.message = string.format("Saved %d points. %d dice remain.", State.game.selection.points, State.game.diceLeft)
        end
    end
    State.resetSelection()
    State.game.buttonsNeedRefresh = true
    return true, #removed
end

function State.startRoll(layout)
    if State.game.rolling or State.game.diceLeft <= 0 or State.game.winner then
        return false
    end
    local tray = layout.trays[getActivePlayer().id]
    local roll = currentRoll()
    if #roll == 0 then
        -- Definisci distribuzione di tipi di dado per il gioco
        -- Per ora: 60% fair, 30% loaded, 10% cursed
        local typeDistribution = {
            fair = 0.6,
            loaded = 0.3,
            cursed = 0.1
        }
        
        -- Crea roll con tipi misti usando la nuova funzione
        local newRoll = Dice.createMixedRoll(tray, State.game.diceLeft, typeDistribution)
        
        -- Aggiungi i dadi al roll corrente
        for _, die in ipairs(newRoll) do
            die.locked = false
            die.isRolling = true
            die.particles = nil
            table.insert(roll, die)
        end
        
        -- Applica scatter iniziale se la funzione esiste
        if Dice.initialScatter then
            Dice.initialScatter(tray, roll)
        end
    else
        for _, die in ipairs(roll) do
            if not die.locked then
                die.isRolling = true
                die.particles = nil
                -- Applica impulso se la funzione esiste
                if Dice.applyThrowImpulse then
                    Dice.applyThrowImpulse(die, tray)
                end
            end
        end
    end
    State.game.rolling = true
    State.game.rollTimer = 0
    State.resetSelection()
    State.game.buttonsNeedRefresh = true
    return true
end

function State.attemptRoll(layout)
    if State.game.rolling then return false end
    if #currentRoll() == 0 then return State.startRoll(layout) end
    local ok = select(1, consumeSelection())
    if not ok then
        if not getActivePlayer().isAI then
            State.game.message = "Only scoring dice can be kept."
        end
        return false
    end
    return State.startRoll(layout)
end

local function endTurn(msg)
    State.resetSelection()
    local currentPlayer = getActivePlayer()
    State.game.rolls[currentPlayer.id] = {}
    State.game.kept[currentPlayer.id] = {}
    State.game.roundScore = 0
    State.game.diceLeft = 6
    State.game.rolling = false
    State.game.rollTimer = 0
    if State.game.ai and State.game.ai.reset then State.game.ai:reset() end
    local nextPrompt, aiTurn
    if not State.game.winner then
        State.game.active = (State.game.active % #State.game.players) + 1
        local nextPlayer = getActivePlayer()
        if nextPlayer.isAI then
            nextPrompt, aiTurn = "Baron von Farkle is thinking...", true
        else
            nextPrompt = "Click Roll Dice to start your turn."
        end
    end
    if msg and msg ~= "" then
        State.game.message = nextPrompt and (msg .. "\n" .. nextPrompt) or msg
    else
        State.game.message = nextPrompt or ""
    end
    State.game.buttonsNeedRefresh = true
    return aiTurn
end

function State.handleBust()
    local current = getActivePlayer()
    if State.Audio and State.Audio.playBust then State.Audio.playBust() end
    if current.isAI then
        endTurn("Bust! Baron von Farkle loses the round.")
    else
        endTurn("Bust! You lose the round points.")
    end
end

local function bankRound(winningScore)
    local player = getActivePlayer()
    if State.game.roundScore <= 0 then return false end
    if State.Audio and State.Audio.playCoins then State.Audio.playCoins() end
    player.banked = player.banked + State.game.roundScore
    if player.banked >= winningScore then
        State.game.winner = player
        State.game.message = string.format("%s wins with %d points!", player.name, player.banked)
    else
        if player.isAI then
            State.game.message = string.format("Baron von Farkle banks %d points.", State.game.roundScore)
        else
            State.game.message = string.format("You banked %d points.", State.game.roundScore)
        end
    end
    endTurn(State.game.message)
    return true
end

function State.attemptBank(winningScore)
    if State.game.rolling then return false end
    if State.game.selection.valid and State.game.selection.points > 0 then
        consumeSelection()
    end
    if State.game.roundScore > 0 then
        return bankRound(winningScore)
    end
    return false
end

function State.keepSelection()
    if State.game.rolling then return false end
    local active = getActivePlayer()
    if not active or active.isAI then return false end
    local roll = currentRoll()
    if not roll or #roll == 0 then
        State.game.message = "Roll before keeping dice."
        return false
    end
    local ok, removed = consumeSelection()
    if not ok or (removed or 0) == 0 then
        State.game.message = "Select scoring dice to keep."
        return false
    end
    State.game.buttonsNeedRefresh = true
    return true
end

function State.toggleLockAt(x, y)
    if State.game.rolling or getActivePlayer().isAI or #currentRoll() == 0 then return false end
    for _, die in ipairs(currentRoll()) do
        local dx = x - die.x
        local dy = y - die.y
        if dx * dx + dy * dy <= Dice.RADIUS * Dice.RADIUS then
            die.locked = not die.locked
            return true
        end
    end
    return false
end

return State
