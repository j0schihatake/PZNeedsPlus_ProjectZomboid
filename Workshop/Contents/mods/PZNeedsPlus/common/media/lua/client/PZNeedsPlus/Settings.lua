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
    if page and not page:getOption("materialWeightReduction") then
        local combo = page:addComboBox("materialWeightReduction", tr("UI_PZNeedsPlus_MaterialWeight", "Material weight reduction"), "")
        combo:addItem("UI_PZNeedsPlus_Weight0")
        combo:addItem("UI_PZNeedsPlus_Weight20", true)
        combo:addItem("UI_PZNeedsPlus_Weight50")
        combo:addItem("UI_PZNeedsPlus_Weight100")
    end
    if page and not page:getOption("animationSpeed") then
        local combo = page:addComboBox("animationSpeed", tr("UI_PZNeedsPlus_AnimationSpeed", "Eat/drink animation speed"), "")
        combo:addItem("UI_PZNeedsPlus_AnimationFast")
        combo:addItem("UI_PZNeedsPlus_AnimationMedium", true)
        combo:addItem("UI_PZNeedsPlus_AnimationLong")
    end
end

local DEFAULTS = {
    autoEat = true, autoDrink = true, autoHeal = true,
    infiniteDurability = true, infiniteAmmo = true,
    infiniteMagazine = false, autoReload = true, animationSpeed = 1, materialWeightReduction = 20,
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
function Settings.materialWeightReduction()
    local option = page and page:getOption("materialWeightReduction")
    if not option then return 20 end
    local v = tonumber(option:getValue()) or 1
    return v == 0 and 0 or (v == 1 and 20 or (v == 2 and 50 or 100))
end
function Settings.materialWeightFactor() return (100 - Settings.materialWeightReduction()) / 100 end
function Settings.animationSpeed()
    local option = page and page:getOption("animationSpeed")
    local v = option and option:getValue() or 1
    return tonumber(v) or 1
end

return Settings
