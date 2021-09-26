local query = require("openmw.query")
local world = require("openmw.world")
local functions = require("stronghold_protectors.functions")


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
    eventHandlers = {}
}
