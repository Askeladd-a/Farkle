
love = love -- workaround: declare love as global for linter
local M = {}

local GameState = require("src.game.state")
local Audio = require("src.audio")
local Assets = require("src.assets")
local OptionsUI = require("src.ui.options")
local Render = require("src.render")
local Layout = require("src.layout")
local Theme = require("src.theme")
local Dice = require("src.graphics.dice")
local DiceMesh = require("src.graphics.dice_mesh")
local Board3D = require("src.graphics.board3d")
local Particles = require("src.effects.particles")
local CrashReporter = require("src.core.crash_reporter")
local EmbeddedAssets = require("src.core.embedded_assets")
local scoring = require("src.core.scoring")
local AIController = require("src.core.ai")
local constants = require("src.core.constants")

local game = {
    state = "menu",
    players = {
        { id = "player", name = "You", isAI = false, banked = 0 },
        { id = "ai", name = "Baron von Farkle", isAI = true, banked = 0 }
    },
    active = 1,
    roundScore = 0,
    diceLeft = 6,
    rolls = { player = {}, ai = {} },
    kept = { player = {}, ai = {} },
    selection = { points = 0, dice = 0, valid = false },
    winningScore = constants.winningScore or 10000,
    message = "Press Play to start",
    rolling = false,
    rollTimer = 0,
    ai = nil,
    layout = nil,
    fonts = nil,
    boardImage = nil,
    menuBackgroundImage = nil,
    showGuide = false,
    uiOptions = {
        open = false,
        buttonHover = false,
        hoverIndex = nil,
        menuW = 200,
        itemH = 32,
        anchor = nil,
        items = {
            {label = "Game Settings", action = "game"},
            {label = "Video & Graphics", action = "video"},
            {label = "Audio Settings", action = "audio"},
            {label = "Toggle 3D Dice", action = "toggle3d"},
            {label = "Show Dice Stats", action = "stats"},
        }
    },
    -- Nuove opzioni per rendering 3D
    show3DStats = false,
    -- ...altri dati di stato del gioco...
}

local function findButtonByLabel(label)
    if not game.layout or not game.layout.buttons then return nil end
    for _, btn in ipairs(game.layout.buttons) do
        if btn.label == label then
            return btn
        end
    end
    return nil
end

local function refreshButtonStates()
    if not game.layout or not game.layout.buttons then return end
    local activePlayer = game.players and game.players[game.active]
    for _, btn in ipairs(game.layout.buttons) do
        if btn.label == "Roll Dice" then
            btn.enabled = game.state == "playing" and not game.rolling and not (activePlayer and activePlayer.isAI)
        elseif btn.label == "Bank Points" then
            btn.enabled = game.state == "playing" and not game.rolling and (game.roundScore or 0) > 0
        elseif btn.label == "Keep Dice" then
            local selection = game.selection or {}
            btn.enabled = game.state == "playing" and not game.rolling and selection.valid and (selection.points or 0) > 0
        elseif btn.label == "Options" or btn.label == "Main Menu" then
            btn.enabled = true
        else
            btn.enabled = true
        end
    end
end

local function toggleOptionsMenu(anchorButton)
    if not game.uiOptions then return end
    if game.uiOptions.open then
        game.uiOptions.open = false
        game.uiOptions.anchor = nil
        return
    end
    local btn = anchorButton or findButtonByLabel("Options")
    if btn then
        game.uiOptions.anchor = {x = btn.x, y = btn.y, w = btn.w, h = btn.h}
    else
        game.uiOptions.anchor = {x = love.graphics.getWidth() - 200, y = 80, w = 160, h = 40}
    end
    game.uiOptions.open = true
end

