








---
local FactoryActivatable_mt = Class(FactoryActivatable)


---
function FactoryActivatable.new(factory)
    local self = setmetatable({}, FactoryActivatable_mt)

    self.factory = factory
    self.activateText = string.format(g_i18n:getText("action_buyOBJECT"), self.factory:getName())

    return self
end


---
function FactoryActivatable:getIsActivatable()
    local ownerFarmId = self.factory:getOwnerFarmId()
    return ownerFarmId == AccessHandler.EVERYONE -- or ownerFarmId == g_currentMission:getFarmId()
end


---
function FactoryActivatable:run()
    local ownerFarmId = self.factory:getOwnerFarmId()
    if ownerFarmId == AccessHandler.EVERYONE then
        self.factory:buyRequest()
    end
end
