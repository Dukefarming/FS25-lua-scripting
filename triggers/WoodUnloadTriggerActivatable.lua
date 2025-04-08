








---
local WoodUnloadTriggerActivatable_mt = Class(WoodUnloadTriggerActivatable)


---
function WoodUnloadTriggerActivatable.new(woodUnloadTrigger)
    local self = setmetatable({}, WoodUnloadTriggerActivatable_mt)

    self.woodUnloadTrigger = woodUnloadTrigger
    self.activateText = g_i18n:getText("action_sellWood")  -- TODO: add custom text support, e.g. for prod points

    return self
end


---
function WoodUnloadTriggerActivatable:getIsActivatable()
    return not g_localPlayer:getIsInVehicle() and g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
end


---
function WoodUnloadTriggerActivatable:run()
    self.woodUnloadTrigger:processWood(g_currentMission:getFarmId())
end


---
function WoodUnloadTriggerActivatable:getDistance(x, y, z)
    if self.woodUnloadTrigger.activationTrigger ~= nil then
        local tx, ty, tz = getWorldTranslation(self.woodUnloadTrigger.activationTrigger)
        return MathUtil.vector3Length(x - tx, y - ty, z - tz)
    end

    return math.huge
end
