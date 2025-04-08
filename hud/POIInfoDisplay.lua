



















---
local POIInfoDisplay_mt = Class(POIInfoDisplay, HUDDisplayElement)























---
function POIInfoDisplay:draw()
    if self.text == "" then
        return
    end

    local posX, posY = self:getPosition()
    local height = self:getHeight()

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    setTextColor(1, 1, 1, 1)

    local width = getTextWidth(self.textSize, self.text)
    width = width + self.offsetLeft + self.offsetRight

    drawFilledRectRound(posX, posY, width, height, self.uiScale, self.r, self.g, self.b, self.a)

    renderText(posX+self.offsetLeft, posY+self.offsetBottom, self.textSize, self.text)

    POIInfoDisplay:superClass().draw(self)
end






---Set this element's UI scale factor.
-- @param float uiScale UI scale factor
function POIInfoDisplay:setScale(uiScale)
    POIInfoDisplay:superClass().setScale(self, uiScale, uiScale)
    self.uiScale = uiScale

    local posX, posY = POIInfoDisplay.getBackgroundPosition(uiScale)
    self:setPosition(posX, posY)

    self:applyValues(uiScale)
end





















---Get the scaled background position.
function POIInfoDisplay.getBackgroundPosition(uiScale)
    local _, height = getNormalizedScreenValues(unpack(POIInfoDisplay.SIZE.SELF))
    local offsetX, offsetY = getNormalizedScreenValues(unpack(POIInfoDisplay.POSITION.SELF))
    local posX = offsetX*uiScale
    local posY = 1 + offsetY*uiScale - height*uiScale

    return posX, posY
end


---Create the background overlay.
function POIInfoDisplay.createBackground()
    local posX, posY = POIInfoDisplay.getBackgroundPosition(1)
    local width, height = getNormalizedScreenValues(unpack(POIInfoDisplay.SIZE.SELF))

    local overlay = Overlay.new(nil, posX, posY, width, height)
    return overlay
end
