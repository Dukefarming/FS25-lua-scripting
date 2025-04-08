


























---
local FillLevelsDisplay_mt = Class(FillLevelsDisplay, HUDDisplay)


---Creates a new FillLevelsDisplay instance.
function FillLevelsDisplay.new()
    local self = FillLevelsDisplay:superClass().new(FillLevelsDisplay_mt)

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.filltypes_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgLeft = g_overlayManager:createOverlay("gui.filltypes_left", 0, 0, 0, 0)
    self.bgLeft:setColor(r, g, b, a)
    self.bgRight = g_overlayManager:createOverlay("gui.filltypes_right", 0, 0, 0, 0)
    self.bgRight:setColor(r, g, b, a)

    -- Icon for showing max weight has been reached
    self.maxWeightIcon = g_overlayManager:createOverlay("gui.vehicleOverview_maxWeight", 0, 0, 0, 0)

    self.bar = ThreePartOverlay.new()
    self.bar:setLeftPart("gui.progressbar_left", 0, 0)
    self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
    self.bar:setRightPart("gui.progressbar_right", 0, 0)

    self.vehicle = nil
    self.fillTypeIcons = {}
    self.fillLevelData = {}

    return self
end
