-- Zero weight for logs, planks, poles and wooden construction materials.
local WoodWeight = {}
local Settings = require "PZNeedsPlus/Settings"
local INTERVAL_MS = 15000
local last = 0

local function isWood(item)
    local full = ''
    pcall(function() full = item:getFullType() or '' end)
    full = full:lower()
    local kind = ''
    pcall(function() kind = item:getType() or '' end)
    kind = kind:lower()
    if full:find('base.log', 1, true) or kind:find('log', 1, true) then return true end
    if full:find('base.plank', 1, true) or kind:find('plank', 1, true) then return true end
    if full:find('woodenpole', 1, true) or full:find('woodenstick', 1, true) then return true end
    if full:find('fencepicket', 1, true) or kind:find('picket', 1, true) then return true end
    if full:find('base.wood', 1, true) then return true end
    local tag = false
    pcall(function() tag = item:hasTag('base:log') end)
    return tag
end

local function apply(item, factor)
    local data = item:getModData()
    local base = data.PZNeedsPlusWoodBaseWeight
    if type(base) ~= 'number' or base <= 0 then
        base = item:getActualWeight()
        data.PZNeedsPlusWoodBaseWeight = base
    end
    local target = base * factor
    if math.abs(item:getActualWeight() - target) > 0.0001 then
        item:setActualWeight(target)
    end
end

local function scan(container, factor, budget, depth)
    if not container or depth > 2 or budget.n > 400 then return end
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        budget.n = budget.n + 1
        if isWood(item) then pcall(apply, item, factor) end
        if item:IsInventoryContainer() then scan(item:getInventory(), factor, budget, depth + 1) end
    end
end

local function tick()
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    local now = getTimestampMs()
    if now - last < INTERVAL_MS then return end
    last = now
    local factor = Settings.materialWeightFactor()
    local budget = { n = 0 }
    scan(player:getInventory(), factor, budget, 0)
end

function WoodWeight.install()
    Events.OnGameStart.Add(function() last = 0 end)
    Events.OnPlayerUpdate.Add(function()
        local ok, err = pcall(tick)
        if not ok then print('[PZNeedsPlus] wood-weight error ' .. tostring(err)) end
    end)
end

return WoodWeight
