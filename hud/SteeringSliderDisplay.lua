




























---Vehicle Steering Slider for Mobile Version
local SteeringSliderDisplay_mt = Class(SteeringSliderDisplay, HUDDisplayElement)


---Creates a new SteeringSliderDisplay instance.
-- @param string hudAtlasPath Path to the HUD texture atlas.
function SteeringSliderDisplay.new(hud, hudAtlasPath)
    local backgroundOverlay = SteeringSliderDisplay.createBackground()
    local self = SteeringSliderDisplay:superClass().new(backgroundOverlay, nil, SteeringSliderDisplay_mt)

    self.hud = hud
    self.uiScale = 1.0
    self.hudAtlasPath = hudAtlasPath

    self.vehicle = nil -- currently controlled vehicle
    self.isRideable = false

    self.sliderPosition = 0
    self.restPosition = 0.5
    self.resetTime = 2500

    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    self.lastGyroscopeSteeringState = false

    self:createComponents()

    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.STEERING_BACK_SPEED], self.onSteeringBackSpeedSettingChanged, self)

    return self
end


---
function SteeringSliderDisplay:delete()
    g_messageCenter:unsubscribeAll(self)

    SteeringSliderDisplay:superClass().delete(self)
end


---Set the currently controlled vehicle which provides display data.
-- @param table vehicle Currently controlled vehicle
function SteeringSliderDisplay:setVehicle(vehicle)
    self.vehicle = vehicle

    if vehicle ~= nil then
        self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
        self.sliderHudElement:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER))
    end
end


---Set the reference to the current player.
function SteeringSliderDisplay:setPlayer(player)
    self.player = player

    self:updateVisibilityState()
end


---
function SteeringSliderDisplay:createComponents()
    --background
    local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.BACKGROUND))
    local bgPosX, bgPosY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.POSITION.BACKGROUND))
    local backgroundOverlay = Overlay.new(self.hudAtlasPath, bgPosX, bgPosY, bgSizeX, bgSizeY)
    backgroundOverlay:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.BACKGROUND))
    self.backgroundHudElement = HUDElement.new(backgroundOverlay)
    self:addChild(self.backgroundHudElement)

    -- slider
    self.uvs = GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER)
    self.uvsDisabled = GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER_DISABLED)
    local slSizeX, slSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.SLIDER_SIZE))
    local sliderPosX = bgPosX
    local sliderPosY = bgPosY + (bgSizeY-slSizeY)*0.5
    local sliderOverlay = Overlay.new(self.hudAtlasPath, sliderPosX, sliderPosY, slSizeX, slSizeY)
    sliderOverlay:setUVs(self.uvs)

    self:updateSliderTranslations(1)
    self.sliderHudElement = HUDSliderElement.new(sliderOverlay, backgroundOverlay, {0.12, 0.05}, 1, 10, 1, self.sliderMin, self.sliderCenter, self.sliderMax, nil)
    self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
    self.sliderHudElement:setMoveToCenterSpeedFactor(g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10)

    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.STEERING))
    local iconPosX = sliderPosX + (slSizeX-iconSizeX)*0.5
    local iconPosY = sliderPosY + (slSizeY-iconSizeY)*0.5
    local iconOverlay = Overlay.new(self.hudAtlasPath, iconPosX, iconPosY, iconSizeX, iconSizeY)
    iconOverlay:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.STEERING))
    self.sliderHudElement:addChild(HUDElement.new(iconOverlay))

    self.backgroundHudElement:addChild(self.sliderHudElement)
    self.sliderHudElement:setAxisPosition(self.sliderCenter)
end













---Set this element's visibility with optional animation.
-- @param boolean isVisible True is visible, false is not.
-- @param boolean animate If true, the element will play an animation before applying the visibility change.
function SteeringSliderDisplay:setVisible(isVisible, animate)
    if not isVisible or g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD then
        SteeringSliderDisplay:superClass().setVisible(self, isVisible, animate)
    end
end


---
function SteeringSliderDisplay:onSliderPositionChanged(position)
    self.sliderPosition = math.clamp(position, 0, 1)
