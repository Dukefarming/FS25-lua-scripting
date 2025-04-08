








---
local PalletBuyingStationActivatable_mt = Class(PalletBuyingStationActivatable)


---
function PalletBuyingStationActivatable.new(placeable, text)
    local self = setmetatable({}, PalletBuyingStationActivatable_mt)

    self.placeable = placeable
    self.activateText = text

    return self
end


---
function PalletBuyingStationActivatable:getIsActivatable()
    return g_currentMission.accessHandler:canPlayerAccess(self.placeable)
end


---
function PalletBuyingStationActivatable:run()
    self.placeable:openShop()
end
