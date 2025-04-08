



























---Vehicle Speed Slider for Mobile Version
local SpeedSliderDisplay_mt = Class(SpeedSliderDisplay, HUDDisplayElement)














---Creates a new SpeedSliderDisplay instance.
-- @param string hudAtlasPath Path to the HUD texture atlas.
function SpeedSliderDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
    local backgroundOverlay = SpeedSliderDisplay.createBackground()
    local self = SpeedSliderDisplay:superClass().new(backgroundOverlay, nil, SpeedSliderDisplay_mt)

    self.hud = hud
    self.uiScale = 1.0
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath

    self.vehicle = nil -- currently controlled vehicle
    self.player = nil
    self.isRideable = false

    self.sliderPosition = 0
    self.restPosition = 0.25

    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD

    self.sliderState = nil

    self:createComponents()

    g_messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, self.onGuiOpen, self)
    g_messageCenter:subscribe(MessageType.GUI_DIALOG_OPENED, self.onDialogOpened, self)
    g_messageCenter:subscribe(MessageType.GUIDED_TOUR_DIALOG, self.onTourDialog, self)
    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)

    return self
end


---
function SpeedSliderDisplay:delete()
    g_messageCenter:unsubscribeAll(self)

    SpeedSliderDisplay:superClass().delete(self)
end



---
function SpeedSliderDisplay:createComponents()
    local baseX, baseY = self:getPosition()

    --background
    local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
    local backgroundOverlay = Overlay.new(self.hudAtlasPath, baseX, baseY, bgSizeX, bgSizeY)
    backgroundOverlay:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND))
    self.sliderBackgroundElement = HUDElement.new(backgroundOverlay)
    self:addChild(self.sliderBackgroundElement)

    --positive bar
    self.positiveBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.POSITIVE_BAR, SpeedSliderDisplay.SIZE.POSITIVE_BAR, SpeedSliderDisplay.COLOR.POSITIVE_BAR)
    self.sliderBackgroundElement:addChild(self.positiveBarHudElement)

    --positive bar
    self.negativeBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.NEGATIVE_BAR, SpeedSliderDisplay.SIZE.NEGATIVE_BAR, SpeedSliderDisplay.COLOR.NEGATIVE_BAR)
    self.sliderBackgroundElement:addChild(self.negativeBarHudElement)
    self.negativeBarPosX, self.negativeBarPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.NEGATIVE_BAR))
    local _, negativeBarSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.NEGATIVE_BAR))
    self.negativeBarSizeY = negativeBarSizeY

    -- text
    self.textPosX, self.textPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SPEED_TEXT))
    self.textPosGamepadX, self.textPosGamepadY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SPEED_TEXT_GAMEPAD))
    self.textOffsetXkmh, _ = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SPEED_TEXT_GAMEPAD_OFFSET_KMH))
    local _, textSize = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SPEED_TEXT))
    self.textSize = textSize

    -- slider
    self.sliderUVs = GuiUtils.getUVs(SpeedSliderDisplay.UV.SLIDER)
    self.sliderUVsDisabled = GuiUtils.getUVs(SpeedSliderDisplay.UV.SLIDER_DISABLED)
    local slOffX, slOffY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SLIDER_OFFSET))
    local slSizeX, slSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SLIDER_SIZE))
    local sliderOverlay = Overlay.new(self.hudAtlasPath, baseX+slOffX, baseY+slOffY, slSizeX, slSizeY)
    sliderOverlay:setUVs(self.sliderUVs)
    self:updateSliderTranslations(1)

    self.sliderHudElement = HUDSliderElement.new(sliderOverlay, backgroundOverlay, 1.5, 0, 100, 2, self.sliderMin, self.sliderCenter, self.sliderMax, self.sliderMax)
    self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
    self.sliderBackgroundElement:addChild(self.sliderHudElement)

    -- player jump button
    local pljbgPosX, pljbgPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.JUMP_BUTTON))
    local playerJumpIconSizeX, playerJumpIconSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.PLAYER_JUMP_ICON))
    self.playerJumpButtonElement = HUDButtonElement.new(self.hud, baseX + pljbgPosX, baseY + pljbgPosY)
    self.playerJumpButtonElement:setIcon(self.controlHudAtlasPath, playerJumpIconSizeX, playerJumpIconSizeY, GuiUtils.getUVs(SpeedSliderDisplay.UV.JUMP_PLAYER))
    self.playerJumpButtonElement:setAction(InputAction.JUMP)
    self.playerJumpButtonElement:addTouchHandler(self.onJumpEventCallback, self)
    self:addChild(self.playerJumpButtonElement)

    self.horseJumpButtonElement = HUDButtonElement.new(self.hud, baseX + pljbgPosX, baseY + pljbgPosY)
    self.horseJumpButtonElement:setIcon(self.controlHudAtlasPath, playerJumpIconSizeX, playerJumpIconSizeY, GuiUtils.getUVs(SpeedSliderDisplay.UV.JUMP_HORSE))
    self.horseJumpButtonElement:setAction(InputAction.JUMP)
    self.horseJumpButtonElement:addTouchHandler(self.onJumpEventCallback, self)
    self:addChild(self.horseJumpButtonElement)

    --gamepad background
    local gpbgPosX, gpbgPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
    local gpbgSizeX, gpbgSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.GAMEPAD_BACKGROUND))
    local gamepadBackgroundOverlay = Overlay.new(self.hudAtlasPath, baseX + gpbgPosX, baseY + gpbgPosY, gpbgSizeX, gpbgSizeY)
    gamepadBackgroundOverlay:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.GAMEPAD_BACKGROUND))
    self.gamepadBackgroundHudElement = HUDElement.new(gamepadBackgroundOverlay)
    self:addChild(self.gamepadBackgroundHudElement)

    self.sliderHudElement:setAxisPosition(self.sliderCenter)

    self.positionVisible = {baseX, baseY}
    local _, yOffset = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
    self.positionInvisible = {baseX, baseY-yOffset}
