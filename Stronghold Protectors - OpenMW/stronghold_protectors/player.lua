local self = require("openmw.self")
local aux = require("openmw_aux.util")
local query = require("openmw.query")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local async = require("openmw.async")
local stronghold = require("stronghold_protectors.strongholds")
local functions = require("stronghold_protectors.functions")
local uiText = require("openmw.ui").showMessage

local atAStronghold = false
local attackme = false
local ownerOfStronghold
local aggressive = false
local leaveTimer = 11
local startTimer = false
local timer



local function onUpdate()
    if not functions.checkCellIsStronghold(self.cell.name) then
        if leaveTimer ~= 11 then
            timer()
        end
        ownerOfStronghold = nil
        leaveTimer = 11
        aggressive = false
        startTimer = false
        return
    end

    if not functions.isOwnerHere(nearby) then
        return
    end

    for _, actor in nearby.actors:ipairs() do
        if actor ~= self.object and actor:isValid() and actor:canMove() and (actor.position - self.position):length() < 1000 then
            if self:isInWeaponStance() or aggressive then
                uiText("The residents consider you an intruder.")
                actor:sendEvent("attackIntruder_strghld_protect", {self.object, ownerOfStronghold})
				aggressive = true
            elseif not aggressive then
                uiText(
                    string.format(
                        "You have %s seconds to leave the property, before they take permanent action.",
                        leaveTimer
                    )
                )
                if not startTimer then
                    startTimer = true
                end
            end
        end
    end

    if startTimer and leaveTimer == 11 then
        timer =
            aux.runEveryNSeconds(
                1,
                function()
                    leaveTimer = leaveTimer - 1
                end
            )
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
