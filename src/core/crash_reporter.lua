-- Crash Reporter Module
-- Cattura e salva i crash del gioco in un file di log

local CrashReporter = {}

-- Configurazione
local LOG_FILE = "crash_report.txt"
local MAX_LOG_SIZE = 1024 * 1024  -- 1MB massimo
local MAX_LOGS = 5  -- Massimo 5 file di log

-- Informazioni del sistema
local function getSystemInfo()
    local info = {}
    
    -- Informazioni Love2D
    info.love_version = love.getVersion()
    info.love_version_string = string.format("%d.%d.%d", info.love_version[1], info.love_version[2], info.love_version[3])
    
    -- Informazioni sistema
    info.os = love.system.getOS()
    info.processor_count = love.system.getProcessorCount()
    
    -- Informazioni finestra
    local width, height = love.graphics.getDimensions()
    info.window_width = width
    info.window_height = height
    
    -- Informazioni memoria (se disponibile)
    if love.system.getMemoryUsage then
        info.memory_usage = love.system.getMemoryUsage()
    end
    
    return info
end

-- Formatta le informazioni del sistema
local function formatSystemInfo()
    local info = getSystemInfo()
    local lines = {}
    
    table.insert(lines, "=== INFORMAZIONI SISTEMA ===")
    table.insert(lines, "Love2D Version: " .. info.love_version_string)
    table.insert(lines, "OS: " .. info.os)
    table.insert(lines, "Processori: " .. info.processor_count)
    table.insert(lines, "Risoluzione: " .. info.window_width .. "x" .. info.window_height)
    
    if info.memory_usage then
        table.insert(lines, "Memoria: " .. info.memory_usage .. " MB")
    end
    
    table.insert(lines, "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "")
    
    return table.concat(lines, "\n")
end

-- Formatta lo stack trace
local function formatStackTrace(err)
    local lines = {}
    
    table.insert(lines, "=== STACK TRACE ===")
    table.insert(lines, "Errore: " .. tostring(err))
    table.insert(lines, "")
    
    -- Aggiungi lo stack trace se disponibile
    local stack = debug.traceback()
    if stack then
        table.insert(lines, "Stack Trace:")
        table.insert(lines, stack)
    end
    
    table.insert(lines, "")
    
    return table.concat(lines, "\n")
end

-- Formatta le informazioni del gioco
function CrashReporter.dumpGameState(gameData)
    local lines = {"--- Game State ---"}
    if gameData then
        table.insert(lines, "Stato gioco: " .. (gameData.state or "sconosciuto"))
        table.insert(lines, "Giocatore attivo: " .. (gameData.active or "sconosciuto"))
        table.insert(lines, "Dadi rimanenti: " .. (gameData.diceLeft or "sconosciuto"))
        table.insert(lines, "Punteggio round: " .. (gameData.roundScore or "sconosciuto"))
        table.insert(lines, "")
        if gameData.players then
            for i, player in ipairs(gameData.players) do
                table.insert(lines, string.format("Player %d: %s (banked: %d)", i, player.name or "Unnamed", player.banked or 0))
            end
        end
    else
        table.insert(lines, "Nessun dato di gioco disponibile")
    end
    return table.concat(lines, "\n")
end

-- Ruota i file di log per evitare che diventino troppo grandi
local function rotateLogFiles()
    -- Controlla se il file principale esiste e se è troppo grande
    local file = io.open(LOG_FILE, "r")
    if file then
        local size = file:seek("end")
        file:close()
        
        if size > MAX_LOG_SIZE then
            -- Sposta i file esistenti
            for i = MAX_LOGS - 1, 1, -1 do
                local old_name = LOG_FILE .. "." .. i
                local new_name = LOG_FILE .. "." .. (i + 1)
                
                local old_file = io.open(old_name, "r")
                if old_file then
                    old_file:close()
                    os.rename(old_name, new_name)
                end
            end
            
            -- Sposta il file principale
            os.rename(LOG_FILE, LOG_FILE .. ".1")
        end
    end
end

-- Salva il crash report
local function saveCrashReport(err)
    rotateLogFiles()
    
    local file = io.open(LOG_FILE, "w")
    if not file then
        return false
    end
    
    -- Scrivi il report
    file:write("=== CRASH REPORT FARKLE ===\n")
    file:write("Data: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    file:write("\n")
    
    local ok_sys, sysInfo = pcall(formatSystemInfo)
    if ok_sys then
        file:write(sysInfo)
    else
        file:write("[CrashReporter] Impossibile ottenere informazioni di sistema: " .. tostring(sysInfo) .. "\n\n")
    end

    local ok_game, gameInfo = pcall(CrashReporter.dumpGameState)
    if ok_game then
        file:write(gameInfo)
        file:write("\n")
    else
        file:write("[CrashReporter] Impossibile ottenere stato del gioco: " .. tostring(gameInfo) .. "\n\n")
    end

    local ok_stack, stackInfo = pcall(formatStackTrace, err)
    if ok_stack then
        file:write(stackInfo)
    else
        file:write("[CrashReporter] Impossibile ottenere stack trace: " .. tostring(stackInfo) .. "\n\n")
    end
    
    file:write("=== FINE REPORT ===\n")
    
    file:close()
    return true
end

-- Handler principale per i crash
function CrashReporter.handleCrash(err)
    print("=== CRASH RILEVATO ===")
    print("Errore: " .. tostring(err))
    print("Salvataggio crash report...")
    
    local success = saveCrashReport(err)
    if success then
        print("Crash report salvato in: " .. LOG_FILE)
    else
        print("Errore nel salvataggio del crash report!")
    end
    
    -- Mostra un messaggio all'utente
    local message = "Il gioco ha riscontrato un errore.\n"
    message = message .. "Un crash report è stato salvato in:\n"
    message = message .. LOG_FILE .. "\n\n"
    message = message .. "Errore: " .. tostring(err)
    
    -- Crea una finestra di errore semplice
    love.graphics.clear(0.1, 0.1, 0.1)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.printf("CRASH REPORT", 0, 50, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(message, 50, 100, love.graphics.getWidth() - 100, "left")
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Premi ESC per uscire", 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), "center")
    
    love.graphics.present()
    
    -- Aspetta che l'utente prema ESC
    while true do
        love.event.pump()
        for e, a, b, c, d in love.event.poll() do
            if e == "keypressed" and a == "escape" then
                love.event.quit()
            elseif e == "quit" then
                love.event.quit()
            end
        end
        love.timer.sleep(0.1)
    end
end

function CrashReporter.handleCrashScreen()
    -- Nota: rimosso override di love.keypressed per evitare conflitto col main.
    -- Se necessario possiamo intercettare ESC direttamente nel loop di polling.
end

-- Inizializza il crash reporter
function CrashReporter.init()
    -- Imposta l'handler di errore personalizzato
    local originalErrorHandler = love.errhand
    
    love.errhand = function(err)
        -- Chiama il nostro handler
        CrashReporter.handleCrash(err)
        
        -- Se il nostro handler non gestisce l'uscita, usa quello originale
        if originalErrorHandler then
            return originalErrorHandler(err)
        else
            return err
        end
    end
    
    print("Crash Reporter inizializzato")
end

-- Funzione di utilità per testare il crash reporter
function CrashReporter.testCrash()
    error("Test crash - questo è intenzionale per testare il crash reporter")
end

-- Funzione per pulire i log vecchi
function CrashReporter.cleanupLogs()
    for i = 1, MAX_LOGS do
        local filename = LOG_FILE .. "." .. i
        local file = io.open(filename, "r")
        if file then
            file:close()
            os.remove(filename)
        end
    end
    
    -- Rimuovi anche il file principale se esiste
    local file = io.open(LOG_FILE, "r")
    if file then
        file:close()
        os.remove(LOG_FILE)
    end
    
    print("Log files puliti")
end

return CrashReporter
