































---Control bar display for Mobile Version
local SwitchVehicleDisplay_mt = Class(SwitchVehicleDisplay, HUDDisplayElement)


---Creates a new SwitchVehicleDisplay instance.
-- @param string hudAtlasPath Path to the HUD texture atlas.
function SwitchVehicleDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
    local backgroundOverlay = SwitchVehicleDisplay.createBackground()
    local self = SwitchVehicleDisplay:superClass().new(backgroundOverlay, nil, SwitchVehicleDisplay_mt)

    self.hud = hud
    self.uiScale = 1.0
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath

    self.vehicle = nil -- currently controlled vehicle
    self.player = nil

    self.touchButtons = {}

    self.hudElements = {}
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    self.lastGyroscopeSteeringState = false

    self.vehicleControls = {}

    self:createComponents()

    return self
end










---Set the currently controlled vehicle which provides display data.
-- @param table vehicle Currently controlled vehicle
function SwitchVehicleDisplay:setVehicle(vehicle)
    self.vehicle = vehicle

    self:updatePositionState()
end


---Set the reference to the current player.
function SwitchVehicleDisplay:setPlayer(player)
    self.player = player

    self:updatePositionState()
end



















































































---Set the currently controlled vehicle which provides display data.
-- @param table vehicle Currently controlled vehicle
function SwitchVehicleDisplay:createComponents()
    local posX, posY = self:getPosition()

    self:createBackgroundElements(posX, posY)

    local iconOffsetX, iconOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.ICON))
    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.ICON))
    local iconOverlay = Overlay.new(self.controlHudAtlasPath, posX+iconOffsetX, posY+iconOffsetY, iconSizeX, iconSizeY)
    iconOverlay:setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ICON))
    self:addChild(HUDElement.new(iconOverlay))

    local glyphSwitchVehicleBackOffsetX, glyphSwitchVehicleBackOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GLYPH_SWITCH_VEHICLE_BACK))
    local glyphElementBack = InputGlyphMobileElement.new(g_inputDisplayManager)
    glyphElementBack:setAction(InputAction.SWITCH_VEHICLE_BACK)
    glyphElementBack:setIsLeftAligned(true)
    glyphElementBack:setPosition(posX + glyphSwitchVehicleBackOffsetX, posY + glyphSwitchVehicleBackOffsetY)
    glyphElementBack:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
    self.glyphElementBack = glyphElementBack
    self:addChild(glyphElementBack)

    local glyphSwitchVehicleOffsetX, glyphSwitchVehicleOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GLYPH_SWITCH_VEHICLE))
    local glyphElement = InputGlyphMobileElement.new(g_inputDisplayManager)
    glyphElement:setAction(InputAction.SWITCH_VEHICLE)
    glyphElement:setPosition(posX + glyphSwitchVehicleOffsetX, posY + glyphSwitchVehicleOffsetY)
    glyphElement:setButtonGlyphColor(HUDButtonElement.COLOR.INPUT_GLYPH)
    self.glyphElement = glyphElement
    self:addChild(glyphElement)

    local arrowLeftSizeX, arrowLeftSizeY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.ARROW_LEFT))
    local arrowLeftOffsetX, arrowLeftOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.ARROW_LEFT))
    local arrowLeftOverlay = Overlay.new(self.controlHudAtlasPath, posX+arrowLeftOffsetX, posY+arrowLeftOffsetY, arrowLeftSizeX, arrowLeftSizeY)
    arrowLeftOverlay:setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ARROW_LEFT))
    self.switchLeftOverlay = arrowLeftOverlay
    self:addChild(HUDElement.new(arrowLeftOverlay))

    local touchOffsetX = {0.1, 0.4}
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowLeftOverlay, touchOffsetX, 0.5, self.onSwitchLeft, self, TouchHandler.TRIGGER_UP))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowLeftOverlay, touchOffsetX, 0.5, self.pressButtonLeftCallback, self, TouchHandler.TRIGGER_DOWN))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowLeftOverlay, touchOffsetX, 0.5, self.releaseButtonCallback, self, TouchHandler.TRIGGER_UP))


    local arrowRightSizeX, arrowRightSizeY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.ARROW_RIGHT))
    local arrowRightOffsetX, arrowRightOffsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.ARROW_RIGHT))
    local arrowRightOverlay = Overlay.new(self.controlHudAtlasPath, posX+arrowRightOffsetX, posY+arrowRightOffsetY, arrowRightSizeX, arrowRightSizeY)
    arrowRightOverlay:setUVs(GuiUtils.getUVs(SwitchVehicleDisplay.UV.ARROW_RIGHT))
    self.switchRightOverlay = arrowRightOverlay
    self:addChild(HUDElement.new(arrowRightOverlay))

    touchOffsetX = {touchOffsetX[2], touchOffsetX[1]}
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowRightOverlay, touchOffsetX, 0.5, self.onSwitchRight, self, TouchHandler.TRIGGER_UP))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowRightOverlay, touchOffsetX, 0.5, self.pressButtonRightCallback, self, TouchHandler.TRIGGER_DOWN))
    table.insert(self.touchButtons, self.hud:addTouchButton(arrowRightOverlay, touchOffsetX, 0.5, self.releaseButtonCallback, self, TouchHandler.TRIGGER_UP))

    local offsetX, offsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GAMEPAD_OFFSET))

    self.positionTouch = {posX+offsetX, posY+offsetY}
    self.positionGamepad = {posX, posY}