function M.init()
    CrashReporter.init()
    print("[Game.init] CrashReporter initialized")
    love.math.setRandomSeed(os.time())
    print("[Game.init] Random seed set")
    
    -- Initialize Settings system first
    local Settings = require("src.core.settings")
    print("[Game.init] Settings module loaded")
    Settings.init()
    print("[Game.init] Settings initialized")

    if DiceMesh and DiceMesh.init then
        DiceMesh.init()
        print("[Game.init] DiceMesh initialized")
    end
    
    local width, height = love.graphics.getDimensions()
    print("[Game.init] Window size", width, height)
    M.refreshFonts(width, height)
    print("[Game.init] Fonts refreshed")
    M.computeLayout()
    print("[Game.init] Layout computed")
    GameState.init(game, Audio)
    print("[Game.init] GameState initialized")
    game.ai = AIController.new()
    print("[Game.init] AI controller created")
    print("[Game.init] Players configured:", game.players[1] and game.players[1].name, game.players[2] and game.players[2].name)
    
    -- Apply saved settings
    Settings.applyVideoSettings()
    print("[Game.init] Video settings applied")
    Settings.applyAudioSettings()
    print("[Game.init] Audio settings applied")
    
    -- Inizializza il menu
    local Menu = require("src.ui.menu")
    print("[Game.init] Menu module loaded")
    Menu.init()
    print("[Game.init] Menu initialized")
    
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
            print("[Game.init] Board image loaded", path)
            break
        end
    end
    M.loadMenuBackground()
    print("[Game.init] Menu background loaded")
    
    -- Initialize 3D Board
    local CX, CY = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    game.board3D = Board3D.new{
        x = CX, y = CY, 
        w = 720, h = 440, 
        t = 28, inset = 18,
        tex = "assets/UI/wooden_board.png",
        scallop = true,          -- Abilita bordi scalloped
        scallop_r = 14,          -- Raggio dei denti
        scallop_segments = 8,    -- Smoothness
        frameW = 12              -- Larghezza cornice
    }
    print("[Game.init] Board3D created")
    game.board3D:setOpen(0)   -- Chiusa, pronta per animazione
    print("[Game.init] Board3D closed")
    
    -- Carica atlas XML e texture PNG per dado 3D
    local USE_BORDER_ATLAS = true
    local xmlPath = USE_BORDER_ATLAS and "assets/dice/dice_border.xml" or "assets/dice/dice_spritesheet.xml"
    local imgPath = USE_BORDER_ATLAS and "assets/dice/border_dice_spritesheet.png" or "assets/dice/dice_spritesheet.png"
    -- ...caricamento mesh e layout...
    game.message = "Welcome back!"
    Audio.init()
    print("[Game.init] Audio initialized")
    game.buttonsNeedRefresh = true
end

function M.load()
    M.init()
end

function M.update(dt)
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.update(dt)
        Audio.update()
        return
    end

    if game.buttonsNeedRefresh then
        refreshButtonStates()
        game.buttonsNeedRefresh = false
    end
    
    -- Update 3D Board
    if game.board3D then
        game.board3D:update(dt)
    end
    
    if game.rolls then
        local layout = game.layout
        if layout and layout.trays then
            if game.rolls.ai and layout.trays.ai then
                Dice.updateRoll(game.rolls.ai, layout.trays.ai, dt)
            end
            if game.rolls.player and layout.trays.player then
                Dice.updateRoll(game.rolls.player, layout.trays.player, dt)
            end
        end
    end
    if game.demoDie then game.demoDie:update(dt) end
    local Cursor = require("src.cursor")
    Cursor.update(dt, function()
        if Audio and Audio.playStamp then Audio.playStamp() end
    end)
    if GameState.update then
        GameState.update(dt, game)
    end
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
    
    -- Draw 3D Board (before dice so dice appear on top)
    if game.board3D then
        game.board3D:draw()
    end
    
    Render.drawScoreboard(layout, game.fonts, game)
    Render.drawLog(layout, game.fonts, game)
    Render.drawActionButtons(layout, game.fonts, game)
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
    
    -- Statistiche 3D (se abilitate)
    if game.show3DStats then
        Render.drawDiceTypeStats(game, game.fonts, 10, 60, true)
    end
    
    -- Info modalità rendering
    if game.fonts and game.fonts.tiny then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        local modeText = "Dice Mode: " .. (Dice.RENDER_MODE == "3d" and "3D Mesh" or "2D Sprite")
        love.graphics.print(modeText, game.fonts.tiny, 10, 10)
    end
    
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
            if btn.enabled ~= false and x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                if btn.label == "Roll Dice" then
                    GameState.attemptRoll(game.layout)
                    game.buttonsNeedRefresh = true
                elseif btn.label == "Bank Points" then
                    GameState.attemptBank(game.winningScore)
                    game.buttonsNeedRefresh = true
                elseif btn.label == "Keep Dice" then
                    if GameState.keepSelection then
                        GameState.keepSelection()
                    end
                    game.buttonsNeedRefresh = true
                elseif btn.label == "Options" then
                    toggleOptionsMenu(btn)
                elseif btn.label == "Main Menu" then
                    Audio.playBookPage()
                    game.state = "menu"
                    game.uiOptions.open = false
                    game.uiOptions.anchor = nil
                end
                return
            end
        end
    end
    -- Selezione dadi
    local activePlayer = (GameState.getActivePlayer and GameState.getActivePlayer()) or (game.players and game.players[game.active])
    if not activePlayer then return end
    if game.rolling or activePlayer.isAI or not game.rolls or not game.rolls[activePlayer.id] or #game.rolls[activePlayer.id] == 0 then return end
    for _, die in ipairs(game.rolls[activePlayer.id]) do
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
        -- Return to menu from game
        game.state = "menu"
        print("[Game] Returning to main menu")
        game.uiOptions.open = false
        game.uiOptions.anchor = nil
        return
    elseif key == "m" then
        game.state = "menu"
        print("[Game] Quick return to menu")
        game.uiOptions.open = false
        game.uiOptions.anchor = nil
        return
    elseif key == "space" or key == "return" or key == "kpenter" or key == "r" then
        if game.state == "playing" then
            local active = GameState.getActivePlayer and GameState.getActivePlayer()
            if not (active and active.isAI) then
                GameState.attemptRoll(game.layout)
                game.buttonsNeedRefresh = true
            end
        end
        return
    elseif key == "b" then
        if game.state == "playing" then
            local active = GameState.getActivePlayer and GameState.getActivePlayer()
            if not (active and active.isAI) then
                GameState.attemptBank(game.winningScore)
                game.buttonsNeedRefresh = true
            end
        end
        return
    elseif key == "k" then
        if game.state == "playing" and GameState.keepSelection then
            local active = GameState.getActivePlayer and GameState.getActivePlayer()
            if not (active and active.isAI) then
                GameState.keepSelection()
                game.buttonsNeedRefresh = true
            end
        end
        return
    elseif key == "o" then
        toggleOptionsMenu()
        return
    elseif key == "f1" then
        CrashReporter.testCrash()
    elseif key == "f2" then
        CrashReporter.cleanupLogs()
    elseif key == "f3" then
        -- Test risoluzione 800x600 (minima)
        love.window.setMode(800, 600)
        print("[Game] Resolution set to 800x600")
    elseif key == "f4" then
        -- Test risoluzione 1920x1080 (Full HD)
        love.window.setMode(1920, 1080)
        print("[Game] Resolution set to 1920x1080")
    elseif key == "f5" then
        -- Test risoluzione 1280x720 (HD)
        love.window.setMode(1280, 720)
        print("[Game] Resolution set to 1280x720")
    elseif key == "f6" then
        -- Torna alla risoluzione di default
        love.window.setMode(960, 640)
        print("[Game] Resolution set to 960x640 (default)")
    elseif key == "f8" then
        -- Toggle Board3D apertura/chiusura
        if game.board3D then
            local currentOpen = math.abs(game.board3D.top.ang) > 0.1
            if currentOpen then
                game.board3D:animateTo(0, 0.8)  -- Chiudi
                print("[Game] Closing 3D Board")
            else
                game.board3D:animateTo(1, 0.8)  -- Apri
                print("[Game] Opening 3D Board")
            end
        end
    elseif key == "f9" then
        -- Board3D aperta parzialmente (50%)
        if game.board3D then
            game.board3D:animateTo(0.5, 0.6)
            print("[Game] Board3D set to 50% open")
        end
    end