end






















---Set silder state
function SpeedSliderDisplay:setSliderState(state)
    if self.sliderState ~= state then
        if state then
            self:showSlider()
        else
            self:hideSlider()
        end
    end
end


---Hide slider and only show speed display
function SpeedSliderDisplay:hideSlider()
    local startX, startY = self:getPosition()

    local sequence = TweenSequence.new(self)
    sequence:insertTween(MultiValueTween.new(self.setPosition, {startX, startY}, self.positionInvisible, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
    sequence:start()

    self.animation = sequence

    self.sliderState = false
    self.sliderHudElement:setTouchIsActive(false)

    self:updateElementsVisibility()
end


---Show slider and speed display
function SpeedSliderDisplay:showSlider()
    local startX, startY = self:getPosition()

    local sequence = TweenSequence.new(self)
    sequence:insertTween(MultiValueTween.new(self.setPosition, {startX, startY}, self.positionVisible, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
    sequence:addCallback(self.onSliderVisibilityChangeFinished, true)
    sequence:start()

    self.animation = sequence

    self.sliderState = true

    self.sliderHudElement:resetSlider()
    self.sliderHudElement:setTouchIsActive(true)
end


---Hide slider and only show speed display
function SpeedSliderDisplay:updateElementsVisibility()
    self.gamepadBackgroundHudElement:setVisible(not self.sliderState and self.player == nil and not (self.vehicle ~= nil and self.isRideable))
    self.sliderBackgroundElement:setVisible(self.sliderState)
end



---Called when the sliders visibility changed
function SpeedSliderDisplay:onSliderVisibilityChangeFinished(visibility)
    if visibility then
        self:updateElementsVisibility()
    end
end


---Set the currently controlled vehicle which provides display data.
-- @param table vehicle Currently controlled vehicle
function SpeedSliderDisplay:setVehicle(vehicle)
    self.vehicle = vehicle

    if vehicle ~= nil then
        self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)

        if self.player ~= nil then
            self:setPlayer(nil)
        end

        self.sliderHudElement:resetSlider()
        self.sliderHudElement:clearSnapPositions()
        if self.isRideable then
            for i=1, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
                self.sliderHudElement:addSnapPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[i])
            end
        end
    end

    if self.isRideable then
        self.sliderBackgroundElement:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND_HORSE))
        local sizeX, sizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND_HORSE))
        self.sliderBackgroundElement:setDimension(sizeX*self.uiScale, sizeY*self.uiScale)
    else
        self.sliderBackgroundElement:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND))
        local sizeX, sizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
        self.sliderBackgroundElement:setDimension(sizeX*self.uiScale, sizeY*self.uiScale)
    end

    self:updateElementsVisibility()
