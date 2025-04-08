
































































---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function Lights.prerequisitesPresent(specializations)
    return true
end


---Called on specialization initializing
function Lights.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("beaconLight", g_i18n:getText("configuration_beacon"), "lights", VehicleConfigurationItem)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Lights")

    schema:register(XMLValueType.FLOAT, "vehicle.lights#reverseLightActivationSpeed", "Speed which needs to be reached to activate reverse lights (km/h)", 1)

    schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.state(?)#lightTypes", "Light states")

    schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.automaticState#lightTypes", "Light states while ai is active", "0")
    schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.automaticState#lightTypesWork", "Light states while ai is working", "0 1 2")

    SharedLight.registerXMLPaths(schema, "vehicle.lights.sharedLight(?)")

    Lights.registerRealLightSetupXMLPath(schema, "vehicle.lights.realLights.low")
    Lights.registerRealLightSetupXMLPath(schema, "vehicle.lights.realLights.high")

    StaticLight.registerXMLPaths(schema, "vehicle.lights.defaultLights.defaultLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.topLights.topLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.bottomLights.bottomLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.brakeLights.brakeLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.reverseLights.reverseLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.dayTimeLights.dayTimeLight(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.turnLights.turnLightLeft(?)")
    StaticLight.registerXMLPaths(schema, "vehicle.lights.turnLights.turnLightRight(?)")

    StaticLightCompound.registerXMLPaths(schema, "vehicle.lights.staticLightCompounds.staticLightCompound(?)")

    BeaconLight.registerVehicleXMLPaths(schema, "vehicle.lights.beaconLights.beaconLight(?)")
    schema:register(XMLValueType.BOOL, "vehicle.lights.beaconLights.beaconLight(?)#alwaysActive", "Defines if the beacon light is always active while the vehicle is entered", false)
    BeaconLight.registerVehicleXMLPaths(schema, "vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(?).beaconLight(?)")
    schema:register(XMLValueType.BOOL, "vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(?).beaconLight(?)#alwaysActive", "Defines if the beacon light is always active while the vehicle is entered", false)

    SoundManager.registerSampleXMLPaths(schema, "vehicle.lights.sounds", "toggleLights")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.lights.sounds", "turnLight")

    Dashboard.registerDashboardXMLPaths(schema, "vehicle.lights.dashboards", {"lightState", "turnLightLeft", "turnLightRight", "turnLight", "turnLightHazard", "turnLightAny", "beaconLight"})

    Dashboard.addDelayedRegistrationFunc(schema, function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#lightTypes", "Light types")
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#excludedLightTypes", "Excluded light types")
    end)

    for i=1, #Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS do
        local key = Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS[i]
        schema:register(XMLValueType.BOOL, key .. "#isTopLight", "Light is only active when switched to top light mode", false)
        schema:register(XMLValueType.BOOL, key .. "#isBottomLight", "Light is only active when not switched to top light mode", false)
    end

    schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#lightTypes", "Defined light types need to be enabled to activate group")
    schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#excludedLightTypes", "Defined light types need to be disabled to activate group")

    schema:setXMLSpecializationType()
end


---
function Lights.registerRealLightSetupXMLPath(schema, basePath)
    RealLight.registerXMLPaths(schema, basePath .. ".light(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".topLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".bottomLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".brakeLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".reverseLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".dayTimeLight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".turnLightLeft(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".turnLightRight(?)")
    RealLight.registerXMLPaths(schema, basePath .. ".interiorLight(?)")
end


---
function Lights.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onTurnLightStateChanged")
    SpecializationUtil.registerEvent(vehicleType, "onTopLightsVisibilityChanged")
    SpecializationUtil.registerEvent(vehicleType, "onBrakeLightsVisibilityChanged")
    SpecializationUtil.registerEvent(vehicleType, "onReverseLightsVisibilityChanged")
    SpecializationUtil.registerEvent(vehicleType, "onLightsTypesMaskChanged")
    SpecializationUtil.registerEvent(vehicleType, "onBeaconLightsVisibilityChanged")
end


---
function Lights.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadRealLightSetup",                   Lights.loadRealLightSetup)
    SpecializationUtil.registerFunction(vehicleType, "applyAdditionalActiveLightType",       Lights.applyAdditionalActiveLightType)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForLights",                 Lights.getIsActiveForLights)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInteriorLights",         Lights.getIsActiveForInteriorLights)
    SpecializationUtil.registerFunction(vehicleType, "getCanToggleLight",                    Lights.getCanToggleLight)
    SpecializationUtil.registerFunction(vehicleType, "getUseHighProfile",                    Lights.getUseHighProfile)
    SpecializationUtil.registerFunction(vehicleType, "setNextLightsState",                   Lights.setNextLightsState)
    SpecializationUtil.registerFunction(vehicleType, "setLightsTypesMask",                   Lights.setLightsTypesMask)
    SpecializationUtil.registerFunction(vehicleType, "getLightsTypesMask",                   Lights.getLightsTypesMask)
    SpecializationUtil.registerFunction(vehicleType, "setTurnLightState",                    Lights.setTurnLightState)
    SpecializationUtil.registerFunction(vehicleType, "getTurnLightState",                    Lights.getTurnLightState)
    SpecializationUtil.registerFunction(vehicleType, "setTopLightsVisibility",               Lights.setTopLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setBrakeLightsVisibility",             Lights.setBrakeLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setBeaconLightsVisibility",            Lights.setBeaconLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "getBeaconLightsVisibility",            Lights.getBeaconLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setReverseLightsVisibility",           Lights.setReverseLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "setInteriorLightsVisibility",          Lights.setInteriorLightsVisibility)
    SpecializationUtil.registerFunction(vehicleType, "getInteriorLightBrightness",           Lights.getInteriorLightBrightness)
    SpecializationUtil.registerFunction(vehicleType, "deactivateLights",                     Lights.deactivateLights)
    SpecializationUtil.registerFunction(vehicleType, "getDeactivateLightsOnLeave",           Lights.getDeactivateLightsOnLeave)
    SpecializationUtil.registerFunction(vehicleType, "loadSharedLight",                      Lights.loadSharedLight)
    SpecializationUtil.registerFunction(vehicleType, "loadAdditionalLightAttributesFromXML", Lights.loadAdditionalLightAttributesFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsLightActive",                     Lights.getIsLightActive)
    SpecializationUtil.registerFunction(vehicleType, "getStaticLightFromNode",               Lights.getStaticLightFromNode)
    SpecializationUtil.registerFunction(vehicleType, "getRealLightFromNode",                 Lights.getRealLightFromNode)
    SpecializationUtil.registerFunction(vehicleType, "updateAutomaticLights",                Lights.updateAutomaticLights)
    SpecializationUtil.registerFunction(vehicleType, "lightsWeatherChanged",                 Lights.lightsWeatherChanged)
    SpecializationUtil.registerFunction(vehicleType, "onLightsProfileChanged",               Lights.onLightsProfileChanged)
    SpecializationUtil.registerFunction(vehicleType, "onLightsRealBeaconLightChanged",       Lights.onLightsRealBeaconLightChanged)
    SpecializationUtil.registerFunction(vehicleType, "deactivateBeaconLights",               Lights.deactivateBeaconLights)
end


---
function Lights.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Lights.loadDashboardGroupFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Lights.getIsDashboardGroupActive)
end


---
function Lights.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onStartMotor", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onStopMotor", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onStartReverseDirectionChange", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAutomatedTrainTravelActive", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableActive", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableEnd", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerActive", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIJobVehicleBlock", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIJobVehicleContinue", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onVehiclePhysicsUpdate", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Lights)
    SpecializationUtil.registerEventListener(vehicleType, "onRequiresTopLightsChanged", Lights)
