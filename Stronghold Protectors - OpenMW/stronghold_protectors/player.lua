local self = require("openmw.self")
local aux = require("openmw_aux.util")
local query = require("openmw.query")
local core = require("openmw.core")
local nearby = require("openmw.nearby")
local async = require("openmw.async")
local stronghold = require("stronghold_protectors.strongholds")
local uiText = require("openmw.ui").showMessage

local atAStronghold = false
local attackme = false
local ownerOfStronghold
local aggressive = false
local leaveTimer = 11
local startTimer = false
local timer

local function checkCell(cell)
    for _, v in pairs(stronghold) do
        if cell:match(v) then
            return true
        end
    end
    return false
end

local function isOwnerHere()
    for _, actor in nearby.actors:ipairs() do
        if actor:isValid() and actor.type == "NPC" and ( actor.recordId == "banden indarys" or actor.recordId == "raynasa rethan" or
                    actor.recordId == "reynel uvirith" ) then
				return true
        end
    end
	return false
end

local function onUpdate()
    if not checkCell(self.cell.name) then
		timer()
		ownerOfStronghold = nil
        leaveTimer = 11
        aggressive = false
        startTimer = false
        return
    end


    if not isOwnerHere() then
        return
    end

    for _, actor in nearby.actors:ipairs() do
        if actor:isValid() and actor:canMove() and (actor.position - self.position):length() < 1000 then
            if actor ~= self.object then
                if self:isInWeaponStance() or aggressive then
                    uiText("The residents consider you an intruder.")
                    actor:sendEvent("attackIntruder_strghld_protect", {self.object, ownerOfStronghold})
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
    end

    if startTimer and leaveTimer == 11 then
        timer = aux.runEveryNSeconds(
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
