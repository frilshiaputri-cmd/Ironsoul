--========================================================--
-- K5-HUB | IronSoul Kaitun + WindUI
-- Single UI entry for the IronSoul engine.
-- WindUI 1.6.66 is pinned for stability.
--========================================================--

local WINDUI_VERSION = "1.6.66"
local BASE = "https://raw.githubusercontent.com/frilshiaputri-cmd/K5_Premium/main/"
local ENGINE_URL = BASE .. "bootstrap_v61_11.lua"
local LOGO = "rbxassetid://115820469332666"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local function notify(title, content)
    if WindUI and WindUI.Notify then
        pcall(function()
            WindUI:Notify({Title = title, Content = content})
        end)
    end
end

local defaults = {
    FPS_CAP = 8,
    FARM = "NEWBIE", -- retained by engine for compatibility; currently informational.
    TICKETS = "SMART",
    HEADLESS = true,
    CAVE_AUTO = true,
    HELL_AUTO = true,
    SHOP_AUTO = true,
    MOBILE_STATUS = false,
    DEBUG_LOGS = false,
}

local Config = getgenv().IronSoulConfig or {}
for k, v in pairs(defaults) do
    if Config[k] == nil then Config[k] = v end
end
getgenv().IronSoulConfig = Config

local CONFIG_FILE = "K5_HUB_IronSoul_WindUI.json"

local function saveConfig()
    if type(writefile) ~= "function" then
        return false, "writefile unavailable"
    end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, Config)
    if not ok then return false, encoded end
    local wok, err = pcall(writefile, CONFIG_FILE, encoded)
    return wok, err
end

local function loadConfig()
    if type(isfile) ~= "function" or not isfile(CONFIG_FILE) then
        return false
    end
    if type(readfile) ~= "function" then return false end
    local ok, data = pcall(readfile, CONFIG_FILE)
    if not ok then return false end
    local jok, decoded = pcall(HttpService.JSONDecode, HttpService, data)
    if not jok or type(decoded) ~= "table" then return false end
    for k, v in pairs(decoded) do Config[k] = v end
    getgenv().IronSoulConfig = Config
    return true
end

loadConfig()

local function startEngine()
    if getgenv().K5IronSoulEngineStarted then
        notify("K5-HUB", "IronSoul engine is already running.")
        return
    end
    getgenv().K5IronSoulEngineStarted = true
    local ok, source = pcall(function()
        return game:HttpGet(ENGINE_URL .. "?t=" .. tostring(os.time()))
    end)
    if not ok then
        getgenv().K5IronSoulEngineStarted = nil
        notify("Engine Error", tostring(source))
        return
    end
    local fn, err = loadstring(source)
    if not fn then
        getgenv().K5IronSoulEngineStarted = nil
        notify("Compile Error", tostring(err))
        return
    end
    local runOk, runErr = pcall(fn)
    if not runOk then
        getgenv().K5IronSoulEngineStarted = nil
        notify("Runtime Error", tostring(runErr))
        return
    end
    notify("K5-HUB", "IronSoul V61.11 started.")
end

local function setConfig(key, value)
    Config[key] = value
    getgenv().IronSoulConfig = Config
    saveConfig()
end

-- WindUI stable release, pinned instead of the moving latest endpoint.
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/download/" .. WINDUI_VERSION .. "/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "K5-HUB",
    Author = "IronSoul Premium",
    Folder = "K5-HUB",
    Icon = LOGO,
    Size = UDim2.fromOffset(480, 340),
    MinSize = Vector2.new(430, 300),
    MaxSize = Vector2.new(620, 460),
    NewElements = true,
    Topbar = true,
    OpenButton = {
        Title = "K5-HUB",
        Icon = LOGO,
        Draggable = true,
        IconShape = "Circle",
        Border = true,
    },
})

local Main = Window:Tab({Title = "Main", Icon = "swords"})
local Farm = Window:Tab({Title = "Farm", Icon = "route"})
local Misc = Window:Tab({Title = "Misc", Icon = "settings-2"})
local ConfigTab = Window:Tab({Title = "Config", Icon = "folder-cog"})

