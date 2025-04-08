







---Slider Element
-- Slider for touch devices
-- 
-- Creates a touch area from an overlay which is slideable
-- 
local HUDSliderElement_mt = Class(HUDSliderElement, HUDElement)


---Create a new instance of FrameElement.
-- @param float posX Initial X position in screen space
-- @param float posY Initial Y position in screen space
-- @param float width Frame width in screen space
-- @param float height Frame height in screen space
-- @param table? parent [optional] Parent HUDElement which will receive this frame as its child element
function HUDSliderElement.new(overlay, backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, touchAreaPressedGain, transAxis, minTrans, centerTrans, maxTrans, lockTrans)
    local self = HUDSliderElement:superClass().new(overlay, nil, HUDSliderElement_mt)

    self.position = {overlay.x, overlay.y}
    self.size = {overlay.width, overlay.height}
    self.transAxis = transAxis
    self.minTrans = minTrans
    self.centerTrans = centerTrans
    self.maxTrans = maxTrans
    self.lockTrans = lockTrans
    self.speed = 0.0002

    self.backgroundOverlay = backgroundOverlay
    self.overlay = overlay

    self.moveToCenterPosition = false
    self.moveToCenterSpeedFactor = 1

    self.snapPositions = {}

    self.touchAreaDown = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_DOWN, self.onSliderDown, self)
    self.touchAreaAlways = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_ALWAYS, self.onSliderAlways, self)
    self.touchAreaUp = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_UP, self.onSliderUp, self)

    g_touchHandler:setAreaPressedSizeGain(self.touchAreaDown, touchAreaPressedGain)
    g_touchHandler:setAreaPressedSizeGain(self.touchAreaAlways, touchAreaPressedGain)
    g_touchHandler:setAreaPressedSizeGain(self.touchAreaUp, touchAreaPressedGain)

    return self
end
