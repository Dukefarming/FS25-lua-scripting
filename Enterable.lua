

















---
function Enterable.prerequisitesPresent(specializations)
    return true
end


---
function Enterable.initSpecialization()
    Vehicle.INTERACTION_FLAG_ENTERABLE = Vehicle.registerInteractionFlag("ENTERABLE")

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Enterable")

    schema:register(XMLValueType.BOOL, "vehicle.enterable#isTabbable", "Vehicle is tabbable", true)
    schema:register(XMLValueType.BOOL, "vehicle.enterable#canBeEnteredFromMenu", "Vehicle can be entered from menu", "same as #isTabbable")
    schema:register(XMLValueType.BOOL, "vehicle.enterable.forceSelectionOnEnter", "Vehicle is selected on entering", false)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.enterReferenceNode#node", "Enter reference node")
    schema:register(XMLValueType.FLOAT, "vehicle.enterable.enterReferenceNode#interactionRadius", "Interaction radius", 6)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.exitPoint#node", "Exit point")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.nicknameRenderNode#node", "Nickname rendering node", "root node")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.enterable.nicknameRenderNode#offset", "Nickname rendering offset")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.reverb#referenceNode", "Reference node for reverb calculations", "center of vehicle +2m Y")

    schema:register(XMLValueType.STRING, "vehicle.enterable.enterAnimation#name", "Enter animation name")

    VehicleCharacter.registerCharacterXMLPaths(schema, "vehicle.enterable.characterNode")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.additionalCharacter#node", "Additional character node")
    VehicleCharacter.registerCharacterXMLPaths(schema, "vehicle.enterable.additionalCharacter")

    VehicleCamera.registerCameraXMLPaths(schema, "vehicle.enterable.cameras.camera(?)")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?)#node", "Target node")
    schema:register(XMLValueType.STRING, "vehicle.enterable.characterTargetNodeModifier(?)#poseId", "Modifier pose id")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#node", "State node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#referenceNode", "State is activated if this node moves or rotates")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#directionReferenceNode", "State node is align to this node")
    schema:register(XMLValueType.BOOL, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#referenceNodeMovement", "The state is active as long as the reference node is moving/rotating. By default it's active while translation/rotation is different compared to the original state.", false)
    schema:register(XMLValueType.STRING, "vehicle.enterable.characterTargetNodeModifier(?).state(?)#poseId", "Pose id")
    schema:register(XMLValueType.FLOAT, "vehicle.enterable.characterTargetNodeModifier(?)#transitionTime", "Time between state changes", 0.1)
    schema:register(XMLValueType.FLOAT, "vehicle.enterable.characterTargetNodeModifier(?)#transitionIdleDelay", "State is changed after this delay", 0.5)

    schema:register(XMLValueType.NODE_INDEX, "vehicle.enterable.mirrors.mirror(?)#node", "Mirror node")
    schema:register(XMLValueType.INT, "vehicle.enterable.mirrors.mirror(?)#prio", "Priority", 2)

    Dashboard.registerDashboardXMLPaths(schema, "vehicle.enterable.dashboards", {"time", "timeHours", "timeMinutes", "operatingTime", "outsideTemperature"})

    SoundManager.registerSampleXMLPaths(schema, "vehicle.enterable.sounds", "rain(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.enterable.sounds", "hail(?)")

    schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isEntered", "Is entered")

    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. "#updateCharacterTargetModifier", "Update character target modifier state", false)
    end)

    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. "#updateCharacterTargetModifier", "Update character target modifier state", false)
    end)

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    VehicleCamera.registerCameraSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).enterable.camera(?)")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).enterable#activeCameraIndex", "Index of active camera", 1)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).enterable#isTabbable", "Is tabbable", true)
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).enterable#isLeavingAllowed", "Is leaving allowed", true)
end


---
function Enterable.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onEnterVehicle")
    SpecializationUtil.registerEvent(vehicleType, "onLeaveVehicle")
    SpecializationUtil.registerEvent(vehicleType, "onCameraChanged")
    SpecializationUtil.registerEvent(vehicleType, "onVehicleCharacterChanged")
end


---
function Enterable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onPlayerEnterVehicle",                  Enterable.onPlayerEnterVehicle)
    SpecializationUtil.registerFunction(vehicleType, "doLeaveVehicle",                        Enterable.doLeaveVehicle)
    SpecializationUtil.registerFunction(vehicleType, "onPlayerLeaveVehicle",                  Enterable.onPlayerLeaveVehicle)
    SpecializationUtil.registerFunction(vehicleType, "setActiveCameraIndex",                  Enterable.setActiveCameraIndex)
    SpecializationUtil.registerFunction(vehicleType, "addToolCameras",                        Enterable.addToolCameras)
    SpecializationUtil.registerFunction(vehicleType, "removeToolCameras",                     Enterable.removeToolCameras)
    SpecializationUtil.registerFunction(vehicleType, "getExitNode",                           Enterable.getExitNode)
    SpecializationUtil.registerFunction(vehicleType, "getUserPlayerStyle",                    Enterable.getUserPlayerStyle)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentPlayerStyle",                 Enterable.getCurrentPlayerStyle)
    SpecializationUtil.registerFunction(vehicleType, "setVehicleCharacter",                   Enterable.setVehicleCharacter)
    SpecializationUtil.registerFunction(vehicleType, "vehicleCharacterLoaded",                Enterable.vehicleCharacterLoaded)
    SpecializationUtil.registerFunction(vehicleType, "onPlayerStyleChanged",                  Enterable.onPlayerStyleChanged)
    SpecializationUtil.registerFunction(vehicleType, "setRandomVehicleCharacter",             Enterable.setRandomVehicleCharacter)
    SpecializationUtil.registerFunction(vehicleType, "restoreVehicleCharacter",               Enterable.restoreVehicleCharacter)
    SpecializationUtil.registerFunction(vehicleType, "deleteVehicleCharacter",                Enterable.deleteVehicleCharacter)
    SpecializationUtil.registerFunction(vehicleType, "getFormattedOperatingTime",             Enterable.getFormattedOperatingTime)
    SpecializationUtil.registerFunction(vehicleType, "loadCharacterTargetNodeModifier",       Enterable.loadCharacterTargetNodeModifier)
    SpecializationUtil.registerFunction(vehicleType, "updateCharacterTargetNodeModifier",     Enterable.updateCharacterTargetNodeModifier)
    SpecializationUtil.registerFunction(vehicleType, "setCharacterTargetNodeStateDirty",      Enterable.setCharacterTargetNodeStateDirty)
    SpecializationUtil.registerFunction(vehicleType, "resetCharacterTargetNodeStateDefaults", Enterable.resetCharacterTargetNodeStateDefaults)
    SpecializationUtil.registerFunction(vehicleType, "setMirrorVisible",                      Enterable.setMirrorVisible)
    SpecializationUtil.registerFunction(vehicleType, "getIsTabbable",                         Enterable.getIsTabbable)
    SpecializationUtil.registerFunction(vehicleType, "setIsTabbable",                         Enterable.setIsTabbable)
    SpecializationUtil.registerFunction(vehicleType, "getIsEnterable",                        Enterable.getIsEnterable)
    SpecializationUtil.registerFunction(vehicleType, "getIsEnterableFromMenu",                Enterable.getIsEnterableFromMenu)
    SpecializationUtil.registerFunction(vehicleType, "getIsEntered",                          Enterable.getIsEntered)
    SpecializationUtil.registerFunction(vehicleType, "getIsControlled",                       Enterable.getIsControlled)
    SpecializationUtil.registerFunction(vehicleType, "getControllerName",                     Enterable.getControllerName)
    SpecializationUtil.registerFunction(vehicleType, "getActiveCamera",                       Enterable.getActiveCamera)
    SpecializationUtil.registerFunction(vehicleType, "getVehicleCharacter",                   Enterable.getVehicleCharacter)
    SpecializationUtil.registerFunction(vehicleType, "getAllowCharacterVisibilityUpdate",     Enterable.getAllowCharacterVisibilityUpdate)
    SpecializationUtil.registerFunction(vehicleType, "getDisableVehicleCharacterOnLeave",     Enterable.getDisableVehicleCharacterOnLeave)
    SpecializationUtil.registerFunction(vehicleType, "loadCamerasFromXML",                    Enterable.loadCamerasFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadAdditionalCharacterFromXML",        Enterable.loadAdditionalCharacterFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsAdditionalCharacterActive",        Enterable.getIsAdditionalCharacterActive)
    SpecializationUtil.registerFunction(vehicleType, "getCanLeave",                           Enterable.getCanLeave)
    SpecializationUtil.registerFunction(vehicleType, "getCanLeaveVehicle",                    Enterable.getCanLeaveVehicle)
    SpecializationUtil.registerFunction(vehicleType, "getCanLeaveRideable",                   Enterable.getCanLeaveRideable)
    SpecializationUtil.registerFunction(vehicleType, "getIsLeavingAllowed",                   Enterable.getIsLeavingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setIsLeavingAllowed",                   Enterable.setIsLeavingAllowed)
end


---
function Enterable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Enterable.getIsActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForInput", Enterable.getIsActiveForInput)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDistanceToNode", Enterable.getDistanceToNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInteractionHelp", Enterable.getInteractionHelp)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "interact", Enterable.interact)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInteractive", Enterable.getIsInteractive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleSelectable", Enterable.getCanToggleSelectable)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleAttach", Enterable.getCanToggleAttach)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", Enterable.getActiveFarm)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Enterable.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Enterable.getIsDashboardGroupActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "mountDynamic", Enterable.mountDynamic)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", Enterable.getIsInUse)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", Enterable.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", Enterable.updateExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Enterable.getIsMapHotspotVisible)
end


