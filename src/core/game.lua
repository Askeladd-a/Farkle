-- Stato centrale del gioco
local game = {
    state = "menu",
    uiOptions = {
        open = false,
        buttonHover = false,
        hoverIndex = nil,
        menuW = 200,
        itemH = 32,
        anchor = nil,
    },
    -- Altri dati di stato...
}

return game