end


---Called on loading
-- @param table savegame savegame
function Lights:onLoad(savegame)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#decoration", "vehicle.lights.defaultLights#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#decoration", "vehicle.lights.defaultLights#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#realLight", "vehicle.lights.realLights.low.light#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#realLight", "vehicle.lights.realLights.high.light#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#realLight", "vehicle.lights.realLights.high.brakeLight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#decoration", "vehicle.lights.brakeLights.brakeLight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#realLight", "vehicle.lights.realLights.high.turnLightLeft#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#decoration", "vehicle.lights.turnLights.turnLightLeft#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#realLight", "vehicle.lights.realLights.high.turnLightRight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#decoration", "vehicle.lights.turnLights.turnLightRight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.states.aiState#lightTypes", "vehicle.lights.states.automaticState#lightTypes") --FS22 to FS25
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.states.aiState#lightTypesWork", "vehicle.lights.states.automaticState#lightTypesWork") --FS22 to FS25

    local spec = self.spec_lights

    spec.reverseLightActivationSpeed = self.xmlFile:getValue("vehicle.lights#reverseLightActivationSpeed", 1) / 3600

    spec.sharedLoadRequestIds = {}
    spec.xmlLoadingHandles = {}

    spec.lightsTypesMask = 0
    spec.currentLightState = 0
    spec.maxLightState = Lights.LIGHT_TYPE_HIGHBEAM
    spec.numLightTypes = 0
    spec.lightStates = {}
    spec.lastIsActiveForLights = false

    local registeredLightTypes = {}
    local i = 0
    while true do
        local key = string.format("vehicle.lights.states.state(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local lightTypes = self.xmlFile:getValue(key.."#lightTypes", nil, true) or {}
        for _, lightType in pairs(lightTypes) do
            if registeredLightTypes[lightType] == nil then
                registeredLightTypes[lightType] = lightType
                spec.numLightTypes = spec.numLightTypes + 1
                spec.maxLightState = math.max(spec.maxLightState, lightType)
            end
        end

        table.insert(spec.lightStates, lightTypes)
        i = i + 1
    end

    local loadLightsMaskFromXML = function(xmlFile, key, default)
        local lightTypes = xmlFile:getValue(key, default, true)
        local lightsTypesMask = 0
        for _, lightType in pairs(lightTypes) do
            lightsTypesMask = bitOR(lightsTypesMask, 2^lightType)
        end

        return lightsTypesMask
    end

    spec.automaticLightsTypesMask = loadLightsMaskFromXML(self.xmlFile, "vehicle.lights.states.automaticState#lightTypes", "0")
    spec.automaticLightsTypesMaskWork = loadLightsMaskFromXML(self.xmlFile, "vehicle.lights.states.automaticState#lightTypesWork", "0 1 2")

    spec.interiorLightsBrightness = 0
    spec.interiorLightsAvailable = false

    spec.realLights = {}

    spec.realLights.low = {}
    self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.low", spec.realLights.low)

    spec.realLights.high = {}
    self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.high", spec.realLights.high)

    spec.staticLights = {}
    spec.staticLights.defaultLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.defaultLights.defaultLight", self, self.components, self.i3dMappings, true)
    spec.staticLights.topLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.topLights.topLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.bottomLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.bottomLights.bottomLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.brakeLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.brakeLights.brakeLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.reverseLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.reverseLights.reverseLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.dayTimeLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.dayTimeLights.dayTimeLight", self, self.components, self.i3dMappings, false)
    spec.staticLights.turnLightsLeft = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.turnLights.turnLightLeft", self, self.components, self.i3dMappings, false)
    spec.staticLights.turnLightsRight = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.turnLights.turnLightRight", self, self.components, self.i3dMappings, false)

    spec.staticLightCompounds = {}
    for _, compoundKey in self.xmlFile:iterator("vehicle.lights.staticLightCompounds.staticLightCompound") do
        local staticLightCompound = StaticLightCompound.new(self)
        if staticLightCompound:loadFromXML(self.xmlFile, compoundKey, self.components, self.i3dMappings, self) then
            table.insert(spec.staticLightCompounds, staticLightCompound)
        end
    end

    spec.sharedLights = {}
    self.xmlFile:iterate("vehicle.lights.sharedLight", function (_, key)
        self:loadSharedLight(self.xmlFile, key)
    end)

    for _, lights in pairs(spec.staticLights) do
        for _, staticLight in ipairs(lights) do
            if staticLight.lightTypes ~= nil then
                spec.maxLightState = math.max(spec.maxLightState, unpack(staticLight.lightTypes))
            end
        end
    end

    for _, profile in pairs(spec.realLights) do
        for _, lights in pairs(profile) do
            for _, realLight in ipairs(lights) do
                if realLight.lightTypes ~= nil then
                    spec.maxLightState = math.max(spec.maxLightState, unpack(realLight.lightTypes))
                end
            end
        end
    end

    spec.maxLightStateMask = 2 ^ (spec.maxLightState + 1) - 1

    spec.additionalLightTypes = {}
    spec.additionalLightTypes.bottomLight = spec.maxLightState + 1
    spec.additionalLightTypes.topLight = spec.maxLightState + 2
    spec.additionalLightTypes.brakeLight = spec.maxLightState + 3
    spec.additionalLightTypes.turnLightLeft = spec.maxLightState + 4
    spec.additionalLightTypes.turnLightRight = spec.maxLightState + 5
    spec.additionalLightTypes.turnLightAny = spec.maxLightState + 6
    spec.additionalLightTypes.reverseLight = spec.maxLightState + 7
    spec.additionalLightTypes.interiorLight = spec.maxLightState + 8
    spec.totalNumLightTypes = spec.additionalLightTypes.interiorLight + 1 -- including lightType 0
    if spec.totalNumLightTypes > 31 then
        Logging.xmlError(self.xmlFile, "Max. number of light types reached (31). Please reduce them.")
        spec.totalNumLightTypes = 31
    end

    spec.topLightsVisibility = false
    spec.brakeLightsVisibility = false
    spec.reverseLightsVisibility = false
    spec.turnLightState = Lights.TURNLIGHT_OFF
    spec.turnLightTriState = 0.5
    spec.turnLightRepetitionCount = nil

    spec.actionEventsActiveChange = {}

    spec.beaconLightsActive = false
    spec.beaconLights = {}
    spec.alwaysActiveBeaconLights = {}

    local configKey = string.format("vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(%d)", (self.configurations["beaconLight"] or 1) - 1)
    self.xmlFile:iterate(configKey .. ".beaconLight", function (_, key)
        if self.xmlFile:hasProperty(key.."#alwaysActive") then
            BeaconLight.loadFromVehicleXML(spec.alwaysActiveBeaconLights, self.xmlFile, key, self)
        else
            BeaconLight.loadFromVehicleXML(spec.beaconLights, self.xmlFile, key, self)
        end
    end)

    self.xmlFile:iterate("vehicle.lights.beaconLights.beaconLight", function (_, key)
        if self.xmlFile:hasProperty(key.."#alwaysActive") then
            BeaconLight.loadFromVehicleXML(spec.alwaysActiveBeaconLights, self.xmlFile, key, self)
        else
            BeaconLight.loadFromVehicleXML(spec.beaconLights, self.xmlFile, key, self)
        end
    end)

    if self.isClient ~= nil then
        spec.samples = {}
        spec.samples.toggleLights = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "toggleLights", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.turnLight = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "turnLight", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.lightsWeatherChanged, self)
    end

    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.LIGHTS_PROFILE], self.onLightsProfileChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.REAL_BEACON_LIGHTS], self.onLightsRealBeaconLightChanged, self)
