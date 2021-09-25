local query = require("openmw.query")
local async = require("openmw.async")
local util = require("openmw.util")
local core = require("openmw.core")
local world = require("openmw.world")
local playerRef

--todo
--prevent some type of creatures from chasing through doors
--take into account locked doors
--take into account trapped doors
--take into account day of time ( for vampire npcs )
--guards come to crime scene through doors
--some other stuff and updates..
--thanks to ptmikheev for openmw-lua and example scripts
--https://gitlab.com/ptmikheev/openmw-lua-examples/-/tree/59d3bb7e9153e0276ec1feb91d20ba01e03b16a9/DataFiles
local function getBestDoor(actor, cell, target)
    local target = target
    if not target then
        target = playerRef
    end
    local doorsQuery = query.doors:where(query.DOOR.destCell.name:eq(cell))
    local doors = actor.cell:selectObjects(doorsQuery)
    local bestDoor
    local bestPathLength
    for i, door in doors:ipairs() do
        local pathLength = (actor.position - door.position):length() + (target.position - door.destPosition):length()
        if i == 1 or pathLength < bestPathLength then
            bestDoor, bestPathLength = door, pathLength
        end
    end
    return bestDoor
end

local function returnToCell(data)
    local actor, cell, target, position = unpack(data)
    local bestDoor = getBestDoor(actor, cell, target)
    if not bestDoor then
        actor:teleport(cell, position)
        return
    end
    actor:teleport(cell, position)
    --actor:teleport(cell, bestDoor.destPosition - util.vector3(math.random(-100, 100), math.random(-100, 100), 50))
    --aipackage to order guards back to cell
end

local travelToTheDoor =
    async:registerTimerCallback(
    "goToTheDoor",
    function(data)
        local actor, target = data.actor, data.target
        if actor.cell ~= target.cell then
            actor:teleport(data.destCellName, data.destPos - util.vector3(0, 0, 50), data.destRot)
        end
    end
)

local function chaseCombatTarget(data)
    local actor, target, bool, masa = unpack(data)
    local delay
    local delay2 = core.getGameTimeInSeconds() - masa
    if not target then
        return
    end
    if not actor:isValid() or not target:isValid() then
        return
    end
    if actor.cell:isInSameSpace(target) or not target:canMove() then
        return
    end
    local bestDoor = getBestDoor(actor, target.cell.name, target)

    if not bestDoor then
        return
    end
    if actor.type == "NPC" then
        delay = (actor.position - bestDoor.position):length() / actor:getRunSpeed()
    else
        delay = (actor.position - bestDoor.position):length() / (actor:getRunSpeed() * 1.8)
    end
    if not bool then
        delay = delay - delay2
    end
    if delay > 15 then
        print(string.format("%s will not pursue further", actor))
        return
    end
    if delay < 0 then
        delay = 0.1
    end
    --print(string.format("%s : delay = %f", actor.recordId, delay))
    async:newTimerInSeconds(
        delay,
        travelToTheDoor,
        {
            actor = actor,
            target = target,
            destCellName = bestDoor.destCell.name,
            destPos = bestDoor.destPosition,
            destRot = bestDoor.destRotation
        }
    )
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor and (actor.type == "NPC" or actor.type == "Creature") then
                actor:addScript("pursuit_for_omw/pursued.lua")
                actor:addScript("pursuit_for_omw/pursuer.lua")
            end
        end,
        onPlayerAdded = function(player)
            playerRef = player
        end,
        onUpdate = function()
            if not playerRef then
                playerRef = world.selectObjects(query.actors:where(query.OBJECT.type:eq("Player")))[1]
            end
        end,
		onLoad = function()
			core.sendGlobalEvent("pursuit_for_omw_installed")
		end
    },
    eventHandlers = {
        chaseCombatTarget_eqnx = chaseCombatTarget,
        returnToCell_eqnx = returnToCell
    }
}
