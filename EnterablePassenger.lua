





















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function EnterablePassenger.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Enterable, specializations)
end


---
function EnterablePassenger.initSpecialization()
    Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER = Vehicle.registerInteractionFlag("ENTERABLE_PASSENGER")

    g_vehicleConfigurationManager:addConfigurationType("enterablePassenger", g_i18n:getText("shop_configuration"), "enterable", VehicleConfigurationItem)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("EnterablePassenger")

    EnterablePassenger.registerXMLPaths("vehicle.enterable.passengerSeats", schema)
    EnterablePassenger.registerXMLPaths("vehicle.enterable.enterablePassengerConfigurations.enterablePassengerConfiguration(?)", schema)

    schema:setXMLSpecializationType()
end


---
function EnterablePassenger.registerXMLPaths(basePath, schema)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".passengerSeat(?)#node", "Seat reference node to calculate entering distance to")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".passengerSeat(?)#exitPoint", "Player spawn point when leaving the vehicle")
    schema:register(XMLValueType.INT, basePath .. ".passengerSeat(?)#outdoorCameraIndex", "Index of regular outdoor camera if it should be available as well")
    schema:register(XMLValueType.FLOAT, basePath .. ".passengerSeat(?)#nicknameOffset", "Nickname rendering offset", 1.5)

    VehicleCamera.registerCameraXMLPaths(schema, basePath .. ".passengerSeat(?).camera(?)")
    VehicleCharacter.registerCharacterXMLPaths(schema, basePath .. ".passengerSeat(?).characterNode")
end


---
function EnterablePassenger.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getClosestSeatIndex", EnterablePassenger.getClosestSeatIndex)
    SpecializationUtil.registerFunction(vehicleType, "getIsPassengerSeatAvailable", EnterablePassenger.getIsPassengerSeatAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getIsPassengerSeatIndexAvailable", EnterablePassenger.getIsPassengerSeatIndexAvailable)
    SpecializationUtil.registerFunction(vehicleType, "getFirstAvailablePassengerSeat", EnterablePassenger.getFirstAvailablePassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "getPlayerNameBySeatIndex", EnterablePassenger.getPlayerNameBySeatIndex)
    SpecializationUtil.registerFunction(vehicleType, "getCanUsePassengerSeats", EnterablePassenger.getCanUsePassengerSeats)
    SpecializationUtil.registerFunction(vehicleType, "enterVehiclePassengerSeat", EnterablePassenger.enterVehiclePassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "leaveLocalPassengerSeat", EnterablePassenger.leaveLocalPassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "leavePassengerSeat", EnterablePassenger.leavePassengerSeat)
    SpecializationUtil.registerFunction(vehicleType, "getPassengerSeatIndexByPlayer", EnterablePassenger.getPassengerSeatIndexByPlayer)
    SpecializationUtil.registerFunction(vehicleType, "copyEnterableActiveCameraIndex", EnterablePassenger.copyEnterableActiveCameraIndex)
    SpecializationUtil.registerFunction(vehicleType, "setPassengerActiveCameraIndex", EnterablePassenger.setPassengerActiveCameraIndex)
    SpecializationUtil.registerFunction(vehicleType, "enablePassengerActiveCamera", EnterablePassenger.enablePassengerActiveCamera)
    SpecializationUtil.registerFunction(vehicleType, "setPassengerSeatCharacter", EnterablePassenger.setPassengerSeatCharacter)
    SpecializationUtil.registerFunction(vehicleType, "updatePassengerSeatCharacter", EnterablePassenger.updatePassengerSeatCharacter)
    SpecializationUtil.registerFunction(vehicleType, "onPassengerPlayerStyleChanged", EnterablePassenger.onPassengerPlayerStyleChanged)
end


---
function EnterablePassenger.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInteractionHelp", EnterablePassenger.getInteractionHelp)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "interact", EnterablePassenger.interact)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDistanceToNode", EnterablePassenger.getDistanceToNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", EnterablePassenger.getIsEnterable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getExitNode", EnterablePassenger.getExitNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", EnterablePassenger.getIsInUse)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", EnterablePassenger.getDeactivateOnLeave)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInteractive", EnterablePassenger.getIsInteractive)
end


---
function EnterablePassenger.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onDrawUIInfo", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onPreRegisterActionEvents", EnterablePassenger)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", EnterablePassenger)
end


