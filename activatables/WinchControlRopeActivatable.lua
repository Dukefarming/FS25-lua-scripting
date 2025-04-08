













---
local WinchControlRopeActivatable_mt = Class(WinchControlRopeActivatable)


---Returns new instance of class
-- @param table animatedObject object of animatedObject
-- @return table self new instance
function WinchControlRopeActivatable.new(vehicle, rope)
    local self = {}
    setmetatable(self, WinchControlRopeActivatable_mt)

    self.vehicle = vehicle
    self.texts = vehicle.spec_winch.texts
    self.ropes = vehicle.spec_winch.ropes
    self.rope = rope
    self.activateText = ""

    return self
end


---
function WinchControlRopeActivatable:registerCustomInput(inputContext)
    local _
    _, self.actionEventIdControl = g_inputBinding:registerActionEvent(InputAction.WINCH_CONTROL, self, self.onControlWinch, false, true, true, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdControl, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(self.actionEventIdControl, self.texts.control)

    _, self.actionEventIdDetachTree = g_inputBinding:registerActionEvent(InputAction.WINCH_DETACH, self, self.onDetachTree, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdDetachTree, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(self.actionEventIdDetachTree, self.texts.detachTree)

    _, self.actionEventIdAttachMode = g_inputBinding:registerActionEvent(InputAction.WINCH_ATTACH_MODE, self, self.onAttachMode, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(self.actionEventIdAttachMode, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(self.actionEventIdAttachMode, self.texts.attachAnotherTree)
end


---
function WinchControlRopeActivatable:removeCustomInput(inputContext)
    g_inputBinding:removeActionEventsByTarget(self)
end


---
function WinchControlRopeActivatable:onControlWinch(actionName, inputValue, callbackState, isAnalog)
    self.vehicle:setWinchControlInput(self.rope.index, inputValue)
end


---
function WinchControlRopeActivatable:onDetachTree(actionName, inputValue, callbackState, isAnalog)
    self.vehicle:detachTreeFromWinch(self.rope.index)
end


---
function WinchControlRopeActivatable:onAttachMode(actionName, inputValue, callbackState, isAnalog)
    if #self.rope.attachedTrees < self.rope.maxNumTrees then
        self.vehicle:setWinchTreeAttachMode(self.rope)
    else
        g_currentMission:showBlinkingWarning(self.texts.warningMaxNumTreesReached, 2500)
    end
end


---
function WinchControlRopeActivatable:update(dt)
    if g_localPlayer ~= nil then
        local x1, _, z1 = getWorldTranslation(g_localPlayer.rootNode)
        local x2, _, z2 = getWorldTranslation(self.rope.attachedTrees[1].activeHookData.hookId)
        local distance = MathUtil.vector2Length(x1-x2, z1-z2)

        g_inputBinding:setActionEventActive(self.actionEventIdAttachMode, distance < self.rope.maxSubLength + WinchControlRopeActivatable.SUB_ATTACH_ADDITIONAL_RANGE)
    end
end


---
function WinchControlRopeActivatable:getIsActivatable()
    if self.vehicle:getOwnerFarmId() ~= g_currentMission:getFarmId() then
        return false
    end

    for i=1, #self.ropes do
        if self.rope ~= self.ropes[i] and self.ropes[i].isPlayerInRange then
            return false
        end

        if self.ropes[i].isAttachModeActive then
            return false
        end
    end

    local player = g_localPlayer
    if player ~= nil then
        if player.currentHandtool == nil and player.isControlled then
            local distance = self:getDistance(getWorldTranslation(player.rootNode))
            if distance < Winch.CONTROL_RANGE then
                return true
            end
        end
    end

    return false
end


---
function WinchControlRopeActivatable:activate()
end


---
function WinchControlRopeActivatable:deactivate()
end


---
function WinchControlRopeActivatable:getDistance(x, y, z)
    for i=1, #self.ropes do
        if self.rope ~= self.ropes[i] and self.ropes[i].isPlayerInRange then
            return math.huge
        end

        if self.ropes[i].isAttachModeActive then
            return math.huge
        end
    end

    if #self.rope.attachedTrees == 0 then
        return math.huge
    end

    local x1, _, z1 = getWorldTranslation(self.rope.ropeNode)
    local hookId = self.rope.attachedTrees[1].activeHookData.hookId
    if entityExists(hookId) then
        local x2, _, z2 = getWorldTranslation(hookId)

        local tx, _, tz = MathUtil.getClosestPointOnLineSegment(x1, 0, z1, x2, 0, z2, x, 0, z)
        return MathUtil.vector2Length(x-tx, z-tz)
    else
        return math.huge
    end
end


---
function WinchControlRopeActivatable:draw()
end
