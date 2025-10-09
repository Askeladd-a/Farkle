
love = love -- workaround: declare love as global for linter
local M = {}

local GameState = require("src.game.state")
local Audio = require("src.audio.audio")
local Assets = require("src.assets")
local OptionsUI = require("src.ui.options")
local Render = require("src.render")
local Layout = require("src.layout")
local Theme = require("src.theme")
local Dice = require("src.graphics.dice")
local DiceMesh = require("src.graphics.dice_mesh")
local Particles = require("src.effects.particles")
local CrashReporter = require("src.core.crash_reporter")
local EmbeddedAssets = require("src.core.embedded_assets")
local scoring = require("src.core.scoring")
local AIController = require("src.core.ai")
local constants = require("src.core.constants")

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
    -- ...altri dati di stato del gioco...
}

function M.init()
    CrashReporter.init()
    love.math.setRandomSeed(os.time())
    local width, height = love.graphics.getDimensions()
    M.refreshFonts(width, height)
    M.computeLayout()
    GameState.init(game, Audio)
    
    -- Inizializza il menu
    local Menu = require("src.ui.menu")
    Menu.init()
    
    -- Caricamento board
    local boardCandidates = {
        "assets/UI/board.png",
        "assets/UI/wooden_board.png",
        "assets/wooden_board.png",
    }
    for _, path in ipairs(boardCandidates) do
        local ok_img, img = pcall(love.graphics.newImage, path)
        if ok_img and img then
            game.boardImage = img
            break
        end
    end
    M.loadMenuBackground()
    -- Carica atlas XML e texture PNG per dado 3D
    local USE_BORDER_ATLAS = true
    local xmlPath = USE_BORDER_ATLAS and "assets/dice/dice_border.xml" or "assets/dice/dice_spritesheet.xml"
    local imgPath = USE_BORDER_ATLAS and "assets/dice/border_dice_spritesheet.png" or "assets/dice/dice_spritesheet.png"
    -- ...caricamento mesh e layout...
    game.message = "Welcome back!"
    Audio.init()
end

function M.update(dt)
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.update(dt)
        Audio.update()
        return
    end
    Dice.updateAnimations(dt)
    if game.demoDie then game.demoDie:update(dt) end
    local Cursor = require("src.cursor")
    Cursor.update(dt, function()
        if Audio and Audio.playStamp then Audio.playStamp() end
    end)
    GameState.update(dt, game)
    Audio.update()
end

function M.draw()
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.draw(game.fonts)
        return
    end
    local layout = game.layout
    if not layout or not layout.board or layout.board.w < 50 or layout.board.h < 50 or layout.board.x < 0 or layout.board.y < 0 then
        love.graphics.setColor(0.2,0.2,0.2,1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("Finestra troppo piccola!", 10, 10)
        return
    end
    Render.safeDrawBoard(game.boardImage, layout)
    Render.drawScoreboard(layout, game.fonts, game)
    Render.drawLog(layout, game.fonts, game)
    if layout.trays and layout.trays.ai and layout.trays.player then
        Render.drawIsometricTray(layout.trays.ai)
        Render.drawIsometricTray(layout.trays.player)
    end
    if layout.kept and layout.kept.ai and layout.kept.player then
        Render.drawIsometricKeptColumn(game.kept.ai, layout.kept.ai)
        Render.drawIsometricKeptColumn(game.kept.player, layout.kept.player)
    end
    -- Dadi
    local drawList = {}
    if game.rolls and game.rolls.ai then
        for _, die in ipairs(game.rolls.ai) do table.insert(drawList, die) end
    end
    if game.rolls and game.rolls.player then
        for _, die in ipairs(game.rolls.player) do table.insert(drawList, die) end
    end
    table.sort(drawList, function(a, b) return (a.y + (a.z or 0)) < (b.y + (b.z or 0)) end)
    Render.drawIsometricDice(drawList)
    -- Guide e opzioni
    if game.showGuide then
        local Guide = require("src.ui.guide")
        Guide.draw(game.fonts)
    end
    OptionsUI.draw(game, game.fonts)
end

function M.mousepressed(x, y, button)
    if button ~= 1 then return end
    local Cursor = require("src.cursor")
    Cursor.startClick()
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.mousepressed(x, y, button, game)
        return
    end
    if game.showGuide then
        game.showGuide = false
        return
    end
    if game.state == "playing" and game.layout and game.uiOptions.anchor then
        if OptionsUI.handleMousePressed(game, x, y, function() Audio.requestQuit() end) then return end
    end
    if game.layout and game.layout.buttons then
        for _, btn in ipairs(game.layout.buttons) do
            btn.enabled = true -- delega a buttonEnabled se serve
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                if btn.label == "Roll Dice" then
                    GameState.attemptRoll(game.layout)
                elseif btn.label == "Bank Points" then
                    GameState.attemptBank()
                elseif btn.label == "Guide" then
                    game.showGuide = not game.showGuide
                elseif btn.label == "Options" then
                    game.uiOptions.anchor = {x = btn.x, y = btn.y, w = btn.w, h = btn.h}
                    game.uiOptions.open = true
                elseif btn.label == "Main Menu" then
                    Audio.playBookPage()
                    game.state = "menu"
                end
                return
            end
        end
    end
    -- Selezione dadi
    if game.rolling or GameState.getActivePlayer().isAI or not game.rolls or #game.rolls[GameState.getActivePlayer().id] == 0 then return end
    for _, die in ipairs(game.rolls[GameState.getActivePlayer().id]) do
        local dx = x - die.x
        local dy = y - die.y
        if dx * dx + dy * dy <= Dice.RADIUS * Dice.RADIUS then
            die.locked = not die.locked
            if die.locked then Audio.playSelect() end
            Particles.ensure(die, game)
            GameState.refreshSelection()
            return
        end
    end
end

function M.keypressed(key)
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.keypressed(key, game)
        return
    end
    if key == "escape" then
        if game.uiOptions and game.uiOptions.open then
            game.uiOptions.open = false
            game.uiOptions.anchor = nil
            return
        end
        Audio.requestQuit()
    elseif key == "f1" then
        CrashReporter.testCrash()
    elseif key == "f2" then
        CrashReporter.cleanupLogs()
    end
end

function M.refreshFonts(width, height)
    game.fonts = Assets.refreshFonts(width, height)
end

function M.computeLayout()
    game.layout = Layout.setupLayout(love.graphics.getWidth(), love.graphics.getHeight(), game.fonts, constants.BUTTON_LABELS, game.boardImage)
end

function M.loadMenuBackground()
    game.menuBackgroundImage = Assets.loadMenuBackground()
end

function M.mousemoved(x, y)
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.mousemoved(x, y)
    end
end

return M