end


---Called after loading
-- @param table savegame savegame
function Lights:onLoadFinished(savegame)
    local spec = self.spec_lights

    self:applyAdditionalActiveLightType(spec.staticLights.topLights, spec.additionalLightTypes.topLight)
    self:applyAdditionalActiveLightType(spec.staticLights.bottomLights, spec.additionalLightTypes.bottomLight)
    self:applyAdditionalActiveLightType(spec.staticLights.brakeLights, spec.additionalLightTypes.brakeLight)
    self:applyAdditionalActiveLightType(spec.staticLights.reverseLights, spec.additionalLightTypes.reverseLight)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsLeft, spec.additionalLightTypes.turnLightLeft, true)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsLeft, spec.additionalLightTypes.turnLightAny, true)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsRight, spec.additionalLightTypes.turnLightRight, true)
    self:applyAdditionalActiveLightType(spec.staticLights.turnLightsRight, spec.additionalLightTypes.turnLightAny, true)

    for _, profile in pairs(spec.realLights) do
        self:applyAdditionalActiveLightType(profile.topLights, spec.additionalLightTypes.topLight)
        self:applyAdditionalActiveLightType(profile.bottomLights, spec.additionalLightTypes.bottomLight)
        self:applyAdditionalActiveLightType(profile.brakeLights, spec.additionalLightTypes.brakeLight)
        self:applyAdditionalActiveLightType(profile.reverseLights, spec.additionalLightTypes.reverseLight)
        self:applyAdditionalActiveLightType(profile.turnLightsLeft, spec.additionalLightTypes.turnLightLeft, true)
        self:applyAdditionalActiveLightType(profile.turnLightsLeft, spec.additionalLightTypes.turnLightAny, true)
        self:applyAdditionalActiveLightType(profile.turnLightsRight, spec.additionalLightTypes.turnLightRight, true)
        self:applyAdditionalActiveLightType(profile.turnLightsRight, spec.additionalLightTypes.turnLightAny, true)
        self:applyAdditionalActiveLightType(profile.interiorLights, spec.additionalLightTypes.interiorLight)

        for _, lights in pairs(profile) do
            for _, realLight in ipairs(lights) do
                realLight:finalize()
            end
        end
    end

    if self:getIsInShowroom() then
        for _, staticLight in ipairs(spec.staticLights.dayTimeLights) do
            staticLight:setState(true)
        end
    end
end


---Called on post load to register dashboard value types
function Lights:onRegisterDashboardValueTypes()
    local spec = self.spec_lights

    local lightState = DashboardValueType.new("lights", "lightState")
    lightState:setValue(spec, function(_, dashboard)
        if dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
            return spec.lightsTypesMask
        end

        local lightIsActive = false
        if dashboard.lightTypes ~= nil then
            for _, lightType in pairs(dashboard.lightTypes) do
                if bitAND(spec.lightsTypesMask, 2^lightType) ~= 0 or (lightType == -1 and self:getIsActiveForLights(true)) then
                    lightIsActive = true
                    break
                end
            end
        end

        if lightIsActive and dashboard.excludedLightTypes ~= nil then
            for _, excludedLightType in pairs(dashboard.excludedLightTypes) do
                if bitAND(spec.lightsTypesMask, 2^excludedLightType) ~= 0 then
                    lightIsActive = false
                    break
                end
            end
        end

        return lightIsActive and 1 or 0
    end)
    lightState:setAdditionalFunctions(Lights.dashboardLightAttributes, Lights.dashboardLightState)
    self:registerDashboardValueType(lightState)

    local turnLightLeft = DashboardValueType.new("lights", "turnLightLeft")
    turnLightLeft:setValue(spec, "turnLightState")
    turnLightLeft:setValueCompare(Lights.TURNLIGHT_LEFT, Lights.TURNLIGHT_HAZARD)
    self:registerDashboardValueType(turnLightLeft)

    local turnLightRight = DashboardValueType.new("lights", "turnLightRight")
    turnLightRight:setValue(spec, "turnLightState")
    turnLightRight:setValueCompare(Lights.TURNLIGHT_RIGHT, Lights.TURNLIGHT_HAZARD)
    self:registerDashboardValueType(turnLightRight)

    local turnLight = DashboardValueType.new("lights", "turnLight")
    turnLight:setValue(spec, "turnLightTriState")
    turnLight:setIdleValue(0.5)
    self:registerDashboardValueType(turnLight)

    local turnLightHazard = DashboardValueType.new("lights", "turnLightHazard")
    turnLightHazard:setValue(spec, "turnLightState")
    turnLightHazard:setValueCompare(Lights.TURNLIGHT_HAZARD)
    self:registerDashboardValueType(turnLightHazard)

    local turnLightAny = DashboardValueType.new("lights", "turnLightAny")
    turnLightAny:setValue(spec, "turnLightState")
    turnLightAny:setValueCompare(Lights.TURNLIGHT_LEFT, Lights.TURNLIGHT_RIGHT, Lights.TURNLIGHT_HAZARD)
    self:registerDashboardValueType(turnLightAny)

    local beaconLight = DashboardValueType.new("lights", "beaconLight")
    beaconLight:setValue(spec, function(_spec) return _spec.beaconLightsActive and 1 or 0 end)
    self:registerDashboardValueType(beaconLight)
