local core = require("openmw.core")
local query = require("openmw.query")
local aux = require("openmw_aux.util")
local searchedCells = {}
local pursuit_for_omw = false

local function searchGuards(data)
    if not pursuit_for_omw then
        return
    end
    local door, agg = unpack(data)
    if searchedCells[tostring(door)] then
        return
    end
    searchedCells[tostring(door)] = true
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

aux.runEveryNSeconds(
    10,
    function()
        searchedCells = {}
    end
)

return {
    engineHandlers = {
        onActorActive = function(actor)
            if not actor then
                return
            end
            actor:addScript("protective_guards_for_omw/aggressor.lua")
            if actor.type == "NPC" then
                actor:addScript("protective_guards_for_omw/protect.lua")
            end
        end,
        onLoad = function()
            aux.runEveryNSeconds(
                10,
                function()
                    searchedCells = {}
                end
            )
        end
    },
    eventHandlers = {
        searchGuards = searchGuards,
        pursuit_for_omw_installed = function()
            pursuit_for_omw = true
            print("Pursuit and Protective Guards interaction established")
        end
    }
}
