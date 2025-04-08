









---HUD player information
local InfoDisplay_mt = Class(InfoDisplay, HUDDisplay)















---Set this element's UI scale factor.
-- @param float uiScale UI scale factor
function InfoDisplay:setScale(uiScale)
    InfoDisplay:superClass().setScale(self, uiScale)

    for _, box in ipairs(self.boxes) do
        box:setScale(uiScale)
    end
end


---Store scaled position and size values.
function InfoDisplay:storeScaledValues()
    self:setPosition(g_hudAnchorRight, g_hudAnchorBottom)

    self.boxMarginY = self:scalePixelToScreenHeight(5)
end














































---
function InfoDisplay:getDisplayHeight()
    if self.isEnabled then
        return self.totalHeight
    else
        return 0
    end
end
