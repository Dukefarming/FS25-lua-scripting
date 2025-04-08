























---Vehicle Steering Slider for Mobile Version
local PlayerControlPadDisplay_mt = Class(PlayerControlPadDisplay, HUDDisplayElement)


---Creates a new PlayerControlPadDisplay instance.
-- @param string hudAtlasPath Path to the HUD texture atlas.
function PlayerControlPadDisplay.new(hud, hudAtlasPath)
    local backgroundOverlay = PlayerControlPadDisplay.createBackground()
    local self = PlayerControlPadDisplay:superClass().new(backgroundOverlay, nil, PlayerControlPadDisplay_mt)

    self.hud = hud
    self.uiScale = 1.0
    self.hudAtlasPath = hudAtlasPath

    self.player = nil

    self.joystickPosX = 0.5
    self.joystickPosY = 0.5

    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD

    self:createComponents()

    return self
end


---Set the reference to the current player.
function PlayerControlPadDisplay:setPlayer(player)
    self.player = player

    self:updateVisibilityState()
end


---
function PlayerControlPadDisplay:createComponents()
    local baseX, baseY = self:getPosition()

    --background
    local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.SIZE.BACKGROUND))
    local backgroundOverlay = Overlay.new(self.hudAtlasPath, baseX, baseY, bgSizeX, bgSizeY)
    backgroundOverlay:setUVs(GuiUtils.getUVs(PlayerControlPadDisplay.UV.BACKGROUND))
    self.backgroundHudElement = HUDElement.new(backgroundOverlay)
    self:addChild(self.backgroundHudElement)

    -- joystick
    self.uvs = GuiUtils.getUVs(PlayerControlPadDisplay.UV.JOYSTICK)
    self.uvsDisabled = GuiUtils.getUVs(PlayerControlPadDisplay.UV.JOYSTICK_DISABLED)

    local joySizeX, joySizeY = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.SIZE.JOYSTICK))
    local joystickOverlay = Overlay.new(self.hudAtlasPath, baseX + joySizeX*0.5, baseY + joySizeY*0.5, joySizeX, joySizeY)
    joystickOverlay:setUVs(self.uvs)
    self.joystickElement = HUDElement.new(joystickOverlay)
    self:addChild(self.joystickElement)

    local joystickOverlayX = Overlay.new(nil, baseX + joySizeX*0.5, baseY + joySizeY*0.5, joySizeX, joySizeY)
    local joystickOverlayY = Overlay.new(nil, baseX + joySizeX*0.5, baseY + joySizeY*0.5, joySizeX, joySizeY)

    self.joystickXHudElement = HUDSliderElement.new(joystickOverlayX, backgroundOverlay, 1, 1, 20, 1, 0, 0.5, 1, nil)
    self.joystickXHudElement:setCallback(self.onSliderPositionChangedX, self)
    self.joystickXHudElement.radius = bgSizeX / 2
    self:addChild(self.joystickXHudElement)

    self.joystickYHudElement = HUDSliderElement.new(joystickOverlayY, backgroundOverlay, 1, 1, 20, 2, 0, 0.5, 1, nil)
    self.joystickYHudElement:setCallback(self.onSliderPositionChangedY, self)
    self.joystickYHudElement.radius = bgSizeY / 2
    self:addChild(self.joystickYHudElement)

    self:updateSliderTranslations(1)

    self.joystickXHudElement:setAxisPosition(self.joystickXHudElement.centerTrans)
    self.joystickYHudElement:setAxisPosition(self.joystickYHudElement.centerTrans)
end


























---Set this element's visibility with optional animation.
-- @param boolean isVisible True is visible, false is not.
-- @param boolean animate If true, the element will play an animation before applying the visibility change.
function PlayerControlPadDisplay:setVisible(isVisible, animate)
    if not isVisible or g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD then
        PlayerControlPadDisplay:superClass().setVisible(self, isVisible, animate)
    end
end


---
function PlayerControlPadDisplay:onSliderPositionChangedX(position)
    self.joystickPosX = position * 2 - 1

    local posX, _ = self:updateJoystickPosition()

    self.joystickElement:setPosition(posX, nil)

    return posX
end


