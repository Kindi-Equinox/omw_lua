local core = require("openmw.core")
local self = require("openmw.self")
local query = require("openmw.query")
local tabpursuer = {}
local masa = 0

local function onActive()
    if not next(tabpursuer) then
        return
    end
    for k, v in pairs(tabpursuer) do
        if self:canMove() and v[1]:canMove() then
            core.sendGlobalEvent("chaseCombatTarget_eqnx", {v[1], v[2], false, masa})
        else
            tabpursuer = {}
        end
    end

    tabpursuer = {}
end

return {
    engineHandlers = {
        onActive = onActive,
        onInactive = function()
            if not self:canMove() then
                return
            end
            masa = core.getGameTimeInSeconds()
            if self:getCombatTarget() and self:getCombatTarget().type == "Player" then
                core.sendGlobalEvent("chaseCombatTarget_eqnx", {self.object, self:getCombatTarget(), true, masa})
            end
        end
    },
    eventHandlers = {
        pursuers_eqnx = function(data)
            tabpursuer[tostring(data)] = {data, self.object}
        end
    }
}