end

function M.refreshFonts(width, height)
    game.fonts = Assets.refreshFonts(width, height)
end

function M.computeLayout()
    game.layout = Layout.setupLayout(love.graphics.getWidth(), love.graphics.getHeight(), game.fonts, constants.BUTTON_LABELS, game.boardImage)
    game.buttonsNeedRefresh = true
    refreshButtonStates()
    game.buttonsNeedRefresh = false
end

function M.loadMenuBackground()
    game.menuBackgroundImage = Assets.loadMenuBackground()
end

function M.mousemoved(x, y)
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.mousemoved(x, y)
    else
        OptionsUI.updateHover(game)
    end
end

function M.mousereleased(x, y, button)
    if game.state == "menu" then
        local Menu = require("src.ui.menu")
        Menu.mousereleased(x, y, button)
    end
end

function M.resize(w, h)
    print("[Game] Window resized to:", w, "x", h)
    M.refreshFonts(w, h)
    M.computeLayout()
    
    -- Update Board3D position
    if game.board3D then
        local CX, CY = w/2, h/2
        game.board3D.x = CX
        game.board3D.y = CY
        print("[Game] Board3D recentered to:", CX, CY)
    end
    
    -- Aggiorna il rendering per la nuova risoluzione
    love.graphics.setDefaultFilter("linear", "linear")
    
    -- Notifica altri sistemi del cambio di risoluzione
    if Dice and Dice.setRenderMode then
        -- Ricalcola le dimensioni dei dadi in base alla nuova risoluzione
        local scale = math.min(w / 960, h / 640) -- Scala basata sulla risoluzione base
        Dice.SIZE = math.floor(48 * scale)
        Dice.RADIUS = Dice.SIZE * 0.5
        print("[Game] Dice size scaled to:", Dice.SIZE)
    end
    
    print("[Game] Layout recalculated for new resolution")
end

return M