end


---Called on deleting
function Lights:onDelete()
    local spec = self.spec_lights

    if spec.sharedLights ~= nil then
        for _, sharedLight in ipairs(spec.sharedLights) do
            sharedLight:delete()
        end
        spec.sharedLights = {}
    end

    if spec.beaconLights ~= nil then
        for _, beaconLight in ipairs(spec.beaconLights) do
            beaconLight:delete()
        end
        spec.beaconLights = {}
    end

    if spec.alwaysActiveBeaconLights ~= nil then
        for _, beaconLight in ipairs(spec.alwaysActiveBeaconLights) do
            beaconLight:delete()
        end
        spec.alwaysActiveBeaconLights = {}
    end

    if spec.xmlLoadingHandles ~= nil then
        for lightXMLFile, _ in pairs(spec.xmlLoadingHandles) do
            lightXMLFile:delete()
            spec.xmlLoadingHandles[lightXMLFile] = nil
        end
    end

    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
    end

    if spec.staticLightCompounds ~= nil then
        spec.staticLightCompounds = {}
    end

    g_soundManager:deleteSamples(spec.samples)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function Lights:onReadStream(streamId, connection)
    local spec = self.spec_lights

    local lightsTypesMask = streamReadUIntN(streamId, spec.totalNumLightTypes)
    self:setLightsTypesMask(lightsTypesMask, true, true)

    local beaconLightsActive = streamReadBool(streamId)
    self:setBeaconLightsVisibility(beaconLightsActive, true, true)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function Lights:onWriteStream(streamId, connection)
    local spec = self.spec_lights

    streamWriteUIntN(streamId, spec.lightsTypesMask, spec.totalNumLightTypes)
    streamWriteBool(streamId, spec.beaconLightsActive)
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function Lights:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isClient then
        local spec = self.spec_lights
        if spec.turnLightState ~= Lights.TURNLIGHT_OFF then
            local shaderTime = getShaderTimeSec()
            local _, fracTime = math.modf(shaderTime)
            local alpha = math.clamp(4 * math.abs(fracTime - 0.5) - 0.8, 0, 1)

            if spec.turnLightState == Lights.TURNLIGHT_LEFT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
                for _, light in pairs(spec.activeTurnLightSetup.turnLightsLeft) do
                    light:setCharge(alpha)
                end
            end
            if spec.turnLightState == Lights.TURNLIGHT_RIGHT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
                for _, light in pairs(spec.activeTurnLightSetup.turnLightsRight) do
                    light:setCharge(alpha)
                end
            end

            if spec.samples.turnLight ~= nil then
                if isActiveForInputIgnoreSelection then
                    local turnLightRepetitionCount = math.floor(shaderTime - 0.8)
                    if spec.turnLightRepetitionCount ~= nil and turnLightRepetitionCount ~= spec.turnLightRepetitionCount then
                        g_soundManager:playSample(spec.samples.turnLight)
                    end
                    spec.turnLightRepetitionCount = turnLightRepetitionCount
                end
            end

            self:raiseActive()
        end
    end
end


---
function Lights:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isClient then
        local spec = self.spec_lights
        local isActiveForLights = self:getIsActiveForLights()

        if isActiveForLights ~= spec.lastIsActiveForLights then
            for _, beaconLight in ipairs(spec.alwaysActiveBeaconLights) do
                beaconLight:setIsActive(isActiveForLights)
            end

            spec.lastIsActiveForLights = isActiveForLights
        end

        if spec.interiorLightsAvailable then
            self:setInteriorLightsVisibility(self:getIsActiveForInteriorLights())
        end

        for _, v in ipairs(spec.actionEventsActiveChange) do
            g_inputBinding:setActionEventActive(v, isActiveForLights)
        end
        g_inputBinding:setActionEventActive(spec.actionEventIdLight, isActiveForLights)

        if Platform.gameplay.automaticLights then
            if self == self.rootVehicle then
                if not self:getIsAIActive() then
                    self:updateAutomaticLights(not g_currentMission.environment.isSunOn and isActiveForLights, self.rootVehicle:getActionControllerDirection() == -1)
                end
            end
        end
    end
end


---Returns if is active for lights
-- @return boolean isActive is active for lights
function Lights:getIsActiveForLights(onlyPowered)
    if onlyPowered == true then
        if not self:getIsPowered() then
            return false
        end
    end

    if self.getIsEntered ~= nil and self:getIsEntered() and self:getCanToggleLight() then
        return true
    end

    if self.attacherVehicle ~= nil then
        return self.attacherVehicle:getIsActiveForLights()
    end

    return false
end


---Returns if is active for interior lights
-- @return boolean isActive is active for interior lights
function Lights:getIsActiveForInteriorLights()
    return false
end


---Returns if lights can be toggled
-- @return boolean canBeToggled lights can be toggled
function Lights:getCanToggleLight()
    local spec = self.spec_lights

    if self:getIsAIActive() then
        return false
    end

    if spec.numLightTypes == 0 then
        return false
    end

    if g_localPlayer:getCurrentVehicle() == self then
        return true
    else
        return false
    end
end


---Returns if high profile is used
-- @return boolean highProfileUsed high profile is used
function Lights:getUseHighProfile()
    local lightsProfile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
    lightsProfile = Utils.getNoNil(Platform.gameplay.lightsProfile, lightsProfile)

    return lightsProfile >= GS_PROFILE_HIGH
end


---
function Lights:setNextLightsState(increment)
    local spec = self.spec_lights

    if spec.lightStates ~= nil and #spec.lightStates > 0 then
        local oldLightsTypesMask = bitAND(spec.lightsTypesMask, spec.maxLightStateMask)

        local currentLightState = spec.currentLightState + increment
        if currentLightState > #spec.lightStates or (spec.currentLightState == 0 and oldLightsTypesMask > 0) then
            currentLightState = 0
        elseif currentLightState < 0 then
            currentLightState = #spec.lightStates
        end

        -- copy the upper bits from the old mask and set the other bits new
        local lightsTypesMask = bitAND(spec.lightsTypesMask, bitNOT(spec.maxLightStateMask))

        if currentLightState > 0 then
            for _, lightType in pairs(spec.lightStates[currentLightState]) do
                lightsTypesMask = bitOR(lightsTypesMask, 2^lightType)
            end
        end
        spec.currentLightState = currentLightState

        self:setLightsTypesMask(lightsTypesMask)
    end
