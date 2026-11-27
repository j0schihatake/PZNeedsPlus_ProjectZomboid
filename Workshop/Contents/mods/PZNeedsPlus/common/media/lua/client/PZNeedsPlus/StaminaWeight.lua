-- Restore a chosen fraction of endurance loss and scale carry capacity.
local StaminaWeight = {}
local Settings = require "PZNeedsPlus/Settings"
local INTERVAL_MS = 1000
local last = 0
local enduranceLast = {}

local function maxEndurance()
    local ok, value = pcall(function() return CharacterStat.ENDURANCE:getMaximumValue() end)
    return ok and value or 1
end

local function applyEndurance(body, id)
    local stats = nil
    pcall(function() stats = body:getStats() end)
    if not stats then return end
    local current = nil
    pcall(function() current = stats:get(CharacterStat.ENDURANCE) end)
    if type(current) ~= 'number' then return end
    local previous = enduranceLast[id]
    if previous and current < previous then
        local restored = (previous - current) * Settings.enduranceFactor()
        if restored > 0 then
            local maximum = maxEndurance()
            pcall(function() stats:set(CharacterStat.ENDURANCE, math.min(maximum, current + restored)) end)
        end
    end
    enduranceLast[id] = current
end

local function applyWeight(body, id)
    local base = body:getModData().PZNeedsPlusBaseMaxWeight
    if type(base) ~= 'number' or base <= 0 then
        base = body:getMaxWeight()
        body:getModData().PZNeedsPlusBaseMaxWeight = base
    end
    local target = math.floor(base * Settings.carryWeightMultiplier())
    if target > 0 and body:getMaxWeight() ~= target then pcall(function() body:setMaxWeight(target) end) end
end

local function tick()
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    local factor = Settings.enduranceFactor()
    if factor > 0 then applyEndurance(player, 'player') end
    applyWeight(player, 'player')
    if factor <= 0 and Settings.carryWeightMultiplier() == 1 then return end
    local lists = {}
    pcall(function() lists[#lists+1] = getCell():getSurvivorList() end)
    pcall(function() lists[#lists+1] = getCell():getRemoteSurvivorList() end)
    for _, list in ipairs(lists) do
        if list then
            for i = 0, math.min(list:size(), 32) - 1 do
                local body = list:get(i)
                local dead = false
                pcall(function() dead = body:isDead() end)
                if not dead then
                    local id = 'npc' .. tostring(i)
                    if factor > 0 then applyEndurance(body, id) end
                    applyWeight(body, id)
                end
            end
        end
    end
end

function StaminaWeight.install()
    Events.OnGameStart.Add(function() last = 0; enduranceLast = {} end)
    Events.OnPlayerUpdate.Add(function()
        local now = getTimestampMs()
        if now - last < INTERVAL_MS then return end
        last = now
        local ok, err = pcall(tick)
        if not ok then print('[PZNeedsPlus] stamina/weight error ' .. tostring(err)) end
    end)
end

return StaminaWeight
