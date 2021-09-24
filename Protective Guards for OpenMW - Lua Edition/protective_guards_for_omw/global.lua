local core = require("openmw.core")
local query = require("openmw.query")
local pursuit_for_omw = false



local function searchGuards(data)
	if not pursuit_for_omw then
		return
	end
    local door, agg = unpack(data)
    local adjacentCellActors = door.destCell:selectObjects(query.actors)
    for _, actor in adjacentCellActors:ipairs() do
        if
            actor:canMove() and actor.recordId:match("guard") or actor.recordId:match("ordinator") or
                (actor:getEquipment()[1] and actor:getEquipment()[1].recordId:match("imperial"))
         then
            actor:addScript("pursuit_for_omw/pursuer.lua")
            actor:addScript("protective_guards_for_omw/protect.lua")
            actor:sendEvent("savePos_eqnx")
            core.sendGlobalEvent("chaseCombatTarget_eqnx", {actor, agg, false, core.getGameTimeInSeconds()})
            actor:sendEvent("PGFOMW_Protect", agg)
        end
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            actor:addScript("protective_guards_for_omw/aggressor.lua")
            if actor.type == "NPC" then
                actor:addScript("protective_guards_for_omw/protect.lua")
            end
        end
    },
    eventHandlers = {
        searchGuards = searchGuards,
		pursuit_for_omw_installed = function() pursuit_for_omw = true print("Pursuit and Protective Guards interaction established") end
    }
}