end


---Set light type mask
-- @param integer lightsTypesMask new light types mask
-- @param boolean force force action
-- @param boolean noEventSend no event send
-- @return boolean changed mask has changed
function Lights:setLightsTypesMask(lightsTypesMask, force, noEventSend)
    local spec = self.spec_lights

    -- as server we apply the bits for the additional light types, client already receives the mask including these bits
    if self.isServer then
        lightsTypesMask = bitAND(lightsTypesMask, spec.maxLightStateMask)
        if spec.turnLightState == Lights.TURNLIGHT_LEFT then
            lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightLeft)
        end
        if spec.turnLightState == Lights.TURNLIGHT_RIGHT then
            lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightRight)
        end
        if spec.turnLightState == Lights.TURNLIGHT_HAZARD then
            lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.turnLightAny)
        end
        if bitAND(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 then
            if spec.topLightsVisibility then
                lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.topLight)
            else
                lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.bottomLight)
            end
        end
        if spec.brakeLightsVisibility then
            lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.brakeLight)
        end
        if spec.reverseLightsVisibility then
            lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.reverseLight)
        end
        if spec.interiorLightsVisibility then
            lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.interiorLight)
        end
    else
        -- update bottom/top light and interior lights on client side depending on local state
        lightsTypesMask = bitAND(lightsTypesMask, bitNOT(2 ^ spec.additionalLightTypes.bottomLight))
        lightsTypesMask = bitAND(lightsTypesMask, bitNOT(2 ^ spec.additionalLightTypes.interiorLight))
        if bitAND(lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT) ~= 0 then
            if spec.topLightsVisibility then
                lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.topLight)
            else
                lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.bottomLight)
            end
        end

        lightsTypesMask = bitAND(lightsTypesMask, bitNOT(2 ^ spec.additionalLightTypes.topLight))
        if spec.interiorLightsVisibility then
            lightsTypesMask = bitOR(lightsTypesMask, 2 ^ spec.additionalLightTypes.interiorLight)
        end
    end

    if lightsTypesMask ~= spec.lightsTypesMask or force then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(VehicleSetLightEvent.new(self, lightsTypesMask, spec.totalNumLightTypes), nil, nil, self)
            else
                g_client:getServerConnection():sendEvent(VehicleSetLightEvent.new(self, lightsTypesMask, spec.totalNumLightTypes))
            end
        end

        -- only check for manual switched light states
        if bitAND(lightsTypesMask, spec.maxLightStateMask) ~= bitAND(spec.lightsTypesMask, spec.maxLightStateMask) then
            if self.isClient then
                g_soundManager:playSample(spec.samples.toggleLights)
            end
        end

        local activeLightSetup = spec.realLights.low
        if self:getUseHighProfile() then
            activeLightSetup = spec.realLights.high
        end

        for _, lights in pairs(spec.staticLights) do
            for _, staticLight in ipairs(lights) do
                staticLight:setLightTypesMask(lightsTypesMask)
            end
        end

        for _, profile in pairs(spec.realLights) do
            for _, lights in pairs(profile) do
                for _, realLight in ipairs(lights) do
                    realLight:setLightTypesMask(profile == activeLightSetup and lightsTypesMask or 0)
                end
            end
        end

        for _, staticLightCompound in pairs(spec.staticLightCompounds) do
            staticLightCompound:setLightTypesMask(lightsTypesMask, self)
        end

        spec.lightsTypesMask = lightsTypesMask

        SpecializationUtil.raiseEvent(self, "onLightsTypesMaskChanged", lightsTypesMask)
    end

    return true
end


---Get light type mask
-- @return integer lightsTypesMask light types mask
function Lights:getLightsTypesMask()
    return self.spec_lights.lightsTypesMask
end


---Toggle beacon light visibility
-- @param boolean visibility new visibility state
-- @param boolean force force action
-- @param boolean noEventSend no event send
-- @return boolean changed visibility has changed
function Lights:setBeaconLightsVisibility(visibility, force, noEventSend)
    local spec = self.spec_lights

    if visibility ~= spec.beaconLightsActive or force then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(VehicleSetBeaconLightEvent.new(self, visibility), nil, nil, self)
            else
                g_client:getServerConnection():sendEvent(VehicleSetBeaconLightEvent.new(self, visibility))
            end
        end

        local isActiveForInput = self:getIsActiveForInput(true)

        spec.beaconLightsActive = visibility
        for _, beaconLight in pairs(spec.beaconLights) do
            beaconLight:setIsActive(visibility)

            if isActiveForInput then
                beaconLight:setDeviceIsActive(visibility)
            end
        end

        SpecializationUtil.raiseEvent(self, "onBeaconLightsVisibilityChanged", visibility)
    end

    return true
end


---Get beacon light state
-- @return boolean state beacon light state
function Lights:getBeaconLightsVisibility()
    return self.spec_lights.beaconLightsActive
end


---Toggle turn light state
-- @param integer state new state, one of the constants Lights.TURNLIGHT_*
-- @param boolean force force action
-- @param boolean noEventSend no event send
-- @return boolean changed state has changed
function Lights:setTurnLightState(state, force, noEventSend)
    local spec = self.spec_lights

    if state ~= spec.turnLightState or force then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(VehicleSetTurnLightEvent.new(self, state), nil, nil, self)
            else
                g_client:getServerConnection():sendEvent(VehicleSetTurnLightEvent.new(self, state))
            end
        end

        local activeLightSetup = spec.realLights.low
        if self:getUseHighProfile() then
            activeLightSetup = spec.realLights.high
        end

        spec.activeTurnLightSetup = activeLightSetup

        spec.turnLightState = state

        spec.turnLightTriState = spec.turnLightState == Lights.TURNLIGHT_LEFT and 0 or (spec.turnLightState == Lights.TURNLIGHT_RIGHT and 1 or 0.5)

        spec.turnLightRepetitionCount = nil -- reset the sound, so we don't play it doubled after activating

        if self.isServer then
            self:setLightsTypesMask(spec.lightsTypesMask, nil)
        end

        SpecializationUtil.raiseEvent(self, "onTurnLightStateChanged", state)
    end

    return true
end


