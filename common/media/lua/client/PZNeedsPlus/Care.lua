-- PZ Needs Plus: player self-care. Uses native B42 timed actions only.
local Care = {}
local Settings = require "PZNeedsPlus/Settings"

pcall(require, "TimedActions/ISTimedActionQueue")
pcall(require, "TimedActions/ISApplyBandage")
pcall(require, "TimedActions/ISTakePillAction")
pcall(require, "TimedActions/ISEatFoodAction")
pcall(require, "TimedActions/ISDrinkFluidAction")
pcall(require, "TimedActions/ISInventoryTransferAction")

local INTERVAL = 2000

local function speed(action)
    local choice = Settings.animationSpeed()
    local factor = choice == 0 and 0.5 or (choice == 2 and 1.6 or 1.0)
    if factor == 1.0 then return action end
    local base = action:getDuration()
    action.maxTime = math.max(1, math.floor(base * factor))
    action.getDuration = function(self) return self.maxTime end
    return action
end
local lastCheck = 0

local function stat(player, name)
    local ok, value = pcall(function() return player:getStats():get(name) end)
    if ok and type(value) == "number" then return value end
    return -1
end

local function maxPain(body)
    local worst = 0
    local parts = body:getBodyParts()
    for i = 0, parts:size() - 1 do
        local value = parts:get(i):getPain()
        if type(value) == "number" and value > worst then worst = value end
    end
    return worst
end

local function woundCount(player)
    local count, parts = 0, player:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local part = parts:get(i)
        if not part:bandaged() and (part:bleeding() or part:HasInjury()) then count = count + 1 end
    end
    return count
end

local function findItem(player, predicate)
    local budget = { n = 0 }
    local function scan(container, depth)
        if not container or depth > 2 then return nil end
        local items = container:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            budget.n = budget.n + 1
            if budget.n > 300 then return nil end
            if predicate(item) then return item end
            if item:IsInventoryContainer() then
                local found = scan(item:getInventory(), depth + 1)
                if found then return found end
            end
        end
    end
    return scan(player:getInventory(), 0)
end

local function findBandage(player)
    local best, bestScore = nil, 0
    findItem(player, function(item)
        local power = 0
        pcall(function() power = item:getBandagePower() end)
        local can = false
        pcall(function() can = item:isCanBandage() end)
        if power <= 0 and not can then return false end
        local infected = false
        pcall(function() infected = item:isInfected() end)
        if infected then return false end
        local score = 2
        if typeOf(item):find("Dirty", 1, true) then score = 1 end
        if score > bestScore then best, bestScore = item, score end
        return false
    end)
    return best
end

local function findPainkiller(player)
    return findItem(player, function(item)
        local full = item:getFullType()
        if full == "Base.Pills" or (item:getType() and item:getType():find("Painkiller", 1, true)) then
            local uses = 0
            pcall(function() uses = item:getCurrentUsesFloat() end)
            return uses > 0
        end
        return false
    end)
end

local function findFood(player)
    return findItem(player, function(item)
        return instanceof(item, "Food") and item:getHungerChange() < 0
            and not item:isRotten() and not item:isBurnt()
    end)
end

local function findDrink(player)
    return findItem(player, function(item)
        local source = false
        pcall(function() source = item:isWaterSource() end)
        if not source then return false end
        local uses = 0
        pcall(function() uses = item:getCurrentUsesFloat() end)
        if uses > 0 then return true end
        local fluid = item:getFluidContainer()
        return fluid ~= nil and fluid:getAmount() > 0
    end)
end

local function ensureMain(player, item)
    local inventory = player:getInventory()
    if item:getContainer() and item:getContainer() ~= inventory then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), inventory, 10))
    end
end

local function inCombat(player)
    if player:isAttacking() then return true end
    local ok, danger = pcall(function() return player:isTargetedByZombie() end)
    return ok and danger or false
end

local function busy(player)
    return player:hasTimedActions() or player:isSprinting() or player:isDraggingCorpse()
end

local function choose(player)
    local body = player:getBodyDamage()
    if Settings.autoHeal() then
        if woundCount(player) > 0 then return "bandage" end
        if maxPain(body) >= 40 then return "painkiller" end
    end
    if Settings.autoDrink() and stat(player, CharacterStat.THIRST) >= 0.20 and findDrink(player) then return "drink" end
    if Settings.autoEat() and stat(player, CharacterStat.HUNGER) >= 0.25 and findFood(player) then return "eat" end
    return nil
end

local function execute(player, action)
    if action == "bandage" then
        local parts = player:getBodyDamage():getBodyParts()
        for i = 0, parts:size() - 1 do
            local part = parts:get(i)
            if not part:bandaged() and (part:bleeding() or part:HasInjury()) then
                local item = findBandage(player)
                if not item then return false end
                ensureMain(player, item)
                ISTimedActionQueue.add(ISApplyBandage:new(player, player, item, part, true))
                return true
            end
        end
    elseif action == "painkiller" then
        local item = findPainkiller(player)
        if not item then return false end
        ensureMain(player, item)
        ISTimedActionQueue.add(ISTakePillAction:new(player, item))
        return true
    elseif action == "drink" then
        local item = findDrink(player)
        if not item then return false end
        ensureMain(player, item)
        ISTimedActionQueue.add(speed(ISDrinkFluidAction:new(player, item, 0.5)))
        return true
    elseif action == "eat" then
        local item = findFood(player)
        if not item then return false end
        ensureMain(player, item)
        ISTimedActionQueue.add(speed(ISEatFoodAction:new(player, item, 1)))
        return true
    end
    return false
end

local function tick(player)
    if not player or player:isDead() then return end
    local now = getTimestampMs()
    if now - lastCheck < INTERVAL then return end
    lastCheck = now
    if busy(player) or inCombat(player) then return end
    local action = choose(player)
    if action then
        local ok, done = pcall(execute, player, action)
        if not ok then print("[PZNeedsPlus] care error " .. tostring(done)) end
    end
end

function Care.install()
    Events.OnGameStart.Add(function() lastCheck = 0 end)
    Events.OnPlayerUpdate.Add(function()
        local player = getSpecificPlayer(0)
        if player then
            local ok, err = pcall(tick, player)
            if not ok then print("[PZNeedsPlus] care tick error " .. tostring(err)) end
        end
    end)
end

return Care