---
function Enterable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onPreUpdate", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onDrawUIInfo", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onPreRegisterActionEvents", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Enterable)
    SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Enterable)
end


---
function Enterable:onLoad(savegame)

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.mirrors.mirror(0)#index", "vehicle.enterable.mirrors.mirror(0)#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterReferenceNode", "vehicle.enterable.enterReferenceNode") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterReferenceNode#index", "vehicle.enterable.enterReferenceNode#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.enterReferenceNode#index", "vehicle.enterable.enterReferenceNode#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.exitPoint", "vehicle.enterable.exitPoint") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.exitPoint#index", "vehicle.enterable.exitPoint#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.exitPoint#index", "vehicle.enterable.exitPoint#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.characterNode", "vehicle.enterable.characterNode") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.characterNode#index", "vehicle.enterable.characterNode#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.characterNode#index", "vehicle.enterable.characterNode#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.nicknameRenderNode", "vehicle.enterable.nicknameRenderNode") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterAnimation", "vehicle.enterable.enterAnimation") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cameras.camera1", "vehicle.enterable.cameras.camera") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.cameras.camera1", "vehicle.enterable.cameras.camera") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.time", "vehicle.enterable.dashboards.dashboard with valueType 'time'") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.operatingTime", "vehicle.enterable.dashboards.dashboard with valueType 'operatingTime'") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.enterable.nicknameRenderNode#index", "vehicle.enterable.nicknameRenderNode#node") --FS19 to FS21

    local spec = self.spec_enterable

    spec.isTabbable = self.xmlFile:getValue("vehicle.enterable#isTabbable", true)
    spec.canBeEnteredFromMenu = self.xmlFile:getValue("vehicle.enterable#canBeEnteredFromMenu", spec.isTabbable)
    spec.isEntered = false
    spec.isControlled = false
    spec.playerStyle = nil
    spec.canUseEnter = true
    spec.controllerFarmId = 0
    spec.controllerUserId = 0
    spec.isLeavingAllowed = true
    spec.lastCameraWasInside = false

    spec.disableCharacterOnLeave = true

    spec.enterText = string.format("%s (%s)", g_i18n:getText("button_enterVehicle"), g_i18n:getText("passengerSeat_driver"))

    spec.forceSelectionOnEnter = self.xmlFile:getValue("vehicle.enterable.forceSelectionOnEnter", false)

    spec.enterReferenceNode = self.xmlFile:getValue("vehicle.enterable.enterReferenceNode#node", nil, self.components, self.i3dMappings)
    spec.exitPoint = self.xmlFile:getValue("vehicle.enterable.exitPoint#node", nil, self.components, self.i3dMappings)

    spec.interactionRadius = self.xmlFile:getValue("vehicle.enterable.enterReferenceNode#interactionRadius", 6.0)

    spec.vehicleCharacter = VehicleCharacter.new(self)
    if spec.vehicleCharacter ~= nil and not spec.vehicleCharacter:load(self.xmlFile, "vehicle.enterable.characterNode", self.i3dMappings) then
        spec.vehicleCharacter = nil
    end

    self:loadAdditionalCharacterFromXML(self.xmlFile)

    spec.nicknameRendering = {}
    spec.nicknameRendering.node = self.xmlFile:getValue("vehicle.enterable.nicknameRenderNode#node", nil, self.components, self.i3dMappings)
    spec.nicknameRendering.offset = self.xmlFile:getValue("vehicle.enterable.nicknameRenderNode#offset", nil, true)
    if spec.nicknameRendering.node == nil then
        if spec.vehicleCharacter ~= nil and spec.vehicleCharacter.characterDistanceRefNode ~= nil then
            spec.nicknameRendering.node = spec.vehicleCharacter.characterDistanceRefNode
            if spec.nicknameRendering.offset == nil then
                spec.nicknameRendering.offset = {0, 1.5, 0}
            end
        else
            spec.nicknameRendering.node = self.components[1].node
        end
    end
    if spec.nicknameRendering.offset == nil then
        spec.nicknameRendering.offset = {0, 4, 0}
    end

    spec.enterAnimation = self.xmlFile:getValue("vehicle.enterable.enterAnimation#name")
    if spec.enterAnimation ~= nil and not self:getAnimationExists(spec.enterAnimation) then
        Logging.xmlWarning(self.xmlFile, "Unable to find enter animation '%s'", spec.enterAnimation)
    end

    self:loadCamerasFromXML(self.xmlFile, savegame)

    if spec.numCameras == 0 then
        Logging.xmlError(self.xmlFile, "No cameras defined!")
        self:setLoadingState(VehicleLoadingState.ERROR)
        return
    end

    spec.characterTargetNodeReferenceToState = {}
    spec.characterTargetNodeStatesDirty = false

    spec.characterTargetNodeModifiers = {}
    local i = 0
    while true do
        local key = string.format("vehicle.enterable.characterTargetNodeModifier(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end

        local modifier = {}
        if self:loadCharacterTargetNodeModifier(modifier, self.xmlFile, key) then
            table.insert(spec.characterTargetNodeModifiers, modifier)
        end
        i = i + 1
    end

    -- for development version we get all mirror meshes from the vehicle
    -- and check if all of them are entered in the xml and the objectMasks are correctly set
    local allMirrors = {}
    if g_isDevelopmentVersion then
        I3DUtil.getNodesByShaderParam(self.rootNode, "reflectionScale", allMirrors)
    end

    spec.mirrors = {}
    local useMirrors = g_gameSettings:getValue(GameSettings.SETTING.MAX_NUM_MIRRORS) > 0
    i = 0
    while true do
        local key = string.format("vehicle.enterable.mirrors.mirror(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end

        local node = self.xmlFile:getValue(key.."#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            local prio = self.xmlFile:getValue(key.."#prio", 2)

            local shapesObjectMask = bit32.bor(ObjectMask.SHAPE_VIS_MIRROR, ObjectMask.SHAPE_VIS_MIRROR_ONLY)
            setReflectionMapObjectMasks(node, shapesObjectMask, ObjectMask.LIGHT_VIS_MIRROR, true) --0x8080, 0x80000000

            if getObjectMask(node) == 0 then
                -- Mirrors should not be visible in other mirrors
                setObjectMask(node, 16711807) -- 0x00FF007F
            end

            if useMirrors then
                table.insert(spec.mirrors, {node=node, prio=prio, cosAngle=1, parentNode=getParent(node)})
            else
                setVisibility(node, false)
            end

            allMirrors[node] = nil
        end
        i = i + 1
    end

    for node, _ in pairs(allMirrors) do
        Logging.xmlError(self.xmlFile, "Found Mesh '%s' with mirrorShader that is not entered in the vehicle XML", getName(node))
    end

    self:setMirrorVisible(spec.cameras[spec.camIndex].useMirror)

    spec.lastIsRaining = false
    spec.lastIsHailing = false
    spec.weatherObject = g_currentMission.environment.weather

    if self.isClient then
        spec.rainSamples = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.enterable.sounds", "rain", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.hasRainSamples = #spec.rainSamples > 0

        spec.hailSamples = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.enterable.sounds", "hail", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.hasHailSamples = #spec.hailSamples > 0
    end

    spec.reverbReferenceNode = self.xmlFile:getValue("vehicle.enterable.reverb#referenceNode", nil, self.components, self.i3dMappings)
    if spec.reverbReferenceNode == nil then
        spec.reverbReferenceNode = createTransformGroup("ReverebRefNode")
        link(self.rootNode, spec.reverbReferenceNode)
        setTranslation(spec.reverbReferenceNode, 0, 2, 0)
    end

    spec.dirtyFlag = self:getNextDirtyFlag()

    spec.playerHotspot = PlayerHotspot.new()
    spec.playerHotspot:setVehicle(self)

    self.needWaterInfo = true

    g_currentMission.vehicleSystem:addInteractiveVehicle(self)
    g_currentMission.vehicleSystem:addEnterableVehicle(self)
end


---
function Enterable:onPostLoad(savegame)
    local spec = self.spec_enterable
    for i=1, #spec.cameras do
        local camera = spec.cameras[i]
        camera:onPostLoad(savegame)
    end

    if savegame ~= nil and not savegame.resetVehicles then
        self:setIsTabbable(savegame.xmlFile:getValue(savegame.key..".enterable#isTabbable", spec.isTabbable))
        spec.camIndex = savegame.xmlFile:getValue(savegame.key..".enterable#activeCameraIndex", 1)
        spec.isLeavingAllowed = savegame.xmlFile:getValue(savegame.key..".enterable#isLeavingAllowed", true)
    end
end


---
function Enterable:onLoadFinished(savegame)
    local spec = self.spec_enterable
    if spec.isControlled then
        spec.playerHotspot:setOwnerFarmId(self:getActiveFarm())
        g_currentMission:addMapHotspot(spec.playerHotspot)
    end
end


---Called on post load to register dashboard value types
function Enterable:onRegisterDashboardValueTypes()
    local time = DashboardValueType.new("enterable", "time")
    time:setValue(g_currentMission.environment, "getEnvironmentTime")
    self:registerDashboardValueType(time)

    local timeHours = DashboardValueType.new("enterable", "timeHours")
    timeHours:setValue(g_currentMission.environment, function(env) local time = env:getEnvironmentTime() return math.floor(time) + time % 1 * 100 / 60 end)
    self:registerDashboardValueType(timeHours)

    local timeMinutes = DashboardValueType.new("enterable", "timeMinutes")
    timeMinutes:setValue(g_currentMission.environment, function(env) return env:getEnvironmentTime() % 1 * 100 end)
    self:registerDashboardValueType(timeMinutes)

    local operatingTime = DashboardValueType.new("enterable", "operatingTime")
    operatingTime:setValue(self, self.getFormattedOperatingTime)
    self:registerDashboardValueType(operatingTime)

    local outsideTemperature = DashboardValueType.new("enterable", "outsideTemperature")
    outsideTemperature:setValue(g_currentMission.environment.weather, "getCurrentTemperature")
    self:registerDashboardValueType(outsideTemperature)
end


---Called on deleting
function Enterable:onDelete()
    local spec = self.spec_enterable

    if spec.isControlled then
        local player = g_currentMission.playerSystem:getPlayerByUserId(self.spec_enterable.controllerUserId)
        if player ~= nil then
            player:leaveVehicle(self, true)
        end
    end

    if spec.vehicleCharacter ~= nil then
        spec.vehicleCharacter:delete()
        spec.vehicleCharacter = nil
    end
    if spec.cameras ~= nil then
        for _, camera in ipairs(spec.cameras) do
            camera:delete()
        end
    end

    if spec.playerHotspot ~= nil then
        g_currentMission:removeMapHotspot(spec.playerHotspot)
        spec.playerHotspot:delete()
        spec.playerHotspot = nil
    end

    g_soundManager:deleteSamples(spec.rainSamples)
    g_soundManager:deleteSamples(spec.hailSamples)

    spec.weatherObject = nil

    g_currentMission.vehicleSystem:removeEnterableVehicle(self)
    g_currentMission.vehicleSystem:removeInteractiveVehicle(self)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function Enterable:onReadStream(streamId, connection)
    local spec = self.spec_enterable
    spec.isTabbable = streamReadBool(streamId)

    local isControlled = streamReadBool(streamId)
    if isControlled then
        local userId = User.streamReadUserId(streamId)
        local player = g_playerSystem:getPlayerByUserId(userId)
        if player ~= nil then
            player:onEnterVehicle(self)
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function Enterable:onWriteStream(streamId, connection)
    local spec = self.spec_enterable

    streamWriteBool(streamId, spec.isTabbable)

    if streamWriteBool(streamId, spec.isControlled) then
        User.streamWriteUserId(streamId, spec.controllerUserId)
    end
end


---
function Enterable:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_enterable
    for i=1, #spec.cameras do
        spec.cameras[i]:saveToXMLFile(xmlFile, string.format("%s.camera(%d)", key, i-1), usedModNames)
    end

    xmlFile:setValue(key .. "#activeCameraIndex", spec.camIndex)
    xmlFile:setValue(key .. "#isTabbable", spec.isTabbable)
    xmlFile:setValue(key .. "#isLeavingAllowed", spec.isLeavingAllowed)
end


---Returns string with name of controller for game stats xml
-- @return string statesAttributes states attributes
function Enterable:saveStatsToXMLFile(xmlFile, key)
    local spec = self.spec_enterable
    if spec.isControlled then
        local name = self:getControllerName()
        if name ~= nil then
            setXMLString(xmlFile, key.."#controller", HTMLUtil.encodeToHTML(name))
        end
    end
    return nil
end


---Called before update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function Enterable:onPreUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_enterable
    if spec.characterTargetNodeStatesDirty then
        local keepDirty = false
        for referenceNode, states in pairs(spec.characterTargetNodeReferenceToState) do
            for _, state in ipairs(states) do
                if state.dirtyFrameOffset ~= nil and state.dirtyFrameOffset > 0 then
                    state.dirtyFrameOffset = state.dirtyFrameOffset - 1
                    if state.dirtyFrameOffset <= 0 then
                        self:setCharacterTargetNodeStateDirty(referenceNode, false)
                        state.dirtyFrameOffset = nil
                    end
                    keepDirty = true
                end
            end
        end

        if not keepDirty then
            spec.characterTargetNodeStatesDirty = false
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function Enterable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self:getIsControlled() then
        if self.isClient then
            local spec = self.spec_enterable
            for _,modifier in ipairs(spec.characterTargetNodeModifiers) do
                self:updateCharacterTargetNodeModifier(dt, modifier)
            end

            if self:getIsAdditionalCharacterActive() ~= spec.additionalCharacterActive then
                spec.additionalCharacterActive = not spec.additionalCharacterActive

                local character = self:getVehicleCharacter()
                if character ~= nil then
                    local node = spec.defaultCharacterNode
                    local targets = spec.defaultCharacterTargets
                    if spec.additionalCharacterActive then
                        targets = spec.additionalCharacterTargets
                        node = spec.additionalCharacterNode
                    end

                    character:setIKChainTargets(targets)
                    character.characterNode = node

                    -- character may not be loaded yet
                    if character.playerModel.rootNode ~= nil then
                        link(node, character.playerModel.rootNode)
                    end
                end
            end

            if spec.hasRainSamples then
                local isRaining = spec.weatherObject:getRainFallScale() > 0
                if isRaining ~= spec.lastIsRaining then
                    if isRaining then
                        g_soundManager:playSamples(spec.rainSamples)
                    else
                        g_soundManager:stopSamples(spec.rainSamples)
                    end

                    spec.lastIsRaining = isRaining
                end
            end

            if spec.hasHailSamples then
                local isHailing = spec.weatherObject:getIsHailing()
                if isHailing ~= spec.lastIsHailing then
                    if isHailing then
                        g_soundManager:playSamples(spec.hailSamples)
                    else
                        g_soundManager:stopSamples(spec.hailSamples)
                    end

                    spec.lastIsHailing = isHailing
                end
            end

            if isActiveForInputIgnoreSelection then
                local x, y, z = getWorldTranslation(self.rootNode)
                local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
                g_currentMission.activatableObjectsSystem:setPosition(x, y, z)
                g_currentMission.activatableObjectsSystem:setDirection(dirX, dirY, dirZ)
            end
        end

        self.rootVehicle:raiseActive()
    end
end


---Called on postUpdate
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function Enterable:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_enterable

    if self.isClient then
        if spec.isEntered and spec.vehicleCharacter ~= nil then
            if spec.vehicleCharacter.characterSpineNode ~= nil and spec.vehicleCharacter.characterSpineSpeedDepended then
                spec.vehicleCharacter:setSpineDirty(self.lastSpeedAcceleration)
            end
        end

        if self.finishedFirstUpdate then
            if self:getIsEntered() then
                spec.activeCamera:update(dt)
            end

            -- update character visibility
            if self:getAllowCharacterVisibilityUpdate() then
                if spec.vehicleCharacter ~= nil then
                    spec.vehicleCharacter:updateVisibility()
                end
            end
        end

        if self:getIsControlled() then
            if spec.vehicleCharacter ~= nil then
                spec.vehicleCharacter:update(dt)
            end

            -- do mirror checks
            if spec.activeCamera ~= nil and spec.activeCamera.useMirror then
                self:setMirrorVisible(true)
            end
        end
    end
end


---Called on ui info draw, renders nicknames in multiplayer
function Enterable:onDrawUIInfo()
    local spec = self.spec_enterable

    local visible = not g_gui:getIsGuiVisible() and not g_noHudModeEnabled and g_gameSettings:getValue(GameSettings.SETTING.SHOW_MULTIPLAYER_NAMES)
    if not spec.isEntered and self.isClient and self:getIsActive() and spec.isControlled and visible then
        local x,y,z = getWorldTranslation(spec.nicknameRendering.node)
        local x1,y1,z1 = getWorldTranslation(g_cameraManager:getActiveCamera())
        local distSq = MathUtil.vector3LengthSq(x-x1,y-y1,z-z1)
        if distSq <= 100*100 then
            x = x + spec.nicknameRendering.offset[1]
            y = y + spec.nicknameRendering.offset[2]
            z = z + spec.nicknameRendering.offset[3]

            Utils.renderTextAtWorldPosition(x,y,z, self:getControllerName(), getCorrectTextSize(0.02), 0)
        end
    end
end


---
function Enterable:loadCamerasFromXML(xmlFile, savegame)
    local spec = self.spec_enterable

    XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.cameras.camera(0)#index", "vehicle.enterable.cameras.camera(0)#node") -- FS17
    XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.cameras.camera(0).raycastNode(0)#index", "vehicle.enterable.cameras.camera(0).raycastNode(0)#node") -- FS17

    spec.cameras = {}
    local i = 0
    while true do
        local cameraKey = string.format("vehicle.enterable.cameras.camera(%d)", i)
        if not xmlFile:hasProperty(cameraKey) then
            break
        end

        local camera = VehicleCamera.new(self)
        if camera:loadFromXML(xmlFile, cameraKey, savegame, i) then
            table.insert(spec.cameras, camera)
        end
        i = i + 1
    end
    spec.numCameras = #spec.cameras

    spec.camIndex = 1
end


---
function Enterable:loadAdditionalCharacterFromXML(xmlFile)
    local spec = self.spec_enterable

    spec.additionalCharacterNode = xmlFile:getValue("vehicle.enterable.additionalCharacter#node", nil, self.components, self.i3dMappings)
    spec.additionalCharacterTargets = {}
    IKUtil.loadIKChainTargets(xmlFile, "vehicle.enterable.additionalCharacter", self.components, spec.additionalCharacterTargets, self.i3dMappings)
    spec.additionalCharacterActive = false
    if spec.vehicleCharacter ~= nil then
        spec.defaultCharacterNode = spec.vehicleCharacter.characterNode
        spec.defaultCharacterTargets = spec.vehicleCharacter:getIKChainTargets()
    end
end


---
function Enterable:getIsAdditionalCharacterActive()
    return false
end


---
function Enterable:loadCharacterTargetNodeModifier(entry, xmlFile, xmlKey)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlKey .. "#index", xmlKey .. "#node") --FS17 to FS19

    entry.node = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)
    if entry.node ~= nil then
        entry.parent = getParent(entry.node)
        entry.translationOffset = {getTranslation(entry.node)}
        entry.rotationOffset = {getRotation(entry.node)}
        entry.poseId = xmlFile:getValue(xmlKey .. "#poseId")

        entry.states = {}

        local j = 0
        while true do
            local stateKey = string.format("%s.state(%d)", xmlKey, j)
            if not xmlFile:hasProperty(stateKey) then
                break
            end

            XMLUtil.checkDeprecatedXMLElements(xmlFile, stateKey .. "#index", stateKey .. "#node") --FS17 to FS19

            local node = xmlFile:getValue(stateKey .. "#node", nil, self.components, self.i3dMappings)
            if node ~= nil then
                local state = {}
                state.node = node
                state.referenceNode = xmlFile:getValue(stateKey .. "#referenceNode", nil, self.components, self.i3dMappings)
                state.directionReferenceNode = xmlFile:getValue(stateKey .. "#directionReferenceNode", nil, self.components, self.i3dMappings)
                state.referenceNodeMovement = xmlFile:getValue(stateKey .. "#referenceNodeMovement", false)
                state.poseId = self.xmlFile:getValue(stateKey .. "#poseId")

                if state.referenceNode ~= nil then
                    state.defaultRotation = {getRotation(state.referenceNode)}
                    state.defaultTranslation = {getTranslation(state.referenceNode)}

                    local spec = self.spec_enterable
                    if spec.characterTargetNodeReferenceToState[state.referenceNode] == nil then
                        spec.characterTargetNodeReferenceToState[state.referenceNode] = {}
                    end

                    table.insert(spec.characterTargetNodeReferenceToState[state.referenceNode], state)

                    table.insert(entry.states, state)
                end
            else
                Logging.xmlWarning(self.xmlFile, "Missing node for state '%s'", stateKey)
            end

            j = j + 1
        end

        entry.transitionTime = self.xmlFile:getValue(xmlKey .. "#transitionTime", 0.1) * 1000
        entry.transitionAlpha = 1.0

        entry.transitionIdleDelay = self.xmlFile:getValue(xmlKey .. "#transitionIdleDelay", 0.5) * 1000
        entry.transitionIdleTime = 0

        return true
    end

    return false
end


---
function Enterable:updateCharacterTargetNodeModifier(dt, modifier)
    local node = modifier.parent
    local poseId = modifier.poseId
    for _,state in pairs(modifier.states) do
        if state.isActive then
            node = state.node
            poseId = state.poseId or poseId

            -- align the target node to the direction reference node
            if state.directionReferenceNode ~= nil then
                local wx, wy, wz = getWorldTranslation(state.directionReferenceNode)
                local lx, ly, lz = getTranslation(state.node)
                local dx, dy, dz = worldToLocal(getParent(state.node), wx, wy, wz)
                setDirection(state.node, dx-lx, dy-ly, dz-lz, 0, 1, 0)
            end
        end
    end

    local isDirty = modifier.transitionAlpha < 1
    local allowSwitch = node ~= modifier.parent

    if not allowSwitch then
        modifier.transitionIdleTime = modifier.transitionIdleTime + dt

        if modifier.transitionIdleTime > modifier.transitionIdleDelay then
            allowSwitch = true
            modifier.transitionIdleTime = 0
        end
    end

    if allowSwitch and getParent(modifier.node) ~= node then
        local transStartPos = {localToLocal(modifier.node, node, 0,0,0)}
        local transEndPos = {0, 0, 0}
        if node == modifier.parent then
            transEndPos = modifier.translationOffset
        end
        modifier.transitionStartPos = transStartPos
        modifier.transitionEndPos = transEndPos

        if math.abs(transEndPos[1] - transStartPos[1]) < 0.001 and math.abs(transEndPos[2] - transStartPos[2]) < 0.001 and math.abs(transEndPos[3] - transStartPos[3]) < 0.001 then
            modifier.transitionAlpha = 1.0
        else
            modifier.transitionAlpha = 0
        end

        isDirty = true

        local rx,ry,rz = localRotationToLocal(modifier.node, node, 0,0,0)
        modifier.transitionStartQuat = {mathEulerToQuaternion(rx, ry, rz)}
        modifier.transitionEndQuat = {0, 0, 0, 1}
        if node == modifier.parent then
            modifier.transitionEndQuat = {mathEulerToQuaternion(unpack(modifier.rotationOffset))}
        end

        link(node, modifier.node)

        if poseId ~= nil then
            local character = self:getVehicleCharacter()
            if character ~= nil then
                character:setIKChainPoseByTarget(modifier.node, poseId)
            end
        end
    end

    if isDirty then
        modifier.transitionAlpha = math.min(1.0, modifier.transitionAlpha + (dt/modifier.transitionTime))

        local x,y,z = MathUtil.vector3ArrayLerp(modifier.transitionStartPos, modifier.transitionEndPos, modifier.transitionAlpha)
        setTranslation(modifier.node, x,y,z)

        local qx,qy,qz,qw = MathUtil.slerpQuaternionShortestPath(modifier.transitionStartQuat[1], modifier.transitionStartQuat[2], modifier.transitionStartQuat[3], modifier.transitionStartQuat[4],
                                                                 modifier.transitionEndQuat[1], modifier.transitionEndQuat[2], modifier.transitionEndQuat[3], modifier.transitionEndQuat[4],
                                                                 modifier.transitionAlpha)
        setQuaternion(modifier.node, qx,qy,qz,qw)
    end
end


---
function Enterable:setCharacterTargetNodeStateDirty(referenceNode, forceActive)
    local spec = self.spec_enterable
    local states = spec.characterTargetNodeReferenceToState[referenceNode]
    if states ~= nil then
        for i=1, #states do
            local state = states[i]
            state.isActive = forceActive == true

            local rx, ry, rz = getRotation(state.referenceNode)
            local refX, refY, refZ = unpack(state.defaultRotation)

            if math.abs(rx-refX) + math.abs(ry-refY) + math.abs(rz-refZ) > 0.00001 then
                state.isActive = true
            end

            -- check if the translation is different than the translation on loading
            local x, y, z = getTranslation(state.referenceNode)
            refX, refY, refZ = unpack(state.defaultTranslation)

            if math.abs(x-refX) + math.abs(y-refY) + math.abs(z-refZ) > 0.00001 then
                state.isActive = true
            end

            if state.referenceNodeMovement then
                state.defaultRotation[1], state.defaultRotation[2], state.defaultRotation[3] = rx, ry, rz
                state.defaultTranslation[1], state.defaultTranslation[2], state.defaultTranslation[3] = x, y, z

                if state.isActive then
                    state.dirtyFrameOffset = 2
                    spec.characterTargetNodeStatesDirty = true
                end
            end
        end
    end
end


---
function Enterable:resetCharacterTargetNodeStateDefaults(referenceNode)
    local spec = self.spec_enterable
    local states = spec.characterTargetNodeReferenceToState[referenceNode]
    if states ~= nil then
        for i=1, #states do
            local state = states[i]
            state.defaultRotation[1], state.defaultRotation[2], state.defaultRotation[3] = getRotation(state.referenceNode)
            state.defaultTranslation[1], state.defaultTranslation[2], state.defaultTranslation[3] = getTranslation(state.referenceNode)
        end
    end
end


---Enter vehicle
-- @param boolean isControlling is controlling vehicle
-- @param integer playerIndex index of player who enters the vehicle
-- @param integer playerColorIndex index of player color
function Enterable:onPlayerEnterVehicle(isControlling, playerStyle, farmId, userId)
    local spec = self.spec_enterable

    self:raiseActive()

    spec.isControlled = true
    spec.isEntered = isControlling
    spec.playerStyle = playerStyle
    spec.canUseEnter = false
    spec.controllerFarmId = farmId
    spec.controllerUserId = userId

    if spec.forceSelectionOnEnter then
        local rootAttacherVehicle = self.rootVehicle
        if rootAttacherVehicle ~= self then
            rootAttacherVehicle:setSelectedImplementByObject(self)
        end
    end

    if spec.isEntered then
        -- if head tracking is available we want to use the first indoor camera
        if g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED) and isHeadTrackingAvailable() then
            for i,camera in pairs(spec.cameras) do
                if camera.isInside then
                    spec.camIndex = i
                    break
                end
            end
        end

        if g_gameSettings:getValue(GameSettings.SETTING.RESET_CAMERA) then
            spec.camIndex = 1
        end
        self:setActiveCameraIndex(spec.camIndex)

        g_currentMission.vehicleSystem:setEnteredVehicle(self)
    end

    if spec.playerHotspot ~= nil then
        spec.playerHotspot:setOwnerFarmId(self:getActiveFarm())
        g_currentMission:addMapHotspot(spec.playerHotspot)
        spec.playerHotspot:setPlayer(g_playerSystem:getPlayerByUserId(userId))
    end

    if not self:getIsAIActive() then
        self:setVehicleCharacter(playerStyle)

        if spec.enterAnimation ~= nil and self.playAnimation ~= nil then
            self:playAnimation(spec.enterAnimation, 1, nil, true)
        end
    end

    -- update state for sounds that are played while entering (e.g. motor start)
    self.isActiveForLocalSound = self:getIsActiveForInput(true, true)

    SpecializationUtil.raiseEvent(self, "onEnterVehicle", isControlling)
    self.rootVehicle:raiseStateChange(VehicleStateChange.ENTER_VEHICLE, self, isControlling)

    if spec.isEntered then
        -- activate actionEvents
        if self.isClient then
            g_messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.requestActionEventUpdate, self)
            self:requestActionEventUpdate()
        end
    end

    if self.isServer and not isControlling and g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0 then
        addTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.components[1].node)
    end

    self:activate()
