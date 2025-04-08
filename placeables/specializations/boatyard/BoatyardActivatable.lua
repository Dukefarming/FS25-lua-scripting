








---
local BoatyardActivatable_mt = Class(BoatyardActivatable)


---
function BoatyardActivatable.new(boatyard)
    local self = setmetatable({}, BoatyardActivatable_mt)

    self.boatyard = boatyard
    self.activateText = string.format(g_i18n:getText("action_buyOBJECT"), self.boatyard:getName())

    return self
end


---
function BoatyardActivatable:getIsActivatable()
    local ownerFarmId = self.boatyard:getOwnerFarmId()
    return ownerFarmId == AccessHandler.EVERYONE -- or ownerFarmId == g_currentMission:getFarmId()
end


---
function BoatyardActivatable:run()
    local ownerFarmId = self.boatyard:getOwnerFarmId()
    if ownerFarmId == AccessHandler.EVERYONE then
        self.boatyard:buyRequest()
    end
end
