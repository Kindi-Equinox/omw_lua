local self = require("openmw.self")
local aux = require("openmw_aux.util")
local query = require("openmw.query")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local stronghold = require("stronghold_protectors.strongholds")
local hostileToPlayer = false
local playerRef

local function checkCell(cell)
    for _, v in pairs(stronghold) do
        if cell:match(v) then
            return true
        end
    end
    return false
end

local function onInactive()
    if not hostileToPlayer then
        return
    end

    if playerRef.cell ~= self.cell then
        self:stopCombat()
    end
end

local function onUpdate()
    if not self:getCombatTarget() then
        return
    end

    if not checkCell(self.cell.name) then
        return
    end

    if hostileToPlayer then
        return
    end

    if self:getCombatTarget().type == "Player" then
    end

    for _, actor in nearby.actors:ipairs() do
        if actor:isValid() and actor:canMove() and (actor.position - self.position):length() < 1000 then
            if actor ~= self.object then
                actor:sendEvent("attackIntruder_strghld_protect", {self.object, playerRef})
            end
        end
    end
end

local function attackIntruder_strghld_protect(data)
    local intruder, owner = unpack(data)
    if not self:canMove() or not self:isValid() then
        return
    end
    for _, actor in nearby.actors:ipairs() do
        if actor ~= self.object then
            if not self:getCombatTarget() then
                if intruder.type == "Player" then
                    hostileToPlayer = true
                    playerRef = intruder
                else
                    hostileToPlayer = false
                end
                self:startCombat(intruder)
            end
        end
    end
end

aux.runEveryNSeconds(3.37, onUpdate)

return {
    engineHandlers = {
        onLoad = function()
            aux.runEveryNSeconds(3.37, onUpdate)
        end,
        onInactive = onInactive
    },
    eventHandlers = {
        attackIntruder_strghld_protect = attackIntruder_strghld_protect
    }
}
