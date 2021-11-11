local self = require("openmw.self")
local aux = require("openmw_aux.util")
local query = require("openmw.query")
local core = require("openmw.core")
local oricell
local oripos
local combatTarget

local function savePos_eqnx()
    oricell = oricell or self.cell.name
    oripos = oripos or self.position
end

aux.runEveryNSeconds(
    0.1,
    function()
        if not self:getCombatTarget() then
            combatTarget = nil
            return
        end
        if not self:getCombatTarget():canMove() then
            return
        end

        --getCombatTarget() always return nil when actor is inactive
        combatTarget = self:getCombatTarget()

        if self:getCombatTarget().type ~= "Player" then
            self:getCombatTarget():sendEvent("Pursuit_pursuerData_eqnx", self)
        end
    end
)

return {
    engineHandlers = {
        onLoad = function(data)
            if data then
                oricell, oripos = unpack(data)
            end
        end,
        onSave = function()
            return {oricell, oripos}
        end,
        onInactive = function()
            savePos_eqnx()
            if
                oricell ~= self.cell.name and not combatTarget and self:canMove() and
                    (self.recordId:match("guard") or self.recordId:match("ordinator") or
                        (self:getEquipment()[1] and self:getEquipment()[1].recordId:match("imperial")))
             then
                core.sendGlobalEvent("Pursuit_returnToCell_eqnx", {self, oricell, nil, oripos})
            end
        end,
        onActive = function()
            savePos_eqnx()
        end
    },
    eventHandlers = {
        Pursuit_savePos_eqnx = savePos_eqnx
    }
}
