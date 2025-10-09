-- Assets module: fonts loader and menu background loader

local Assets = {}

local loggedFontFallback = false

local function safeLoadFont(path, size)
  local ok, font = pcall(love.graphics.newFont, path, size)
  if ok and font then return font end
  return nil
end

local function loadChain(paths, size)
  local loaded = {}
  for _, p in ipairs(paths) do
    local f = safeLoadFont(p, size)
    if f then table.insert(loaded, f) end
  end
  local system = love.graphics.newFont(size)
  local chosen = loaded[1] or system
  local fallbacks = {}
  for i = 2, #loaded do table.insert(fallbacks, loaded[i]) end
  table.insert(fallbacks, system)
  if chosen and chosen.setFallbacks and #fallbacks > 0 then
    pcall(function() chosen:setFallbacks(table.unpack(fallbacks)) end)
  end
  if #loaded == 0 and not loggedFontFallback then
    print("[Font] Nessun font custom disponibile, uso system font")
    loggedFontFallback = true
  end
  return chosen
end

function Assets.refreshFonts(width, height)
  local base = math.min(width, height)
  local sizes = {
    title = math.max(48, math.floor(base * 0.07)),
    h2    = math.max(28, math.floor(base * 0.04)),
    body  = math.max(20, math.floor(base * 0.028)),
    small = math.max(16, math.floor(base * 0.022)),
    tiny  = math.max(12, math.floor(base * 0.018)),
  }

  local titlePaths = {
    "fonts/Gregorian.ttf","fonts/Gregorian.otf","fonts/gregorian.ttf","fonts/gregorian.otf",
    "images/Gregorian.ttf","images/Gregorian.otf","images/gregorian.ttf","images/gregorian.otf",
    "fonts/rothenbg.ttf","images/rothenbg.ttf",
    "fonts/Pentiment_Textura.otf","images/Pentiment_Textura.otf",
    "fonts/teutonic1.ttf","images/teutonic1.ttf",
    "fonts/Cinzel-Regular.ttf","images/Cinzel-Regular.ttf",
  }

  local bodyPaths = {
    "fonts/Gregorian.ttf","fonts/Gregorian.otf","fonts/gregorian.ttf","fonts/gregorian.otf",
    "images/Gregorian.ttf","images/Gregorian.otf","images/gregorian.ttf","images/gregorian.otf",
    "fonts/teutonic1.ttf","images/teutonic1.ttf",
    "fonts/Cinzel-Regular.ttf","images/Cinzel-Regular.ttf",
    "fonts/Pentiment_Textura.otf","images/Pentiment_Textura.otf",
  }

  local fonts = {
    title = loadChain(titlePaths, sizes.title),
    h2    = loadChain(titlePaths, sizes.h2),
    body  = loadChain(bodyPaths,  sizes.body),
    small = loadChain(bodyPaths,  sizes.small),
    tiny  = love.graphics.newFont(sizes.tiny),
    menu  = nil,
    help  = love.graphics.newFont(math.max(14, math.floor(base * 0.02))),
  }
  fonts.menu = fonts.h2 or fonts.body
  print(string.format("[Font] Sizes -> title=%d h2=%d body=%d small=%d tiny=%d", sizes.title, sizes.h2, sizes.body, sizes.small, sizes.tiny))
  return fonts
end

function Assets.loadMenuBackground()
  local bases = {
    "images/brown_age_by_darkwood67",
    "images/brown_age",
  }
  local exts = {".png", ".jpg", ".jpeg", ".webp", ".PNG", ".JPG", ".JPEG", ".WEBP"}
  for _, base in ipairs(bases) do
    for _, ext in ipairs(exts) do
      local ok, img = pcall(love.graphics.newImage, base .. ext)
      if ok and img then
        print("[Menu BG] Loaded: " .. base .. ext)
        return img
      end
    end
  end
  print("[Menu BG] background not found; using default background")
  return nil
end

return Assets