end

























---
function Enterable:doLeaveVehicle()

    if not self:getCanLeave() or not self:getIsLeavingAllowed() then
        return
    end

    g_localPlayer:leaveVehicle()
end


---Leave vehicle
function Enterable:onPlayerLeaveVehicle()
    local spec = self.spec_enterable

    g_currentMission:removePauseListeners(self)

    local wasEntered = spec.isEntered
    if spec.activeCamera ~= nil and spec.isEntered then
        spec.lastCameraWasInside = spec.activeCamera.isInside

        spec.activeCamera:onDeactivate()
        g_soundManager:setIsIndoor(false)
        g_currentMission.ambientSoundSystem:setIsIndoor(false)
        g_currentMission.environment.environmentMaskSystem:setIsIndoor(false)
        g_currentMission.activatableObjectsSystem:deactivate(Vehicle.INPUT_CONTEXT_NAME)

        if self.isClient then
            g_soundManager:stopSamples(spec.rainSamples)
            spec.lastIsRaining = false

            g_soundManager:stopSamples(spec.hailSamples)
            spec.lastIsHailing = false
        end
    end

    if spec.playerHotspot ~= nil then
        g_currentMission:removeMapHotspot(spec.playerHotspot)
        spec.playerHotspot:setPlayer(nil)
    end

    spec.isControlled = false
    spec.isEntered = false
    spec.playerIndex = 0
    spec.playerColorIndex = 0
    spec.canUseEnter = true
    spec.controllerFarmId = 0
    spec.controllerUserId = 0

    g_currentMission:setLastInteractionTime(200)

    if spec.vehicleCharacter ~= nil and self:getDisableVehicleCharacterOnLeave() then
        self:deleteVehicleCharacter()
    end

    if spec.enterAnimation ~= nil and self.playAnimation ~= nil then
        self:playAnimation(spec.enterAnimation, -1, nil, true)
    end

    self:setMirrorVisible(false)

    SpecializationUtil.raiseEvent(self, "onLeaveVehicle", wasEntered)
    self.rootVehicle:raiseStateChange(VehicleStateChange.LEAVE_VEHICLE, self)

    -- deactivate actionEvents
    if wasEntered and self.isClient then
        g_messageCenter:unsubscribe(MessageType.INPUT_BINDINGS_CHANGED, self)
        self:requestActionEventUpdate()

        if g_touchHandler ~= nil then
            g_touchHandler:removeGestureListener(self.touchListenerDoubleTab)
        end
    end

    if self.isServer and not spec.isEntered and g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.trafficSystemId ~= 0 then
        removeTrafficSystemPlayer(g_currentMission.trafficSystem.trafficSystemId, self.components[1].node)
    end

    if self:getDeactivateOnLeave() then
        self:deactivate()
    end
