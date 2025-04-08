






















---
local WarningDisplay_mt = Class(WarningDisplay, HUDDisplay)


---Create a new WarningDisplay.
-- @param any? customMt
-- @param string? hudAtlasPath Path to the HUD atlas texture
-- @return any self
function WarningDisplay.new(customMt)
    local self = WarningDisplay:superClass().new(WarningDisplay_mt)

    self.warnings = {}

    self.icon = g_overlayManager:createOverlay("gui.storeAttribute_info", 0, 0, 0, 0)
    self.icon:setColor(0.8, 0.8, 0.8, 0.7)

    return self
end






---Store scaled positioning, size and offset values.
function WarningDisplay:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 0)
    local posX = 0.5 + offsetX
    local posY = 0.45 + offsetY
    self:setPosition(posX, posY)

    self.maxTextWidth = self:scalePixelToScreenWidth(600)
    self.textSize = self:scalePixelToScreenHeight(16)
    self.boxPaddingX, self.boxPaddingY = self:scalePixelValuesToScreenVector(20, 10)
    self.textOffsetY = self:scalePixelToScreenHeight(2)
    self.boxOffsetY = self:scalePixelToScreenHeight(6)
    self.iconTextOffsetX = self:scalePixelToScreenHeight(10)

    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(36, 36)
    self.icon:setDimension(iconWidth, iconHeight)
end












---Draw the notifications.
function WarningDisplay:draw()
    WarningDisplay:superClass().draw(self)

    local numWarnings = #self.warnings
    if numWarnings == 0 then
        return
    end

    setTextWrapWidth(self.maxTextWidth)

    local posX, posY = self:getPosition()
    local textSize = self.textSize
    local textOffsetY = self.textOffsetY

    local totalHeight = 0
    for _, warning in ipairs(self.warnings) do
        local text = warning.text
        local textHeight = getTextHeight(textSize, text)

        totalHeight = totalHeight + textHeight + 2*self.boxPaddingY + self.boxOffsetY
    end

    totalHeight = totalHeight - self.boxOffsetY
    posY = posY + totalHeight*0.5

    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
    local alpha = 0.4 + 0.6 * IngameMap.alpha
    setTextColor(0.7796, 0.0578, 0.0612, alpha)

    for _, warning in ipairs(self.warnings) do
        local text = warning.text
        local textWidth = getTextWidth(textSize, text)
        local textHeight = getTextHeight(textSize, text)

        local boxWidth = textWidth + self.iconTextOffsetX + self.icon.width + 2*self.boxPaddingX
        local boxHeight = math.max(textHeight + 2*self.boxPaddingY, self.icon.height+2*self.boxPaddingY)
        local boxX = posX-boxWidth*0.5
        local boxY = posY-boxHeight*0.5

        drawFilledRectRound(boxX, boxY, boxWidth, boxHeight, 0.35, 0, 0, 0, 0.8)
        posY = posY - boxHeight

        self.icon:setPosition(boxX + self.boxPaddingX, boxY + boxHeight*0.5 - self.icon.height*0.5)
        self.icon:render()

        renderText(self.icon.x + self.icon.width + self.iconTextOffsetX, boxY + boxHeight*0.5 + textOffsetY, self.textSize, text)

        posY = posY - self.boxOffsetY
    end

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
    setTextColor(1, 1, 1, 1)
    setTextBold(false)
end
