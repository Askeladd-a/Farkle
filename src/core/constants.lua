-- Costanti globali per Farkle
local M = {}

M.winningScore = 10000
M.BUTTON_LABELS = {"Roll Dice", "Bank Points", "Keep Dice", "Options", "Main Menu"}

-- === TIPI DI DADO CON PESI ===
M.DICE_TYPES = {
    fair = {
        name = "Fair",
        color = {0.96, 0.93, 0.82}, -- Bianco avorio
        weights = {1, 1, 1, 1, 1, 1}, -- Pesi uguali (dado normale)
        description = "Dado equilibrato"
    },
    loaded = {
        name = "Loaded", 
        color = {0.8, 0.7, 0.3}, -- Dorato
        weights = {0.5, 0.5, 0.5, 0.5, 2, 3}, -- Favorisce 5 e 6
        description = "Favorisce valori alti"
    },
    cursed = {
        name = "Cursed",
        color = {0.6, 0.3, 0.3}, -- Rosso scuro
        weights = {3, 2, 0.5, 0.5, 0.5, 0.5}, -- Favorisce 1 e 2
        description = "Favorisce valori bassi"
    }
}

M.DEFAULT_DICE_TYPE = "fair"

return M