---
function EnterablePassenger:onLoad(savegame)
    local spec = self.spec_enterablePassenger

    spec.currentSeatIndex = 1 -- local used seat index when we are entered
    spec.passengerEntered = false -- local client is entered as passenger

    local baseKey = "vehicle.enterable.passengerSeats"

    local configIndex = self.configurations["enterablePassenger"]
    if configIndex ~= nil then
        local configKey = string.format("vehicle.enterable.enterablePassengerConfigurations.enterablePassengerConfiguration(%d)", configIndex - 1)
        if self.xmlFile:hasProperty(configKey) then
            baseKey = configKey
        end
    end

    spec.passengerSeats = {}
    for _, key in self.xmlFile:iterator(baseKey .. ".passengerSeat") do
        local seatEntry = {}
        seatEntry.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        seatEntry.exitPoint = self.xmlFile:getValue(key .. "#exitPoint", nil, self.components, self.i3dMappings)
        if seatEntry.node ~= nil then
            seatEntry.cameras = {}
            seatEntry.camIndex = 1

            local outdoorCameraIndex = self.xmlFile:getValue(key .. "#outdoorCameraIndex")
            if outdoorCameraIndex ~= nil then
                local specEnterable = self.spec_enterable
                if specEnterable.cameras ~= nil and specEnterable.cameras[outdoorCameraIndex] ~= nil then
                    table.insert(seatEntry.cameras, specEnterable.cameras[outdoorCameraIndex])
                end
            end

            self.xmlFile:iterate(key .. ".camera", function(index, cameraKey)
                local camera = VehicleCamera.new(self)
                if camera:loadFromXML(self.xmlFile, cameraKey, nil, index) then
                    camera.isPassengerCamera = true
                    table.insert(seatEntry.cameras, camera)
                end
            end)

            seatEntry.nicknameOffset = self.xmlFile:getValue(key .. "#nicknameOffset", 1.5)

            seatEntry.vehicleCharacter = VehicleCharacter.new(self)
            if seatEntry.vehicleCharacter ~= nil and not seatEntry.vehicleCharacter:load(self.xmlFile, key .. ".characterNode") then
                seatEntry.vehicleCharacter = nil
            end

            seatEntry.isUsed = false
            seatEntry.playerStyle = nil
            seatEntry.userId = nil

            table.insert(spec.passengerSeats, seatEntry)
        else
            Logging.xmlWarning(self.xmlFile, "Missing node for '%s'", key)
        end
    end

    spec.available = #spec.passengerSeats > 0 and g_currentMission.missionDynamicInfo.isMultiplayer

    spec.texts = {}
    spec.texts.enterVehicleDriver = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_driver"))
    spec.texts.enterVehiclePassenger = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_passenger"))
    spec.texts.switchSeatDriver = g_i18n:getText("passengerSeat_switchSeatDriver")
    spec.texts.switchSeatPassenger = g_i18n:getText("passengerSeat_switchSeatPassenger")
    spec.texts.switchNextSeat = g_i18n:getText("passengerSeat_switchNextSeat")

    spec.minEnterDistance = 3

    if spec.available then
        g_messageCenter:subscribe(MessageType.PLAYER_STYLE_CHANGED, self.onPassengerPlayerStyleChanged, self)
    end
end


---
function EnterablePassenger:onDelete()
    self:leaveLocalPassengerSeat(true)

    local spec = self.spec_enterablePassenger
    if spec.passengerSeats ~= nil then
        for seatIndex=1, #spec.passengerSeats do
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat.isUsed then
                self:leavePassengerSeat(false, seatIndex)
            end

            for _, camera in ipairs(passengerSeat.cameras) do
                if camera.isPassengerCamera then
                    camera:delete()
                end
            end

            if passengerSeat.vehicleCharacter ~= nil then
                passengerSeat.vehicleCharacter:delete()
            end
        end
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassenger:onReadStream(streamId, connection)
    local spec = self.spec_enterablePassenger
    for seatIndex=1, #spec.passengerSeats do
        if streamReadBool(streamId) then
            local userId = User.streamReadUserId(streamId)
            local player = g_playerSystem:getPlayerByUserId(userId)
            if player ~= nil then
                player:onEnterVehicleAsPassenger(self, seatIndex)
            end
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassenger:onWriteStream(streamId, connection)
    local spec = self.spec_enterablePassenger
    for seatIndex=1, #spec.passengerSeats do
        local passengerSeat = spec.passengerSeats[seatIndex]
        if streamWriteBool(streamId, passengerSeat.isUsed) then
            User.streamWriteUserId(streamId, passengerSeat.userId)
        end
    end