end


---
function Enterable:getIsMapHotspotVisible(superFunc)
    if not superFunc(self) then
        return false
    end

    return not self.spec_enterable.isControlled
end


---Change active camera index
-- @param integer index index of camera to set
function Enterable:setActiveCameraIndex(index)
    local spec = self.spec_enterable

    if spec.camIndex == index and spec.activeCamera ~= nil and g_cameraManager.activeCameraNode == spec.activeCamera.cameraNode then
        return
    end

    if spec.activeCamera ~= nil then
        spec.activeCamera:onDeactivate()
    end
    spec.camIndex = index
    if spec.camIndex > spec.numCameras then
        spec.camIndex = 1
    end
    local activeCamera = spec.cameras[spec.camIndex]
    spec.activeCamera = activeCamera
    activeCamera:onActivate()

    g_soundManager:setIsIndoor(not activeCamera.useOutdoorSounds)
    g_currentMission.ambientSoundSystem:setIsIndoor(not activeCamera.useOutdoorSounds)
    g_currentMission.environment.environmentMaskSystem:setIsIndoor(not activeCamera.useOutdoorSounds)

    self:setMirrorVisible(activeCamera.useMirror)

    g_currentMission.environmentAreaSystem:setReferenceNode(activeCamera.cameraNode)

    SpecializationUtil.raiseEvent(self, "onCameraChanged", activeCamera, spec.camIndex)
