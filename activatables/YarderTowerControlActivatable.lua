











---
local YarderTowerControlActivatable_mt = Class(YarderTowerControlActivatable)


---Returns new instance of class
-- @param table animatedObject object of animatedObject
-- @return table self new instance
function YarderTowerControlActivatable.new(vehicle)
    local self = {}
    setmetatable(self, YarderTowerControlActivatable_mt)

    self.vehicle = vehicle
    self.activateText = ""

    return self
end


---
function YarderTowerControlActivatable:registerCustomInput(inputContext)
    local _
    _, self.actionEventIdFollowMe = g_inputBinding:registerActionEvent(InputAction.YARDER_FOLLOW_ME, self, self.onToggleFollowMeMode, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdFollowMe, GS_PRIO_VERY_HIGH)

    _, self.actionEventIdFollowHome = g_inputBinding:registerActionEvent(InputAction.YARDER_FOLLOW_HOME, self, self.onToggleFollowHome, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdFollowHome, GS_PRIO_VERY_HIGH)

    _, self.actionEventIdFollowPickup = g_inputBinding:registerActionEvent(InputAction.YARDER_FOLLOW_PICKUP, self, self.onToggleFollowPickup, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdFollowPickup, GS_PRIO_VERY_HIGH)

    _, self.actionEventIdManualControl = g_inputBinding:registerActionEvent(InputAction.YARDER_CONTROL_LEFTRIGHT, self, self.onManualControlLeftRight, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdManualControl, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(self.actionEventIdManualControl, self.vehicle.spec_yarderTower.texts.actionCarriageManualControl)

    _, self.actionEventIdLiftLower = g_inputBinding:registerActionEvent(InputAction.YARDER_CONTROL_UPDOWN, self, self.onManualControlUpDown, false, false, true, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdLiftLower, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(self.actionEventIdLiftLower, self.vehicle.spec_yarderTower.texts.actionCarriageLiftLower)

    _, self.actionEventIdAttach = g_inputBinding:registerActionEvent(InputAction.YARDER_ATTACH, self, self.onTreeAttach, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdAttach, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(self.actionEventIdAttach, self.vehicle.spec_yarderTower.texts.actionCarriageAttachTree)

    _, self.actionEventIdDetach = g_inputBinding:registerActionEvent(InputAction.YARDER_DETACH, self, self.onTreeDetach, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdDetach, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(self.actionEventIdDetach, self.vehicle.spec_yarderTower.texts.actionCarriageDetachTree)

    self:updateActionEventTexts()
end


---
function YarderTowerControlActivatable:removeCustomInput(inputContext)
    g_inputBinding:removeActionEventsByTarget(self)
end


---
function YarderTowerControlActivatable:onToggleFollowMeMode()
    local spec = self.vehicle.spec_yarderTower
    if spec.carriage.followModeState == YarderTower.FOLLOW_MODE_ME then
        self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_NONE)
    else
        self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_ME)
    end
end


---
function YarderTowerControlActivatable:onToggleFollowHome()
    self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_HOME)
end


---
function YarderTowerControlActivatable:onToggleFollowPickup()
    self.vehicle:setYarderCarriageFollowMode(YarderTower.FOLLOW_MODE_PICKUP)
end


---
function YarderTowerControlActivatable:onManualControlLeftRight(actionName, inputValue, callbackState, isAnalog, isMouse)
    self.vehicle:setYarderCarriageMoveInput(inputValue)
end


---
function YarderTowerControlActivatable:onManualControlUpDown(actionName, inputValue, callbackState, isAnalog, isMouse)
    self.vehicle:setYarderCarriageLiftInput(inputValue)
end


---
function YarderTowerControlActivatable:onTreeAttach(actionName, inputValue, callbackState, isAnalog, isMouse)
    self.vehicle:onYarderCarriageAttach()
end


---
function YarderTowerControlActivatable:onTreeDetach(actionName, inputValue, callbackState, isAnalog, isMouse)
    self.vehicle:onYarderCarriageDetach(inputValue)
end


---
function YarderTowerControlActivatable:update(dt)
    local carriage = self.vehicle.spec_yarderTower.carriage.vehicle
    if carriage ~= nil then
        g_inputBinding:setActionEventActive(self.actionEventIdAttach, carriage:getIsTreeInMountRange())

        local treesAttached = carriage:getNumAttachedTrees() > 0
        g_inputBinding:setActionEventActive(self.actionEventIdDetach, treesAttached)
        g_inputBinding:setActionEventActive(self.actionEventIdLiftLower, treesAttached)
    end
end


---
function YarderTowerControlActivatable:updateActionEventTexts()
    local spec = self.vehicle.spec_yarderTower
    local ropeLength = self.vehicle:getYarderMainRopeLength()

    g_inputBinding:setActionEventText(self.actionEventIdFollowMe, spec.carriage.followModeState == YarderTower.FOLLOW_MODE_ME and spec.texts.actionCarriageFollowModeDisable or spec.texts.actionCarriageFollowModeEnable)

    if spec.carriage.followModeState == YarderTower.FOLLOW_MODE_NONE then
        g_inputBinding:setActionEventActive(self.actionEventIdFollowHome, spec.carriage.lastPosition * ropeLength > 5)

        if spec.carriage.followModePickupPosition ~= 0 then
            local offset = math.abs(spec.carriage.lastPosition-spec.carriage.followModePickupPosition) * ropeLength
            g_inputBinding:setActionEventActive(self.actionEventIdFollowPickup, offset > 5)
        else
            g_inputBinding:setActionEventActive(self.actionEventIdFollowPickup, false)
        end
    else
        g_inputBinding:setActionEventActive(self.actionEventIdFollowHome, false)
        g_inputBinding:setActionEventActive(self.actionEventIdFollowPickup, false)
    end
end


---
function YarderTowerControlActivatable:getIsActivatable()
    local isInRange, _ = self.vehicle:getIsPlayerInYarderControlRange()
    return isInRange
end


---
function YarderTowerControlActivatable:activate()
end


---
function YarderTowerControlActivatable:deactivate()
end


---
function YarderTowerControlActivatable:getDistance(x, y, z)
    local _, distance = self.vehicle:getIsPlayerInYarderControlRange()
    return distance
end


---
function YarderTowerControlActivatable:draw()
end