end


---Set the reference to the current player.
function SpeedSliderDisplay:setPlayer(player)
    self.player = player

    if player ~= nil then
        if self.vehicle ~= nil then
            self:setVehicle(nil)
        end
    end

    self:updateVisibilityState()
    self:updateElementsVisibility()
end



























---
function SpeedSliderDisplay:createBar(position, size, color)
    local baseX, baseY = self:getPosition()

    local posX, posY = getNormalizedScreenValues(unpack(position))
    local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
    local barOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, baseX + posX, baseY + posY, sizeX, sizeY)
    barOverlay:setColor(unpack(color))

    return HUDElement.new(barOverlay)
end

---
function SpeedSliderDisplay:onSliderPositionChanged(position)
    self.sliderPosition = math.clamp(position, 0, 1)
    local selfX, selfY = self:getPosition()

    local acc, brake = self:getAccelerateAndBrakeValue()

    self.positiveBarHudElement:setScale(self.uiScale, acc*self.uiScale)
    self.positiveBarHudElement:setColor(unpack(self.cruiseControlIsActive and SpeedSliderDisplay.COLOR.CRUISE_CONTROL or SpeedSliderDisplay.COLOR.POSITIVE_BAR))

    local x = selfX + self.negativeBarPosX*self.uiScale
    local y = selfY + (self.negativeBarPosY + self.negativeBarSizeY*(1-brake))*self.uiScale
    self.negativeBarHudElement:setPosition(x, y)
    self.negativeBarHudElement:setScale(self.uiScale, brake*self.uiScale)

    if self.vehicle ~= nil then
        if self.isRideable then
            for gait=1, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
                if math.abs(position - SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[gait]) < 0.01 then
                    self.vehicle:setCurrentGait(gait)

                    self.lastGait = gait
                    self.lastGaitTime = g_time
                    break
                end
            end
        end
    end
end


---
function SpeedSliderDisplay:getAccelerateAndBrakeValue()
    return math.clamp((self.sliderPosition - self.restPosition) / (1-self.restPosition), 0, 1), 1 - math.clamp(self.sliderPosition / self.restPosition, 0, 1)
end


---
function SpeedSliderDisplay:onJumpEventCallback()
    if g_sleepManager:getIsSleeping() then
        return
    end

    if self.vehicle ~= nil then
        if self.isRideable then
            if self.vehicle:getIsRideableJumpAllowed() then
                self.vehicle:jump()
            end
        end
    end

    if self.player ~= nil then
        self.player:onInputJump(nil, 1)
    end
end






---Update the fill levels state.
function SpeedSliderDisplay:update(dt)
    SpeedSliderDisplay:superClass().update(self, dt)

    self:updateButton()

    if self.sliderHudElement ~= nil then
        self.sliderHudElement:update(dt)
    end

    if self.vehicle ~= nil then
        if self.vehicle.setAccelerationPedalInput ~= nil then
            local acceleration, brake = self:getAccelerateAndBrakeValue()

            local direction = acceleration > 0 and 1 or (brake > 0 and -1 or 0)
            self.vehicle:setTargetSpeedAndDirection(math.abs(acceleration + brake), direction)
        end

        -- reset slider if the gait was changed from rideable due to collisions or user input on pc
        if self.isRideable then
            local currentGait = self.vehicle:getCurrentGait()
            if currentGait ~= self.lastGait then
                if self.lastGaitTime < g_time - 250 then
                    if SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[currentGait] ~= nil then
                        self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[currentGait])
                        self.lastGait = currentGait
                    end
                end
            end
        end
    end
