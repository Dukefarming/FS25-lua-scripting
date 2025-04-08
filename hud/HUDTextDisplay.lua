









---HUD text display.
-- 
-- Displays a formatted single-line text with optional animations.
local HUDTextDisplay_mt = Class(HUDTextDisplay, HUDDisplayElement)





---Create a new HUDTextDisplay.
-- @param float posX Screen space X position of the text display
-- @param float posY Screen space Y position of the text display
-- @param float textSize Text size in reference resolution pixels
-- @param integer? textAlignment Text alignment as one of RenderText.[ALIGN_LEFT | ALIGN_CENTER | ALIGN_RIGHT]
-- @param table? textColor Text display color as an array {r, g, b, a}, default: {1, 1, 1, 1}
-- @param boolean? textBold If true, will render the text in bold
-- @return table HUDTextDisplay instance
function HUDTextDisplay.new(posX, posY, textSize, textAlignment, textColor, textBold)
    local backgroundOverlay = Overlay.new(nil, 0, 0, 0, 0)
    backgroundOverlay:setColor(1, 1, 1, 1)
    local self = HUDTextDisplay:superClass().new(backgroundOverlay, nil, HUDTextDisplay_mt)

    self.initialPosX = posX
    self.initialPosY = posY
    self.text = "" -- must be set in a separate call which will correctly set up boundaries and position
    self.textSize = textSize or 0
    self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
    self.textAlignment = textAlignment or RenderText.ALIGN_LEFT
    self.textColor = textColor or {1, 1, 1, 1}
    self.textBold = textBold or false

    self.hasShadow = false
    self.shadowColor = {0, 0, 0, 1}

    return self
end


---Set the text to display.
-- @param string text Display text
-- @param float textSize Text size in reference resolution pixels
-- @param integer textAlignment Text alignment as one of RenderText.[ALIGN_LEFT | ALIGN_CENTER | ALIGN_RIGHT]
-- @param table textColor Text display color as an array {r, g, b, a}
-- @param boolean textBold If true, will render the text in bold
function HUDTextDisplay:setText(text, textSize, textAlignment, textColor, textBold)
    -- assign values with initial values as defaults
    self.text = text or self.text
    self.textSize = textSize or self.textSize
    self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
    self.textAlignment = textAlignment or self.textAlignment
    self.textColor = textColor or self.textColor
    self.textBold = textBold or self.textBold

    local width, height = getTextWidth(self.screenTextSize, self.text), getTextHeight(self.screenTextSize, self.text)
    self:setDimension(width, height)

    local posX, posY = self.initialPosX, self.initialPosY

    self:setPosition(posX, posY)
end


---Set the text display UI scale.
-- @param float uiScale
function HUDTextDisplay:setScale(uiScale)
    HUDTextDisplay:superClass().setScale(self, uiScale)

    self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
end


---Set this element's visibility.
-- @param boolean isVisible Visibility state
-- @param boolean animate If true, will play the currently set animation on becoming visible or and reset it when necessary.
function HUDTextDisplay:setVisible(isVisible, animate)
    -- shadow parent behavior which includes repositioning
    HUDElement.setVisible(self, isVisible)

    if animate then
        if not isVisible or not self.animation:getFinished() then
            self.animation:reset()
        end

        if isVisible then
            self.animation:start()
        end
    end
end


---Set the global alpha value for this text display.
-- The alpha value will be multiplied with any text color alpha channel value.
-- @param float alpha
function HUDTextDisplay:setAlpha(alpha)
    self:setColor(nil, nil, nil, alpha)
end


---Set the text color by channels.
-- Use for dynamic changes and animation.
-- @param float r
-- @param float g
-- @param float b
-- @param float a
function HUDTextDisplay:setTextColorChannels(r, g, b, a)
    self.textColor[1] = r
    self.textColor[2] = g
    self.textColor[3] = b
    self.textColor[4] = a
end


---Set the text shadow state.
-- @param boolean isShadowEnabled If true, will cause a shadow to be rendered under the text
-- @param table shadowColor Shadow text color as an array {r, g, b, a}
function HUDTextDisplay:setTextShadow(isShadowEnabled, shadowColor)
    self.hasShadow = isShadowEnabled or self.hasShadow
    self.shadowColor = shadowColor or self.shadowColor
end


---Set an animation tween (sequence) for this text display.
-- The animation can be played when calling HUDTextDisplay:setVisible() with the "animate" paramter set to true.
-- @param table animationTween
function HUDTextDisplay:setAnimation(animationTween)
    self:storeOriginalPosition()
    self.animation = animationTween or TweenSequence.NO_SEQUENCE
end


---Update this element's state.
-- @param float dt
function HUDTextDisplay:update(dt)
    if self:getVisible() then
        HUDTextDisplay:superClass().update(self, dt)
    end
end


---Draw the text.
function HUDTextDisplay:draw()
    if self.text == "" then
        return
    end

    if not self:getVisible() then
        return
    end

    setTextBold(self.textBold)
    local posX, posY = self:getPosition()
    setTextAlignment(self.textAlignment)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextWrapWidth(0.9)

    if self.hasShadow then
        local offset = self.screenTextSize * HUDTextDisplay.SHADOW_OFFSET_FACTOR
        local r, g, b, a = unpack(self.shadowColor)
        setTextColor(r, g, b, a * self.overlay.a)
        renderText(posX + offset, posY - offset, self.screenTextSize, self.text)
    end

    local r, g, b, a = unpack(self.textColor)
    setTextColor(r, g, b, a * self.overlay.a)
    renderText(posX, posY, self.screenTextSize, self.text)

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextWrapWidth(0)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)
end
