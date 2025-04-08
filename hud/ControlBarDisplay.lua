































---Control bar display for Mobile Version
local ControlBarDisplay_mt = Class(ControlBarDisplay, HUDDisplayElement)


---Creates a new ControlBarDisplay instance.
-- @param string hudAtlasPath Path to the HUD texture atlas.
function ControlBarDisplay.new(hud, hudAtlasPath, controlHudAtlasPath)
    local backgroundOverlay = ControlBarDisplay.createBackground()
    local self = ControlBarDisplay:superClass().new(backgroundOverlay, nil, ControlBarDisplay_mt)

    self.hud = hud
    self.uiScale = 1.0
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath

    self.vehicle = nil -- currently controlled vehicle
    self.lastChildVehicleHash = ""
    self.sowingMachine = nil -- sowing machine if any is attached
    self.player = nil

    self.hudElements = {}
    self.buttons = {}
    self.controlButtons = {}
    self.inputGlyphs = {}
    self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
    self.lastAIState = false
    self.lastGyroscopeSteeringState = false

    self.fillLevelBuffer = {}
    self.fillLevelBufferAddIndex = 0
    self.fillLevelBufferNeedsSorting = false

    self.fillLevelControls = {}

    self.vehicleControls = {}
    self.vehicleControls["attach"] = {
        availableFunc="getShowAttachControlBarAction",
        accessibleFunc="getAttachControlBarActionAccessible",
        actionFunc="detachAttachedImplement",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.DETACH,
        prio=3,
        inputAction = InputAction.ATTACH,
        name="attach",
    }

    self.vehicleControls["turnOn"] = {
        allowedFunc="getAreControlledActionsAllowed",
        availableFunc="getAreControlledActionsAvailable",
        accessibleFunc="getAreControlledActionsAccessible",
        getIconsFunc="getControlledActionIcons",
        actionFunc="playControlledActions",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        directionFunc="getActionControllerDirection",
        controlButton=nil,
        uvs=ControlBarDisplay.UV.TURN_ON,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        prio=4,
        inputAction = InputAction.VEHICLE_ACTION_CONTROL,
        name="turnOn",
    }

    self.vehicleControls["ai"] = {
        availableFunc="getCanToggleAIVehicle",
        accessibleFunc="getShowAIToggleActionEvent",
        actionFunc="toggleAIVehicle",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        directionFunc="getIsAIActive",
        controlButton=nil,
        uvs=ControlBarDisplay.UV.AI,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=5,
        inputAction = InputAction.TOGGLE_AI,
        name = "ai",
    }

    self.vehicleControls["leave"] = {
        availableFunc="getCanLeaveVehicle",
        accessibleFunc="getIsLeavingAllowed",
        actionFunc="doLeaveVehicle",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.LEAVE_VEHICLE,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=6,
        inputAction = InputAction.ENTER,
        name = "leave",
    }

    self.vehicleControls["unloadFork"] = {
        availableFunc="getCanUnloadFork",
        accessibleFunc="getIsForkUnloadingAllowed",
        actionFunc="doUnloadFork",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.UNLOAD_FORK,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=7,
        inputAction = InputAction.UNLOAD_FORK,
        name = "unloadFork",
    }

    self.vehicleControls["leave_horse"] = {
        availableFunc="getCanLeaveRideable",
        accessibleFunc="getIsLeavingAllowed",
        actionFunc="doLeaveVehicle",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.LEAVE_HORSE,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=6,
        inputAction = InputAction.ENTER,
        name = "leave_horse",
    }

    self.playerControls = {}
    self.playerControls["enter_vehicle"] = {
        availableFunc="getCanEnterVehicle",
        actionFunc="onInputEnter",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.ENTER_VEHICLE,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=7,
        inputAction = InputAction.ENTER,
        name = "enter_vehicle",
    }

    self.playerControls["enter_horse"] = {
        availableFunc="getCanEnterRideable",
        actionFunc="onInputEnter",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.ENTER_HORSE,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=8,
        inputAction = InputAction.ENTER,
        name="ride_horse",
    }

    self.playerControls["ride"] = {
        availableFunc="getIsRideStateAvailable",
        actionFunc="activateRideState",
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.ENTER_HORSE,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=9,
        inputAction = InputAction.ENTER,
        name="ride_horse",
    }

    self.customControls = {}
    self.customControls["activateObject"] = {
        availableFunc=self.getIsActivatableObjectAvailable,
        actionFunc=self.triggerActivatableObject,
        triggerType=TouchHandler.TRIGGER_UP,
        fullTapNeeded=true,
        controlButton=nil,
        uvs=ControlBarDisplay.UV.ACTIVATABLE_OBJECT,
        iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
        iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
        prio=7,
        inputAction = InputAction.ACTIVATE_OBJECT,
        name = "activateObject",
    }

    self:createComponents()

    return self
