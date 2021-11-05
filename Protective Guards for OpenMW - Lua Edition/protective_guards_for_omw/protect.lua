local self = require("openmw.self")
local aux = require("openmw_aux.util")
local target

aux.runEveryNSeconds(
    math.random(4),
    function()
        if not target or not target:isValid() or not target:canMove() then
            return
        end
        if not (self.cell.isExterior or self.cell == target.cell) then
            return
        end
        if (target.position - self.position):length() > 8192 then
            self:stopCombat()
        end
    end
)

return {
    eventHandlers = {
        ProtectiveGuards_alertGuard_eqnx = function(attacker)
            target = attacker
            if not self:canMove() or not attacker:isValid() then
                return
            end
            self:startCombat(attacker)
        end
    }
}