end


---
function SpeedSliderDisplay:getIsSliderActive()
    if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        return false
    end

    if not Platform.hasTouchSliders then
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
function SpeedSliderDisplay:onInputHelpModeChange(inputHelpMode)
    self.lastInputHelpMode = inputHelpMode

    -- reset speed slider if user starts using gamepad
    if inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
        self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * self.restPosition)
    end

    self:updateVisibilityState()
end


---
function SpeedSliderDisplay:onAIVehicleStateChanged(state, vehicle)
    if vehicle == self.vehicle then
        self:updateVisibilityState()
    end
end


---
function SpeedSliderDisplay:updateVisibilityState()
    local sliderState = self:getIsSliderActive()
    if sliderState ~= self.sliderState then
        self:setSliderState(sliderState, true)
    end
end


---
function SpeedSliderDisplay:draw()
    SpeedSliderDisplay:superClass().draw(self)

    if self.vehicle ~= nil and not self.isRideable then
        local speed = MathUtil.round(g_i18n:getSpeed(self.vehicle:getLastSpeed()))
        local baseX, baseY = self:getPosition()
        local width = self:getWidth()

        setTextColor(1, 1, 1, 1)
        setTextBold(true)

        local posX = baseX
        local posY = baseY
        local text
        local useLongSpeedStr = self.vehicle:getIsAIActive() or self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD or not Platform.hasTouchSliders

        if useLongSpeedStr then
            posX = self.gamepadBackgroundHudElement:getPosition()
            width = self.gamepadBackgroundHudElement:getWidth()
            posY = posY + self.textPosGamepadY*self.uiScale
            text = string.format("%02d %s", speed, g_i18n:getSpeedMeasuringUnit())
        else
            posY = posY + self.textPosY*self.uiScale
            text = string.format("%02d", speed)
        end

        setTextAlignment(RenderText.ALIGN_CENTER)
        renderText(posX + width*0.5, posY, self.textSize*self.uiScale, text)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextBold(false)
    end
end











---
function SpeedSliderDisplay:onDialogOpened(guiName, overlappingDialog)
    -- only reset silder if it's a direct dialog, not in a menu since the game is paused there anyway
    if not overlappingDialog then
        self.sliderHudElement:resetSlider()
    end
end


---
function SpeedSliderDisplay:onGuiOpen()
    self.sliderHudElement:resetSlider()
end










---Set this element's scale.
function SpeedSliderDisplay:setScale(uiScale)
    SpeedSliderDisplay:superClass().setScale(self, uiScale, uiScale)

    local currentVisibility = self:getVisible()
    self:setVisible(true, false)

    self.uiScale = uiScale
    local posX, posY = SpeedSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)

    self.positionVisible = {posX, posY}
    local _, yOffset = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
    self.positionInvisible = {posX, posY-yOffset*uiScale}

    self:updateSliderTranslations(uiScale)
    self.sliderHudElement:setRange(self.sliderMin, self.sliderCenter, self.sliderMax, self.sliderMax)

    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)

    if not self:getIsSliderActive() then
        self:setPosition(self.positionInvisible[1], self.positionInvisible[2])
    end
end






---Get the position of the background element, which provides this element's absolute position.
-- @param scale Current UI scale
-- @param float width Scaled background width in pixels
-- @return float X position in screen space
-- @return float Y position in screen space
function SpeedSliderDisplay.getBackgroundPosition(scale, width)
    local offX, offY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.BACKGROUND))

    local posX = 1 + offX * scale
    local posY = offY * scale

    local _, rightInset, _, _ = getSafeFrameInsets()
    local maxPosX = 1 - rightInset - width
    posX = math.min(posX, maxPosX)

    return posX, posY
end






---Create an empty background overlay as a base frame for this element.
function SpeedSliderDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
    local posX, posY = SpeedSliderDisplay.getBackgroundPosition(1, width)

    local overlay = Overlay.new(nil, posX, posY, width, height) -- empty overlay, only used as a positioning frame
    return overlay
end
