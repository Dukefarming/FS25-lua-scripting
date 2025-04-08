









---HUD display element whose subclasses implement more complex HUD display subsystems.
local HUDDisplayElement_mt = Class(HUDDisplayElement, HUDElement)





---Create a new HUD display element.
-- @param table subClass Subclass metatable for inheritance
-- @param table overlay Wrapped Overlay instance
-- @param table? parentHudElement [optional] Parent HUD element of the newly created HUD element
-- @return table HUDDisplayElement instance
function HUDDisplayElement.new(overlay, parentHudElement, customMt)
    local self = HUDDisplayElement:superClass().new(overlay, parentHudElement, customMt or HUDDisplayElement_mt)

    self.origX, self.origY = 0, 0 -- original positions, stored to support stable animation states
    self.animationState = nil

    return self
end


---Set this element's visibility with optional animation.
-- @param boolean isVisible True is visible, false is not.
-- @param boolean animate If true, the element will play an animation before applying the visibility change.
function HUDDisplayElement:setVisible(isVisible, animate)
    if animate and self.animation:getFinished() then
        if isVisible then
            self:animateShow()
        else
            self:animateHide()
        end
    else
        self.animation:stop()
        HUDDisplayElement:superClass().setVisible(self, isVisible)

        local posX, posY = self:getPosition()
        local transX, transY = self:getHidingTranslation()
        if isVisible then
            self:setPosition(self.origX, self.origY)
        else
            self:setPosition(posX + transX, posY + transY)
        end
    end

    self.animationState = isVisible
end


---Simplification of scale setter because these high-level elements always use a uniform scale.
function HUDDisplayElement:setScale(uiScale)
    HUDDisplayElement:superClass().setScale(self, uiScale, uiScale)
end


---Store the current element position as its original positions.
function HUDDisplayElement:storeOriginalPosition()
    self.origX, self.origY = self:getPosition()
end


---Get the screen space translation for hiding.
-- Override in sub-classes if a different translation is required.
-- @return float Screen space X translation
-- @return float Screen space Y translation
function HUDDisplayElement:getHidingTranslation()
    return 0, -0.5
end


---Animation setter function for X position.
function HUDDisplayElement:animationSetPositionX(x)
    self:setPosition(x, nil)
end


---Animation setter function for Y position.
function HUDDisplayElement:animationSetPositionY(y)
    self:setPosition(nil, y)
end


---Animate this element on hiding.
function HUDDisplayElement:animateHide()
    local transX, transY = self:getHidingTranslation()
    local startX, startY = self:getPosition()

    local sequence = TweenSequence.new(self)
    sequence:insertTween(MultiValueTween.new(self.setPosition, {startX, startY}, {startX + transX, startY + transY}, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
    sequence:addCallback(self.onAnimateVisibilityFinished, false)
    sequence:start()
    self.animation = sequence
end


---Animate this element on showing.
function HUDDisplayElement:animateShow()
    HUDDisplayElement:superClass().setVisible(self, true)

    local startX, startY = self:getPosition()

    local sequence = TweenSequence.new(self)
    sequence:insertTween(MultiValueTween.new(self.setPosition, {startX, startY}, {self.origX, self.origY}, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
    sequence:addCallback(self.onAnimateVisibilityFinished, true)
    sequence:start()
    self.animation = sequence
end


---Called when a hiding or showing animation has finished.
function HUDDisplayElement:onAnimateVisibilityFinished(isVisible)
    if not isVisible then -- delayed call when hiding
        HUDDisplayElement:superClass().setVisible(self, isVisible)
    end
end