end


---
function EnterablePassenger:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_enterablePassenger
    if spec.available then
        if self.isClient then
            local specEnterable = self.spec_enterable
            if specEnterable.activeCamera ~= nil then
                specEnterable.activeCamera:update(dt)
            end

            EnterablePassenger.updateActionEvents(self)

            if spec.passengerEntered then
                self:raiseActive()
            end

            self:updatePassengerSeatCharacter(dt)
        end
    end
end


---Called on ui info draw, renders nicknames in multiplayer
function EnterablePassenger:onDrawUIInfo()
    local spec = self.spec_enterablePassenger
    if spec.available then
        local visible = not g_gui:getIsGuiVisible() and not g_noHudModeEnabled and g_gameSettings:getValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES)
        if self.isClient and visible then
            for seatIndex=1, #spec.passengerSeats do
                local passengerSeat = spec.passengerSeats[seatIndex]
                if passengerSeat.isUsed and (not spec.passengerEntered or seatIndex ~= spec.currentSeatIndex) then
                    local distance = calcDistanceFrom(passengerSeat.node, getCamera())
                    if distance < 100 then
                        local x, y, z = getWorldTranslation(passengerSeat.node)
                        y = y + passengerSeat.nicknameOffset

                        Utils.renderTextAtWorldPosition(x, y, z, self:getPlayerNameBySeatIndex(seatIndex), getCorrectTextSize(0.02), 0)
                    end
                end
            end
        end
    end
end


---
function EnterablePassenger:onSetBroken()
    local spec = self.spec_enterablePassenger
    if spec.passengerEntered then
        g_localPlayer:leaveVehicle()
    end
end


---
function EnterablePassenger:onEnterVehicle()
    if EnterablePassenger.DEBUG_ACTIVE then
        local spec = self.spec_enterablePassenger
        for seatIndex=1, #spec.passengerSeats do
            self:setPassengerSeatCharacter(seatIndex, self:getUserPlayerStyle())
        end
    end
end


---
function EnterablePassenger:onLeaveVehicle()
    if EnterablePassenger.DEBUG_ACTIVE then
        local spec = self.spec_enterablePassenger
        for seatIndex=1, #spec.passengerSeats do
            self:setPassengerSeatCharacter(seatIndex, nil)
        end
    end
end


---Returns interaction help text
-- @return string text text
function EnterablePassenger:getInteractionHelp(superFunc)
    local spec = self.spec_enterablePassenger
    if spec.available then
        if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER then
            return self.spec_enterablePassenger.texts.enterVehiclePassenger
        end
    end

    return superFunc(self)
end


---Interact
function EnterablePassenger:interact(superFunc, player)
    if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER then
        local seatIndex = self:getClosestSeatIndex(player.rootNode)
        player:requestToEnterVehicleAsPassenger(self, seatIndex)
    else
        superFunc(self, player)
    end
end














---Returns distance between given object and enterReferenceNode
-- @param integer object id of object
-- @return float distance distance
function EnterablePassenger:getDistanceToNode(superFunc, node)
    local superDistance = superFunc(self, node)

    -- only check for passenger if a player is already driving. otherwise enter as driver
    if self:getIsControlled() then
        local seatIndex, distance = self:getClosestSeatIndex(node)
        if seatIndex ~= nil and distance < superDistance then
            self.interactionFlag = Vehicle.INTERACTION_FLAG_ENTERABLE_PASSENGER
            return distance
        end
    end

    return superDistance
end


---
function EnterablePassenger:getIsEnterable(superFunc)
    local spec = self.spec_enterablePassenger
    if spec.available then
        return not self:getCanUsePassengerSeats() and superFunc(self)
    end

    return superFunc(self)
end


---
function EnterablePassenger:getExitNode(superFunc, player)
    local spec = self.spec_enterablePassenger
    if spec.available then
        for seatIndex=1, #spec.passengerSeats do
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat.userId == player.userId then
                return passengerSeat.exitPoint
            end
        end
    end

    return superFunc(self, player)
