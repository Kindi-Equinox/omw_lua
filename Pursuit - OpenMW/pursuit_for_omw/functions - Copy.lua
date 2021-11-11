local core = require("openmw.core")
local this = {}







this.passAllConditions = function (actor, target, conditions)

	if conditions == true then
		return false
	elseif not conditions then
		return true
	end


    for _, condition in ipairs(conditions) do
		if type(condition) ~= "string" then
			break
		end
        if condition == "noexterior" and target.cell.isExterior then

        elseif condition == "nointerior" and not target.cell.isExterior then

        elseif condition:match("nocell:(.+)") and condition:match("nocell:(.+)") == target.cell.name then

        elseif condition:match("hasitem:(.+)") and actor.inventory:countOf(condition:match("hasitem:(.+)")) > 0 then

        elseif condition:match("targethasitem:(.+)") and target.inventory:countOf(condition:match("targethasitem:(.+)")) > 0 then

        elseif condition:match("equipped:(.+)") and actor:isEquipped(condition:match("equipped:(.+)")) then

        elseif condition:match("targetequipped:(.+)") and target:isEquipped(condition:match("targetequipped:(.+)")) then

        elseif condition == "isvampire" and target.cell.isExterior and
				math.fmod(core.getGameTimeInHours(), 24) > 6 and
					math.fmod(core.getGameTimeInHours(), 24) < 20 then
        else
			return true --one of the conditions not passed
        end
    end

	return false --all conditions passed

end













return this
