








---
local ProductionPointActivatable_mt = Class(ProductionPointActivatable)


---
function ProductionPointActivatable.new(productionPoint)
    local self = setmetatable({}, ProductionPointActivatable_mt)

    self.productionPoint = productionPoint
    self.mission = productionPoint.mission

    self:updateText()

    return self
end


---
function ProductionPointActivatable:updateText()
    if not self.productionPoint.isOwned and self.productionPoint.useInteractionTriggerForBuying then
        self.activateText = g_i18n:getText("action_buyProductionPoint")
    else
        self.activateText = g_i18n:getText("action_manageProductionPoint")
    end
end


---
function ProductionPointActivatable:getIsActivatable()
    return self.mission.accessHandler:canFarmAccess(self.mission:getFarmId(), self.productionPoint)
end


---
function ProductionPointActivatable:run()
    local ownerFarmId = self.productionPoint:getOwnerFarmId()

    if ownerFarmId == AccessHandler.EVERYONE and self.productionPoint.useInteractionTriggerForBuying then
        self.productionPoint:buyRequest()
    elseif ownerFarmId == self.mission:getFarmId() then
        self.productionPoint:openMenu()
    end
end


---
function ProductionPointActivatable:getDistance(x, y, z)
    if self.productionPoint.interactionTriggerNode ~= nil then
        if self.productionPoint.isOwned and not self.productionPoint.useInteractionTriggerForBuying then
            local tx, ty, tz = getWorldTranslation(self.productionPoint.interactionTriggerNode)
            return MathUtil.vector3Length(x - tx, y - ty, z - tz)
        end
    end

    return math.huge
end