end


---
function EnterablePassenger:getIsInUse(superFunc, connection)
    local spec = self.spec_enterablePassenger
    if spec.available then
        for seatIndex=1, #spec.passengerSeats do
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat.isUsed then
                return true
            end
        end
    end

    return superFunc(self, connection)
end


---
function EnterablePassenger:getDeactivateOnLeave(superFunc, connection)
    local spec = self.spec_enterablePassenger
    if spec.available then
        for seatIndex=1, #spec.passengerSeats do
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat.isUsed then
                return false
            end
        end
    end

    return superFunc(self, connection)
end


---
function EnterablePassenger:onPreRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    local spec = self.spec_enterablePassenger
    if spec.available then
        -- clear the events before the Enterable action events are registered, otherwise we remove them directly again
        self:clearActionEventsTable(spec.actionEvents)
    end
end


---
function EnterablePassenger:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    local spec = self.spec_enterablePassenger
    if spec.available then
        if spec.passengerEntered then
            g_localPlayer.inputComponent:registerGlobalPlayerActionEvents(Vehicle.INPUT_CONTEXT_NAME)

            local actionEventId, _
            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ENTER, self, EnterablePassenger.actionEventLeave, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

            local currentSeat = spec.passengerSeats[spec.currentSeatIndex]
            if currentSeat ~= nil and #currentSeat.cameras > 0 then
                _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CAMERA_SWITCH, self, EnterablePassenger.actionEventCameraSwitch, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
                g_inputBinding:setActionEventTextVisibility(actionEventId, true)
            end

            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CAMERA_ZOOM_IN_OUT, self, Enterable.actionEventCameraZoomInOut, false, true, true, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SWITCH_SEAT, self, EnterablePassenger.actionEventSwitchSeat, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        else
            if self:getIsEntered() then
                if self:getIsActiveForInput(true, true) then
                    local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SWITCH_SEAT, self, EnterablePassenger.actionEventSwitchSeat, false, true, false, true, nil)
                    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)


                end
            end
        end

        EnterablePassenger.updateActionEvents(self)
    end
end


---
function EnterablePassenger.actionEventLeave(self, actionName, inputValue, callbackState, isAnalog, isMouse)
    local spec = self.spec_enterablePassenger
    if spec.passengerEntered then
        g_localPlayer:leaveVehicle()
    end
end


---
function EnterablePassenger.actionEventCameraSwitch(self, actionName, inputValue, callbackState, isAnalog, isMouse)
    local spec = self.spec_enterablePassenger
    if spec.passengerEntered then
        self:setPassengerActiveCameraIndex()
    end
end


---
function EnterablePassenger.actionEventSwitchSeat(self, actionName, inputValue, callbackState, isAnalog, isMouse)
    local spec = self.spec_enterablePassenger

    if spec.passengerEntered then
        local nextSeatIndex = self:getFirstAvailablePassengerSeat(spec.currentSeatIndex)
        if nextSeatIndex ~= nil then
            self:copyEnterableActiveCameraIndex(nextSeatIndex)
            g_localPlayer:requestToEnterVehicleAsPassenger(self, nextSeatIndex)
            return
        else
            if not self:getIsControlled() and g_currentMission.accessHandler:canPlayerAccess(self) then
                self:copyEnterableActiveCameraIndex()
                g_localPlayer:requestToEnterVehicle(self)
                return
            end
        end
    end

    -- fallback
    local seatIndex = self:getFirstAvailablePassengerSeat()
    if seatIndex ~= nil then
        self:copyEnterableActiveCameraIndex(seatIndex)
        g_localPlayer:requestToEnterVehicleAsPassenger(self, seatIndex)
    end
end