---Get turn light state
-- @return integer state turn light state
function Lights:getTurnLightState()
    return self.spec_lights.turnLightState
end


---Set top light visibility
-- @param boolean visibility new visibility
-- @return boolean changed visibility has changed
function Lights:setTopLightsVisibility(visibility)
    local spec = self.spec_lights

    if visibility ~= spec.topLightsVisibility then
        spec.topLightsVisibility = visibility

        self:setLightsTypesMask(spec.lightsTypesMask)

        SpecializationUtil.raiseEvent(self, "onTopLightsVisibilityChanged", visibility)
    end

    return true
end


---Set brake light visibility
-- @param boolean visibility new visibility
-- @return boolean changed visibility has changed
function Lights:setBrakeLightsVisibility(visibility)
    local spec = self.spec_lights

    if visibility ~= spec.brakeLightsVisibility then
        spec.brakeLightsVisibility = visibility

        self:setLightsTypesMask(spec.lightsTypesMask)

        SpecializationUtil.raiseEvent(self, "onBrakeLightsVisibilityChanged", visibility)
    end

    return true
end


---Set reverse light visibility
-- @param boolean visibility new visibility
-- @return boolean changed visibility has changed
function Lights:setReverseLightsVisibility(visibility)
    local spec = self.spec_lights

    if visibility ~= spec.reverseLightsVisibility then
        spec.reverseLightsVisibility = visibility

        self:setLightsTypesMask(spec.lightsTypesMask)

        SpecializationUtil.raiseEvent(self, "onReverseLightsVisibilityChanged", visibility)
    end

    return true
end


---Set interior light visibility
-- @param boolean visibility new visibility
-- @return boolean changed visibility has changed
function Lights:setInteriorLightsVisibility(visibility)
    local spec = self.spec_lights

    local brightness, hasChanged = self:getInteriorLightBrightness(true)
    if brightness == 0 then
        visibility = false
    end

    if visibility ~= spec.interiorLightsVisibility or hasChanged then
        spec.interiorLightsVisibility = visibility

        self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    end

    return true
end


---Returns tnterior light brightness
-- @param boolean updateState brightness is recalculated
-- @return float brightness brightness
-- @return boolean changed value changed
function Lights:getInteriorLightBrightness(updateState)
    local spec = self.spec_lights

    local changed = false
    if updateState then
        -- interior lights are turned of between 8am and 10am and turn on between 4pm and 6pm
        local brightness = 0
        local hour = g_currentMission.environment.currentHour + g_currentMission.environment.currentMinute / 60
        if hour < 10 then
            brightness = 1-(hour - 8) / 2
        end
        if hour > 16 then
            brightness = (hour - 16) / 2
        end

        local oldBrightness = spec.interiorLightsBrightness
        spec.interiorLightsBrightness = math.clamp(brightness, 0, 1)
        changed = spec.interiorLightsBrightness ~= oldBrightness
    end

    return spec.interiorLightsBrightness, changed
end


---
function Lights:deactivateLights(keepHazardLightsOn)
    local spec = self.spec_lights

    self:setLightsTypesMask(0, true, true)
    self:setBeaconLightsVisibility(false, true, true)
    if not keepHazardLightsOn or spec.turnLightState ~= Lights.TURNLIGHT_HAZARD then
        self:setTurnLightState(Lights.TURNLIGHT_OFF, true, true)
    end
    self:setBrakeLightsVisibility(false)
    self:setReverseLightsVisibility(false)
    self:setInteriorLightsVisibility(false)

    spec.currentLightState = 0
end


---Deactivate real physical beacon lights
function Lights:deactivateBeaconLights()
    local spec = self.spec_lights
    for _, beaconLight in pairs(spec.beaconLights) do
        beaconLight:setIsActive(false)
        beaconLight:setDeviceIsActive(false)
    end
end


---
function Lights:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
    if not superFunc(self, xmlFile, key, group) then
        return false
    end

    group.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
    group.excludedLightTypes = xmlFile:getValue(key .. "#excludedLightTypes", nil, true)

    return true
end


---
function Lights:getIsDashboardGroupActive(superFunc, group)
    if group.lightTypes ~= nil or group.excludedLightTypes ~= nil then
        local spec = self.spec_lights

        if group.lightTypes ~= nil then
            local lightIsActive = false
            for _, lightType in pairs(group.lightTypes) do
                if bitAND(spec.lightsTypesMask, 2^lightType) ~= 0 then
                    lightIsActive = true
                    break
                end
            end

            if not lightIsActive then
                return false
            end
        end

        if group.excludedLightTypes ~= nil then
            for _, excludedLightType in pairs(group.excludedLightTypes) do
                if bitAND(spec.lightsTypesMask, 2^excludedLightType) ~= 0 then
                    return false
                end
            end
        end
    end

    return superFunc(self, group)
end



---
function Lights:getDeactivateLightsOnLeave()
    return true
end


---
function Lights:loadSharedLight(xmlFile, key)
    local spec = self.spec_lights
    local sharedLight = SharedLight.new(self, spec.staticLights)
    sharedLight:loadFromVehicleXML(key, self.baseDirectory, function(success)
        if success then
            table.insert(spec.sharedLights, sharedLight)

            if sharedLight.staticLightCompound ~= nil then
                table.insert(spec.staticLightCompounds, sharedLight.staticLightCompound)
            end
        end
    end)
end


---
function Lights:loadAdditionalLightAttributesFromXML(xmlFile, key, light)
    light.isTopLight = xmlFile:getValue(key .. "#isTopLight", false)
    light.isBottomLight = xmlFile:getValue(key .. "#isBottomLight", false)

    return true
end


---
function Lights:getIsLightActive(light)
    if light.isTopLight then
        if not self.spec_lights.topLightsVisibility then
            return false
        end
    elseif light.isBottomLight then
        if self.spec_lights.topLightsVisibility then
            return false
        end
    end

    return true
end


---
function Lights:getStaticLightFromNode(node)
    local spec = self.spec_lights
    for _, lights in pairs(spec.staticLights) do
        for _, staticLight in ipairs(lights) do
            if staticLight.node == node then
                return staticLight
            end
        end
    end
end


---
function Lights:getRealLightFromNode(node)
    local spec = self.spec_lights
    for _, profile in pairs(spec.realLights) do
        for _, lights in pairs(profile) do
            for _, realLight in ipairs(lights) do
                if realLight.node == node then
                    return realLight
                end
            end
        end
    end
end


