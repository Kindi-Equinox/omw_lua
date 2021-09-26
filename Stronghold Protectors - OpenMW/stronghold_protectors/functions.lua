local stronghold = require("stronghold_protectors.strongholds")
local this = {}


this.checkCellIsStronghold = function (cell)
    for _, v in pairs(stronghold) do
        if cell:match(v) then
            return true
        end
    end
    return false
end

this.isOwnerHere = function (nearby)
    for _, actor in nearby.actors:ipairs() do
        if
            actor:isValid() and actor.type == "NPC" and
            (actor.recordId == "banden indarys" or actor.recordId == "raynasa rethan" or
            actor.recordId == "reynel uvirith")
        then
            return true
        end
    end
    return false
end



return this--phucking phunctions
