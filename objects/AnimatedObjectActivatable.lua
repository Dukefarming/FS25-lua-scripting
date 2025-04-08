




---
local AnimatedObjectActivatable_mt = Class(AnimatedObjectActivatable)


---Returns new instance of class
-- @param table animatedObject object of animatedObject
-- @return table self new instance
function AnimatedObjectActivatable.new(animatedObject)
    local self = setmetatable({}, AnimatedObjectActivatable_mt)

    self.animatedObject = animatedObject
    self.activateText = ""

    return self
end


---
function AnimatedObjectActivatable:registerCustomInput(inputContext)
    local controls = self.animatedObject.controls
    local _ -- unused register state
    if controls.posAction then
        if not controls.negAction then
            -- one event, button up for toggle
            _, controls.posActionEventId = g_inputBinding:registerActionEvent(controls.posAction, self, self.onAnimationInputToggle, false, true, false, true)
        elseif controls.posAction == controls.negAction then
            -- one event, full axis, check always
            _, controls.posActionEventId = g_inputBinding:registerActionEvent(controls.posAction, self, self.onAnimationInputContinuous, false, false, true, true)
        else
            -- need two events, one for each component, check always
            _, controls.posActionEventId = g_inputBinding:registerActionEvent(controls.posAction, self, self.onAnimationInputContinuous, false, false, true, true)
            _, controls.negActionEventId = g_inputBinding:registerActionEvent(controls.negAction, self, self.onAnimationInputContinuous, false, false, true, true)
        end
    end

    if controls.posActionEventId then
        g_inputBinding:setActionEventTextPriority(controls.posActionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventTextVisibility(controls.posActionEventId, true)

        if controls.posActionText then
            g_inputBinding:setActionEventText(controls.posActionEventId, controls.posActionText)
        end
    end

    if controls.negActionEventId then
        g_inputBinding:setActionEventTextPriority(controls.negActionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventTextVisibility(controls.negActionEventId, true)

        if controls.negActionText then
            g_inputBinding:setActionEventText(controls.negActionEventId, controls.negActionText)
        end
    end

    self:updateActionEventTexts()
end


---
function AnimatedObjectActivatable:removeCustomInput(inputContext)
    g_inputBinding:removeActionEventsByTarget(self)

    local controls = self.animatedObject.controls
    controls.posActionEventId = nil
    controls.negActionEventId = nil
end



---Event function for continuous animation (e.g. keep button pressed to raise/lower something).
function AnimatedObjectActivatable:onAnimationInputContinuous(actionName, inputValue)
    local changed = false
    local animation = self.animatedObject.animation
    local controls = self.animatedObject.controls
    local direction = 0
    if inputValue ~= 0 then
        if actionName == controls.posAction and inputValue > 0 then
            controls.wasPressed = true
            if animation.direction ~= 1 and animation.time ~= 1 then
                direction = 1
                changed = true
            end
        elseif actionName == controls.negAction or actionName == controls.posAction and inputValue < 0 then
            controls.wasPressed = true
            if animation.direction ~= -1 and animation.time ~= 0 then
                direction = -1
                changed = true
            end
        end
    else
        if animation.direction ~= 0 and controls.wasPressed then
            direction = 0
            changed = true
        end
    end

    if changed then
        self.animatedObject:setDirection(direction)
    end

end


---Event function for animation toggle (e.g. open/close door with one input).
function AnimatedObjectActivatable:onAnimationInputToggle()
    local direction = self.animatedObject.animation.direction * -1
    self.animatedObject:setDirection(direction)

    self:updateActionEventTexts()
end


---
function AnimatedObjectActivatable:updateActionEventTexts()
    local controls = self.animatedObject.controls
    if controls.posAction and not controls.negAction and controls.posActionText ~= nil and controls.negActionText ~= nil then
        local animation = self.animatedObject.animation
        if (animation.direction == 0 and animation.time == 0) or animation.direction < 0 then
            g_inputBinding:setActionEventText(controls.posActionEventId, controls.posActionText)
        else
            g_inputBinding:setActionEventText(controls.posActionEventId, controls.negActionText)
        end
    end
end


---
function AnimatedObjectActivatable:getIsActivatable()
    return self.animatedObject:getCanBeTriggered()
end


---
function AnimatedObjectActivatable:activate()
    g_currentMission:addDrawable(self)
end


---
function AnimatedObjectActivatable:deactivate()
    g_currentMission:removeDrawable(self)
end


---
function AnimatedObjectActivatable:getDistance(x, y, z)
    if self.animatedObject.triggerNode ~= nil then
        local tx, ty, tz = getWorldTranslation(self.animatedObject.triggerNode)
        return MathUtil.vector3Length(x-tx, y-ty, z-tz)
    end

    return math.huge
end


---
function AnimatedObjectActivatable:draw()
    if self.animatedObject.openingHours ~= nil and self.animatedObject.openingHours.closedText ~= nil then
        g_currentMission:addExtraPrintText(self.animatedObject.openingHours.closedText)
    end
end
