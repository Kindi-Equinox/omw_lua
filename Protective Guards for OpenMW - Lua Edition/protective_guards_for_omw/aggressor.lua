local self = require("openmw.self")
local nearby = require("openmw.nearby")
local aux = require("openmw_aux.util")
local core = require("openmw.core")
local functions = require("protective_guards_for_omw.functions")
local bL = require("protective_guards_for_omw.blacklistedareas")
local timer = 0
local firstRun = false
local previousCell
local playerRef
local resistedArrest = false --only relevant if script is attached on guards

local function searchGuardsAdjacentCells(target)

    if not firstRun then
        return
    end
    local doorDistCheck = 8192
    local tempTab = {}
    if self.cell.isExterior then
        doorDistCheck = doorDistCheck / 5
    end
    for _, door in nearby.doors:ipairs() do
        if
            door.destCell ~= previousCell and door.isTeleport and
            (door.position - self.position):length() < doorDistCheck
        then
            tempTab[tostring(door)] = door
        end
    end
    for _, door in pairs(tempTab) do
        core.sendGlobalEvent("ProtectiveGuards_searchGuards_eqnx", {door, target})
    end
    firstRun = false
end

local function selfIsHostileCheck()
    if bL[self.cell.name] then
        return
    end
    if not self:getCombatTarget() or not self:canMove() then
        firstRun = true
        return
    end

    local distCheck = 8192
    if self.cell.isExterior then
        distCheck = distCheck / 4
    end
    if self:getCombatTarget().type == "Player" then
        playerRef = self:getCombatTarget()


        for _, actor in nearby.actors:ipairs() do
            if
                actor ~= self.object and actor.type == "NPC" and
                (actor.position - self.position):length() < distCheck and
                functions.isGuard(actor)
            then
                if playerRef.inventory:countOf("PG_TrigCrime") > 0 and functions.isGuard(self) then
                        actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {playerRef})
                        --searchGuardsAdjacentCells(playerRef) bad
                        resistedArrest = true
                elseif playerRef.inventory:countOf("PG_TrigCrime") == 0 and not resistedArrest then
                    if math.random(5) < 3 then
                        actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {self.object})
                        searchGuardsAdjacentCells(self.object)
                    end
                elseif playerRef.inventory:countOf("PG_TrigCrime") > 0 and not resistedArrest and not functions.isGuard(self) then
                    if math.random(5) < 3 then
                        actor:sendEvent("ProtectiveGuards_alertGuard_eqnx", {self.object})
                        searchGuardsAdjacentCells(self.object)
                    end
                end
            end
        end


    end
end

aux.runEveryNSeconds(0.5, selfIsHostileCheck)


return {
    engineHandlers = {
        onLoad = function()
            aux.runEveryNSeconds(0.5, selfIsHostileCheck)
        end,
        onInactive = function()
            firstRun = true
            previousCell = self.cell
        end,
        onUpdate = function(dt)

            if resistedArrest and playerRef then
                if playerRef.inventory:countOf("PG_TrigCrime") == 0 then
                    resistedArrest = false
                    self:stopCombat()
                end
            end


            if timer < 3 then
                timer = timer + dt
            else
                firstRun = true
                timer = 0
            end
        end
    }
}












