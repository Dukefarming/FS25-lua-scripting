








---
local DestructibleActivatable_mt = Class(DestructibleActivatable)


---
function DestructibleActivatable.new(placeable)
    local self = setmetatable({}, DestructibleActivatable_mt)

    self.placeable = placeable
    self.activateText = g_i18n:getText("action_destructibleStartRepairing")

    return self
end


---
function DestructibleActivatable:getIsActivatable()
    return self.placeable:getCanRepairDestructible(g_currentMission:getFarmId())
end


---
function DestructibleActivatable:run()
    if g_guidedTourManager:getIsTourRunning() then
        InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
        return
    end

    g_client:getServerConnection():sendEvent(PlaceableDestructibleRepairEvent.new(self.placeable))
end