end


---Set the currently controlled vehicle which provides display data.
-- @param table vehicle Currently controlled vehicle
function ControlBarDisplay:createComponents()
    self.buttonStartPos = {getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BUTTON_START))}
    self.buttonOffsetX = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BUTTON_OFFSET))

    self.fillLevelIconSizeX, self.fillLevelIconSizeY = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.FILL_LEVEL_ICON))
    self.fillLevelIconOffsetX, self.fillLevelIconOffsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.FILL_LEVEL_ICON_OFFSET))

    self.hudControls = {}
    table.insert(self.hudControls, self:addFillLevelControl())
    table.insert(self.hudControls, self:addFillLevelControl())

    local iconSizeX, iconSizeY = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.ICON))
    for _, control in pairs(self.vehicleControls) do
        local button = HUDButtonElement.new(self.hud, 0, 0)
        button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
        button:setAction(control.inputAction)

        button.buttonCallback = function()
            if g_sleepManager:getIsSleeping() then
                return
            end

            local vehicle = control.vehicle
            if vehicle ~= nil then
                if control.allowedFunc ~= nil then
                    local allowed, warning = vehicle[control.allowedFunc](vehicle)
                    if not allowed then
                        g_currentMission:showBlinkingWarning(warning, 2500)

                        return
                    end
                end

                vehicle[control.actionFunc](vehicle)
            end
        end
        button:addTouchHandler(button.buttonCallback, self)

        self:addChild(button)
        control.button = button
        table.insert(self.hudControls, control)
    end

    for _, control in pairs(self.playerControls) do
        local button = HUDButtonElement.new(self.hud, 0, 0)
        button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
        button:setAction(control.inputAction)

        button.buttonCallback = function()
            if g_sleepManager:getIsSleeping() then
                return
            end

            local player = self.player
            if player ~= nil then
                player[control.actionFunc](player)
            end
        end
        button:addTouchHandler(button.buttonCallback, self)

        self:addChild(button)
        control.button = button
        table.insert(self.hudControls, control)
    end

    for _, control in pairs(self.customControls) do
        local button = HUDButtonElement.new(self.hud, 0, 0)
        button:setIcon(self.controlHudAtlasPath, iconSizeX, iconSizeY, GuiUtils.getUVs(control.uvs))
        button:setAction(control.inputAction)

        button.buttonCallback = function()
            control.actionFunc()
        end
        button:addTouchHandler(button.buttonCallback, self)

        control.button = button
        self:addChild(button)
        table.insert(self.hudControls, control)
    end

    self.buttons = {}
    self.controlButtons = {}
    self.hudElements = {}

    local posX, posY = self:getPosition()
    local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.GAMEPAD_OFFSET))
    self.positionTouch = {posX+offsetX, posY+offsetY}
    self.positionGamepad = {posX, posY}
end



---Set the currently controlled vehicle which provides display data.
-- @param table vehicle Currently controlled vehicle
function ControlBarDisplay:setVehicle(vehicle)
    self.vehicle = vehicle
    self:updatePositionState()
    self:updateFillLevelBuffers(vehicle)

    self:updateButtons()

    if self.buttonToggleSeeds ~= nil then
        local glyphOverlay = self.buttonToggleSeeds.glyphElement.overlay

        --if sowing machine has only one type of selectable plants, we dont need an input glyph
        glyphOverlay.getIsVisible = function()
            return glyphOverlay.visible and self.sowingMachine ~= nil and #self.sowingMachine.spec_sowingMachine.seeds > 1
        end
    end
end


---Set the reference to the current player.
function ControlBarDisplay:setPlayer(player)
    self.player = player
    self:updatePositionState()
end



---Update the fill levels state.
function ControlBarDisplay:update(dt)
    ControlBarDisplay:superClass().update(self, dt)

    self:updateButtons()
    self:updateButtonPositions()
end

















































































































































---
function ControlBarDisplay:onInputHelpModeChange(inputHelpMode, force)
    self.lastInputHelpMode = inputHelpMode
    self:updatePositionState(force)
end


---
function ControlBarDisplay:onAIVehicleStateChanged(state, vehicle, force)
    self.lastAIState = state
    self:updatePositionState(force)
end


---
function ControlBarDisplay:onGyroscopeSteeringChanged(state)
    self.lastGyroscopeSteeringState = state
    self:updatePositionState()
end