end


---Add cameras from tool
-- @param table cameras cameras to add
function Enterable:addToolCameras(cameras)
    local spec = self.spec_enterable

    for _,toolCamera in pairs(cameras) do
        table.insert(spec.cameras, toolCamera)
    end
    spec.numCameras = #spec.cameras
end


---Remove cameras from tool
-- @param table cameras cameras to remove
function Enterable:removeToolCameras(cameras)
    local spec = self.spec_enterable

    local isToolCameraActive = false

    for j = #spec.cameras, 1, -1 do
        local camera = spec.cameras[j]
        for _,toolCamera in pairs(cameras) do
            if toolCamera == camera then
                table.remove(spec.cameras, j)
                if j == spec.camIndex then
                    isToolCameraActive = true
                end
                break
            end
        end
    end

    spec.numCameras = #spec.cameras

    -- only reset camera if current camera was a tool camera which is not available anymore
    if isToolCameraActive then
        if spec.activeCamera ~= nil then
            spec.activeCamera:onDeactivate()
        end

        spec.camIndex = 1
        self:setActiveCameraIndex(spec.camIndex)
    end
end


---
function Enterable:getExitNode(player)
    local spec = self.spec_enterable
    return spec.exitPoint
end


---
function Enterable:getUserPlayerStyle()
    return self.spec_enterable.playerStyle
