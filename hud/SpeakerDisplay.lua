




















---
local SpeakerDisplay_mt = Class(SpeakerDisplay, HUDDisplay)


---Create a new SpeakerDisplay.
-- @return table SpeakerDisplay instance
function SpeakerDisplay.new(customMt)
    local self = SpeakerDisplay:superClass().new(SpeakerDisplay_mt)

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.rectangle_center", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgLeft = g_overlayManager:createOverlay("gui.rectangle_left", 0, 0, 0, 0)
    self.bgLeft:setColor(r, g, b, a)
    self.bgRight = g_overlayManager:createOverlay("gui.rectangle_right", 0, 0, 0, 0)
    self.bgRight:setColor(r, g, b, a)

    self.iconTalk = g_overlayManager:createOverlay("gui.multiplayer_chatTalk", 0, 0, 0, 0)
    self.iconTalk:setColor(1, 1, 1, 0.5)
    self.iconMuted = g_overlayManager:createOverlay("gui.multiplayer_soundMute", 0, 0, 0, 0)
    self.iconMuted:setColor(1, 1, 1, 0.5)

    self.speakingTimer = {}

    return self
end










---Store scaled positioning, size and offset values.
function SpeakerDisplay:storeScaledValues()
    local offsetX, offsetY = self:scalePixelValuesToScreenVector(0, -300)
    local posX = g_hudAnchorRight + offsetX
    local posY = g_hudAnchorTop + offsetY
    self:setPosition(posX, posY)

    local bgRightWidth, bgHeight = self:scalePixelValuesToScreenVector(10, 25)
    local bgLeftWidth = self:scalePixelToScreenWidth(10)
    self.bgRight:setDimension(bgRightWidth, bgHeight)
    self.bgLeft:setDimension(bgLeftWidth, bgHeight)
    self.bgScale:setDimension(0, bgHeight)

    self.textSize = self:scalePixelToScreenHeight(16)
    self.textOffsetY = self:scalePixelToScreenHeight(6)
    self.speakerOffsetY = self:scalePixelToScreenHeight(6)

    local iconWidth, iconHeight = self:scalePixelValuesToScreenVector(24, 24)
    self.iconTalk:setDimension(iconWidth, iconHeight)
    self.iconMuted:setDimension(iconWidth, iconHeight)

    local iconOffsetX = self:scalePixelToScreenWidth(6)
    self.iconTotalOffsetX = iconWidth + iconOffsetX
end















---Draw the notifications.
function SpeakerDisplay:draw()
    SpeakerDisplay:superClass().draw(self)

    local users = g_currentMission.userManager:getUsers()
    if #users == 0 then
        return
    end

    -- make sure we draw on top of everything because this display is so important for PS technical requirements:
    new2DLayer()

    local posX, posY = self:getPosition()

    setTextBold(true)
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_RIGHT)

    for _, user in ipairs(users) do
        local uuid = user:getUniqueUserId()
        local isSpeakingNow = VoiceChatUtil.getIsSpeakerActive(uuid) and not user:getIsBlocked()

        if isSpeakingNow then
            self.speakingTimer[uuid] = 500
        end

        if self.speakingTimer[uuid] ~= nil then
            local text = utf8ToUpper(user:getNickname())

            posY = posY - self.bgRight.height - self.speakerOffsetY

            local textWidth = getTextWidth(self.textSize, text)
            local scaleWidth = textWidth + self.iconTotalOffsetX
            self.bgRight:setPosition(posX - self.bgRight.width, posY)
            self.bgRight:render()
            self.bgScale:setDimension(scaleWidth, nil)
            self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, posY)
            self.bgScale:render()
            self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, posY)
            self.bgLeft:render()

            local isMuted = user:getVoiceMuted()
            if isMuted then
                self.iconMuted:renderCustom(self.bgRight.x - self.iconTalk.width, self.bgRight.y)
            else
                self.iconTalk:renderCustom(self.bgRight.x - self.iconTalk.width, self.bgRight.y)
            end

            renderText(self.bgRight.x - self.iconTotalOffsetX, self.bgRight.y + self.textOffsetY, self.textSize, text)
        end
    end

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
end