---
function ControlBarDisplay:updatePositionState(force)
    if Platform.hasTouchSliders and self.player ~= nil and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
        self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
        return
    end

    local isControllerInput = not Platform.hasTouchSliders or
                              self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD or
                              self.lastGyroscopeSteeringState

    if isControllerInput then
        self:setPositionState(ControlBarDisplay.STATE_CONTROLLER, force)
    else
        self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
    end
end


---
function ControlBarDisplay:setPositionState(state, force)
    if not Platform.hasTouchSliders then
        return
    end

    if state ~= self.lastPositionState then
        local startX, startY = self:getPosition()
        local targetX = self.positionGamepad[1]
        local targetY = self.positionGamepad[2]

        local speed = ControlBarDisplay.MOVE_ANIMATION_DURATION

        if state == ControlBarDisplay.STATE_TOUCH then
            targetX = self.positionTouch[1]
            targetY = self.positionTouch[2]
            speed = ControlBarDisplay.MOVE_ANIMATION_DURATION / 5
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


---
function ControlBarDisplay:addFillLevelControl()
    local fillLevelControl = {}

    local button = HUDButtonElement.new(self.hud, 0, 0)
    button:setIcon(nil, self.fillLevelIconSizeX, self.fillLevelIconSizeY, Overlay.DEFAULT_UVS, self.fillLevelIconOffsetX, self.fillLevelIconOffsetY)
    button:setAction(InputAction.TOGGLE_SEEDS)
    button:addTouchHandler(ControlBarDisplay.onChangeSeedCallback, fillLevelControl)
    self:addChild(button)

    fillLevelControl.button = button
    fillLevelControl.prio = #self.fillLevelControls + 1
    table.insert(self.fillLevelControls, fillLevelControl)

    -- fill level bar
    local uvs = GuiUtils.getUVs(ControlBarDisplay.UV.FILL_LEVEL_BAR)
    local posX, posY = button:getPosition()
    local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.FILL_LEVEL_BAR_OFFSET))
    local sizeX, sizeY = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.FILL_LEVEL_BAR))
    local backgroundOverlay = Overlay.new(self.hudAtlasPath, posX + offsetX, posY + offsetY, sizeX, sizeY)
    backgroundOverlay:setColor(unpack(ControlBarDisplay.COLOR.FILL_LEVEL_BAR_BACKGROUND))
    backgroundOverlay:setUVs(uvs)
    local fillLevelBarBackground = HUDElement.new(backgroundOverlay)
    button:addChild(fillLevelBarBackground)

    local fillLevelBarOverlay = Overlay.new(self.hudAtlasPath, posX + offsetX, posY + offsetY, sizeX, sizeY)
    local fillLevelBar = HUDElement.new(fillLevelBarOverlay)
    fillLevelBar:setUVs(uvs)
    fillLevelBar:setColor(unpack(ControlBarDisplay.COLOR.FILL_LEVEL_BAR))
    fillLevelBarBackground:addChild(fillLevelBar)
    fillLevelControl.bar = fillLevelBar
    fillLevelControl.defaultUVs = table.clone(uvs)

    return fillLevelControl
end


---Update fill levels data.
function ControlBarDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached)
    local added = false
    for j=1, #self.fillLevelBuffer do
        local fillLevelInformation = self.fillLevelBuffer[j]
        if fillLevelInformation.fillType == fillType then
            fillLevelInformation.fillLevel = fillLevelInformation.fillLevel + fillLevel
            fillLevelInformation.capacity = fillLevelInformation.capacity + capacity
            fillLevelInformation.precision = precision
            fillLevelInformation.maxReached = maxReached

            if self.fillLevelBufferAddIndex ~= fillLevelInformation.addIndex then
                fillLevelInformation.addIndex = self.fillLevelBufferAddIndex
                self.fillLevelBufferNeedsSorting = true
            end

            added = true
            break
        end
    end

    if not added then
        table.insert(self.fillLevelBuffer, {fillType=fillType, fillLevel=fillLevel, capacity=capacity, precision=precision, addIndex=self.fillLevelBufferAddIndex, maxReached=maxReached})
        self.fillLevelBufferNeedsSorting = true
    end

    self.fillLevelBufferAddIndex = self.fillLevelBufferAddIndex + 1
end