end


---
function Enterable:getCurrentPlayerStyle()
    local spec = self.spec_enterable
    if spec.vehicleCharacter ~= nil then
        return spec.vehicleCharacter:getPlayerStyle()
    end

    return nil
end


---
function Enterable:setVehicleCharacter(playerStyle)
    local spec = self.spec_enterable

    self:deleteVehicleCharacter()

    if spec.vehicleCharacter ~= nil then
        spec.vehicleCharacter:loadCharacter(playerStyle, self, self.vehicleCharacterLoaded)
    end
end


---
function Enterable:vehicleCharacterLoaded(loadingState, arguments)
    local spec = self.spec_enterable
    if loadingState == HumanModelLoadingState.OK then
        spec.vehicleCharacter:updateVisibility()
        spec.vehicleCharacter:updateIKChains()
    end

    SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", spec.vehicleCharacter)

    g_messageCenter:subscribe(MessageType.PLAYER_STYLE_CHANGED, self.onPlayerStyleChanged, self)
end


---
function Enterable:onPlayerStyleChanged(style, userId)
    if self.isServer then
        local connection = self:getOwnerConnection()
        if connection ~= nil then
            local currentUserId = g_currentMission.userManager:getUserIdByConnection(connection)
            if currentUserId == userId then
                self:setVehicleCharacter(style)
                g_server:broadcastEvent(VehiclePlayerStyleChangedEvent.new(self, style))
            end
        end
    end
