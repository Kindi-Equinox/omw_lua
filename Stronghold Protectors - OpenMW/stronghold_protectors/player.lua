local self = require("openmw.self")
local aux = require("openmw_aux.util")
local nearby = require("openmw.nearby")
local async = require("openmw.async")
local core = require('openmw.core')
local functions = require("stronghold_protectors.functions")
local messageBox = require("openmw.ui").showMessage

local aggressive = false
local leaveTimer = 11
local startTimer = false
local timer
local isThisPartEnabled = true
local timeStamp = 0

--todo
--check if the player is a member of a rival house
--check if the actor is affected by certain spells
--check if the actor is a follower
--some other stuff


--this part makes rival stronghold tenants hostile towards the player
--this feature is incomplete, any actors including your followers can attack you
--to enable, change 'isThisPartEnabled' to true
local function onUpdate()
	if not isThisPartEnabled then return end
    if not functions.checkCellIsStronghold(self.cell.name) then
        if leaveTimer ~= 11 then
            timer()
        end
        leaveTimer = 11
        aggressive = false
        startTimer = false
        return
    end

    if not functions.isOwnerHere(nearby) then
        return
    end

    for _, actor in nearby.actors:ipairs() do
        if
		  actor:canMove() and
		  actor:isValid() and
		  actor ~= self.object and
		  (actor.position - self.position):length() < 1000 then
            if
			  self:isInWeaponStance() or
			  aggressive then
                messageBox("The residents consider you an intruder.")
                actor:sendEvent("ProtectiveAllies_attackIntruder_eqnx", {self.object, ownerOfStronghold})
				aggressive = true
            elseif
			  not aggressive then
                messageBox(
                    string.format(
                        "You have %s seconds to leave the property, before they take permanent action.",
                        leaveTimer
                    )
                )
                if not startTimer then
                    startTimer = true
					timeStamp = math.floor(core.getGameTimeInSeconds()) + 10
                end
            end
        end
    end

    if startTimer then
        leaveTimer = timeStamp - math.floor(core.getGameTimeInSeconds())
        async:newUnsavableTimerInSeconds(
            10,
            function()
                aggressive = true
            end
        )
    end
end

aux.runEveryNSeconds(1, onUpdate)

return {
    engineHandlers = {
        onLoad = function()
            aux.runEveryNSeconds(1, onUpdate)
        end
    }
}
