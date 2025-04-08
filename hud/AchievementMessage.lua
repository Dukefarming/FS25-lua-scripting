




















---
local AchievementMessage_mt = Class(AchievementMessage, HUDDisplay)



---Create a new AchievementMessage.
-- @param any? customMt
-- @return any self
function AchievementMessage.new(customMt)
    local self = AchievementMessage:superClass().new(AchievementMessage_mt)

    self.pendingMessages = {}
    self.currentMessage = nil
    self.showNextFrame = false

    self.headerText = utf8ToUpper(g_i18n:getText("message_achievementUnlocked"))

    self.iconOverlay = Overlay.new(nil, 0, 0, 0, 0)
    self.nextMessageTimer = -1

    return self
end






---Store scaled positioning, size and offset values.
function AchievementMessage:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, 0)
    local posX = 0.5 + offsetX
    local posY = g_hudAnchorBottom + offsetY
    self:setPosition(posX, posY)

    self.width, self.height = self:scalePixelValuesToScreenVector(600, 100)

    posX = posX - self.width * 0.5

    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(90, 90)
    self.iconOffsetX, self.iconOffsetY = self:scalePixelValuesToScreenVector(5, -5)
    self.iconOverlay:setDimension(iconWidth, iconHeight)

    self.titleTextSize = self:scalePixelToScreenHeight(19)
    self.titleTextOffsetX, self.titleTextOffsetY = self:scalePixelValuesToScreenVector(105, -30)

    self.descriptionTextSize = self:scalePixelToScreenHeight(17)
    self.descriptionTextOffsetX, self.descriptionTextOffsetY = self:scalePixelValuesToScreenVector(105, -50)
    self.descriptionTextMaxWidth = self:scalePixelToScreenWidth(490)

    self.textOffsetY = self:scalePixelToScreenHeight(20)
end
