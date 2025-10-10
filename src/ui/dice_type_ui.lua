-- UI per mostrare informazioni sui tipi di dado
local DiceTypeUI = {}

local WeightedRNG = require("src.core.weighted_rng")
local constants = require("src.core.constants")

function DiceTypeUI.drawDiceTypeInfo(x, y, font)
    if not font then return end
    
    local startY = y
    local lineHeight = 25
    
    -- Titolo
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Dice Types:", font, x, startY)
    startY = startY + lineHeight + 5
    
    -- Mostra ogni tipo di dado
    for typeName, typeInfo in pairs(constants.DICE_TYPES) do
        -- Nome e colore
        love.graphics.setColor(typeInfo.color)
        love.graphics.rectangle("fill", x, startY, 20, 20, 3)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(typeInfo.name .. ": " .. typeInfo.description, font, x + 25, startY + 2)
        
        -- Probabilità
        local probabilities = WeightedRNG.getProbabilities(typeName)
        if probabilities then
            local probText = "Prob: "
            for i = 1, 6 do
                probText = probText .. string.format("%.0f%%", probabilities[i] * 100)
                if i < 6 then probText = probText .. " " end
            end
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(probText, font, x + 25, startY + 15)
        end
        
        startY = startY + 35
    end
end

function DiceTypeUI.drawRollStats(roll, x, y, font)
    if not roll or #roll == 0 or not font then return end
    
    local stats = require("src.graphics.dice").getRollStats(roll)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Current Roll:", font, x, y)
    y = y + 25
    
    -- Statistiche per tipo
    for typeName, count in pairs(stats.byType) do
        local typeInfo = constants.DICE_TYPES[typeName]
        if typeInfo then
            love.graphics.setColor(typeInfo.color)
            love.graphics.rectangle("fill", x, y, 15, 15, 2)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(string.format("%s: %d", typeInfo.name, count), font, x + 20, y)
            y = y + 20
        end
    end
    
    -- Valori ottenuti
    if next(stats.values) then
        y = y + 10
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Values:", font, x, y)
        y = y + 20
        
        for value = 1, 6 do
            local count = stats.values[value] or 0
            if count > 0 then
                love.graphics.print(string.format("%d: %dx", value, count), font, x, y)
                y = y + 18
            end
        end
    end
end

-- Disegna tooltip per un dado specifico
function DiceTypeUI.drawDiceTooltip(die, x, y, font)
    if not die or not font then return end
    
    local typeInfo = WeightedRNG.getDiceTypeInfo(die.diceType)
    if not typeInfo then return end
    
    -- Background del tooltip
    local text = typeInfo.name .. " Die"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x - 5, y - 5, textWidth + 10, textHeight + 10, 3)
    
    -- Testo
    love.graphics.setColor(typeInfo.color)
    love.graphics.print(text, font, x, y)
    
    -- Descrizione
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.print(typeInfo.description, font, x, y + textHeight + 2)
    
    -- Stato
    local statusText = ""
    if die.isRolling then
        statusText = "Rolling..."
    elseif die.isSnapping then
        statusText = "Snapping to " .. die.value
    else
        statusText = "Value: " .. die.value
    end
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(statusText, font, x, y + textHeight * 2 + 4)
end

return DiceTypeUI