end


---
function Enterable:setRandomVehicleCharacter(helper)
    local spec = self.spec_enterable
    if spec.vehicleCharacter ~= nil then
        local playerStyle
        if helper ~= nil then
            playerStyle = helper.playerStyle
        else
            playerStyle = g_helperManager:getRandomHelperStyle()
        end

        self:setVehicleCharacter(playerStyle)
    end
end


---
function Enterable:restoreVehicleCharacter()
    local spec = self.spec_enterable
    if spec.vehicleCharacter ~= nil then
        if self:getIsControlled() then
            self:setVehicleCharacter(self:getUserPlayerStyle())
        else
            self:deleteVehicleCharacter()
        end
    end
end


---
function Enterable:deleteVehicleCharacter()
    local spec = self.spec_enterable

    SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", nil)

    if spec.vehicleCharacter ~= nil then
        spec.vehicleCharacter:unloadCharacter()
    end

    g_messageCenter:unsubscribe(MessageType.PLAYER_STYLE_CHANGED, self)
end


---
function Enterable:getFormattedOperatingTime()
    local minutes = self.operatingTime / (1000 * 60)
    local hours = math.floor(minutes / 60)
    minutes = math.floor((minutes - hours * 60) / 6)
    local minutesString = string.format("%02d", minutes*10)

    return tonumber(hours.."."..minutesString)
end


---
function Enterable:getIsActive(superFunc)
    local spec = self.spec_enterable
    if spec.isEntered or spec.isControlled then
        return true
    else
        return superFunc(self)
    end
end


---
function Enterable:getIsActiveForInput(superFunc, ignoreSelection, activeForAI)
    if not superFunc(self, ignoreSelection, activeForAI) then
        return false
    end

    if g_currentMission.isPlayerFrozen then
        return false
    end

    local spec = self.spec_enterable
    if not spec.isEntered or not spec.isControlled then
        -- if the vehicle we check if not entered we check if there is another enterable vehicle attached
        -- if yes we check if that vehicle is entered since only one vehicle in the "vehicle chain" has to be entered
        local noOtherEnterableIsEntered = true

        local vehicles = self.rootVehicle:getChildVehicles()
        for _, vehicle in ipairs(vehicles) do
            local vehicleSpec = vehicle.spec_enterable
            if vehicleSpec ~= nil then
                if vehicle ~= self then
                    if vehicleSpec.isEntered or vehicleSpec.isControlled then
                        noOtherEnterableIsEntered = false
                    end
                end
            end
        end

        if noOtherEnterableIsEntered then
            return false
        end
    end

    return true
end


---Returns distance between given object and enterReferenceNode
-- @param integer object id of object
-- @return float distance distance
function Enterable:getDistanceToNode(superFunc, node)
    local spec = self.spec_enterable

    local superDistance = superFunc(self, node)

    if spec == nil or spec.enterReferenceNode == nil then
        return superDistance
    end

    if not self:getIsControlled() then
        local px, py, pz = getWorldTranslation(node)
        local vx, vy, vz = getWorldTranslation(spec.enterReferenceNode)
        local distance = MathUtil.vector3Length(px-vx, py-vy, pz-vz)

        if distance < spec.interactionRadius and distance < superDistance then
            self.interactionFlag = Vehicle.INTERACTION_FLAG_ENTERABLE
            return distance
        end
    end

    return superDistance
end


---Returns interaction help text
-- @return string text text
function Enterable:getInteractionHelp(superFunc)
    if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE then
        return self.spec_enterable.enterText
    else
        return superFunc(self)
    end
end


---Interact
function Enterable:interact(superFunc, player)
    if self.interactionFlag == Vehicle.INTERACTION_FLAG_ENTERABLE then
        player:requestToEnterVehicle(self)
    else
        superFunc(self)
    end
end