---
function PlayerControlPadDisplay:onSliderPositionChangedY(position)
    self.joystickPosY = position * 2 - 1

    local _, posY = self:updateJoystickPosition()

    return posY
end


---
function PlayerControlPadDisplay:updateJoystickPosition()
    local distance = math.sqrt(self.joystickPosX ^ 2 + self.joystickPosY ^ 2)
    if distance > 1 then
        self.joystickPosX = self.joystickPosX / distance

        local posX = self.joystickXHudElement.minTrans + (self.joystickXHudElement.maxTrans - self.joystickXHudElement.minTrans) * (self.joystickPosX / 2 + 0.5)
        self.joystickXHudElement:setAxisPosition(posX, true)

        self.joystickPosY = self.joystickPosY / distance
        local posY = self.joystickYHudElement.minTrans + (self.joystickYHudElement.maxTrans - self.joystickYHudElement.minTrans) * (self.joystickPosY / 2 + 0.5)
        self.joystickYHudElement:setAxisPosition(posY, true)

        return posX, posY
    end

    return nil
end


---
function PlayerControlPadDisplay:onInputHelpModeChange(inputHelpMode)
    self.lastInputHelpMode = inputHelpMode

    self:updateVisibilityState()
end


---
function PlayerControlPadDisplay:updateVisibilityState()
    local animationState = self:getIsPlayerMoveActive()
    if animationState ~= self.animationState then
        self:setVisible(animationState, true)
        self.joystickXHudElement:setTouchIsActive(animationState)
        self.joystickYHudElement:setTouchIsActive(animationState)
    end
end







---Update the fill levels state.
function PlayerControlPadDisplay:update(dt)
    PlayerControlPadDisplay:superClass().update(self, dt)

--TODO
--     local guidedTour = g_currentMission.guidedTour
--     local canControl = not g_gui:getIsGuiVisible() and guidedTour:getCanAccessHudButton("playerControlPadDisplay_playerMove")
    local canControl = true

    if canControl then
        self.joystickElement:setUVs(self.uvs)
    else
        self.joystickElement:setUVs(self.uvsDisabled)
    end

    local posX, _ = self.joystickXHudElement:getPosition()
    local _, posY = self.joystickYHudElement:getPosition()
    self.joystickElement:setPosition(posX, posY)

    if self.player ~= nil then
        if self.joystickXHudElement ~= nil and self.joystickYHudElement ~= nil then
            self.joystickXHudElement:update(dt)
            self.joystickYHudElement:update(dt)
        end

        self.player:onInputMoveSide(nil, self.joystickPosX, nil, nil, false)
        self.player:onInputMoveForward(nil, -self.joystickPosY, nil, nil, false)
    end
end


---
function PlayerControlPadDisplay:onAnimateVisibilityFinished(isVisible)
    PlayerControlPadDisplay:superClass().onAnimateVisibilityFinished(self, isVisible)

    if isVisible then
        self.joystickXHudElement:resetSlider()
        self.joystickYHudElement:resetSlider()
    end
end






















---Set this element's scale.
function PlayerControlPadDisplay:setScale(uiScale)
    PlayerControlPadDisplay:superClass().setScale(self, uiScale, uiScale)

    local currentVisibility = self:getVisible()
    self:setVisible(true, false)

    self.uiScale = uiScale
    local posX, posY = PlayerControlPadDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)
    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)
    self:updateVisibilityState()

    self:updateSliderTranslations(uiScale)
end


---Get the position of the background element, which provides this element's absolute position.
-- @param scale Current UI scale
-- @param float width Scaled background width in pixels
-- @return float X position in screen space
-- @return float Y position in screen space
function PlayerControlPadDisplay.getBackgroundPosition(scale, width)
    local offX, offY = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.POSITION.BACKGROUND))
    return offX * scale, offY * scale
end






---Create an empty background overlay as a base frame for this element.
function PlayerControlPadDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(PlayerControlPadDisplay.SIZE.BACKGROUND))
    local posX, posY = PlayerControlPadDisplay.getBackgroundPosition(1, width)

    local overlay = Overlay.new(nil, posX, posY, width, height) -- empty overlay, only used as a positioning frame
    return overlay
end
