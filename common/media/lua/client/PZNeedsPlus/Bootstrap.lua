local Settings = require "PZNeedsPlus/Settings"
local Care = require "PZNeedsPlus/Care"
local Weapons = require "PZNeedsPlus/Weapons"

pcall(require, "TimedActions/ISTimedActionQueue")
pcall(require, "TimedActions/ISReloadWeaponAction")

local RELOAD_MS = 1000
local lastReload = 0

local function reload(player)
    if not Settings.autoReload() or Settings.infiniteMagazine() then return end
    if player:hasTimedActions() or player:getVehicle() then return end
    local gun = player:getPrimaryHandItem()
    if not gun or not gun:IsWeapon() then return end
    local ranged = false
    pcall(function() ranged = gun:isRanged() end)
    if not ranged then return end
    local current, maximum = 0, 0
    pcall(function() current = gun:getCurrentAmmoCount() end)
    pcall(function() maximum = gun:getMaxAmmo() end)
    if maximum <= 0 or current >= maximum then return end
    local reloadable = true
    pcall(function() reloadable = gun:isReloadable(player) end)
    if not reloadable then return end
    if ISReloadWeaponAction and ISTimedActionQueue then
        ISTimedActionQueue.add(ISReloadWeaponAction:new(player, gun))
    end
end

local function tick(player)
    if not player or player:isDead() then return end
    local now = getTimestampMs()
    if now - lastReload < RELOAD_MS then return end
    lastReload = now
    pcall(reload, player)
end

local function install()
    Care.install()
    Weapons.install()
    Events.OnGameStart.Add(function() lastReload = 0 end)
    Events.OnPlayerUpdate.Add(function()
        local player = getSpecificPlayer(0)
        if player then
            local ok, err = pcall(tick, player)
            if not ok then print("[PZNeedsPlus] reload tick error " .. tostring(err)) end
        end
    end)
    print("[PZNeedsPlus] loaded")
end

Events.OnGameStart.Add(install)