---
function EnterablePassenger.updateActionEvents(self)
    local spec = self.spec_enterablePassenger
    local switchSeatEvent = spec.actionEvents[InputAction.SWITCH_SEAT]
    if switchSeatEvent ~= nil then
        local isActive = false
        if spec.passengerEntered then
            local nextSeatIndex = self:getFirstAvailablePassengerSeat(spec.currentSeatIndex)
            if nextSeatIndex ~= nil then
                g_inputBinding:setActionEventText(switchSeatEvent.actionEventId, spec.texts.switchNextSeat)
                isActive = true
            else
                if not self:getIsControlled() then
                    if g_currentMission.accessHandler:canPlayerAccess(self) then
                        g_inputBinding:setActionEventText(switchSeatEvent.actionEventId, spec.texts.switchSeatDriver)
                        isActive = true
                    end
                end
            end
        end

        if not isActive then
            local seatIndex = self:getFirstAvailablePassengerSeat()
            if seatIndex ~= nil then
                g_inputBinding:setActionEventText(switchSeatEvent.actionEventId, spec.texts.switchSeatPassenger)
                isActive = true
            end
        end

        g_inputBinding:setActionEventActive(switchSeatEvent.actionEventId, isActive)
    end
end


---
function EnterablePassenger:getClosestSeatIndex(playerNode)
    local spec = self.spec_enterablePassenger

    local minDistance = math.huge
    local minIndex = nil

    for i=1, #spec.passengerSeats do
        local passengerSeat = spec.passengerSeats[i]
        if self:getIsPassengerSeatAvailable(passengerSeat) then
            local distance = calcDistanceFrom(playerNode, passengerSeat.node)
            if distance < spec.minEnterDistance and distance < minDistance then
                minDistance = distance
                minIndex = i
            end
        end
    end

    return minIndex, minDistance
end


---
function EnterablePassenger:getIsPassengerSeatAvailable(passengerSeat)
    return not passengerSeat.isUsed
end


---
function EnterablePassenger:getIsPassengerSeatIndexAvailable(seatIndex)
    local spec = self.spec_enterablePassenger
    local passengerSeat = spec.passengerSeats[seatIndex]
    if passengerSeat ~= nil then
        return self:getIsPassengerSeatAvailable(passengerSeat)
    end

    return false
end


---
function EnterablePassenger:getFirstAvailablePassengerSeat(startIndex)
    local spec = self.spec_enterablePassenger
    for i=(startIndex or 1), #spec.passengerSeats do
        local passengerSeat = spec.passengerSeats[i]
        if self:getIsPassengerSeatAvailable(passengerSeat) then
            return i
        end
    end

    return nil
end


---
function EnterablePassenger:getPlayerNameBySeatIndex(seatIndex)
    local spec = self.spec_enterablePassenger
    local passengerSeat = spec.passengerSeats[seatIndex]
    if passengerSeat ~= nil then
        local user = g_currentMission.userManager:getUserByUserId(passengerSeat.userId)
        if user ~= nil then
            return user:getNickname()
        end
    end

    return ""
end


---
function EnterablePassenger:getCanUsePassengerSeats()
    if self.isBroken then
        return false
    end

    -- first enter always the driver seat
    if self:getIsControlled() then
        return true
    end

    -- if we don't own the vehicle we can only use the passenger seat
    if not g_currentMission.accessHandler:canPlayerAccess(self) then
        return true
    end

    return false
end


---
function EnterablePassenger:enterVehiclePassengerSeat(isOwner, seatIndex, playerStyle, userId)
    local spec = self.spec_enterablePassenger

    if isOwner then
        if spec.passengerEntered then
            self:leaveLocalPassengerSeat(true)
        end

        spec.currentSeatIndex = seatIndex
        spec.passengerEntered = true

        self:enablePassengerActiveCamera()
        self:setPassengerSeatCharacter(seatIndex, playerStyle)

        if self.spec_enterable.playerHotspot ~= nil then
            self.spec_enterable.playerHotspot:setOwnerFarmId(g_currentMission:getFarmId())
            g_currentMission:addMapHotspot(self.spec_enterable.playerHotspot)
        end

        -- activate actionEvents
        if self.isClient then
            g_messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.requestActionEventUpdate, self)
            self:requestActionEventUpdate()
        end
    else
        for index, seat in ipairs(spec.passengerSeats) do
            if seat.isUsed and seat.userId == userId then
                self:leavePassengerSeat(false, index)
                break
            end
        end

        self:setPassengerSeatCharacter(seatIndex, playerStyle)
    end

    local isEmpty = true
    for i=1, #spec.passengerSeats do
        if spec.passengerSeats[i].isUsed then
            isEmpty = false
            break
        end
    end

    if isEmpty and not self:getIsControlled() then
        self:activate()
    end

    local currentSeat = spec.passengerSeats[seatIndex]
    if currentSeat ~= nil then
        currentSeat.isUsed = true
        currentSeat.playerStyle = playerStyle
        currentSeat.userId = userId
    end