---
function Lights:updateAutomaticLights(isTurnedOn, isWorking)
    local spec = self.spec_lights

    if isTurnedOn then
        local lightsTypesMask = isWorking and spec.automaticLightsTypesMaskWork or spec.automaticLightsTypesMask
        if spec.lightsTypesMask ~= lightsTypesMask then
            self:setLightsTypesMask(lightsTypesMask)
        end
    else
        if spec.lightsTypesMask ~= 0 then
            self:setLightsTypesMask(0)
        end
    end
end


---
function Lights:lightsWeatherChanged()
    local spec = self.spec_lights
    g_inputBinding:setActionEventTextVisibility(spec.actionEventIdLight, not g_currentMission.environment.isSunOn)
end


---
function Lights:onLightsProfileChanged(lightsProfile)
    local spec = self.spec_lights

    for _, profile in pairs(spec.realLights) do
        for _, lights in pairs(profile) do
            for _, realLight in ipairs(lights) do
                realLight:onLightsProfileChanged(lightsProfile)
            end
        end
    end

    self:setLightsTypesMask(spec.lightsTypesMask, true)
end


---
function Lights:onLightsRealBeaconLightChanged()
    local spec = self.spec_lights
    for _, beaconLight in pairs(spec.beaconLights) do
        beaconLight:onLightsRealBeaconLightChanged()
    end
end


---
function Lights:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        if self.getIsEntered ~= nil and self:getIsEntered() then
            local spec = self.spec_lights
            self:clearActionEventsTable(spec.actionEvents)

            if isActiveForInputIgnoreSelection then
                local _
                _, spec.actionEventIdLight = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHTS, self, Lights.actionEventToggleLights, false, true, false, true, nil)
                local _, actionEventIdReverse = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHTS_BACK, self, Lights.actionEventToggleLightsBack, false, true, false, true, nil)
                local _, actionEventIdFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHT_FRONT, self, Lights.actionEventToggleLightFront, false, true, false, true, nil)
                local _, actionEventIdWorkBack = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_BACK, self, Lights.actionEventToggleWorkLightBack, false, true, false, true, nil)
                local _, actionEventIdWorkFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_FRONT, self, Lights.actionEventToggleWorkLightFront, false, true, false, true, nil)
                local _, actionEventIdHighBeam = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_HIGH_BEAM_LIGHT, self, Lights.actionEventToggleHighBeamLight, false, true, false, true, nil)
                self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_HAZARD, self, Lights.actionEventToggleTurnLightHazard, false, true, false, true, nil)
                self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_LEFT, self, Lights.actionEventToggleTurnLightLeft, false, true, false, true, nil)
                self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_RIGHT, self, Lights.actionEventToggleTurnLightRight, false, true, false, true, nil)
                local _, actionEventIdBeacon = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_BEACON_LIGHTS, self, Lights.actionEventToggleBeaconLights, false, true, false, true, nil)

                -- action events that are only active if getIsActiveForLights
                spec.actionEventsActiveChange = {actionEventIdFront, actionEventIdWorkBack, actionEventIdWorkFront, actionEventIdHighBeam, actionEventIdBeacon}

                for _,actionEvent in pairs(spec.actionEvents) do
                    if actionEvent.actionEventId ~= nil then
                        g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
                        g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_LOW)
                    end
                end

                g_inputBinding:setActionEventTextVisibility(spec.actionEventIdLight, not g_currentMission.environment.isSunOn)
                g_inputBinding:setActionEventTextVisibility(actionEventIdReverse, false)
            end
        end
    end
end


---Called on load to register external action events
function Lights:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
    if name == "lights" then
        local spec = self.spec_lights
        if #spec.lightStates > 0 then
            self:registerExternalActionEvent(trigger, name, Lights.externalActionEventRegister, Lights.externalActionEventUpdate)
        end
    end
end


---
function Lights:onEnterVehicle(isControlling)
    local spec = self.spec_lights

    self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    self:setBeaconLightsVisibility(spec.beaconLightsActive, true, true)
    self:setTurnLightState(spec.turnLightState, true, true)
end


---
function Lights:onLeaveVehicle()
    if self:getDeactivateLightsOnLeave() then
        self:deactivateLights(true)
        self:deactivateBeaconLights()
    end

    local spec = self.spec_lights
    for _, beaconLight in pairs(spec.beaconLights) do
        beaconLight:setDeviceIsActive(false)
    end
end


---
function Lights:onDeactivate()
    if self:getDeactivateLightsOnLeave() then
        self:deactivateBeaconLights()
    end
end


---
function Lights:onRequiresTopLightsChanged(requiresTopLights)
    self:setTopLightsVisibility(requiresTopLights)
end


---
function Lights:onStartMotor()
    local spec = self.spec_lights
    self:setLightsTypesMask(spec.lightsTypesMask, true, true)

    for _, staticLight in ipairs(spec.staticLights.dayTimeLights) do
        staticLight:setState(true)
    end
end


---
function Lights:onStopMotor()
    local spec = self.spec_lights
    self:setLightsTypesMask(spec.lightsTypesMask, true, true)

    for _, staticLight in ipairs(spec.staticLights.dayTimeLights) do
        staticLight:setState(false or self:getIsInShowroom())
    end
end


---
function Lights:onStartReverseDirectionChange()
    local spec = self.spec_lights

    if spec.lightsTypesMask > 0 then
        self:setLightsTypesMask(spec.lightsTypesMask, true, true)
    end
end


---
function Lights:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
    if attacherVehicle.getLightsTypesMask ~= nil then
        self:setLightsTypesMask(attacherVehicle:getLightsTypesMask(), true, true)
        self:setBeaconLightsVisibility(attacherVehicle:getBeaconLightsVisibility(), true, true)
        self:setTurnLightState(attacherVehicle:getTurnLightState(), true, true)
    end
end


---
function Lights:onPostDetach()
    self:deactivateLights()
end


---
function Lights:onAutomatedTrainTravelActive()
    self:updateAutomaticLights(not g_currentMission.environment.isSunOn, false)
end


---
function Lights:onAIDriveableActive()
    self:updateAutomaticLights(not g_currentMission.environment.isSunOn, false)
end


---
function Lights:onAIDriveableEnd()
    if self.getIsControlled ~= nil then
        if not self:getIsControlled() then
            self:setLightsTypesMask(0)
        end
    end

    self:setBeaconLightsVisibility(false, true, true)
end


---
function Lights:onAIFieldWorkerStart()
    self:setBeaconLightsVisibility(false, true, true)
end


---
function Lights:onAIFieldWorkerActive()
    self:updateAutomaticLights(not g_currentMission.environment.isSunOn, true)
end


---
function Lights:onAIJobVehicleBlock()
    self:setBeaconLightsVisibility(true, true, true)
end


---
function Lights:onAIJobVehicleContinue()
    self:setBeaconLightsVisibility(false, true, true)
end


