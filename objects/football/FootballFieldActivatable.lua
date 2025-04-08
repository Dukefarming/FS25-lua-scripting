








---
local FootballFieldResetActivatable_mt = Class(FootballFieldResetActivatable)



















---
function FootballFieldResetActivatable:getDistance(x, y, z)
    if self.footballField.resetTriggerNode ~= nil then
        local tx, ty, tz = getWorldTranslation(self.footballField.resetTriggerNode)
        return MathUtil.vector3Length(x - tx, y - ty, z - tz)
    end

    return math.huge
end
