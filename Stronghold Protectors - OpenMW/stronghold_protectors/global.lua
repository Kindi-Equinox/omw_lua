local query = require("openmw.query")
local async = require("openmw.async")
local util = require("openmw.util")
local core = require("openmw.core")
local world = require("openmw.world")
local stronghold = require("stronghold_protectors.strongholds")


local playerRef

return {
    engineHandlers = {
        onActorActive = function(actor)
            local strongholdActor = false
            if not actor:isValid() then
                return
            end

            for _, cell in pairs(stronghold) do
                if actor.cell.name:match(cell) then
                    strongholdActor = true
                    break
                end
				strongholdActor = false
            end

            if not strongholdActor then
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
