local self = require("openmw.self")
local aux = require("openmw_aux.util")
local query = require("openmw.query")
local core = require("openmw.core")
local oricell
local oripos
local combatTarget

local function savePos_eqnx()
    if not oricell then
        oricell = self.cell.name
    end
    if not oripos then
        oripos = self.position
    end
end

local function onUpdate()
    if not self:getCombatTarget() then
        combatTarget = nil
        return
    end
    combatTarget = self:getCombatTarget()
    if self:getCombatTarget().type ~= "Player" and self:getCombatTarget():canMove() then
        self:getCombatTarget():sendEvent("pursuers_eqnx", self.object)
    end
end

local function onInactive()
    savePos_eqnx()
    if
        oricell ~= self.cell.name and not combatTarget and self:canMove() and
            (self.recordId:match("guard") or self.recordId:match("ordinator") or
                (self:getEquipment()[1] and self:getEquipment()[1].recordId:match("imperial")))
     then
        core.sendGlobalEvent("returnToCell_eqnx", {self.object, oricell, nil, oripos})
    end
end

aux.runEveryNSeconds(0.1, onUpdate)

return {
    engineHandlers = {
        onLoad = function(data)
            if data then
                oricell, oripos = unpack(data)
            end
            aux.runEveryNSeconds(0.1, onUpdate)
        end,
        onSave = function()
            return {oricell, oripos}
        end,
        onInactive = onInactive,
        onActive = function()
            if not oricell then
                oricell = self.cell.name
            end
            if not oripos then
                oripos = self.position
            end
        end
    },
    eventHandlers = {
        savePos_eqnx = savePos_eqnx
    }
}