end


---
function SteeringSliderDisplay:getSteeringValue()
    -- IN: self.sliderPosition = [0,1]

    local norm = self.sliderPosition * 2 - 1
    -- norm = [-1,1]

    -- no need for squaring if we are in the middle (and prevent from division by zero)
    if norm == 0 then
        return norm
    end

    -- Store sign so we can turn to [-1,1] again after the squaring.
    local sign = norm / math.abs(norm)

    return norm * norm * sign
end


---
function SteeringSliderDisplay:getIsSliderActive()
    if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        return false
    end

    if not Platform.hasTouchSliders then
        return false
    end

    if self.lastGyroscopeSteeringState then
        return false
    end

    if self.vehicle ~= nil and self.vehicle:getIsAIActive() then
        return false
    end

    if self.player ~= nil then
        return false
    end

    return true
end



---
function SteeringSliderDisplay:onInputHelpModeChange(inputHelpMode)
    self.lastInputHelpMode = inputHelpMode

    self:updateVisibilityState()
end


---
function SteeringSliderDisplay:onAIVehicleStateChanged(state, vehicle)
    self:updateVisibilityState()
end


---
function SteeringSliderDisplay:onGyroscopeSteeringChanged(state)
    self.lastGyroscopeSteeringState = state

    self:updateVisibilityState()
end


---
function SteeringSliderDisplay:updateVisibilityState()
    local animationState = self:getIsSliderActive()
    if animationState ~= self.animationState then
        self:setVisible(animationState, true)
        self.sliderHudElement:setTouchIsActive(animationState)
    end
end


---
function SteeringSliderDisplay:onSteeringBackSpeedSettingChanged()
    if self.sliderHudElement ~= nil then
        self.sliderHudElement:setMoveToCenterSpeedFactor(g_gameSettings:getValue(GameSettings.SETTING.STEERING_BACK_SPEED) / 10)
    end
end






---Update the fill levels state.
function SteeringSliderDisplay:update(dt)
    SteeringSliderDisplay:superClass().update(self, dt)

--TODO
--     local guidedTour = g_currentMission.guidedTour
--     local canControl = not g_gui:getIsGuiVisible() and guidedTour:getCanAccessHudButton("steeringSliderDisplay_vehicleSteering")

--     if canControl then
--         self.sliderHudElement:setUVs(self.uvs)
--     else
--         self.sliderHudElement:setUVs(self.uvsDisabled)
--     end

    if not g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) then
        if self.vehicle ~= nil then
            if self.isRideable then
                self.vehicle:setRideableSteer(self:getSteeringValue())
            else
                if self.vehicle.setSteeringInput ~= nil then
                    self.vehicle:setSteeringInput(self:getSteeringValue(), true, InputDevice.CATEGORY.WHEEL)
                end
            end
        end
    end

    if self.sliderHudElement ~= nil then
        self.sliderHudElement:update(dt)
    end
end






---Set this element's scale.
function SteeringSliderDisplay:setScale(uiScale)
    SteeringSliderDisplay:superClass().setScale(self, uiScale, uiScale)

    local currentVisibility = self:getVisible()
    self:setVisible(true, false)

    self.uiScale = uiScale
    local posX, posY = SteeringSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)

    self:updateSliderTranslations(uiScale)
    self.sliderHudElement:setRange(self.sliderMin, self.sliderCenter, self.sliderMax, nil)

    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)
end


---Get the position of the background element, which provides this element's absolute position.
-- @param scale Current UI scale
-- @param float width Scaled background width in pixels
-- @return float X position in screen space
-- @return float Y position in screen space
function SteeringSliderDisplay.getBackgroundPosition(scale, width)
    local offX, offY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.POSITION.BACKGROUND))
    return offX * scale, offY * scale
end






---Create an empty background overlay as a base frame for this element.
function SteeringSliderDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.BACKGROUND))
    local posX, posY = SteeringSliderDisplay.getBackgroundPosition(1, width)
    local overlay = Overlay.new(nil, posX, posY, width, height)
    return overlay -- empty overlay, only used as a positioning frame
end
