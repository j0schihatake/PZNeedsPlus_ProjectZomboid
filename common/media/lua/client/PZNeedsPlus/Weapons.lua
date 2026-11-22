-- PZ Needs Plus: infinite weapon condition and ammunition logistics.
local Weapons = {}
local Settings = require "PZNeedsPlus/Settings"

local DURABILITY_MS, AMMO_MS = 5000, 10000
local lastDurability, lastAmmo = 0, 0

local function countItems(container, fullType, depth)
    if not container or depth > 2 then return 0 end
    local total, items = 0, container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getFullType() == fullType then
            local count = 1
            pcall(function() count = item:getCount() end)
            total = total + count
        elseif item:IsInventoryContainer() then
            total = total + countItems(item:getInventory(), fullType, depth + 1)
        end
    end
    return total
end

local function repair(player)
    for _, item in ipairs({ player:getPrimaryHandItem(), player:getSecondaryHandItem() }) do
        if item and item:IsWeapon() then
            local okay, maximum = pcall(function() return item:getConditionMax() end)
            if okay and maximum and maximum > 0 then
                pcall(function() item:setConditionNoSound(maximum) end)
                pcall(function() if item:getSharpness() < 1 then item:setSharpness(1) end end)
            end
        end
    end
end

local function ammo(player)
    local gun = player:getPrimaryHandItem()
    if not gun or not gun:IsWeapon() then return end
    local ranged = false
    pcall(function() ranged = gun:isRanged() end)
    if not ranged then return end
    local maximum = 0
    pcall(function() maximum = gun:getMaxAmmo() end)
    if maximum <= 0 then return end
    if Settings.infiniteMagazine() then
        pcall(function() if gun:getCurrentAmmoCount() < maximum then gun:setCurrentAmmoCount(maximum) end end)
        return
    end
    local ammoType, magazine, inventory = nil, nil, player:getInventory()
    pcall(function() ammoType = gun:getAmmoType() end)
    pcall(function() magazine = gun:getMagazineType() end)
    if ammoType and ammoType.getItemKey then
        local key = ammoType:getItemKey()
        local have = countItems(inventory, key, 0)
        local want = math.min(300, maximum * 3) - have
        if key and key ~= "" and want > 0 then inventory:AddItem(key, want) end
    end
    if magazine and magazine ~= "" and countItems(inventory, magazine, 0) <= 0 then
        inventory:AddItem(magazine, 1)
    end
end

local function tick(player)
    if not player or player:isDead() then return end
    local now = getTimestampMs()
    if Settings.infiniteDurability() and now - lastDurability >= DURABILITY_MS then
        lastDurability = now
        pcall(repair, player)
    end
    if Settings.infiniteAmmo() and now - lastAmmo >= AMMO_MS then
        lastAmmo = now
        pcall(ammo, player)
    end
end

function Weapons.install()
    Events.OnGameStart.Add(function() lastDurability, lastAmmo = 0, 0 end)
    Events.OnPlayerUpdate.Add(function()
        local player = getSpecificPlayer(0)
        if player then
            local ok, err = pcall(tick, player)
            if not ok then print("[PZNeedsPlus] weapon tick error " .. tostring(err)) end
        end
    end)
end

return Weapons
