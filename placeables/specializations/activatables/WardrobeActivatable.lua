








---
local WardrobeActivatable_mt = Class(WardrobeActivatable)


---
function WardrobeActivatable.new(placeable)
    local self = setmetatable({}, WardrobeActivatable_mt)

    self.placeable = placeable
    self.activateText = g_i18n:getText("action_openWardrobe")

    return self
end


---
function WardrobeActivatable:getIsActivatable()
    return self.placeable.spec_wardrobe.isFreeForAll or g_currentMission:getFarmId() == self.placeable:getOwnerFarmId()
end


---
function WardrobeActivatable:run()
    if g_guidedTourManager:getIsTourRunning() then
        InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
        return
    end

    g_gui:changeScreen(nil, WardrobeScreen)
end