end


---
function SwitchVehicleDisplay:onSwitchLeft(x, y, isCancel)
    if g_sleepManager:getIsSleeping() then
        return
    end

    if not self.isActive then
        return
    end

    if not isCancel then
        g_localPlayer:cycleCurrentVehicle(-1)
    end
end


---
function SwitchVehicleDisplay:onSwitchRight(x, y, isCancel)
    if g_sleepManager:getIsSleeping() then
        return
    end

    if not self.isActive then
        return
    end

    if not isCancel then
        g_localPlayer:cycleCurrentVehicle(1)
    end
end





































---
function SwitchVehicleDisplay:updatePositionState(force)
    local isControllerInput = self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD or
                              not Platform.hasTouchSliders or
                              (self.lastGyroscopeSteeringState and self.vehicle ~= nil)

    if isControllerInput then
        self:setPositionState(SwitchVehicleDisplay.STATE_CONTROLLER, force)
    else
        self:setPositionState(SwitchVehicleDisplay.STATE_TOUCH, force)
    end
end


---
function SwitchVehicleDisplay:onInputHelpModeChange(inputHelpMode, force)
    self.lastInputHelpMode = inputHelpMode
    self:updatePositionState(force)
end


---
function SwitchVehicleDisplay:onGyroscopeSteeringChanged(state)
    self.lastGyroscopeSteeringState = state
    self:updatePositionState()
end


---
function SwitchVehicleDisplay:setPositionState(state, force)
    if not Platform.hasTouchSliders then
        return
    end

    if state ~= self.lastPositionState then
        local startX, startY = self:getPosition()

        local targetX = self.positionGamepad[1]
        local targetY = self.positionGamepad[2]
        local speed = SwitchVehicleDisplay.MOVE_ANIMATION_DURATION

        if state == SwitchVehicleDisplay.STATE_TOUCH then
            targetX = self.positionTouch[1]
            targetY = self.positionTouch[2]
            speed = SwitchVehicleDisplay.MOVE_ANIMATION_DURATION / 5
        end

        if force then
            speed = 0.01
        end

        local sequence = TweenSequence.new(self)
        sequence:insertTween(MultiValueTween.new(self.setPosition, {startX, startY}, {targetX, targetY}, speed), 0)
        sequence:start()
        self.animation = sequence

        self.lastPositionState = state
    end
end






---Set this element's scale.
function SwitchVehicleDisplay:setScale(uiScale)
    SwitchVehicleDisplay:superClass().setScale(self, uiScale, uiScale)

    local currentVisibility = self:getVisible()
    self:setVisible(true, false)

    self.uiScale = uiScale
    local posX, posY = SwitchVehicleDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)

    local offsetX, offsetY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.GAMEPAD_OFFSET))
    self.positionTouch = {posX+offsetX*uiScale, posY+offsetY*uiScale}
    self.positionGamepad = {posX, posY}

    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)

    if self.lastPositionState == SwitchVehicleDisplay.STATE_TOUCH then
        self:setPosition(self.positionTouch[1], self.positionTouch[2])
    end
end


---Get the position of the background element, which provides this element's absolute position.
-- @param scale Current UI scale
-- @param float width Scaled background width in pixels
-- @return float X position in screen space
-- @return float Y position in screen space
function SwitchVehicleDisplay.getBackgroundPosition(scale, width)
    local offX, offY = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.POSITION.BACKGROUND))
    return offX * scale, offY * scale
end






---Create an empty background overlay as a base frame for this element.
function SwitchVehicleDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(SwitchVehicleDisplay.SIZE.BACKGROUND))
    local posX, posY = SwitchVehicleDisplay.getBackgroundPosition(1, width)
    return Overlay.new(nil, posX, posY, width, height) -- empty overlay, only used as a positioning frame
end
