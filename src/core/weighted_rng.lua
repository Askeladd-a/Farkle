-- Modulo per gestire roll pesati e tipi di dado
local WeightedRNG = {}

local constants = require("src.core.constants")
local random = love.math.random

-- Funzione per fare un roll pesato basato sui pesi
local function weightedRoll(weights)
    local totalWeight = 0
    for _, weight in ipairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local roll = random() * totalWeight
    local cumulative = 0
    
    for i, weight in ipairs(weights) do
        cumulative = cumulative + weight
        if roll <= cumulative then
            return i
        end
    end
    
    -- Fallback (non dovrebbe mai succedere)
    return 1
end

-- Crea un valore di dado basato sul tipo
function WeightedRNG.rollDiceValue(diceType)
    diceType = diceType or constants.DEFAULT_DICE_TYPE
    local diceConfig = constants.DICE_TYPES[diceType]
    
    if not diceConfig then
        error("Tipo di dado sconosciuto: " .. tostring(diceType))
    end
    
    return weightedRoll(diceConfig.weights)
end

-- Ottieni le informazioni su un tipo di dado
function WeightedRNG.getDiceTypeInfo(diceType)
    return constants.DICE_TYPES[diceType]
end

-- Ottieni tutti i tipi di dado disponibili
function WeightedRNG.getAvailableDiceTypes()
    local types = {}
    for typeName, _ in pairs(constants.DICE_TYPES) do
        table.insert(types, typeName)
    end
    table.sort(types)
    return types
end

-- Calcola la probabilità di ogni faccia per un tipo di dado
function WeightedRNG.getProbabilities(diceType)
    local diceConfig = constants.DICE_TYPES[diceType]
    if not diceConfig then
        return nil
    end
    
    local totalWeight = 0
    for _, weight in ipairs(diceConfig.weights) do
        totalWeight = totalWeight + weight
    end
    
    local probabilities = {}
    for i, weight in ipairs(diceConfig.weights) do
        probabilities[i] = weight / totalWeight
    end
    
    return probabilities
end

return WeightedRNG