---
function Enterable:setMirrorVisible(visible)
    local spec = self.spec_enterable

    if spec.mirrors == nil or next(spec.mirrors) == nil then
        return
    end

    if visible then
        local numVisibleMirrors = 0
        for _, mirror in pairs(spec.mirrors) do
            -- only update mirrors which parents are visible and are within the current view frustum
            if getEffectiveVisibility(mirror.parentNode) and getIsInCameraFrustum(mirror.node, spec.activeCamera.cameraNode, g_presentedScreenAspectRatio) then
                -- calculate angle between mirror and camera
                --local dirX, dirY, dirZ = worldToLocal(spec.activeCamera.cameraNode, getWorldTranslation(mirror.node))
                local dirX, dirY, dirZ = localToLocal(spec.activeCamera.cameraNode, mirror.node, 0,0,0)

                dirY = dirY * g_screenAspectRatio
                local length = MathUtil.vector3Length(dirX, dirY, dirZ)
                mirror.cosAngle = -dirZ / length
            else
                mirror.cosAngle = math.huge
            end
        end

        -- sort mirrors based on prio and angle
        table.sort(spec.mirrors,
                   function(mirror1, mirror2)
                        if mirror1.prio == mirror2.prio then
                            -- the bigger cosAngle, the smaller the angle to the z-axis
                            return mirror1.cosAngle > mirror2.cosAngle
                        else
                            return mirror1.prio < mirror2.prio
                        end
                   end)

        local maxNumMirrors = g_gameSettings:getValue(GameSettings.SETTING.MAX_NUM_MIRRORS)
        -- show first mirrors within the limit
        for _, mirror in ipairs(spec.mirrors) do
            if getEffectiveVisibility(mirror.parentNode) then  -- ignore mirrors which parents are not visible, e.g. as part of an inactive design config
                if mirror.cosAngle ~= math.huge and numVisibleMirrors < maxNumMirrors then
                    setVisibility(mirror.node, true)
                    numVisibleMirrors = numVisibleMirrors + 1
                else
                    setVisibility(mirror.node, false)
                end
            end
        end
    else
        for _, mirror in pairs(spec.mirrors) do
            setVisibility(mirror.node, false)
        end
    end
end


---
function Enterable:getIsTabbable()
    return self.spec_enterable.isTabbable
end


---
function Enterable:setIsTabbable(isTabbable)
    if isTabbable == nil then
        isTabbable = false
    end
    self.spec_enterable.isTabbable = isTabbable
end


---Get whether current player can enter this vehicle
-- Only works when isClient
function Enterable:getIsEnterable()
    local spec = self.spec_enterable
    return spec.enterReferenceNode ~= nil and spec.exitPoint ~= nil and not spec.isBroken and not spec.isControlled and g_currentMission.accessHandler:canPlayerAccess(self)
end


---Get whether current player can enter this vehicle from menu
-- Only works when isClient
function Enterable:getIsEnterableFromMenu()
    return self:getIsEnterable() and self.spec_enterable.canBeEnteredFromMenu
end


---
function Enterable:getIsEntered()
    return self.spec_enterable.isEntered
end


---
function Enterable:getIsControlled()
    return self.spec_enterable.isControlled
end


---
function Enterable:getControllerName()
    local user

    if self.isServer then
        user = g_currentMission.userManager:getUserByConnection(self:getOwnerConnection())
    else
        user = g_currentMission.userManager:getUserByUserId(self.spec_enterable.controllerUserId)
    end

    if user == nil then
        return ""
    end

    return user:getNickname()
end


---
function Enterable:getActiveCamera()
    return self.spec_enterable.activeCamera
end


---
function Enterable:getVehicleCharacter()
    return self.spec_enterable.vehicleCharacter
end


---
function Enterable:getAllowCharacterVisibilityUpdate()
    return true
end


---
function Enterable:getDisableVehicleCharacterOnLeave()
    return self.spec_enterable.disableCharacterOnLeave
end


---
function Enterable:getCanToggleSelectable(superFunc)
    if self:getIsEntered() then
        return true
    end
    return superFunc(self)
end


---
function Enterable:getCanToggleAttach(superFunc)
    if not self:getIsEntered() then
        return false
    end
    return superFunc(self)
end


---
function Enterable:getActiveFarm(superFunc)
    local spec = self.spec_enterable

    local farmId = spec.controllerFarmId
    if farmId ~= 0 then
        return farmId
    else
        return superFunc(self)
    end
end


---
function Enterable:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
    if not superFunc(self, xmlFile, key, group) then
        return false
    end

    group.isEntered = xmlFile:getValue(key .. "#isEntered")

    return true
end


---
function Enterable:getIsDashboardGroupActive(superFunc, group)
    if group.isEntered ~= nil then
        if group.isEntered ~= self:getIsEntered() then
            return false
        end
    end

    return superFunc(self, group)
end


---
function Enterable:mountDynamic(superFunc, object, objectActorId, jointNode, mountType, forceAcceleration)
    local spec = self.spec_enterable

    if spec.isControlled then
        return false
    end

    return superFunc(self, object, objectActorId, jointNode, mountType, forceAcceleration)
end


---
function Enterable:getIsInUse(superFunc, connection)
    local spec = self.spec_enterable
    if spec.isControlled and self:getOwnerConnection() ~= connection then
        return true
    end

    return superFunc(self, connection)
end


---
function Enterable:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end

    entry.updateCharacterTargetModifier = xmlFile:getValue(baseName.. "#updateCharacterTargetModifier", false)

    return true
end


---
function Enterable:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)

    if part.updateCharacterTargetModifier then
        self:setCharacterTargetNodeStateDirty(part.node, false)
    end
end


---
function Enterable:onPreRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    local spec = self.spec_enterable
    self:clearActionEventsTable(spec.actionEvents)
end


---
function Enterable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self:getIsEntered() then
        local spec = self.spec_enterable
        if g_touchHandler ~= nil then
            g_touchHandler:removeGestureListener(self.touchListenerDoubleTab)
        end

        if self:getIsActiveForInput(true, true) then
            g_localPlayer.inputComponent:registerGlobalPlayerActionEvents(Vehicle.INPUT_CONTEXT_NAME)

            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ENTER, self, Enterable.actionEventLeave, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

            if spec.numCameras > 1 then
                _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CAMERA_SWITCH, self, Enterable.actionEventCameraSwitch, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
                g_inputBinding:setActionEventTextVisibility(actionEventId, true)
            end

            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.CAMERA_ZOOM_IN_OUT, self, Enterable.actionEventCameraZoomInOut, false, true, true, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

            _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.RESET_HEAD_TRACKING, self, Enterable.actionEventResetHeadTracking, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
            g_inputBinding:setActionEventTextVisibility(actionEventId, false)

            if g_touchHandler ~= nil then
                self.touchListenerDoubleTab = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_DOUBLE_TAP, Enterable.actionEventCameraSwitch, self)
            end

            -- stop and reenter modification of vehicle context since activatableObjectsSystem is doing this on it's own and leaving the modification after this call
            g_inputBinding:endActionEventsModification()
            g_currentMission.activatableObjectsSystem:activate(Vehicle.INPUT_CONTEXT_NAME)
            g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
        end
    end
end


---
function Enterable:onSetBroken()
    local spec = self.spec_enterable
    if spec.isEntered then
        g_localPlayer:leaveVehicle()
    end
end


---
function Enterable.actionEventLeave(self, actionName, inputValue, callbackState, isAnalog)
    self:doLeaveVehicle()
end


---
function Enterable.actionEventCameraSwitch(self, actionName, inputValue, callbackState, isAnalog)
    if not g_gui:getIsGuiVisible() and self:getIsEntered() then
        local spec = self.spec_enterable
        self:setActiveCameraIndex(spec.camIndex + 1)
    end
end














---
function Enterable.actionEventResetHeadTracking(self, actionName, inputValue, callbackState, isAnalog)
    centerHeadTracking()
end