---
function Lights:onAIFieldWorkerEnd()
    if self.getIsControlled ~= nil then
        if not self:getIsControlled() then
            self:setLightsTypesMask(0)
        end
    end

    self:setBeaconLightsVisibility(false, true, true)
end


---
function Lights:onVehiclePhysicsUpdate(acceleratorPedal, brakePedal, automaticBrake, currentSpeed)
    self:setBrakeLightsVisibility(not automaticBrake and math.abs(brakePedal) > 0)

    local reverserDirection = 1
    if self.spec_drivable ~= nil then
        reverserDirection = self.spec_drivable.reverserDirection
    end
    self:setReverseLightsVisibility((currentSpeed < -self.spec_lights.reverseLightActivationSpeed or acceleratorPedal < 0) and reverserDirection == 1)
end


---
function Lights:loadRealLightSetup(xmlFile, key, lightTable, realLightToLight)
    lightTable.defaultLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".light", self, self.components, self.i3dMappings, true)
    lightTable.topLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".topLight", self, self.components, self.i3dMappings, false)
    lightTable.bottomLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".bottomLight", self, self.components, self.i3dMappings, false)
    lightTable.brakeLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".brakeLight", self, self.components, self.i3dMappings, false)
    lightTable.reverseLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".reverseLight", self, self.components, self.i3dMappings, false)
    lightTable.turnLightsLeft = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".turnLightLeft", self, self.components, self.i3dMappings, false)
    lightTable.turnLightsRight = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".turnLightRight", self, self.components, self.i3dMappings, false)
    lightTable.interiorLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".interiorLight", self, self.components, self.i3dMappings, false)

    for i, light in ipairs(lightTable.interiorLights) do
        light:setChargeFunction(self.getInteriorLightBrightness, self)
        self.spec_lights.interiorLightsAvailable = true
    end
end


---
function Lights:applyAdditionalActiveLightType(lights, lightType, isBlinking)
    for _, light in ipairs(lights) do
        table.insert(light.lightTypes, lightType)

        if isBlinking then
            light:setIsBlinking(true)
        end
    end
end


---
function Lights.actionEventToggleLightFront(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        if spec.numLightTypes >= 1 then
            local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_DEFAULT)
            self:setLightsTypesMask(lightsTypesMask)
        end
    end
end


---
function Lights.actionEventToggleLights(self, actionName, inputValue, callbackState, isAnalog)
    if self:getCanToggleLight() then
        self:setNextLightsState(1)
    end
end


---
function Lights.actionEventToggleLightsBack(self, actionName, inputValue, callbackState, isAnalog)
    if self:getCanToggleLight() then
        self:setNextLightsState(-1)
    end
end


---
function Lights.actionEventToggleWorkLightBack(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_BACK)
        self:setLightsTypesMask(lightsTypesMask)
    end
end


---
function Lights.actionEventToggleWorkLightFront(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_WORK_FRONT)
        self:setLightsTypesMask(lightsTypesMask)
    end
end


---
function Lights.actionEventToggleHighBeamLight(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2 ^ Lights.LIGHT_TYPE_HIGHBEAM)
        self:setLightsTypesMask(lightsTypesMask)
    end
end


---
function Lights.actionEventToggleTurnLightHazard(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        local state = Lights.TURNLIGHT_OFF
        if spec.turnLightState ~= Lights.TURNLIGHT_HAZARD then
            state = Lights.TURNLIGHT_HAZARD
        end
        self:setTurnLightState(state)
    end
end


---
function Lights.actionEventToggleTurnLightLeft(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        local state = Lights.TURNLIGHT_OFF
        if spec.turnLightState ~= Lights.TURNLIGHT_LEFT then
            state = Lights.TURNLIGHT_LEFT
        end
        self:setTurnLightState(state)
    end
end


---
function Lights.actionEventToggleTurnLightRight(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        local state = Lights.TURNLIGHT_OFF
        if spec.turnLightState ~= Lights.TURNLIGHT_RIGHT then
            state = Lights.TURNLIGHT_RIGHT
        end
        self:setTurnLightState(state)
    end
end


---
function Lights.actionEventToggleBeaconLights(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_lights
    if self:getCanToggleLight() then
        self:setBeaconLightsVisibility(not spec.beaconLightsActive)
    end
end


---
function Lights.externalActionEventRegister(data, vehicle)
    local function actionEvent(_, actionName, inputValue, callbackState, isAnalog)
        vehicle:setNextLightsState(1)
    end

    local _
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_LIGHTS_EXTERNAL, data, actionEvent, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
    g_inputBinding:setActionEventText(data.actionEventId, g_i18n:getText("input_TOGGLE_LIGHTS"))
end


---
function Lights.externalActionEventUpdate(data, vehicle)
end


---
function Lights.dashboardLightAttributes(self, xmlFile, key, dashboard, isActive)
    dashboard.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
    dashboard.excludedLightTypes = xmlFile:getValue(key.."#excludedLightTypes", nil, true)
    dashboard.lightStates = {}
    for i=0, self.spec_lights.maxLightState do
        dashboard.lightStates[i] = false
    end

    return true
end


---
function Lights.dashboardLightState(self, dashboard, newValue, minValue, maxValue, isActive)
    local lightsTypesMask = self.spec_lights.lightsTypesMask

    if dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
        local anyLightActive = false
        for i=0, self.spec_lights.maxLightState do
            dashboard.lightStates[i] = bitAND(lightsTypesMask, 2 ^ i) ~= 0
            anyLightActive = anyLightActive or dashboard.lightStates[i]
        end

        if anyLightActive then
            Dashboard.defaultDashboardStateFunc(self, dashboard, dashboard.lightStates, minValue, maxValue, isActive)
        else
            Dashboard.defaultDashboardStateFunc(self, dashboard, -1, minValue, maxValue, isActive)
        end
    else
        Dashboard.defaultDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
    end
end


---
function Lights.consoleCommandTopLights()
    local vehicle = g_localPlayer:getCurrentVehicle()
    if vehicle ~= nil and vehicle.setTopLightsVisibility ~= nil then
        vehicle:setTopLightsVisibility(not vehicle.spec_lights.topLightsVisibility)
    end
end




---
function Lights.consoleCommandProfile()
    local profile = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
    if profile >= GS_PROFILE_HIGH then
        g_gameSettings:setValue(GameSettings.SETTING.LIGHTS_PROFILE, GS_PROFILE_LOW)
        Logging.info("Activated LOW light setup.")
    else
        g_gameSettings:setValue(GameSettings.SETTING.LIGHTS_PROFILE, GS_PROFILE_VERY_HIGH)
        Logging.info("Activated HIGH light setup.")
    end
end