---Update fill levels data.
function ControlBarDisplay:updateFillLevelBuffers(vehicle)
    for i=1, #self.fillLevelControls do
        self.fillLevelControls[i].fillLevelPct = 0
        self.fillLevelControls[i].button:setVisible(false)
    end

    if vehicle == nil then
        return
    end

    -- only empty fill level and capacity, so we won't need create the sub tables every frame
    for i=1, #self.fillLevelBuffer do
        self.fillLevelBuffer[i].fillLevel = 0
        self.fillLevelBuffer[i].capacity = 0
    end

    self.fillLevelBufferAddIndex = 0
    self.fillLevelBufferNeedsSorting = false
    vehicle:getFillLevelInformation(self)

    if self.fillLevelBufferNeedsSorting then
        table.sort(self.fillLevelBuffer, ControlBarDisplay.sortFillLevelBuffers)
    end

    self.buttonToggleSeeds = nil
    self.buttonShowFillLevel = nil

    local displayIndex = 0
    for i=1, #self.fillLevelBuffer do
        if self.fillLevelBuffer[i].capacity ~= 0 then
            displayIndex = displayIndex + 1
            local fillLevelControl = self.fillLevelControls[displayIndex]
            if fillLevelControl ~= nil then
                self:updateFillLevelControl(fillLevelControl, self.fillLevelBuffer[i])
            end
        end
    end
end


---Sort buffer
function ControlBarDisplay.sortFillLevelBuffers(a, b)
    return a.addIndex < b.addIndex
end


---
function ControlBarDisplay:updateFillLevelControl(fillLevelControl, fillLevelBuffer)
    local fillLevelPct = fillLevelBuffer.fillLevel / fillLevelBuffer.capacity
    fillLevelControl.fillLevelPct = fillLevelPct

    local bar = fillLevelControl.bar.overlay
    bar.uvs[5] = (fillLevelControl.defaultUVs[5] - fillLevelControl.defaultUVs[1]) * fillLevelPct + fillLevelControl.defaultUVs[1]
    bar.uvs[7] = (fillLevelControl.defaultUVs[7] - fillLevelControl.defaultUVs[3]) * fillLevelPct + fillLevelControl.defaultUVs[3]
    bar:setUVs(bar.uvs)
    bar:setScale(fillLevelPct*self.uiScale, self.uiScale)

    local fillType = g_fillTypeManager:getFillTypeByIndex(fillLevelBuffer.fillType)
    if fillType ~= nil then
        local iconFilename = fillType.hudOverlayFilename
        if iconFilename ~= "" then
            fillLevelControl.button:setIcon(iconFilename)
        end
    end

    fillLevelControl.vehicle = nil
    local button = fillLevelControl.button

    if self.sowingMachine ~= nil then
        local fillTypeIndex = self.sowingMachine:getSowingMachineSeedFillTypeIndex()
        if fillTypeIndex == fillLevelBuffer.fillType then
            fillLevelControl.vehicle = self.sowingMachine
        end
        self.buttonToggleSeeds = button
    else
        self.buttonShowFillLevel = button
    end

    button:setIsActive(fillLevelControl.vehicle ~= nil)
    button:setVisible(fillLevelBuffer.fillLevel > 0 or fillLevelControl.vehicle ~= nil)

-- TODO
--     local guidedTour = g_currentMission.guidedTour
--     local canBeAccessed = self.sowingMachine == nil or guidedTour:getCanChangeSeeds(self.sowingMachine)
--     button:setDisabled(not canBeAccessed)
end



















---Set this element's scale.
function ControlBarDisplay:setScale(uiScale)
    ControlBarDisplay:superClass().setScale(self, uiScale, uiScale)

    local currentVisibility = self:getVisible()
    self:setVisible(true, false)

    self.uiScale = uiScale
    local posX, posY = ControlBarDisplay.getBackgroundPosition(uiScale, self:getWidth())
    self:setPosition(posX, posY)

    local offsetX, offsetY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.GAMEPAD_OFFSET))
    self.positionTouch = {posX+offsetX*uiScale, posY+offsetY*uiScale}
    self.positionGamepad = {posX, posY}

    self:storeOriginalPosition()
    self:setVisible(currentVisibility, false)

    if self.lastPositionState == ControlBarDisplay.STATE_TOUCH then
        self:setPosition(self.positionTouch[1], self.positionTouch[2])
    end
end


---Get the position of the background element, which provides this element's absolute position.
-- @param scale Current UI scale
-- @param float width Scaled background width in pixels
-- @return float X position in screen space
-- @return float Y position in screen space
function ControlBarDisplay.getBackgroundPosition(scale, width)
    local offX, offY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BACKGROUND))
    return offX * scale, offY * scale
end






---Create an empty background overlay as a base frame for this element.
function ControlBarDisplay.createBackground()
    local width, height = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.BACKGROUND))
    local posX, posY = ControlBarDisplay.getBackgroundPosition(1, width)

    local overlay = Overlay.new(nil, posX, posY, width, height) -- empty overlay, only used as a positioning frame
    return overlay
end
