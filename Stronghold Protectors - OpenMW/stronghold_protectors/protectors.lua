local self = require("openmw.self")
local aux = require("openmw_aux.util")
local nearby = require("openmw.nearby")
local core = require('openmw.core')
local functions = require("stronghold_protectors.functions")
local hostileToPlayer = false --changes when in stronghold only
local playerRef

local function onInactive()
    if not hostileToPlayer then
        return
    end

    self:stopCombat()
    hostileToPlayer = false

end

local function onUpdate()
    if not self:getCombatTarget() or not functions.checkCellIsStronghold(self.cell.name) or hostileToPlayer or functions.isOwnerHere(nearby) then
        return
    end

    if self:getCombatTarget().type == "Player" then
    --do something about this specific event later
    else
        return
    end

    --if it's a renegade creature in the property or an NPC that attacks the player, all tenants of the stronghold will attack it
    for _, actor in nearby.actors:ipairs() do
        if actor ~= self.object and actor ~= self:getCombatTarget() and self:canMove() and self:isValid() and actor:isValid() and actor:canMove() and (actor.position - self.position):length() < 2048 then
            actor:sendEvent("attackIntruder_strghld_protect", {self.object, playerRef})
        end
    end
	for _, door in nearby.doors:ipairs() do
		if functions.checkCellIsStronghold(door.destCell.name) then
			core.sendGlobalEvent("attackIntruderOutside_strghld_protect", {self.object, door.destCell.name})
		end
	end
end

local function attackIntruder_strghld_protect(data)
    local intruder, owner = unpack(data)
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

aux.runEveryNSeconds(1.67, onUpdate)

return {
    engineHandlers = {
        onLoad = function()
            aux.runEveryNSeconds(1.67, onUpdate)
        end,
        onInactive = onInactive
    },
    eventHandlers = {
        attackIntruder_strghld_protect = attackIntruder_strghld_protect
    }
}