end


---
function EnterablePassenger:leaveLocalPassengerSeat(noEventSend)
    local spec = self.spec_enterablePassenger
    if spec.passengerEntered then
        if noEventSend ~= true then
            g_client:getServerConnection():sendEvent(EnterablePassengerLeaveEvent.new(self, g_localPlayer.userId))
        end

        self:leavePassengerSeat(true, spec.currentSeatIndex)
    end
end


---
function EnterablePassenger:leavePassengerSeat(isOwner, seatIndex)
    local spec = self.spec_enterablePassenger

    if isOwner then
        local specEnterable = self.spec_enterable
        if specEnterable.activeCamera ~= nil and spec.passengerEntered then
            specEnterable.activeCamera:onDeactivate()
            g_soundManager:setIsIndoor(false)
            g_currentMission.ambientSoundSystem:setIsIndoor(false)
            g_currentMission.environment.environmentMaskSystem:setIsIndoor(false)
            g_currentMission.activatableObjectsSystem:deactivate(Vehicle.INPUT_CONTEXT_NAME)
            specEnterable.activeCamera = nil
        end

        self:setMirrorVisible(false)
        self:setPassengerSeatCharacter(seatIndex, nil)

        spec.currentSeatIndex = 1
        spec.passengerEntered = false

        if self.spec_enterable.playerHotspot ~= nil then
            g_currentMission:removeMapHotspot(self.spec_enterable.playerHotspot)
        end

        -- deactivate actionEvents
        if self.isClient then
            g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self)
            self:requestActionEventUpdate()

            if g_touchHandler ~= nil then
                g_touchHandler:removeGestureListener(self.touchListenerDoubleTab)
            end
        end
    else
        self:setPassengerSeatCharacter(seatIndex, nil)
    end

    local currentSeat = spec.passengerSeats[seatIndex]
    if currentSeat ~= nil then
        currentSeat.isUsed = false
        currentSeat.playerStyle = nil
        currentSeat.userId = nil
    end

    if not self:getIsControlled() then
        local isEmpty = true
        for i=1, #spec.passengerSeats do
            if spec.passengerSeats[i].isUsed then
                isEmpty = false
                break
            end
        end

        if isEmpty then
            self:deactivate()
        end
    end
end


---
function EnterablePassenger:getPassengerSeatIndexByPlayer(userId)
    local spec = self.spec_enterablePassenger
    for i=1, #spec.passengerSeats do
        if spec.passengerSeats[i].userId == userId then
            return i
        end
    end

    return nil
end


---
function EnterablePassenger:copyEnterableActiveCameraIndex(seatIndex)
    local spec = self.spec_enterablePassenger
    local specEnterable = self.spec_enterable

    -- try to find the same camera used in the passenger/enterable seat
    -- if not found we use the first camera with the same isInside flag set
    if specEnterable.activeCamera ~= nil then
        if seatIndex ~= nil then
            -- copy enterable camera index to passenger seat
            local passengerSeat = spec.passengerSeats[seatIndex]
            if passengerSeat ~= nil then
                local foundCamera = false
                for camIndex=1, #passengerSeat.cameras do
                    local camera = passengerSeat.cameras[camIndex]
                    if camera == specEnterable.activeCamera then
                        passengerSeat.camIndex = camIndex
                        foundCamera = true
                    end
                end

                if not foundCamera then
                    for camIndex=1, #passengerSeat.cameras do
                        local camera = passengerSeat.cameras[camIndex]
                        if camera.isInside == specEnterable.activeCamera.isInside then
                            passengerSeat.camIndex = camIndex
                            break
                        end
                    end
                end
            end
        else
            -- copy passenger camera index to enterable camera
            local passengerSeat = spec.passengerSeats[spec.currentSeatIndex]
            if passengerSeat ~= nil then
                local foundCamera = false
                for camIndex=1, #specEnterable.cameras do
                    local camera = specEnterable.cameras[camIndex]
                    if camera == specEnterable.activeCamera then
                        specEnterable.camIndex = camIndex
                        foundCamera = true
                    end
                end

                if not foundCamera then
                    for camIndex=1, #specEnterable.cameras do
                        local camera = specEnterable.cameras[camIndex]
                        if camera.isInside == specEnterable.activeCamera.isInside then
                            specEnterable.camIndex = camIndex
                            break
                        end
                    end
                end
            end
        end
    end
