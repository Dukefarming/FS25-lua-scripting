



















---SideNotification
-- 
local GamePausedDisplay_mt = Class(GamePausedDisplay, HUDDisplay)


---Create a new GamePausedDisplay.
-- @return table GamePausedDisplay instance
function GamePausedDisplay.new()
    local self = SideNotification:superClass().new(GamePausedDisplay_mt)

    self.syncBackground = Overlay.new("shared/splash.png", 0, 0, 1, g_screenAspectRatio)
    self.pauseText = utf8ToUpper("Pausiert")

    return self
end






---Store scaled positioning, size and offset values.
function GamePausedDisplay:storeScaledValues()
    local posX = 0.5
    local posY = 0.5
    self:setPosition(posX, posY)

    self.width = 1
    self.height = self:scalePixelToScreenHeight(75)

    self.textSize = self:scalePixelToScreenHeight(26)
    self.textOffsetY = self:scalePixelToScreenHeight(28)
end


---Draw the notifications.
function GamePausedDisplay:draw(drawBackground)
    if self:getVisible() then
        GamePausedDisplay:superClass().draw(self)

        if drawBackground then
            self.syncBackground:render()
        end

        local posX, posY = self:getPosition()
        posY = posY-self.height*0.5

        drawFilledRect(0, posY, 1, self.height, 0, 0, 0, 0.8)

        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        setTextColor(1, 1, 1, 1)

        renderText(posX, posY + self.textOffsetY, self.textSize, self.pauseText)

        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
    end
end


---Set a custom text to display.
function GamePausedDisplay:setPauseText(text)
    self.pauseText = utf8ToUpper(text)
end
