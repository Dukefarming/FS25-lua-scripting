







---FrameElement
-- HUD background frame element.
-- 
-- Displays a transparent frame with a thick bottom bar for use as a background in HUD elements.
-- 
local HUDFrameElement_mt = Class(HUDFrameElement, HUDElement)


---Create a new instance of FrameElement.
-- @param float posX Initial X position in screen space
-- @param float posY Initial Y position in screen space
-- @param float width Frame width in screen space
-- @param float height Frame height in screen space
-- @param table? parent [optional] Parent HUDElement which will receive this frame as its child element
function HUDFrameElement.new(posX, posY, width, height, parent, showBar, frameThickness, barThickness)
    local backgroundOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, width, height)
    backgroundOverlay:setColor(0, 0, 0, 0) -- default invisible
    local self = HUDElement.new(backgroundOverlay, parent, HUDFrameElement_mt)

    self.topLine = nil
    self.leftLine = nil
    self.rightLine = nil
    self.bottomBar = nil
    self.frameWidth, self.frameHeight = 0, 0
    self.showBar = Utils.getNoNil(showBar, true)
    self.frameThickness = frameThickness or HUDFrameElement.THICKNESS.FRAME
    self.barThickness = barThickness or HUDFrameElement.THICKNESS.BAR

    self:createComponents(posX, posY, width, height)

    return self
end


---Create display components.
function HUDFrameElement:createComponents(baseX, baseY, width, height)
    -- get pixel sizes so that frame lines are always at least a screen pixel thick
    local refPixelX, refPixelY = 1 / g_referenceScreenWidth, 1 / g_referenceScreenHeight
    local onePixelX, onePixelY = math.max(refPixelX, g_pixelSizeX), math.max(refPixelY, g_pixelSizeY)

    -- top line
    local posX, posY = baseX, baseY + self:getHeight()
    local frameWidth, frameHeight = getNormalizedScreenValues(self.frameThickness, self.frameThickness)
    local pixelsX, pixelsY = math.ceil(frameWidth / onePixelX), math.ceil(frameHeight / onePixelY)
    self.frameWidth, self.frameHeight = pixelsX * onePixelX, pixelsY * onePixelY

    local lineOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY - self.frameHeight, width, self.frameHeight)
    lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))

    local lineElement = HUDElement.new(lineOverlay)
    self.topLine = lineElement
    self:addChild(lineElement)

    -- side lines
    posX, posY = baseX, baseY + self.frameHeight
    lineOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, self.frameWidth, height - self.frameHeight * 2)
    lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))

    lineElement = HUDElement.new(lineOverlay)
    self.leftLine = lineElement
    self:addChild(lineElement)

    posX, posY = baseX + width - self.frameWidth, baseY + self.frameHeight
    lineOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, self.frameWidth, height - self.frameHeight * 2)
    lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))

    lineElement = HUDElement.new(lineOverlay)
    self.rightLine = lineElement
    self:addChild(lineElement)

    -- bottom bar
    local barSize = self.barThickness
    local barColor = HUDFrameElement.COLOR.BAR
    if not self.showBar then
        barSize = self.frameThickness
        barColor = HUDFrameElement.COLOR.FRAME
    end

    local _, barHeight = getNormalizedScreenValues(0, barSize)
    pixelsY = math.ceil(barHeight / onePixelY)
    local barOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, baseX, baseY, width, pixelsY * onePixelY)
    barOverlay:setColor(unpack(barColor))

    local barElement = HUDElement.new(barOverlay)
    self.bottomBar = barElement
    self:addChild(barElement)
end


---Set frame element dimensions.
-- Override from HUDElement to preserve border positioning and sizes.
function HUDFrameElement:setDimension(width, height)
    HUDFrameElement:superClass().setDimension(self, width, height)

    local lineHeight = nil
    if height ~= nil then
        lineHeight = height - self.frameHeight * 2
    end

    self.topLine:setDimension(width, nil)
    self.leftLine:setDimension(nil, lineHeight)
    self.rightLine:setDimension(nil, lineHeight)
    self.bottomBar:setDimension(width, nil)

    local x, y = self:getPosition()
    self.topLine:setPosition(nil, y + self:getHeight() - self.frameHeight)
    self.rightLine:setPosition(x + self:getWidth() - self.frameWidth, nil)
end


---Set frame bottom bar height.
function HUDFrameElement:setBottomBarHeight(height)
    self.bottomBar:setDimension(nil, height)
end


---Set frame bottom bar height.
function HUDFrameElement:setBottomBarColor(r, g, b, a)
    self.bottomBar:setColor(r, g, b, a)
end


---Set visibility of left line
function HUDFrameElement:setLeftLineVisible(visible)
    self.leftLine:setVisible(visible)
end


---Set visibility of right line
function HUDFrameElement:setRightLineVisible(visible)
    self.rightLine:setVisible(visible)
end


---Sets color of the frame
function HUDFrameElement:setFrameColor(r, g, b, a)
    self.topLine:setColor(r, g, b, a)
    self.leftLine:setColor(r, g, b, a)
    self.rightLine:setColor(r, g, b, a)
    self.bottomBar:setColor(r, g, b, a)
end
