local query = require("openmw.query")
local world = require("openmw.world")
local core = require('openmw.core')
local functions = require("stronghold_protectors.functions")

local pursuit_for_omw
local playerRef

return {
    engineHandlers = {
        onActorActive = function(actor)
            if not actor:isValid() then
                return
            end

            if not functions.checkCellIsStronghold(actor.cell.name) then
                return
            end

            actor:addScript("stronghold_protectors/protectors.lua")
        end,
        onPlayerAdded = function(player)
            playerRef = player
            player:addScript("stronghold_protectors/player.lua")
        end,
        onUpdate = function()
            if not playerRef then
                playerRef = world.selectObjects(query.actors:where(query.OBJECT.type:eq("Player")))[1]
                playerRef:addScript("stronghold_protectors/player.lua")
            end
        end
    },
    eventHandlers = {
        pursuit_for_omw_installed = function()
            pursuit_for_omw = true
            print("Pursuit and Stronghold Protectors interaction established")
        end,
        attackIntruderOutside_strghld_protect = function(data)
            --people inside cell will come out to defend stronghold
            --require pursuit mod
            --for now disabled until it is possible to get aipackages
            --if data or not data then return end --remove this line to enable
            if not pursuit_for_omw then return end
            local intruder, cellName = unpack(data)
            local innerCell = world.getCellByName(cellName)
            local actors = innerCell:selectObjects(query.actors)
            local door = innerCell:selectObjects(query.doors:where(query.DOOR.destCell.name:eq(intruder.cell.name)))

            for _, actor in actors:ipairs() do
                if actor.type == "NPC" and actor:canMove() and actor:isValid() then
                    actor:addScript("pursuit_for_omw/pursuer.lua")
                    actor:sendEvent("savePos_eqnx")
                    actor:addScript("stronghold_protectors/protectors.lua")
                    core.sendGlobalEvent("chaseCombatTarget_eqnx", {actor, intruder})
                    actor:sendEvent("attackIntruder_strghld_protect", {intruder, playerRef})
                end
            end

        end
    }
}