end


---
function EnterablePassenger:setPassengerActiveCameraIndex(cameraIndex, seatIndex)
    local spec = self.spec_enterablePassenger
    local currentSeat = spec.passengerSeats[seatIndex or spec.currentSeatIndex]
    if currentSeat ~= nil then
        currentSeat.camIndex = cameraIndex or (currentSeat.camIndex + 1)
        if currentSeat.camIndex > #currentSeat.cameras then
            currentSeat.camIndex = 1
        end
    end

    self:enablePassengerActiveCamera()
end


---
function EnterablePassenger:enablePassengerActiveCamera()
    local spec = self.spec_enterablePassenger
    local specEnterable = self.spec_enterable
    if specEnterable.activeCamera ~= nil then
        specEnterable.activeCamera:onDeactivate()
    end

    local currentSeat = spec.passengerSeats[spec.currentSeatIndex]
    if currentSeat ~= nil then
        local activeCamera = currentSeat.cameras[currentSeat.camIndex]

        specEnterable.activeCamera = activeCamera
        specEnterable.activeCamera:onActivate()

        self:setMirrorVisible(activeCamera.useMirror)

        g_currentMission.environmentAreaSystem:setReferenceNode(activeCamera.cameraNode)
    end

    self:updatePassengerSeatCharacter(99999)

    self:raiseActive()
end


---
function EnterablePassenger:setPassengerSeatCharacter(seatIndex, playerStyle)
    local spec = self.spec_enterablePassenger
    local currentSeat = spec.passengerSeats[seatIndex]
    if currentSeat ~= nil then
        if currentSeat.vehicleCharacter ~= nil then
            currentSeat.vehicleCharacter:unloadCharacter()

            if playerStyle ~= nil then
                currentSeat.vehicleCharacter:loadCharacter(playerStyle, self, EnterablePassenger.vehiclePassengerCharacterLoaded, {currentSeat})
            end
        end
    end
end


---
function EnterablePassenger:updatePassengerSeatCharacter(dt)
    local spec = self.spec_enterablePassenger
    for _, seat in ipairs(spec.passengerSeats) do
        if seat.isUsed and seat.vehicleCharacter ~= nil then
            seat.vehicleCharacter:updateVisibility()
            seat.vehicleCharacter:update(dt)
        end
    end
end


---
function EnterablePassenger:onPassengerPlayerStyleChanged(style, userId)
    local spec = self.spec_enterablePassenger
    for seatIndex=1, #spec.passengerSeats do
        local passengerSeat = spec.passengerSeats[seatIndex]
        if passengerSeat.userId == userId then
            self:setPassengerSeatCharacter(seatIndex, style)
        end
    end
end


---
function EnterablePassenger.vehiclePassengerCharacterLoaded(self, loadingState, arguments)
    if loadingState == HumanModelLoadingState.OK then
        local currentSeat = arguments[1]
        if currentSeat ~= nil then
            currentSeat.vehicleCharacter:updateVisibility()
            currentSeat.vehicleCharacter:updateIKChains()

            if EnterablePassenger.DEBUG_ACTIVE then
                currentSeat.vehicleCharacter:setCharacterVisibility(true)
            end
        end
    end
end


---
function EnterablePassenger.consoleCommandDebugPassengerSeat()
    EnterablePassenger.DEBUG_ACTIVE = not EnterablePassenger.DEBUG_ACTIVE

    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle ~= nil and vehicle.spec_enterablePassenger ~= nil then
        if EnterablePassenger.DEBUG_ACTIVE then
            for seatIndex=1, #vehicle.spec_enterablePassenger.passengerSeats do
                vehicle:setPassengerSeatCharacter(seatIndex, vehicle:getUserPlayerStyle())
            end
        else
            for seatIndex=1, #vehicle.spec_enterablePassenger.passengerSeats do
                vehicle:setPassengerSeatCharacter(seatIndex, nil)
            end
        end
    end

    Logging.info("Passenger Seat Debug: %s", tostring(EnterablePassenger.DEBUG_ACTIVE))
end
