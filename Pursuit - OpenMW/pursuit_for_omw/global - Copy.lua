local query = require("openmw.query")
local async = require("openmw.async")
local util = require("openmw.util")
local core = require("openmw.core")
local world = require("openmw.world")
local functions = require("pursuit_for_omw.functions")
local playerRef

local blockedActors = {}
--[[
(still under testing)
--use this event to block any actor from pursuing through doors
--core.sendGlobalEvent("Pursuit_blockActorPursuit_eqnx",{x, y})
--x can be game object or record ID
--y can be a boolean or table with serializable values (optional)

--block the actor
--core.sendGlobalEvent("Pursuit_blockActorPursuit_eqnx",{actor, true}) --simple block
--core.sendGlobalEvent("Pursuit_blockActorPursuit_eqnx", {actor, {}}) --block without conditions
--core.sendGlobalEvent("Pursuit_blockActorPursuit_eqnx",{actor}) --block, nil is interpreted as true
--core.sendGlobalEvent("Pursuit_blockActorPursuit_eqnx", actor) --block
--core.sendGlobalEvent("Pursuit_blockActorPursuit_eqnx",{actor, {conditions}}) --block with conditions

--unblock the actor
--core.sendGlobalEvent("Pursuit_blockActorPursuit_eqnx", {actor, false})
]]


--todo
--prevent some type of creatures from chasing through doors
--take into account locked doors
--take into account trapped doors
--take into account day of time ( for vampire npcs )
--guards come to crime scene through doors --partially done in protective guards
--some other stuff and updates..
--thanks to ptmikheev for openmw-lua and example scripts

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

--the parameter is a table with 3 values
--[1] the pursuing actor object
--[2] the target actor object of [1]
--[3] number in seconds to deduct to the time it takes to teleport (optional)
local function chaseCombatTarget(data)
    local actor, target, masa = unpack(data)
    local delay
    local conditions = blockedActors[tostring(actor)] or blockedActors[actor.recordId]

    if not functions or not functions.passAllConditions(actor, target, conditions) then
        return
    end

    actor:sendEvent("Pursuit_savePos_eqnx")

    if not target or not actor then
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
    if masa and type(masa) == "number" then
        delay = delay - masa
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
		onPlayerAdded = function(player)
            playerRef = player
        end,
        onActorActive = function(actor)
            if not actor:isValid() then
                return
            end

            if actor and (actor.type == "NPC" or actor.type == "Creature") then
                actor:addScript("pursuit_for_omw/pursued.lua")
                actor:addScript("pursuit_for_omw/pursuer.lua")
            end
        end,
        onUpdate = function()
            if not playerRef then
                playerRef = world.selectObjects(query.actors:where(query.OBJECT.type:eq("Player")))[1]
            end
        end,
        onLoad = function()
            core.sendGlobalEvent("Pursuit_installed_eqnx")
        end
    },
    eventHandlers = {
        --[[Pursuit_blockActorPursuit_eqnx = function(data)
            if type(data) ~= "table" then
                data = {data}
            end

            local actor, conditions = unpack(data)

            assert(
                type(actor) == "string" or type(actor) == "userdata",
                string.format(
                    "[Pursuit] block has received an invalid actor value (%s)?. Actor value must be a string ID or game object.",
                    type(actor)
                )
            )


            if conditions == nil then
                conditions = true
            end

            if conditions == false then
                --print(string.format("[Pursuit] %s successfully removed from BLOCKED list", actor))
                blockedActors[tostring(actor)] = nil
            else
                --print(string.format("[Pursuit] %s successfully added to BLOCKED list", actor))
                blockedActors[tostring(actor)] = conditions
            end
        end,]]
        Pursuit_chaseCombatTarget_eqnx = chaseCombatTarget,
        Pursuit_returnToCell_eqnx = returnToCell
    }
}