local CombatSection = Main:Section({Title = "Combat Engine"})
CombatSection:Paragraph({
    Title = "Automatic Combat",
    Content = "IronSoul's V61.11 combat controller automatically uses the verified Skill1, Skill2 and Ultimate (SkillU) loadout."
})
CombatSection:Toggle({
    Title = "Headless Combat",
    Value = Config.HEADLESS == true,
    Callback = function(v)
        -- The current validated combat stack is headless-first. This toggle is
        -- intentionally informational rather than pretending to disable the controller.
        setConfig("HEADLESS", v == true)
        notify("Combat", v and "Headless mode selected." or "Headless mode remains engine-controlled.")
    end,
})
CombatSection:Paragraph({
    Title = "Skill status",
    Content = "Supported by this engine: Auto Skill 1, Auto Skill 2 and Auto Ultimate. Separate Skill 3–5 controls are not exposed because this engine does not have verified Skill3/4/5 remotes."
})
CombatSection:Button({
    Title = "Start / Restart Engine",
    Icon = "play",
    Callback = function()
        getgenv().K5IronSoulEngineStarted = nil
        startEngine()
    end,
})

local FarmSection = Farm:Section({Title = "Automatic Farming"})
FarmSection:Toggle({
    Title = "Auto Hell",
    Value = Config.HELL_AUTO ~= false,
    Callback = function(v) setConfig("HELL_AUTO", v == true) end,
})
FarmSection:Toggle({
    Title = "Auto Cave / SMART Tickets",
    Value = Config.CAVE_AUTO ~= false,
    Callback = function(v) setConfig("CAVE_AUTO", v == true) end,
})
FarmSection:Toggle({
    Title = "Auto Shop Blocker",
    Value = Config.SHOP_AUTO ~= false,
    Callback = function(v) setConfig("SHOP_AUTO", v == true) end,
})
FarmSection:Dropdown({
    Title = "Ticket Mode",
    Values = {"SMART", "OFF"},
    Value = Config.TICKETS,
    Callback = function(v)
        setConfig("TICKETS", tostring(v))
    end,
})
FarmSection:Paragraph({
    Title = "Engine policy",
    Content = "Hell uses the validated Hell-first planner. Cave uses the SMART highest-unlocked tier policy. Shop only buys verified exact blockers."
})

local MiscSection = Misc:Section({Title = "Performance / Status"})
MiscSection:Slider({
    Title = "FPS Cap",
    Value = {Min = 3, Max = 60, Default = tonumber(Config.FPS_CAP) or 8},
    Step = 1,
    Callback = function(v)
        local n = tonumber(v) or 8
        setConfig("FPS_CAP", n)
        if type(setfpscap) == "function" then pcall(setfpscap, n) end
    end,
})
MiscSection:Toggle({
    Title = "Mobile Status",
    Value = Config.MOBILE_STATUS == true,
    Callback = function(v) setConfig("MOBILE_STATUS", v == true) end,
})
MiscSection:Toggle({
    Title = "Debug Logs",
    Value = Config.DEBUG_LOGS == true,
    Callback = function(v) setConfig("DEBUG_LOGS", v == true) end,
})
MiscSection:Button({
    Title = "Rejoin Server",
    Icon = "refresh-cw",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

local ConfigSection = ConfigTab:Section({Title = "Configuration"})
ConfigSection:Button({
    Title = "Save Config",
    Icon = "save",
    Callback = function()
        local ok, err = saveConfig()
        notify(ok and "Config" or "Config Error", ok and "Saved." or tostring(err))
    end,
})
ConfigSection:Button({
    Title = "Reset Config",
    Icon = "rotate-ccw",
    Callback = function()
        for k, v in pairs(defaults) do Config[k] = v end
        getgenv().IronSoulConfig = Config
        saveConfig()
        notify("Config", "Reset. Restart the engine to apply all settings.")
    end,
})
ConfigSection:Paragraph({
    Title = "Real vs informational controls",
    Content = "K5-HUB only exposes settings verified by the IronSoul engine. Features without a verified runtime switch are shown as engine-managed instead of fake ON/OFF controls."
})

Window:SelectTab(1)
notify("K5-HUB", "WindUI " .. WINDUI_VERSION .. " loaded.")

task.defer(function()
    task.wait(0.8)
    startEngine()
end)
