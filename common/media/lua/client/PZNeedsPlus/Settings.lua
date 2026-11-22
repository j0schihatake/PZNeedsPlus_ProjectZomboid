local Settings = {}
local page
local function tr(key, fallback)
    local ok, value = pcall(getText, key)
    if ok and value and value ~= key then return value end
    return fallback
end

local ok = pcall(require, "PZAPI/ModOptions")
if ok and PZAPI and PZAPI.ModOptions then
    page = PZAPI.ModOptions:getOptions("PZNeedsPlus")
        or PZAPI.ModOptions:create("PZNeedsPlus", tr("UI_PZNeedsPlus_Title", "PZ Needs Plus"))
    local function tick(key, label, default)
        if not page:getOption(key) then page:addTickBox(key, label, default, "") end
    end
    tick("autoEat", tr("UI_PZNeedsPlus_AutoEat", "Auto eat outside combat"), true)
    tick("autoDrink", tr("UI_PZNeedsPlus_AutoDrink", "Auto drink outside combat"), true)
    tick("autoHeal", tr("UI_PZNeedsPlus_AutoHeal", "Auto bandage / pain relief"), true)
    tick("infiniteDurability", tr("UI_PZNeedsPlus_InfiniteDurability", "Infinite weapon condition"), true)
    tick("infiniteAmmo", tr("UI_PZNeedsPlus_InfiniteAmmo", "Infinite ammo reserve"), true)
    tick("infiniteMagazine", tr("UI_PZNeedsPlus_InfiniteMagazine", "Refill magazine instantly (no reload needed)"), false)
    tick("autoReload", tr("UI_PZNeedsPlus_AutoReload", "Auto reload empty / partial magazine"), true)
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
