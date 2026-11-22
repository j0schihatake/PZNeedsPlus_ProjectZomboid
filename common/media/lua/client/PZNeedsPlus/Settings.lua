local Settings = {}
local page

local ok = pcall(require, "PZAPI/ModOptions")
if ok and PZAPI and PZAPI.ModOptions then
    page = PZAPI.ModOptions:getOptions("PZNeedsPlus")
        or PZAPI.ModOptions:create("PZNeedsPlus", "PZ Needs Plus")
    local function tick(key, label, default)
        if not page:getOption(key) then page:addTickBox(key, label, default, "") end
    end
    tick("autoEat", "Auto eat outside combat", true)
    tick("autoDrink", "Auto drink outside combat", true)
    tick("autoHeal", "Auto bandage / pain relief", true)
    tick("infiniteDurability", "Infinite weapon condition", true)
    tick("infiniteAmmo", "Infinite ammo reserve", true)
    tick("infiniteMagazine", "Refill magazine instantly (no reload needed)", false)
    tick("autoReload", "Auto reload empty / partial magazine", true)
end

local DEFAULTS = {
    autoEat = true, autoDrink = true, autoHeal = true,
    infiniteDurability = true, infiniteAmmo = true,
    infiniteMagazine = false, autoReload = true,
}

local function value(key)
    local option = page and page:getOption(key)
    if option then
        local okv, v = pcall(function() return option:getValue() end)
        if okv and v ~= nil then return v end
    end
    return DEFAULTS[key]
end

function Settings.autoEat() return value("autoEat") == true end
function Settings.autoDrink() return value("autoDrink") == true end
function Settings.autoHeal() return value("autoHeal") == true end
function Settings.infiniteDurability() return value("infiniteDurability") == true end
function Settings.infiniteAmmo() return value("infiniteAmmo") == true end
function Settings.infiniteMagazine() return value("infiniteMagazine") == true end
function Settings.autoReload() return value("autoReload") == true end

return Settings
