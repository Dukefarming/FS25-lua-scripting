


























---
function Wheels.prerequisitesPresent(specializations)
    return true
end


---
function Wheels.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onBrake")
    SpecializationUtil.registerEvent(vehicleType, "onFinishedWheelLoading")
    SpecializationUtil.registerEvent(vehicleType, "onWheelConfigurationChanged")
end


---
function Wheels.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getSteeringRotTimeByCurvature",       Wheels.getSteeringRotTimeByCurvature)
    SpecializationUtil.registerFunction(vehicleType, "getTurningRadiusByRotTime",           Wheels.getTurningRadiusByRotTime)

    SpecializationUtil.registerFunction(vehicleType, "loadHubsFromXML",                     Wheels.loadHubsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadHubFromXML",                      Wheels.loadHubFromXML)
    SpecializationUtil.registerFunction(vehicleType, "onWheelHubI3DLoaded",                 Wheels.onWheelHubI3DLoaded)

    SpecializationUtil.registerFunction(vehicleType, "loadAckermannSteeringFromXML",        Wheels.loadAckermannSteeringFromXML)

    SpecializationUtil.registerFunction(vehicleType, "loadWheelsFromXML",                   Wheels.loadWheelsFromXML)
    SpecializationUtil.registerFunction(vehicleType, "loadWheelFromXML",                    Wheels.loadWheelFromXML)

    SpecializationUtil.registerFunction(vehicleType, "onLoadWheelChockFromXML",             Wheels.onLoadWheelChockFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsWheelChockAllowed",              Wheels.getIsWheelChockAllowed)

    SpecializationUtil.registerFunction(vehicleType, "getIsVersatileYRotActive",            Wheels.getIsVersatileYRotActive)
    SpecializationUtil.registerFunction(vehicleType, "getWheelFromWheelIndex",              Wheels.getWheelFromWheelIndex)
    SpecializationUtil.registerFunction(vehicleType, "getWheelByWheelNode",                 Wheels.getWheelByWheelNode)
    SpecializationUtil.registerFunction(vehicleType, "getWheels",                           Wheels.getWheels)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentSurfaceSound",              Wheels.getCurrentSurfaceSound)
    SpecializationUtil.registerFunction(vehicleType, "getAreSurfaceSoundsActive",           Wheels.getAreSurfaceSoundsActive)
    SpecializationUtil.registerFunction(vehicleType, "brake",                               Wheels.brake)
    SpecializationUtil.registerFunction(vehicleType, "getBrakeForce",                       Wheels.getBrakeForce)
    SpecializationUtil.registerFunction(vehicleType, "setCustomBrakeForce",                 Wheels.setCustomBrakeForce)
    SpecializationUtil.registerFunction(vehicleType, "updateWheelDirtAmount",               Wheels.updateWheelDirtAmount)
    SpecializationUtil.registerFunction(vehicleType, "updateWheelMudAmount",                Wheels.updateWheelMudAmount)
    SpecializationUtil.registerFunction(vehicleType, "forceUpdateWheelPhysics",             Wheels.forceUpdateWheelPhysics)
    SpecializationUtil.registerFunction(vehicleType, "onWheelSnowHeightChanged",            Wheels.onWheelSnowHeightChanged)
    SpecializationUtil.registerFunction(vehicleType, "getSteeringNodeByNode",               Wheels.getSteeringNodeByNode)
    SpecializationUtil.registerFunction(vehicleType, "updateSteeringNodes",                 Wheels.updateSteeringNodes)
end


---
function Wheels.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Wheels.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Wheels.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getComponentMass", Wheels.getComponentMass)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldXRot", Wheels.getVehicleWorldXRot)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldDirection", Wheels.getVehicleWorldDirection)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Wheels.validateWashableNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIDirectionNode", Wheels.getAIDirectionNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRootNode", Wheels.getAIRootNode)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsMountKinematic", Wheels.getSupportsMountKinematic)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadBendingNodeFromXML", Wheels.loadBendingNodeFromXML)
end


---
function Wheels.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", Wheels)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Wheels)
end


---
function Wheels.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("wheel",      g_i18n:getText("configuration_wheelSetup"), "wheels", VehicleConfigurationItemWheel, g_i18n:getText("configuration_wheelBrand"), Wheels.getBrands, Wheels.getWheelsByBrand, 2)
    g_vehicleConfigurationManager:addConfigurationType("rimColor",   g_i18n:getText("configuration_rimColor"), nil, VehicleConfigurationItemColor)

    g_storeManager:addSpecType("wheels", "shopListAttributeIconWheels", Wheels.loadSpecValueWheels, Wheels.getSpecValueWheels, StoreSpecies.VEHICLE)

    g_storeManager:addVRamUsageFunction(Wheels.getVRamUsageFromXML)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Wheels")

    schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations#tireCategories", "List of tire categories to include in the automatic wheel config generation (separated by whitespace)")
    schema:register(XMLValueType.STRING_LIST, "vehicle.wheels.wheelConfigurations#customBrandOrder", "Custom brand order for dynamic configurations (names of the brands separated by whitespace)")
    schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.tireCombination(?)#brand", "Brand name of the combination")
    schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.tireCombination(?)#names", "List of tire names that are allowed to be mixed. Otherwise all mixes are allowed. Does not effect configuration with all tires from the same name. (separated by whitespace)")

    schema:register(XMLValueType.INT, Wheels.CONFIG_XML_PATH .. "(?)#numDynamicConfigurations", "Max. number of dynamic configurations per brand", "unlimited")
    schema:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?)#tireCategories", "List of tire categories to include in the automatic wheel config generation (separated by whitespace)")
    schema:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?).tireCombination(?)#brand", "Brand name of the combination")
    schema:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?).tireCombination(?)#names", "List of tire names that are allowed to be mixed. Otherwise all mixes are allowed. Does not effect configuration with all tires from the same name. (separated by whitespace)")

    local configKey = Wheels.WHEELS_XML_PATH
    schema:register(XMLValueType.FLOAT, configKey .. "#autoRotateBackSpeed", "Auto rotate back speed", 1)
    schema:register(XMLValueType.BOOL, configKey .. "#speedDependentRotateBack", "Speed dependent auto rotate back speed", true)
    schema:register(XMLValueType.INT, configKey .. "#differentialIndex", "Differential index")
    schema:register(XMLValueType.INT, configKey .. "#ackermannSteeringIndex", "Ackermann steering index")
    schema:register(XMLValueType.FLOAT, configKey .. "#ackermannSteeringAngle", "Ackermann steering angle to set while this config is active")
    schema:register(XMLValueType.BOOL, configKey .. "#isCareWheelConfiguration", "All wheels will be care wheels")
    schema:register(XMLValueType.STRING, configKey .. "#baseConfig", "Base for this configuration")

    schema:register(XMLValueType.BOOL, configKey .. "#hasSurfaceSounds", "Has surface sounds", true)
    schema:register(XMLValueType.STRING, configKey .. "#surfaceSoundTireType", "Tire type that is used for surface sounds", "Tire type of first wheel")
    schema:register(XMLValueType.NODE_INDEX, configKey .. "#surfaceSoundLinkNode", "Surface sound link node", "Root component")

    Wheel.registerXMLPaths(schema, configKey .. ".wheel(?)")

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.rimMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.rimMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.rimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.innerRimMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.innerRimMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.innerRimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.outerRimMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.outerRimMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.outerRimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.additionalMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.additionalMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.additionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubMaterial#useRimColor", "Use rim color", false)

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubBoltMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubBoltMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubBoltMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubBoltMaterial#useRimColor", "Use rim color", false)

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.material")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.material#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.material#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.material#useRimColor", "Use rim color", false)

    schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.hubs.hub(?)#linkNode", "Link node")
    schema:register(XMLValueType.STRING, "vehicle.wheels.hubs.hub(?)#filename", "Filename")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?)#isLeft", "Is left side", false)
    schema:register(XMLValueType.FLOAT, "vehicle.wheels.hubs.hub(?)#offset", "X axis offset")
    schema:register(XMLValueType.VECTOR_SCALE, "vehicle.wheels.hubs.hub(?)#scale", "Hub scale")

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).material")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).material#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).material#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).material#useRimColor", "Use rim color", false)

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).boltMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).boltMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltMaterial#useRimColor", "Use rim color", false)

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).additionalMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).additionalMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).additionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).additionalMaterial#useRimColor", "Use rim color", false)

    VehicleMaterial.registerXMLPaths(schema, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useBaseColor", "Use base vehicle color", false)
    schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
    schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useRimColor", "Use rim color", false)

    schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. "#wheelIndex", "Wheel index [1..n]")
        cSchema:register(XMLValueType.ANGLE, cKey .. "#startSteeringAngle", "Start steering angle")
        cSchema:register(XMLValueType.ANGLE, cKey .. "#endSteeringAngle", "End steering angle")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#startBrakeFactor", "Start brake force factor")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#endBrakeFactor", "End brake force factor")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#startTorqueDirection", "Start torque direction")
        cSchema:register(XMLValueType.FLOAT, cKey .. "#endTorqueDirection", "End torque direction")
    end)

    local dynamicallyLoadedWheelKey = "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)"
    schema:register(XMLValueType.NODE_INDEX, dynamicallyLoadedWheelKey .. "#linkNode", "Link node")
    schema:register(XMLValueType.BOOL, dynamicallyLoadedWheelKey .. "#isLeft", "Is Left", false)
    schema:register(XMLValueType.STRING, dynamicallyLoadedWheelKey .. "#filename", "Filename")
    schema:register(XMLValueType.STRING, dynamicallyLoadedWheelKey .. "#configId", "Wheel config id", "default")
    schema:register(XMLValueType.BOOL, dynamicallyLoadedWheelKey .. "#isShallowWaterObstacle", "The dynamically loaded wheel will interact with the shallow water simulation", false)
    WheelVisual.registerXMLPaths(schema, dynamicallyLoadedWheelKey)

    Wheels.registerAckermannSteeringXMLPaths(schema, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering(?)")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.steeringNodes.steeringNode(?)#node", "Additional node that is used for steering (Same behaviour as wheels using the ackermann steering setting)")
    schema:register(XMLValueType.FLOAT, "vehicle.wheels.steeringNodes.steeringNode(?)#rotScale", "Scale factor for rotation", 1)
    schema:register(XMLValueType.ANGLE, "vehicle.wheels.steeringNodes.steeringNode(?)#rotChangeSpeed", "Max. rotation speed when limits change", 45)

    schema:register(XMLValueType.VECTOR_N, FoliageBending.BENDING_NODE_XML_KEY .. "#wheelIndices", "Wheel Indices to calculate the bending node size automatically")

    Dashboard.registerDashboardXMLPaths(schema, "vehicle.wheels.dashboards", {"brake", "steeringAngle"})
    Dashboard.addDelayedRegistrationFunc(schema, function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. "#steeringNodeIndex", "Index of steering node")
        cSchema:register(XMLValueType.INT, cKey .. "#wheelIndex", "Index of wheel")
    end)

    schema:setXMLSpecializationType()

    Wheels.xmlSchema = XMLSchema.new("wheel")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#brand", "Wheel tire brand", "LIZARD")
    Wheels.xmlSchema:registerAutoCompletionDataSource("wheel.metadata#brand", "$dataS/brands.xml", "brands.brand#name")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#name", "Wheel tire name", "Tire")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#category", "Wheel tire category for automatic wheel configurations")
    Wheels.xmlSchema:register(XMLValueType.BOOL, "wheel.metadata#allowMixture", "Allow mixing with other tires from the same brand", false)
    Wheels.xmlSchema:register(XMLValueType.INT, "wheel.metadata#priority", "Tire priority for selection in the shop (wheels with high prio will be shown first)", 1)
    Wheel.registerXMLPaths(Wheels.xmlSchema, "wheel.default")
    Wheel.registerXMLPaths(Wheels.xmlSchema, "wheel.configurations.configuration(?)")
    Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.configurations.configuration(?)#id", "Configuration Id")

    Wheels.xmlSchemaHub = XMLSchema.new("wheelHub")
    local hubSchema = Wheels.xmlSchemaHub
    hubSchema:register(XMLValueType.STRING, "hub.filename", "I3D filename")
    hubSchema:register(XMLValueType.STRING, "hub.nodes#left", "Index of left node in hub i3d file")
    hubSchema:register(XMLValueType.STRING, "hub.nodes#right", "Index of right node in hub i3d file")

    Wheels.xmlSchemaConnector = XMLSchema.new("wheelConnector")
    local connectorSchema = Wheels.xmlSchemaConnector
    connectorSchema:register(XMLValueType.STRING, "connector.file#name", "I3D filename")
    connectorSchema:register(XMLValueType.STRING, "connector.file#leftNode", "Index of left node in connector i3d file")
    connectorSchema:register(XMLValueType.STRING, "connector.file#rightNode", "Index of right node in connector i3d file")

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).wheels#lastConfigId", "Last selected wheel configuration id")
end


---
function Wheels.registerAckermannSteeringXMLPaths(schema, key)
    schema:register(XMLValueType.FLOAT, key .. "#rotSpeed", "Rotation speed")
    schema:register(XMLValueType.FLOAT, key .. "#rotMax", "Max. rotation")
    schema:register(XMLValueType.INT, key .. "#rotCenterWheel1", "Rotation center wheel 1")
    schema:register(XMLValueType.INT, key .. "#rotCenterWheel2", "Rotation center wheel 2")
    schema:register(XMLValueType.VECTOR_N, key .. "#rotCenterWheels", "List of wheel indices which represent the steering center")
    schema:register(XMLValueType.NODE_INDEX, key .. "#rotCenterNode", "Rotation center node (Used if rotCenterWheelX not given)")
    schema:register(XMLValueType.VECTOR_2, key .. "#rotCenter", "Center position (from root component) (Used if rotCenterWheelX not given)")
    schema:register(XMLValueType.FLOAT, key .. "#minTurningRadius", "Overwrites the automatically calculated turning radius for this config")
end


---
function Wheels:onPreLoad(savegame)
    local spec = self.spec_wheels

    spec.wheelConfigurationId = self.configurations["wheel"] or 1
    spec.configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", spec.wheelConfigurationId - 1)

    spec.configItem = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "wheel", spec.wheelConfigurationId)
    if spec.configItem ~= nil then
        spec.configItem:applyGeneratedConfiguration(self.xmlFile)

        spec.configKey = spec.configItem.configKey
        spec.lastWheelConfigSaveId = spec.configItem.saveId
    end
end


---
function Wheels:onLoad(savegame)
    local spec = self.spec_wheels

    spec.sharedLoadRequestIds = {}

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.driveGroundParticleSystems", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#hasParticles") --FS13 to FS15

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration", "vehicle.wheels.wheelConfigurations.wheelConfiguration") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rimColor", "vehicle.wheels.rimColor") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.hubColor", "vehicle.wheels.hubs.color0") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicallyLoadedWheels", "vehicle.wheels.dynamicallyLoadedWheels") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteeringConfigurations", "vehicle.wheels.ackermannSteeringConfigurations") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configIndex", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configId") --FS17 to FS19

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteering", "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering") --FS19 to FS21

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.rimColor", "vehicle.wheels.rimMaterial") --FS22 to FS25
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.hubs.rimColor.color0", "vehicle.wheels.hubMaterial") --FS22 to FS25
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.hubs.rimColor.color1", "vehicle.wheels.hubBoltMaterial") --FS22 to FS25

    spec.configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(self.xmlFile)

    if spec.configItem ~= nil then
        -- apply the object changes again including the ones from the parent configurations
        spec.configItem:applyObjectChanges(self, spec.configurationIndexToParentConfigIndex)
    end

    local loadMaterial = function(name, key, hubMaterial)
        local material = VehicleMaterial.new(self.baseDirectory)
        if material:loadFromXML(self.xmlFile, key, self.customEnvironment) then
            spec[name] = material
        else
            material = nil
        end

        if self.xmlFile:getValue(key .. "#useBaseColor") then
            spec[name] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, "baseColor") or spec[name]
        else
            local useDesignColorIndex = self.xmlFile:getValue(key .. "#useDesignColorIndex")
            if useDesignColorIndex ~= nil then
                local configName = "designColor"
                if useDesignColorIndex >= 2 then
                    configName = string.format("designColor%d", useDesignColorIndex)
                end

                spec[name] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, configName) or spec[name]
            else
                if (material == nil and not hubMaterial) or self.xmlFile:getBool(key .. "#useRimColor", false) then
                    spec[name] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, "rimColor") or spec["rimMaterial"] or spec[name]

                    if spec[name] == nil then
                        spec[name] = VehicleMaterial.new(self.baseDirectory)
                        spec[name]:setTemplateName("RIM_DEFAULT")
                    end
                end
            end
        end
    end

    loadMaterial("rimMaterial", "vehicle.wheels.rimMaterial", false)
    loadMaterial("innerRimMaterial", "vehicle.wheels.innerRimMaterial", false)
    loadMaterial("outerRimMaterial", "vehicle.wheels.outerRimMaterial", false)
    loadMaterial("additionalMaterial", "vehicle.wheels.additionalMaterial", false)
    loadMaterial("hubMaterial", "vehicle.wheels.hubMaterial", true)
    loadMaterial("hubBoltMaterial", "vehicle.wheels.hubBoltMaterial", true)

    -- load hubs to hubs/repr nodes
    self:loadHubsFromXML()

    self.maxRotTime = 0
    self.minRotTime = 0
    self.rotatedTimeInterpolator = InterpolatorValue.new(0)

    self.autoRotateBackSpeed = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#autoRotateBackSpeed", 1)
    self.speedDependentRotateBack = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#speedDependentRotateBack", true)
    self.differentialIndex = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#differentialIndex")
    spec.ackermannSteeringIndex = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#ackermannSteeringIndex")
    spec.ackermannSteeringAngle = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#ackermannSteeringAngle")
    spec.isCareWheelConfiguration = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#isCareWheelConfiguration")
    local hasSurfaceSounds = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#hasSurfaceSounds", true)

    spec.wheelSmoothAccumulation = 0

    spec.currentUpdateIndex = 1

    spec.wheels = {}
    spec.wheelsByNode = {}

    -- load wheels
    self:loadWheelsFromXML(self.xmlFile, spec.configKey, spec.wheelConfigurationId)

    --load surface sounds
    if hasSurfaceSounds then
        local surfaceSoundLinkNode = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#surfaceSoundLinkNode", self.components[1].node, self.components, self.i3dMappings)

        local tireTypeName = ""
        if #spec.wheels > 0 and spec.wheels[1].physics.tireType ~= nil then
            tireTypeName = WheelsUtil.getTireTypeName(spec.wheels[1].physics.tireType)
        end
        tireTypeName = WheelXMLObject.getValueStatic(spec.wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#surfaceSoundTireType", tireTypeName)

        spec.surfaceSounds = {}
        spec.surfaceIdToSound = {}
        spec.surfaceNameToSound = {}
        spec.currentSurfaceSound = nil

        local function addSurfaceSound(surfaceSound)
            local sample = g_soundManager:cloneSample(surfaceSound.sample, surfaceSoundLinkNode, self)
            sample.sampleName = surfaceSound.name

            table.insert(spec.surfaceSounds, sample)
            spec.surfaceIdToSound[surfaceSound.materialId] = sample
            spec.surfaceNameToSound[surfaceSound.name] = sample
        end

        local surfaceSounds = g_currentMission.surfaceSounds
        for j=1, #surfaceSounds do
            local surfaceSound = surfaceSounds[j]
            if surfaceSound.type:lower() == ("wheel_" .. tireTypeName):lower() then
                addSurfaceSound(surfaceSound)
            end
        end

        for j=1, #surfaceSounds do
            local surfaceSound = surfaceSounds[j]
            if spec.surfaceNameToSound[surfaceSound.name] == nil then
                if surfaceSound.type == "wheel" then
                    addSurfaceSound(surfaceSound)
                end
            end
        end
    end

    -- load non physical wheels
    spec.dynamicallyLoadedWheels = {}
    self.xmlFile:iterate("vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel", function(index, key)
        local linkNode = self.xmlFile:getValue(key .. "#linkNode", self.components[1].node, self.components, self.i3dMappings)
        local isLeft = self.xmlFile:getValue(key .. "#isLeft", false)
        local isShallowWaterObstacle = self.xmlFile:getValue(key .. "#isShallowWaterObstacle", false)

        local xmlObject = WheelXMLObject.new(self.xmlFile, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel", index, "", {})

        local visualWheel = WheelVisual.new(self, nil, linkNode, isLeft, 0, self.baseDirectory)
        if visualWheel:loadFromXML(xmlObject) then
            if isShallowWaterObstacle then
                visualWheel:addShallowWaterObstacle()
            end

            visualWheel.name = xmlObject.externalWheelName

            table.insert(spec.dynamicallyLoadedWheels, visualWheel)
        else
            visualWheel:delete()
        end

        xmlObject:delete()
    end)

    spec.steeringNodes = {}
    self.xmlFile:iterate("vehicle.wheels.steeringNodes.steeringNode", function(index, key)
        local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if node ~= nil then
            local steeringNode = {}
            steeringNode.node = node

            steeringNode.rotScale = self.xmlFile:getValue(key .. "#rotScale", 1)
            steeringNode.rotChangeSpeed = self.xmlFile:getValue(key .. "#rotChangeSpeed", 45)
            steeringNode.rotScaleOrig = steeringNode.rotScale
            steeringNode.rotScaleTarget = steeringNode.rotScale
            steeringNode.rotScaleTargetSpeed = 1

            steeringNode.steeringAngle = 0

            steeringNode.offset = 0
            steeringNode.offsetTarget = 0
            steeringNode.offsetTargetSpeed = 1

            for _, componentJoint in pairs(self.componentJoints) do
                if componentJoint.jointNode == node then
                    steeringNode.componentJoint = componentJoint
                    break
                end
            end

            table.insert(spec.steeringNodes, steeringNode)
        end
    end)
    spec.hasSteeringNodes = #spec.steeringNodes > 0

    spec.networkTimeInterpolator = InterpolationTime.new(1.2)

    self:loadAckermannSteeringFromXML(self.xmlFile, spec.ackermannSteeringIndex, spec.ackermannSteeringAngle)

    SpecializationUtil.raiseEvent(self, "onFinishedWheelLoading", self.xmlFile, spec.configKey .. ".wheels")

    spec.brakePedal = 0
    spec.dirtyFlag = self:getNextDirtyFlag()

    g_messageCenter:subscribe(MessageType.SNOW_HEIGHT_CHANGED, self.onWheelSnowHeightChanged, self)
end


---
function Wheels:onLoadFinished(savegame)
    local spec = self.spec_wheels

    -- add wheel masses to default vehicle mass
    if self.isServer then
        for _, wheel in pairs(spec.wheels) do
            self.defaultMass = self.defaultMass + wheel:getMass()
        end

        if savegame ~= nil and not savegame.resetVehicles then
            local lastConfigId = savegame.xmlFile:getValue(savegame.key ..".wheels#lastConfigId")
            if lastConfigId ~= nil then
                if spec.configItem ~= nil and spec.configItem.saveId ~= lastConfigId then
                    for _, wheel in pairs(spec.wheels) do
                        local washableNode = self:getWashableNodeByCustomIndex(wheel)
                        if washableNode ~= nil then
                            self:setNodeDirtAmount(washableNode, 0, true)
                        end

                        if wheel.wheelMudMeshes ~= nil then
                            local mudWashableNode = self:getWashableNodeByCustomIndex(wheel.wheelMudMeshes)
                            if mudWashableNode ~= nil then
                                self:setNodeDirtAmount(mudWashableNode, 0, true)
                            end
                        end
                    end

                    SpecializationUtil.raiseEvent(self, "onWheelConfigurationChanged")
                end
            end
        end
    end

    if spec.rimMaterial ~= nil then
        spec.rimMaterial:applyToVehicle(self, "rim_inner_mat")
        spec.rimMaterial:applyToVehicle(self, "rim_outer_mat")
    end

    if spec.innerRimMaterial ~= nil then
        spec.innerRimMaterial:applyToVehicle(self, "rim_inner_mat")
    end

    if spec.outerRimMaterial ~= nil then
        spec.outerRimMaterial:applyToVehicle(self, "rim_outer_mat")
    end

    if spec.additionalMaterial ~= nil then
        spec.additionalMaterial:applyToVehicle(self, "rim_additional_mat")
    end

    if spec.hubMaterial ~= nil then
        spec.hubMaterial:applyToVehicle(self, "hub_main_mat")
    end

    if spec.hubBoltMaterial ~= nil then
        spec.hubBoltMaterial:applyToVehicle(self, "hub_bolt_mat")
    end

    for i, hub in ipairs(spec.hubs) do
        if hub.material ~= nil then
            hub.material:apply(hub.node, "hub_main_mat")
        end

        if hub.boltMaterial ~= nil then
            hub.boltMaterial:apply(hub.node, "hub_bolt_mat")
        end

        if hub.additionalMaterial ~= nil then
            hub.additionalMaterial:apply(hub.node, "hub_main_additional_mat")
        end

        if hub.boltAdditionalMaterial ~= nil then
            hub.boltAdditionalMaterial:apply(hub.node, "hub_bolt_additional_mat")
        end
    end

    -- wheel post load handles individual colors of wheel parts, so should be applied after the general rim material
    for _, wheel in pairs(spec.wheels) do
        wheel:postLoad()
    end

    for _, visualWheel in pairs(spec.dynamicallyLoadedWheels) do
        visualWheel:postLoad()
    end
end


---Called on post load to register dashboard value types
function Wheels:onRegisterDashboardValueTypes()
    local spec = self.spec_wheels

    local brake = DashboardValueType.new("wheels", "brake")
    brake:setValue(spec, "brakePedal")
    brake:setRange(0, 1)
    self:registerDashboardValueType(brake)

    local steeringAngle = DashboardValueType.new("wheels", "steeringAngle")
    steeringAngle:setRange(-180, 180)
    steeringAngle:setValue(spec, function(_, dashboard)
        if dashboard.steeringNodeIndex ~= nil then
            local steeringNode = spec.steeringNodes[dashboard.steeringNodeIndex]
            if steeringNode ~= nil then
                return math.deg(steeringNode.steeringAngle)
            end
        end

        if dashboard.wheelIndex ~= nil then
            local wheel = spec.wheels[dashboard.wheelIndex]
            if wheel ~= nil then
                return math.deg(wheel.physics.steeringAngle)
            end
        end

        return 0
    end)
    steeringAngle:setAdditionalFunctions(function(self, xmlFile, key, dashboard, isActive)
        dashboard.steeringNodeIndex = xmlFile:getValue(key .. "#steeringNodeIndex")
        dashboard.wheelIndex = xmlFile:getValue(key .. "#wheelIndex")

        return true
    end)
    self:registerDashboardValueType(steeringAngle)
end


---
function Wheels:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_wheels
    if spec.lastWheelConfigSaveId ~= nil then
        xmlFile:setValue(key .. "#lastConfigId", spec.lastWheelConfigSaveId)
    end
end


---
function Wheels:onDelete()
    local spec = self.spec_wheels

    if spec.sharedLoadRequestIds ~= nil then
        for _, sharedLoadRequestId in pairs(spec.sharedLoadRequestIds) do
            g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
        end
    end

    if spec.hubs ~= nil then
        for _, hub in pairs(spec.hubs) do
            delete(hub.node)
        end
    end

    if spec.wheels ~= nil then
        for _, wheel in pairs(spec.wheels) do
            wheel:delete()
        end
    end

    if spec.dynamicallyLoadedWheels ~= nil then
        for _, visualWheel in ipairs(spec.dynamicallyLoadedWheels) do
            visualWheel:delete()
        end
    end

    g_soundManager:deleteSamples(spec.surfaceSounds)
end


---
function Wheels:onReadStream(streamId, connection)
    if connection.isServer then
        local spec = self.spec_wheels
        spec.networkTimeInterpolator:reset()
        for i=1, #spec.wheels do
            local wheel = spec.wheels[i]
            if wheel.physics.isSynchronized then
                wheel:readStream(streamId, true)
            end
        end

        self.rotatedTimeInterpolator:setValue(0)
    end
end


---
function Wheels:onWriteStream(streamId, connection)
    if not connection.isServer then
        local spec = self.spec_wheels
        for i=1, #spec.wheels do
            local wheel = spec.wheels[i]
            if wheel.physics.isSynchronized then
                wheel:writeStream(streamId)
            end
        end
    end
end


---
function Wheels:onReadUpdateStream(streamId, timestamp, connection)
    if connection.isServer then
        local hasUpdate = streamReadBool(streamId)
        if hasUpdate then
            local spec = self.spec_wheels
            spec.networkTimeInterpolator:startNewPhaseNetwork()

            for i=1, #spec.wheels do
                local wheel = spec.wheels[i]
                if wheel.physics.isSynchronized then
                    wheel:readStream(streamId, false)
                end
            end

            if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
                local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
                local rotatedTime = streamReadUIntN(streamId, 8)
                -- set to 0 due to inaccuracy
                if math.abs(self.rotatedTime) < 0.001 then
                    self.rotatedTime = 0
                end

                local rotatedTimeTarget = rotatedTime / 255 * rotatedTimeRange + self.minRotTime
                self.rotatedTimeInterpolator:setTargetValue(rotatedTimeTarget)
            end
        end
    end
end


---
function Wheels:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection.isServer then
        local spec = self.spec_wheels

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            for i=1, #spec.wheels do
                local wheel = spec.wheels[i]
                if wheel.physics.isSynchronized then
                    wheel:writeStream(streamId)
                end
            end

            if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
                local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
                local rotatedTime = math.clamp(math.floor((self.rotatedTime - self.minRotTime)/rotatedTimeRange * 255), 0, 255)
                streamWriteUIntN(streamId, rotatedTime, 8)
            end
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function Wheels:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_wheels

    -- interpolation of wheel properties
    if not self.isServer and self.isClient then
        --#profile     RemoteProfiler.zoneBeginN("updateClient")

        spec.networkTimeInterpolator:update(dt)
        local interpolationAlpha = spec.networkTimeInterpolator:getAlpha()

        self.rotatedTime = self.rotatedTimeInterpolator:getInterpolatedValue(interpolationAlpha)

        for i=1, #spec.wheels do
            local wheel = spec.wheels[i]
            wheel:clientUpdate(dt, interpolationAlpha)
        end

        if spec.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end

        --#profile RemoteProfiler.zoneEnd()
    end

    if self.finishedFirstUpdate then
        local groundWetness = g_currentMission.environment.weather:getGroundWetness()

        for k, wheel in ipairs(spec.wheels) do
            --#profile RemoteProfiler.zoneBeginN("wheel:update")
            wheel:update(dt, spec.currentUpdateIndex, groundWetness)
            --#profile RemoteProfiler.zoneEnd()
        end

        spec.currentUpdateIndex = spec.currentUpdateIndex + 1
        if spec.currentUpdateIndex > 4 then
            spec.currentUpdateIndex = 1
        end

        if self.isActive then
            --#profile RemoteProfiler.zoneBeginN("updateWheelDestruction")

            local allowFoliageDestruction = g_currentMission.missionInfo.fruitDestruction
            allowFoliageDestruction = allowFoliageDestruction and not self:getIsAIActive()
            allowFoliageDestruction = allowFoliageDestruction and (self.getBlockFoliageDestruction == nil or not self:getBlockFoliageDestruction())

            for k, wheel in ipairs(spec.wheels) do
                wheel.destruction:update(dt, allowFoliageDestruction)
            end
            --#profile RemoteProfiler.zoneEnd()
        end

        --#profile RemoteProfiler.zoneBeginN("updateSurfaceSound")
        if spec.surfaceSounds ~= nil then
            -- update surface sounds
            if self:getAreSurfaceSoundsActive() then
                local currentSound = self:getCurrentSurfaceSound()
                if currentSound ~= spec.currentSurfaceSound then
                    if spec.currentSurfaceSound ~= nil then
                        g_soundManager:stopSample(spec.currentSurfaceSound)
                    end
                    if currentSound ~= nil then
                        g_soundManager:playSample(currentSound)
                    end

                    spec.currentSurfaceSound = currentSound
                end
            else
                if spec.currentSurfaceSound ~= nil then
                    g_soundManager:stopSample(spec.currentSurfaceSound)
                    spec.currentSurfaceSound = nil
                end
            end
        end
        --#profile RemoteProfiler.zoneEnd()

        if spec.hasSteeringNodes then
            self:updateSteeringNodes(dt)
        end
    end

    if #spec.wheels > 0 then
        if self.isServer then
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
end



---
function Wheels:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isServer then
        local spec = self.spec_wheels
        for _,wheel in ipairs(spec.wheels) do
            wheel:postUpdate(dt)
        end
    end
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActive true if vehicle is active
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function Wheels:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_wheels

    local groundWetness = g_currentMission.environment.weather:getGroundWetness()
    for _, wheel in pairs(spec.wheels) do
        wheel:updateTick(dt, groundWetness)
    end
end


---Called after last update tick
-- @param float dt time since last call in ms
-- @param boolean isActive true if vehicle is active
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function Wheels:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isClient then
        local spec = self.spec_wheels
        for _, wheel in pairs(spec.wheels) do
            wheel:onUpdateEnd()
        end

        if spec.currentSurfaceSound ~= nil then
            g_soundManager:stopSample(spec.currentSurfaceSound)
            spec.currentSurfaceSound = nil
        end
    end
end


---
function Wheels:loadHubsFromXML()
    local spec = self.spec_wheels

    spec.hubs = {}
    self.xmlFile:iterate("vehicle.wheels.hubs.hub", function (_, key)
        self:loadHubFromXML(self.xmlFile, key)
    end)
end


---
function Wheels.loadHubMaterial(vehicle, xmlFile, key, hub, materialName)
    local material = VehicleMaterial.new(vehicle.baseDirectory)
    if material:loadFromXML(xmlFile, key, vehicle.customEnvironment) then
        hub[materialName] = material
    end

    if xmlFile:getValue(key .. "#useBaseColor", false) then
        hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "baseColor") or hub[materialName]
    elseif xmlFile:getValue(key .. "#useRimColor", false) then
        hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "rimColor") or vehicle.spec_wheels["rimMaterial"] or hub[materialName]

        if hub[materialName] == nil then
            hub[materialName] = VehicleMaterial.new(self.baseDirectory)
            hub[materialName]:setTemplateName("RIM_DEFAULT")
        end
    else
        local useDesignColorIndex = xmlFile:getValue(key .. "#useDesignColorIndex")
        if useDesignColorIndex ~= nil then
            local configName = "designColor"
            if useDesignColorIndex >= 2 then
                configName = string.format("designColor%d", useDesignColorIndex)
            end

            hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, configName) or hub[materialName]
        end
    end
end


---
function Wheels:loadHubFromXML(xmlFile, key)
    local spec = self.spec_wheels
    local linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
    if linkNode == nil then
        Logging.xmlError(xmlFile, "Missing link node for hub '%s'", key)
        return
    end

    local hub = {}
    hub.linkNode = linkNode
    hub.isLeft = xmlFile:getValue(key .. "#isLeft")

    local hubXmlFilename = xmlFile:getValue(key .. "#filename")
    hub.xmlFilename = Utils.getFilename(hubXmlFilename, self.baseDirectory)
    local xmlFileHub = XMLFile.load("wheelHubXml", hub.xmlFilename, Wheels.xmlSchemaHub)
    if xmlFileHub ~= nil then
        local i3dFilename = xmlFileHub:getValue("hub.filename")
        if i3dFilename == nil then
            Logging.xmlError(xmlFileHub, "Unable to retrieve hub i3d filename!")
            return
        end
        hub.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)

        Wheels.loadHubMaterial(self, xmlFile, key .. ".material", hub, "material")
        Wheels.loadHubMaterial(self, xmlFile, key .. ".boltMaterial", hub, "boltMaterial")
        Wheels.loadHubMaterial(self, xmlFile, key .. ".additionalMaterial", hub, "additionalMaterial")
        Wheels.loadHubMaterial(self, xmlFile, key .. ".boltAdditionalMaterial", hub, "boltAdditionalMaterial")

        hub.nodeStr = xmlFileHub:getValue("hub.nodes#" .. (hub.isLeft and "left" or "right"))

        local arguments = {
            hub = hub,
            linkNode = linkNode,
            xmlFile = xmlFile,
            key = key
        }

        local sharedLoadRequestId = self:loadSubSharedI3DFile(hub.i3dFilename, false, false, self.onWheelHubI3DLoaded, self, arguments)
        table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)

        xmlFileHub:delete()
    end

    return true
end


---Called when wheel hub i3d was loaded
-- @param integer i3dNode i3dNode of wheel chock
-- @param table args arguments
function Wheels:onWheelHubI3DLoaded(i3dNode, failedReason, args)
    local spec = self.spec_wheels
    local hub = args.hub
    local linkNode = args.linkNode
    local xmlFile = args.xmlFile
    local key = args.key

    if i3dNode ~= 0 then
        hub.node = I3DUtil.indexToObject(i3dNode, hub.nodeStr, self.i3dMappings)

        if hub.node ~= nil then
            link(linkNode, hub.node)
            delete(i3dNode)
        else
            Logging.xmlError(xmlFile, "Could not find hub node '%s' in '%s'", hub.nodeStr, hub.xmlFilename)
            return
        end

        local offset = xmlFile:getValue(key .. "#offset")
        if offset ~= nil then
            if not hub.isLeft then
                offset = offset * -1
            end
            setTranslation(hub.node, offset, 0, 0)
        end

        local scale = xmlFile:getValue(key .. "#scale", nil, true)
        if scale ~= nil then
            setScale(hub.node, scale[1], scale[2], scale[3])
        end

        table.insert(spec.hubs, hub)
    else
        if not (self.isDeleting or self.isDeleted) then
            Logging.xmlError(xmlFile, "Unable to load '%s' in hub '%s'", hub.i3dFilename, hub.xmlFilename)
        end
    end
end



























---
function Wheels:loadAckermannSteeringFromXML(xmlFile, ackermannSteeringIndex, ackermannSteeringAngle)
    local spec = self.spec_wheels

    local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, ackermannSteeringIndex, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering", nil, "ackermann")

    spec.steeringCenterNode = nil

    if key ~= nil then
        local rotSpeed = xmlFile:getValue(key.."#rotSpeed")
        local rotMax = ackermannSteeringAngle or xmlFile:getValue(key.."#rotMax")

        local centerX
        local centerZ
        local rotCenterWheel1 = xmlFile:getValue(key.."#rotCenterWheel1")
        if rotCenterWheel1 ~= nil and spec.wheels[rotCenterWheel1] ~= nil then
            local wheel = spec.wheels[rotCenterWheel1]
            centerX, _, centerZ = localToLocal(wheel.node, self.components[1].node, wheel.physics.positionX, wheel.physics.positionY, wheel.physics.positionZ)

            local rotCenterWheel2 = xmlFile:getValue(key.."#rotCenterWheel2")
            if rotCenterWheel2 ~= nil and spec.wheels[rotCenterWheel2] ~= nil then
                if rotCenterWheel2 == rotCenterWheel1 then
                    Logging.xmlWarning(xmlFile, "The ackermann steering wheels are identical (both index %d). Are you sure this is correct? (%s)", rotCenterWheel1, key)
                end

                local wheel2 = spec.wheels[rotCenterWheel2]
                local x, _, z = localToLocal(wheel2.node, self.components[1].node, wheel2.physics.positionX, wheel2.physics.positionY, wheel2.physics.positionZ)
                centerX, centerZ = 0.5*(centerX + x), 0.5*(centerZ + z)
            end
        else
            local centerNode, _ = xmlFile:getValue(key.."#rotCenterNode", nil, self.components, self.i3dMappings)
            if centerNode ~= nil then
                centerX, _, centerZ = localToLocal(centerNode, self.components[1].node, 0,0,0)
                spec.steeringCenterNode = centerNode
            else
                local rotCenterWheels = xmlFile:getValue(key.."#rotCenterWheels", nil, true)
                if rotCenterWheels ~= nil and #rotCenterWheels > 0 then
                    local x, z, numWheels = 0, 0, 0
                    for i=1, #rotCenterWheels do
                        local wheel = spec.wheels[rotCenterWheels[i]]
                        if wheel ~= nil then
                            local _x, _, _z = localToLocal(wheel.node, self.components[1].node, wheel.physics.positionX, 0, wheel.physics.positionZ)
                            x, z, numWheels = x + _x, z + _z, numWheels + 1
                        end
                    end

                    if numWheels > 0 then
                        centerX, centerZ = x / numWheels, z / numWheels
                    end
                else
                    local p = xmlFile:getValue(key.."#rotCenter", nil, true)
                    if p ~= nil then
                        centerX = p[1]
                        centerZ = p[2]
                    end
                end
            end
        end
        if spec.steeringCenterNode == nil then
            spec.steeringCenterNode = createTransformGroup("steeringCenterNode")
            link(self.components[1].node, spec.steeringCenterNode)
            if centerX ~= nil and centerZ ~= nil then
                setTranslation(spec.steeringCenterNode, centerX, 0, centerZ)
            end
        end

        if rotSpeed ~= nil and rotMax ~= nil and centerX ~= nil then
            rotSpeed = math.abs(math.rad(rotSpeed))
            rotMax = math.abs(math.rad(rotMax))

            -- find the wheel that should get the maximum steering (the one that results in the maximum turnign radius)
            local maxTurningRadius = 0
            local isValid = false
            for i, wheel in ipairs(spec.wheels) do
                if wheel.physics.rotSpeed ~= 0 then
                    local diffX, _, diffZ = localToLocal(wheel.repr, spec.steeringCenterNode, 0, 0, 0)
                    local turningRadius = math.abs(diffZ)/math.tan(rotMax) + math.abs(diffX)
                    if turningRadius >= maxTurningRadius then
                        maxTurningRadius = turningRadius
                        isValid = true
                    end
                end
            end

            for _, steeringNode in ipairs(spec.steeringNodes) do
                local diffX, _, diffZ = localToLocal(steeringNode.node, spec.steeringCenterNode, 0, 0, 0)
                local turningRadius = math.abs(diffZ)/math.tan(rotMax) + math.abs(diffX)
                if turningRadius >= maxTurningRadius then
                    maxTurningRadius = turningRadius
                    isValid = true
                end
            end

            self.maxRotation = math.max(Utils.getNoNil(self.maxRotation, 0), rotMax)
            self.maxTurningRadius = xmlFile:getValue(key.."#minTurningRadius", maxTurningRadius)
            self.wheelSteeringDuration = rotMax / rotSpeed

            if isValid then
                for _, wheel in ipairs(spec.wheels) do
                    if wheel.physics.rotSpeed ~= 0 then
                        local rotMinI, rotMaxI, inverted = Wheels.getAckermannSteeringAngles(wheel.repr, spec.steeringCenterNode, maxTurningRadius)
                        wheel:setSteeringValues(rotMinI, rotMaxI, rotMaxI / self.wheelSteeringDuration, -rotMinI / self.wheelSteeringDuration, inverted)
                    end
                end

                for _, steeringNode in ipairs(spec.steeringNodes) do
                    local rotMinI, rotMaxI, inverted = Wheels.getAckermannSteeringAngles(steeringNode.node, spec.steeringCenterNode, maxTurningRadius)

                    steeringNode.rotMin = rotMinI
                    steeringNode.rotMax = rotMaxI
                    steeringNode.rotSpeed = rotMaxI / self.wheelSteeringDuration
                    steeringNode.rotSpeedNeg = -rotMinI / self.wheelSteeringDuration
                    if inverted then
                        steeringNode.rotSpeed, steeringNode.rotSpeedNeg = -steeringNode.rotSpeedNeg, -steeringNode.rotSpeed
                    end

                    steeringNode.rotMinOrig, steeringNode.rotMaxOrig = steeringNode.rotMin, steeringNode.rotMax
                    steeringNode.rotSpeedOrig, steeringNode.rotSpeedNegOrig = steeringNode.rotSpeed, steeringNode.rotSpeedNeg
                end
            end
        end
    end

    for _, wheel in ipairs(spec.wheels) do
        if wheel.physics.rotSpeed ~= 0 then
            -- if both speed and rot have the same sign, we can reach it with the positive time
            if (wheel.physics.rotMax >= 0) == (wheel.physics.rotSpeed >= 0) then
                self.maxRotTime = math.max(wheel.physics.rotMax/wheel.physics.rotSpeed, self.maxRotTime)
            end
            if (wheel.physics.rotMin >= 0) == (wheel.physics.rotSpeed >= 0) then
                self.maxRotTime = math.max(wheel.physics.rotMin/wheel.physics.rotSpeed, self.maxRotTime)
            end

            -- if speed and rot have a different sign, we can reach it with the negative time
            local rotSpeedNeg = wheel.physics.rotSpeedNeg
            if rotSpeedNeg == nil or rotSpeedNeg == 0 then
                rotSpeedNeg = wheel.physics.rotSpeed
            end
            if (wheel.physics.rotMax >= 0) ~= (rotSpeedNeg >= 0) then
                self.minRotTime = math.min(wheel.physics.rotMax/rotSpeedNeg, self.minRotTime)
            end
            if (wheel.physics.rotMin >= 0) ~= (rotSpeedNeg >= 0) then
                self.minRotTime = math.min(wheel.physics.rotMin/rotSpeedNeg, self.minRotTime)
            end
        end

        if wheel.physics.rotSpeedLimit ~= nil then
            wheel.physics.rotSpeedDefault = wheel.physics.rotSpeed
            wheel.physics.rotSpeedNegDefault = wheel.physics.rotSpeedNeg
            wheel.physics.currentRotSpeedAlpha = 1
        end
    end

    for _, steeringNode in ipairs(spec.steeringNodes) do
        self.maxRotTime = math.max(steeringNode.rotMax / steeringNode.rotSpeed, self.maxRotTime)

        -- if speed and rot have a different sign, we can reach it with the negative time
        local rotSpeedNeg = steeringNode.rotSpeedNeg
        if rotSpeedNeg == nil or rotSpeedNeg == 0 then
            rotSpeedNeg = steeringNode.rotSpeed
        end

        self.minRotTime = math.min(steeringNode.rotMin / rotSpeedNeg, self.minRotTime)
    end
end


---
function Wheels:loadWheelsFromXML(xmlFile, key, wheelConfigurationId)
    local spec = self.spec_wheels

    local i = 0
    while true do
        local wheelKey = string.format(".wheels.wheel(%d)", i)
        if not xmlFile:hasProperty(key .. wheelKey) then
            break
        end

        local wheel = Wheel.new(self, self.xmlFile, Wheels.CONFIG_XML_PATH, wheelKey, i + 1, wheelConfigurationId, spec.configurationIndexToParentConfigIndex, self.baseDirectory)
        if self:loadWheelFromXML(wheel) then
            wheel:finalize()

            if spec.isCareWheelConfiguration ~= nil then
                wheel:setIsCareWheel(spec.isCareWheelConfiguration)
            end

            table.insert(spec.wheels, wheel)
        end

        i = i + 1
    end
end


---
function Wheels:loadWheelFromXML(wheel)
    return wheel:loadFromXML()
end


---
function Wheels:onLoadWheelChockFromXML(wheelChock)
end


---
function Wheels:getIsWheelChockAllowed(wheelChock)
    return true
end


---
function Wheels:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end

    local spec = self.spec_wheels

    local brakeForce = self:getBrakeForce()
    for _, wheel in pairs(spec.wheels) do
        wheel:addToPhysics(brakeForce)
    end

    if self.isServer then
        self:brake(brakeForce)
    end

    return true
end


---
function Wheels:removeFromPhysics(superFunc)
    local ret = superFunc(self)

    if self.isServer then
        local spec = self.spec_wheels
        for _, wheel in pairs(spec.wheels) do
            wheel:removeFromPhysics()
        end
    end

    return ret
end


---Returns total mass of vehicle (optional including attached vehicles)
-- @param boolean onlyGivenVehicle use only the given vehicle, if false or nil it includes all attachables
-- @return float totalMass total mass
function Wheels:getComponentMass(superFunc, component)
    local mass = superFunc(self, component)

    local spec = self.spec_wheels
    for _, wheel in pairs(spec.wheels) do
        if wheel.node == component.node then
            mass = mass + wheel:getMass()
        end
    end

    return mass
end


---Returns the world space x rotation in rad
-- @return float rotation rotation
function Wheels:getVehicleWorldXRot(superFunc)
    local slopeAngle = 0
    local minWheelZ = math.huge
    local minWheelZHeight = 0
    local maxWheelZ = -math.huge
    local maxWheelZHeight = 0

    local spec = self.spec_wheels
    for i=1, #spec.wheels do
        local wheel = spec.wheels[i]
        if wheel.physics.hasGroundContact then
            local netInfo, radius = wheel.physics.netInfo, wheel.physics.radius
            local _, _, z = localToLocal(wheel.node, self.components[1].node, 0, 0, netInfo.z)
            local _, wheelY, _ = localToWorld(wheel.node, netInfo.x, netInfo.y - radius, netInfo.z)
            if z < minWheelZ then
                minWheelZ = z
                minWheelZHeight = wheelY
            end
            if z > maxWheelZ then
                maxWheelZ = z
                maxWheelZHeight = wheelY
            end
        end
    end

    if minWheelZ ~= math.huge then
        local y = maxWheelZHeight - minWheelZHeight
        if y ~= 0 then
            local l = maxWheelZ - minWheelZ
            if l < 0.25 and superFunc ~= nil then
                return superFunc(self)
            end

            slopeAngle = math.pi * 0.5 - math.atan(l/(y))
            if slopeAngle > math.pi * 0.5 then
                slopeAngle = slopeAngle - math.pi
            end
        end
    end

    return slopeAngle
end


---Returns the world space direction of the vehicle
-- @return float x x
-- @return float y y
-- @return float z z
function Wheels:getVehicleWorldDirection(superFunc)
    local avgDirX, avgDirY, avgDirZ, _ = 0, 0, 0, nil
    local centerZ = 0
    local contactedWheels = 0
    local spec = self.spec_wheels
    for i=1, #spec.wheels do
        local wheel = spec.wheels[i]
        if wheel.physics.hasGroundContact then
            local netInfo = wheel.physics.netInfo
            local _, _, z = localToLocal(wheel.node, self.components[1].node, netInfo.x, netInfo.y, netInfo.z)
            centerZ = centerZ + z

            local dx, dy, dz = localDirectionToWorld(wheel.node, wheel.physics.directionZ, wheel.physics.directionX, -wheel.physics.directionY)
            avgDirX, avgDirY, avgDirZ = avgDirX + dx, avgDirY + dy, avgDirZ + dz

            contactedWheels = contactedWheels + 1
        end
    end

    if contactedWheels > 0 then
        avgDirX, _, avgDirZ = avgDirX / contactedWheels, avgDirY / contactedWheels, avgDirZ / contactedWheels
    end

    if contactedWheels > 2 then
        centerZ = centerZ / contactedWheels

        local frontCenterX, frontCenterY, frontCenterZ, frontWheelsCount = 0, 0, 0, 0
        local backCenterX, backCenterY, backCenterZ, backWheelsCount = 0, 0, 0, 0

        for i=1, #spec.wheels do
            local wheel = spec.wheels[i]
            if wheel.physics.hasGroundContact then
                local netInfo, radius = wheel.physics.netInfo, wheel.physics.radius
                local x, y, z = localToLocal(wheel.node, self.components[1].node, netInfo.x + wheel.physics.directionX * radius, netInfo.y + wheel.physics.directionY * radius, netInfo.z + wheel.physics.directionZ * radius)

                if z > centerZ + 0.25 then
                    frontCenterX, frontCenterY, frontCenterZ, frontWheelsCount = frontCenterX + x, frontCenterY + y, frontCenterZ + z, frontWheelsCount + 1
                elseif z < centerZ - 0.25 then
                    backCenterX, backCenterY, backCenterZ, backWheelsCount = backCenterX + x, backCenterY + y, backCenterZ + z, backWheelsCount + 1
                end
            end
        end

        if frontWheelsCount > 0 and backWheelsCount > 0 then
            frontCenterX, frontCenterY, frontCenterZ = frontCenterX / frontWheelsCount, frontCenterY / frontWheelsCount, frontCenterZ / frontWheelsCount
            backCenterX, backCenterY, backCenterZ = backCenterX / backWheelsCount, backCenterY / backWheelsCount, backCenterZ / backWheelsCount

            frontCenterX, frontCenterY, frontCenterZ = localToWorld(self.components[1].node, frontCenterX, frontCenterY, frontCenterZ)
            backCenterX, backCenterY, backCenterZ = localToWorld(self.components[1].node, backCenterX, backCenterY, backCenterZ)

            if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
                DebugGizmo.renderAtPosition(frontCenterX, frontCenterY, frontCenterZ, 1, 0, 0, 0, 1, 0, "frontWheels")
                DebugGizmo.renderAtPosition(backCenterX, backCenterY, backCenterZ, 1, 0, 0, 0, 1, 0, "backWheels")
            end

            local dx, dy, dz, _ = frontCenterX - backCenterX, frontCenterY - backCenterY, frontCenterZ - backCenterZ, nil
            _, avgDirY, _ = MathUtil.vector3Normalize(dx, dy, dz)
        else
            return superFunc(self)
        end
    else
        return 0, 0, 0
    end

    return MathUtil.vector3Normalize(avgDirX, avgDirY, avgDirZ)
end


---
function Wheels:validateWashableNode(superFunc, node)
    -- start checking the wheel nodes only if all wheel parts are loaded
    if self.loadingStep >= SpecializationLoadStep.FINISHED then
        local spec = self.spec_wheels
        for i=1, #spec.wheels do
            local wheel = spec.wheels[i]
            local wheelNode = wheel.driveNode
            if wheel.linkNode ~= wheel.driveNode then
                wheelNode = wheel.linkNode
            end

            if wheel.wheelDirtNodes == nil then
                wheel.wheelDirtNodes = {}
                I3DUtil.getNodesByShaderParam(wheelNode, "scratches_dirt_snow_wetness", wheel.wheelDirtNodes)
            end

            if wheel.wheelMudMeshes == nil then
                wheel.wheelMudMeshes = {}
                I3DUtil.getNodesByShaderParam(wheelNode, "mudAmount", wheel.wheelMudMeshes)
            end

            if wheel.wheelDirtNodes[node] ~= nil then
                local nodeData = {}
                nodeData.wheel = wheel
                nodeData.fieldDirtMultiplier = wheel.physics.fieldDirtMultiplier
                nodeData.streetDirtMultiplier = wheel.physics.streetDirtMultiplier
                nodeData.waterWetnessFactor = wheel.physics.waterWetnessFactor
                nodeData.minDirtPercentage = wheel.physics.minDirtPercentage
                nodeData.maxDirtOffset = wheel.physics.maxDirtOffset
                nodeData.dirtColorChangeSpeed = wheel.physics.dirtColorChangeSpeed
                nodeData.isSnowNode = true

                nodeData.loadFromSavegameFunc = function(xmlFile, key)
                    nodeData.wheel.physics.snowScale = xmlFile:getValue(key.."#snowScale", 0)
                    nodeData.wheel.physics.lastSnowScale = nodeData.wheel.physics.snowScale

                    local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
                    local r, g, b = MathUtil.vector3ArrayLerp(defaultColor, snowColor, nodeData.wheel.physics.snowScale)
                    local washableNode = self:getWashableNodeByCustomIndex(wheel)
                    self:setNodeDirtColor(washableNode, r, g, b, true)
                end
                nodeData.saveToSavegameFunc = function(xmlFile, key)
                    xmlFile:setValue(key.."#snowScale", nodeData.wheel.physics.snowScale)
                end

                return false, self.updateWheelDirtAmount, wheel, nodeData
            end

            if wheel.wheelMudMeshes[node] ~= nil then
                local nodeData = {}
                nodeData.wheel = wheel
                nodeData.fieldDirtMultiplier = wheel.physics.fieldDirtMultiplier
                nodeData.streetDirtMultiplier = wheel.physics.streetDirtMultiplier
                nodeData.waterWetnessFactor = wheel.physics.waterWetnessFactor
                nodeData.minDirtPercentage = wheel.physics.minDirtPercentage
                nodeData.maxDirtOffset = wheel.physics.maxDirtOffset
                nodeData.dirtColorChangeSpeed = wheel.physics.dirtColorChangeSpeed
                nodeData.isSnowNode = true
                nodeData.cleaningMultiplier = 4

                -- randomly rotate the mud mesh, so they do not look the same on each tire
                rotateAboutLocalAxis(node, math.random() * 3.14, 1, 0, 0)

                return false, self.updateWheelMudAmount, wheel.wheelMudMeshes, nodeData
            end
        end
    end

    return superFunc(self, node)
end


---
function Wheels:getAIDirectionNode(superFunc)
    return self.spec_wheels.steeringCenterNode or superFunc(self)
end


---
function Wheels:getAIRootNode(superFunc)
    return self.spec_wheels.steeringCenterNode or superFunc(self)
end


---
function Wheels:getSupportsMountKinematic(superFunc)
    return #self.spec_wheels.wheels == 0 and superFunc(self)
end


---
function Wheels:loadBendingNodeFromXML(superFunc, xmlFile, key, bendingNode, ...)
    if not superFunc(self, xmlFile, key, bendingNode, ...) then
        return false
    end

    local wheelIndices = xmlFile:getValue(key .. "#wheelIndices", nil, true)
    if wheelIndices ~= nil and #wheelIndices > 0 then
        bendingNode.minX = math.huge
        bendingNode.maxX = -math.huge
        bendingNode.minZ = math.huge
        bendingNode.maxZ = -math.huge

        local offset = 0.05
        for _, wheelIndex in ipairs(wheelIndices) do
            local wheel = self:getWheelFromWheelIndex(wheelIndex)
            if wheel ~= nil then
                local x1, _, z1 = localToLocal(wheel.driveNode, bendingNode.node, (wheel.physics.wheelShapeWidth * 0.5 + offset) + wheel.physics.wheelShapeWidthOffset, 0, (wheel.physics.radius * 0.5 + offset))
                local x2, _, z2 = localToLocal(wheel.driveNode, bendingNode.node, -((wheel.physics.wheelShapeWidth * 0.5 + offset) - wheel.physics.wheelShapeWidthOffset), 0, -(wheel.physics.radius * 0.5 + offset))

                bendingNode.minX = math.min(bendingNode.minX, x1, x2)
                bendingNode.maxX = math.max(bendingNode.maxX, x1, x2)
                bendingNode.minZ = math.min(bendingNode.minZ, z1, z2)
                bendingNode.maxZ = math.max(bendingNode.maxZ, z1, z2)
            else
                Logging.xmlWarning(xmlFile, "Unable to find wheel index '%s' in '%s'", wheelIndex, key)
            end
        end

        -- values still can be overwritten by the XML file
        bendingNode.minX = xmlFile:getValue(key.."#minX", bendingNode.minX)
        bendingNode.maxX = xmlFile:getValue(key.."#maxX", bendingNode.maxX)
        bendingNode.minZ = xmlFile:getValue(key.."#minZ", bendingNode.minZ)
        bendingNode.maxZ = xmlFile:getValue(key.."#maxZ", bendingNode.maxZ)
    end

    return true
end


---
function Wheels:updateWheelDirtAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
    local changeDirt, changeWetness = 0, 0
    local dirtMultiplier = self.spec_washable.lastDirtMultiplier
    if dirtMultiplier ~= 0 then
        changeDirt = dt * self.spec_washable.dirtDuration * dirtMultiplier
    end

    local allowManipulation = true
    if nodeData.wheel ~= nil then
        if nodeData.wheel.physics.contact == WheelContactType.NONE and nodeData.wheel.forceWheelDirtUpdate ~= true then
            allowManipulation = false
        end
    end

    if allowManipulation then
        local physics = nodeData.wheel.physics
        local isOnDirtField = physics:getIsOnField()

        local lastSpeed = self.lastSpeed * 3600

        if isOnDirtField then
            changeDirt = changeDirt * nodeData.fieldDirtMultiplier
        else
            -- dirt is not reduced when driving on grassland, just not increased more
            if not self:getIsOnField() then
                if nodeData.dirtAmount > nodeData.minDirtPercentage then
                    local dirtFactor = lastSpeed / 20
                    dirtFactor = dirtFactor * nodeData.streetDirtMultiplier
                    dirtFactor = dirtFactor * (rainScale > 0.1 and 0.15 or 1) -- mud sticks more when it's wet

                    changeDirt = changeDirt * dirtFactor
                end
            end
        end

        if nodeData.wetness < 0.25 then
            local globalValue = self.spec_washable.washableNodes[1].dirtAmount
            local minDirtOffset = nodeData.maxDirtOffset * (math.pow(1-globalValue, 2) * 0.75 + 0.25)
            local maxDirtOffset = nodeData.maxDirtOffset * (math.pow(1-globalValue, 2) * 0.95 + 0.05)
            if globalValue - nodeData.dirtAmount > minDirtOffset then
                if changeDirt < 0 then
                    changeDirt = 0
                end
            elseif globalValue - nodeData.dirtAmount < -maxDirtOffset then
                if changeDirt > 0 then
                    changeDirt = 0
                end
            end
        end

        -- change dirt scale of wheels slowly to snow color when having snow contact
        -- changing back to normal color takes longer
        local factor = (physics.hasSnowContact and (temperature or 0) < 1) and 1 or -0.25
        local speedFactor = math.min(lastSpeed / 5, 2)
        local lastSnowScale = physics.snowScale
        physics.snowScale = math.min(math.max(lastSnowScale + factor * dt * nodeData.dirtColorChangeSpeed * speedFactor, 0), 1)

        if physics.snowScale ~= physics.lastSnowScale then
            local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
            local r, g, b = MathUtil.vector3ArrayLerp(defaultColor, snowColor, physics.snowScale)
            self:setNodeDirtColor(nodeData, r, g, b)

            physics.lastSnowScale = physics.snowScale
        end

        if physics.hasWaterContact then
            changeWetness = dt * self.spec_washable.wetDuration * nodeData.waterWetnessFactor * (1 + math.min(self.lastSpeed * 3600 / 10, 1))
        else
            changeWetness = -dt * self.spec_washable.dryDuration * (math.min(self.lastSpeed * 3600 / 10, 1) * 5)
        end

        nodeData.wheel.forceWheelDirtUpdate = false
    end

    return changeDirt, changeWetness
end


---
function Wheels:updateWheelMudAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
    local changeDirt, changeWetness = 0, 0
    local dirtMultiplier = self.spec_washable.lastDirtMultiplier
    if dirtMultiplier ~= 0 then
        changeDirt = dt * self.spec_washable.dirtDuration * dirtMultiplier
    end

    if nodeData.wheelDirtNode == nil then
        nodeData.wheelDirtNode = self:getWashableNodeByCustomIndex(nodeData.wheel)

        if nodeData.wheelDirtNode == nil then
            return 0, 0
        end
    end

    if nodeData.wheel ~= nil then
        if nodeData.wheel.physics.contact == WheelContactType.NONE and nodeData.wheel.forceWheelDirtUpdate ~= true then
            return 0, nodeData.wheelDirtNode.wetness - nodeData.wetness
        end
    end

    local lastSpeed = self.lastSpeed * 3600
    local maxAmount = WheelEffects.MAX_MUD_AMOUNT[nodeData.wheel.physics.densityType] or 0
    maxAmount = maxAmount * (rainScale > 0.1 and 1 or 0.5) -- full mud only when it's wet, otherwise 50%

    local wheelDirtAmount = nodeData.wheelDirtNode.dirtAmount

    if nodeData.dirtAmount < maxAmount and wheelDirtAmount > 0.75 then
        changeDirt = changeDirt * nodeData.fieldDirtMultiplier * 2
    elseif nodeData.dirtAmount > maxAmount or wheelDirtAmount < 0.75 then
        local speedFactor = lastSpeed / 20
        changeDirt = changeDirt * nodeData.streetDirtMultiplier * 2 * speedFactor
    end

    changeWetness = nodeData.wheelDirtNode.wetness - nodeData.wetness

    local colorMud, colorWheel = nodeData.color, nodeData.wheelDirtNode.color
    if colorMud[1] ~= colorWheel[1] or colorMud[2] ~= colorWheel[2] or colorMud[3] ~= colorWheel[3] then
        self:setNodeDirtColor(nodeData, colorWheel[1], colorWheel[2], colorWheel[3])
    end

    return changeDirt, changeWetness
end


---
function Wheels:forceUpdateWheelPhysics(dt)
    local spec = self.spec_wheels
    for i=1, #spec.wheels do
        spec.wheels[i]:updatePhysics(self:getBrakeForce())
    end
end


---
function Wheels:onWheelSnowHeightChanged(heightPct, heightAbs)
    if heightPct <= 0 then
        local spec = self.spec_wheels
        local changedSnowScale = false
        for i=1, #spec.wheels do
            if spec.wheels[i].physics.snowScale > 0 then
                spec.wheels[i].physics.snowScale = 0
                spec.wheels[i].forceWheelDirtUpdate = true
                changedSnowScale = true
            end
        end

        -- raise active to update dirt amount
        if changedSnowScale then
            self:raiseActive()
        end
    end
end


---
function Wheels:getSteeringNodeByNode(node)
    local spec = self.spec_wheels
    for _, steeringNode in ipairs(spec.steeringNodes) do
        if steeringNode.node == node then
            return steeringNode
        end
    end

    return nil
end


---
function Wheels:updateSteeringNodes(dt)
    local spec = self.spec_wheels
    for _, steeringNode in ipairs(spec.steeringNodes) do
        local targetSteeringAngle
        if self.rotatedTime > 0 or steeringNode.rotSpeedNeg == nil then
            targetSteeringAngle = self.rotatedTime * steeringNode.rotSpeed
        else
            targetSteeringAngle = self.rotatedTime * steeringNode.rotSpeedNeg
        end

        if targetSteeringAngle > steeringNode.rotMax then
            targetSteeringAngle = steeringNode.rotMax
        elseif targetSteeringAngle < steeringNode.rotMin then
            targetSteeringAngle = steeringNode.rotMin
        end

        if steeringNode.rotScale ~= steeringNode.rotScaleTarget then
            local direction = math.sign(steeringNode.rotScaleTarget - steeringNode.rotScale)
            local change = dt * steeringNode.rotScaleTargetSpeed * direction
            local limit = direction > 0 and math.min or math.max
            steeringNode.rotScale = limit(steeringNode.rotScale + change, steeringNode.rotScaleTarget)
        end
        targetSteeringAngle = targetSteeringAngle * steeringNode.rotScale

        if steeringNode.offset ~= steeringNode.offsetTarget then
            local direction = math.sign(steeringNode.offsetTarget - steeringNode.offset)
            local change = dt * steeringNode.offsetTargetSpeed * direction
            local limit = direction > 0 and math.min or math.max
            steeringNode.offset = limit(steeringNode.offset + change, steeringNode.offsetTarget)
        end
        targetSteeringAngle = targetSteeringAngle + steeringNode.offset

        local _, steeringAngle, _ = getRotation(steeringNode.node)
        if math.abs(steeringAngle - targetSteeringAngle) > 0.004 then
            local direction = math.sign(targetSteeringAngle - steeringAngle)
            local change = dt * steeringNode.rotChangeSpeed * 0.001 * direction
            local limit = direction > 0 and math.min or math.max
            steeringAngle = limit(steeringAngle + change, targetSteeringAngle)

            setRotation(steeringNode.node, 0, steeringAngle, 0)
            steeringNode.steeringAngle = steeringAngle

            if self.isServer then
                if steeringNode.componentJoint ~= nil then
                    self:setComponentJointFrame(steeringNode.componentJoint, 0)
                end
            end
        end
    end
end


---
function Wheels:getCurrentSurfaceSound()
    local spec = self.spec_wheels

    local numWheels = #spec.wheels
    for i, wheel in ipairs(spec.wheels) do
        if wheel.syncContactState or i == numWheels then
            local surfaceName, surfaceId = wheel.physics:getSurfaceSoundAttributes()
            if surfaceName ~= nil then
                return spec.surfaceNameToSound[surfaceName]
            elseif surfaceId ~= nil then
                return spec.surfaceIdToSound[surfaceId]
            end
        end
    end

    return nil
end


---
function Wheels:getAreSurfaceSoundsActive()
    return self.isActiveForLocalSound
end


---
function Wheels:getIsVersatileYRotActive(wheel)
    return true
end


---
function Wheels:getWheelFromWheelIndex(wheelIndex)
    return self.spec_wheels.wheels[wheelIndex]
end


---
function Wheels:getWheelByWheelNode(wheelNode)
    local spec = self.spec_wheels

    if type(wheelNode) == "string" then
        local mapping = self.i3dMappings[wheelNode]
        if mapping ~= nil then
            wheelNode = mapping.nodeId
        end
    end

    for i=1, #spec.wheels do
        local wheel = spec.wheels[i]
        if wheel.repr == wheelNode
        or wheel.driveNode == wheelNode
        or wheel.linkNode == wheelNode then
            return wheel
        end
    end

    return nil
end


---
function Wheels:getWheels()
    return self.spec_wheels.wheels
end


---
function Wheels:brake(brakePedal)
    local spec = self.spec_wheels
    if brakePedal ~= spec.brakePedal then
        spec.brakePedal = brakePedal

        for _,wheel in pairs(spec.wheels) do
            wheel:setBrakePedal(spec.brakePedal)
        end

        SpecializationUtil.raiseEvent(self, "onBrake", spec.brakePedal)
    end
end







---
function Wheels:getBrakeForce()
    local spec = self.spec_wheels
    return spec.customBrakeForce or 0
end


---
function Wheels:onLeaveVehicle()
    local spec = self.spec_wheels
    if self.isServer and self.isAddedToPhysics then
        local brakeForce = self:getBrakeForce()
        for _,wheel in pairs(spec.wheels) do
            wheel:updatePhysics(brakeForce, 0)
        end
    end
end


---
function Wheels:onPreAttach()
    local spec = self.spec_wheels
    for _,wheel in pairs(spec.wheels) do
        wheel:onPreAttach()
    end
end


---
function Wheels:onPostDetach()
    local spec = self.spec_wheels
    for _,wheel in pairs(spec.wheels) do
        wheel:onPostDetach()
    end
end


---
function Wheels:getSteeringRotTimeByCurvature(curvature)
    local targetRotTime = 0
    if curvature ~= 0 then
        local spec = self.spec_wheels

        targetRotTime = math.huge
        if curvature > 0 then
            targetRotTime = -math.huge
        end
        for i, wheel in ipairs(spec.wheels) do
            if wheel.physics.rotSpeed ~= 0 then
                local diffX, _, diffZ = localToLocal(wheel.repr, spec.steeringCenterNode, 0, 0, 0)
                local targetRot = math.atan((diffZ * math.abs(curvature)) / ((1 - math.abs(curvature) * math.abs(diffX))))
                local wheelRotTime = targetRot / wheel.physics.rotSpeed
                if curvature > 0 then
                    wheelRotTime = -wheelRotTime
                    targetRotTime = math.max(targetRotTime, wheelRotTime)
                else
                    targetRotTime = math.min(targetRotTime, wheelRotTime)
                end

            end
        end

        targetRotTime = targetRotTime * -1

--        log(string.format("Curvature %.4f , MaxCurvature %.4f, CalcTurnRadius %.3fm -> targetRot %.3f deg -> targetRotTime %.4f", curvature, maxCurvature, currentTurnRadius, math.deg(targetRot), targetRotTime))
    end


    return targetRotTime
end


---
function Wheels:getTurningRadiusByRotTime(rotTime)
    local spec = self.spec_wheels

    local maxTurningRadius = math.huge
    if spec.steeringCenterNode ~= nil then
        for i, wheel in ipairs(spec.wheels) do
            if wheel.physics.rotSpeed ~= 0 then
                local wheelRot = math.abs(rotTime * wheel.physics.rotSpeed)
                if wheelRot > 0 then
                    local diffX, _, diffZ = localToLocal(wheel.repr, spec.steeringCenterNode, 0, 0, 0)
                    local turningRadius = math.abs(diffZ) / math.tan(wheelRot) + math.abs(diffX)
                    if turningRadius < maxTurningRadius then
                        maxTurningRadius = turningRadius
                    end
                end
            end
        end
    end

    return maxTurningRadius
end


---Called on pre load to register animation value types
function Wheels:onRegisterAnimationValueTypes()
    self:registerAnimationValueType("steeringAngle", "startSteeringAngle", "endSteeringAngle", false, AnimationValueFloat,
        function(value, xmlFile, xmlKey)
            value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")
            value.wheelNode = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)

            if value.wheelIndex ~= nil or value.wheelNode then
                if value.wheelIndex ~= nil then
                    value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
                    value:addCompareParameters("wheelIndex")
                else
                    value:setWarningInformation("wheelNode: " .. getName(value.wheelNode))
                    value:addCompareParameters("wheelNode")
                end

                return true
            end

            return false
        end,

        function(value)
            if value.wheelIndex ~= nil or value.wheelNode ~= nil then
                if value.wheel == nil and value.wheelIndex ~= nil then
                    value.wheel = self:getWheelFromWheelIndex(value.wheelIndex)
                    if value.wheel == nil then
                        Logging.xmlWarning(self.xmlFile, "Unknown wheel index '%s' for animation part.", value.wheelIndex)
                        value.wheelIndex = nil
                        return 0
                    end
                end

                if value.wheel == nil and value.wheelNode ~= nil then
                    value.wheel = self:getWheelByWheelNode(value.wheelNode)
                    if value.wheel == nil then
                        Logging.xmlWarning(self.xmlFile, "Unknown wheel node '%s' for animation part.", getName(value.wheelNode))
                        value.wheelNode = nil
                        return 0
                    end
                end

                return value.wheel.physics.steeringAngle
            end

            return 0
        end,

        function(value, steeringAngle)
            if value.wheel ~= nil then
                value.wheel.physics.steeringAngle = steeringAngle
            end
        end)

        self:registerAnimationValueType("brakeFactor", "startBrakeFactor", "endBrakeFactor", false, AnimationValueFloat,
            function(value, xmlFile, xmlKey)
                value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")
                value.wheelNode = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)

                if value.wheelIndex ~= nil or value.wheelNode then
                    if value.wheelIndex ~= nil then
                        value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
                        value:addCompareParameters("wheelIndex")
                    else
                        value:setWarningInformation("wheelNode: " .. getName(value.wheelNode))
                        value:addCompareParameters("wheelNode")
                    end

                    return true
                end

                return false
            end,

            function(value)
                if value.wheel == nil and value.wheelIndex ~= nil then
                    value.wheel = self:getWheelFromWheelIndex(value.wheelIndex)
                    if value.wheel == nil then
                        Logging.xmlWarning(self.xmlFile, "Unknown wheel index '%s' for animation part.", value.wheelIndex)
                        value.wheelIndex = nil
                        return 0
                    end
                end

                if value.wheel == nil and value.wheelNode ~= nil then
                    value.wheel = self:getWheelByWheelNode(value.wheelNode)
                    if value.wheel == nil then
                        Logging.xmlWarning(self.xmlFile, "Unknown wheel node '%s' for animation part.", getName(value.wheelNode))
                        value.wheelNode = nil
                        return 0
                    end
                end

                return value.wheel.physics.brakeFactor
            end,

            function(value, brakeFactor)
                if value.wheel ~= nil then
                    value.wheel.physics.brakeFactor = brakeFactor
                    value.wheel:updatePhysics(self:getBrakeForce())
                end
            end)

    self:registerAnimationValueType("torqueDirection", "startTorqueDirection", "endTorqueDirection", false, AnimationValueFloat,
            function(value, xmlFile, xmlKey)
                value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")
                value.wheelNode = xmlFile:getValue(xmlKey .. "#node", nil, self.components, self.i3dMappings)

                if value.wheelIndex ~= nil or value.wheelNode then
                    if value.wheelIndex ~= nil then
                        value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
                        value:addCompareParameters("wheelIndex")
                    else
                        value:setWarningInformation("wheelNode: " .. getName(value.wheelNode))
                        value:addCompareParameters("wheelNode")
                    end

                    return true
                end

                return false
            end,

            function(value)
                if value.wheel == nil and value.wheelIndex ~= nil then
                    value.wheel = self:getWheelFromWheelIndex(value.wheelIndex)
                    if value.wheel == nil then
                        Logging.xmlWarning(self.xmlFile, "Unknown wheel index '%s' for animation part.", value.wheelIndex)
                        value.wheelIndex = nil
                        return 0
                    end
                end

                if value.wheel == nil and value.wheelNode ~= nil then
                    value.wheel = self:getWheelByWheelNode(value.wheelNode)
                    if value.wheel == nil then
                        Logging.xmlWarning(self.xmlFile, "Unknown wheel node '%s' for animation part.", getName(value.wheelNode))
                        value.wheelNode = nil
                        return 0
                    end
                end

                return value.wheel.physics.torqueDirection
            end,

            function(value, torqueDirection)
                if value.wheel ~= nil then
                    value.wheel.physics:setTorqueDirection(torqueDirection)
                end
            end)
end


---
function Wheels:onPostAttachImplement(object, inputJointDescIndex, jointDescIndex)
    -- raise onBrake event again, so the brake force of the new implement is updated, even if the attacherVehicle has no brake pedal change
    SpecializationUtil.raiseEvent(self, "onBrake", self.spec_wheels.brakePedal)
end



---
function Wheels:onAIFieldWorkerStart()
    local spec = self.spec_wheels
    for _, wheel in ipairs(spec.wheels) do
        wheel.physics:setDisplacementAllowed(false)
    end
end


---
function Wheels:onAIImplementStart()
    local spec = self.spec_wheels
    for _, wheel in ipairs(spec.wheels) do
        wheel.physics:setDisplacementAllowed(false)
    end
end


---
function Wheels:onAIFieldWorkerEnd()
    local spec = self.spec_wheels
    for _, wheel in ipairs(spec.wheels) do
        wheel.physics:setDisplacementAllowed(true)
    end
end


---
function Wheels:onAIImplementEnd()
    local spec = self.spec_wheels
    for _, wheel in ipairs(spec.wheels) do
        wheel.physics:setDisplacementAllowed(true)
    end
end


---
function Wheels:getWheelSuspensionModfier()
    local spec = self.spec_wheels

    local numWheels = #spec.wheels
    if numWheels > 0 then
        local totalDelta = 0
        for _, wheel in ipairs(spec.wheels) do
            totalDelta = totalDelta + (wheel.physics.deltaY - wheel.physics.netInfo.suspensionLength)
        end

        local averageDelta = totalDelta / numWheels

        local maxDelta = 0
        for _, wheel in ipairs(spec.wheels) do
            local delta = averageDelta - (wheel.physics.deltaY - wheel.physics.netInfo.suspensionLength)
            maxDelta = math.max(math.abs(delta), maxDelta)
        end

        return maxDelta
    end

    return 0
end




---Returns set of tire names used on the vehicle or nil if none are present
function Wheels.getTireNames(instance)
    local spec = instance.spec_wheels
    if spec == nil then
        return nil
    end

    local tireNames = {}
    for _, wheel in ipairs(spec.wheels) do
        if wheel.name ~= nil then
            tireNames[wheel.name] = true
        end
    end
    for _, dynLoadedWheel in ipairs(spec.dynamicallyLoadedWheels) do
        if dynLoadedWheel.name ~= nil then
            tireNames[dynLoadedWheel.name] = true
        end
    end

    if table.size(tireNames) == 0 then
        return nil
    end

    return tireNames
end


---
function Wheels.getBrands(items)
    local brands = {}
    local addedBrands = {}
    for _, item in ipairs(items) do
        if item.isSelectable ~= false and item.wheelBrandName ~= nil and addedBrands[item.wheelBrandName] == nil then
            table.insert(brands, {title=item.wheelBrandName, icon=item.wheelBrandIconFilename})
            addedBrands[item.wheelBrandName] = true
        end
    end

    return brands
end


---
function Wheels.getWheelsByBrand(items, brand)
    local wheels = {}
    for _, item in ipairs(items) do
        if item.isSelectable ~= false and item.wheelBrandName == brand.title then
            table.insert(wheels, item)
        end
    end

    return wheels
end


---
function Wheels.loadSpecValueWheelWeight(xmlFile, customEnvironment, baseDir)
    local storeItem = g_storeManager:getItemByXMLFilename(xmlFile.filename)

    local configItem
    if storeItem.configurations ~= nil then
        local configItems = storeItem.configurations["wheel"]
        if configItems ~= nil then
            for i, item in ipairs(configItems) do
                if item.isSelectable and item.isDefault then
                    configItem = item
                    break
                end
            end

            if configItem == nil then
                for i, item in ipairs(configItems) do
                    if item.isSelectable then
                        configItem = item
                        break
                    end
                end
            end
        end
    end

    local configMass = 0

    if configItem ~= nil then
        configItem:applyGeneratedConfiguration(xmlFile)
        local configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(xmlFile)

        xmlFile:iterate(configItem.configKey .. ".wheels.wheel", function(index, key)
            local wheelKey = string.format(".wheels.wheel(%d)", index - 1)

            local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", configItem.index, wheelKey, configurationIndexToParentConfigIndex)
            wheeXMLObject:setXMLLoadKey("")

            local mass = wheeXMLObject:cacheWheelMass()

            wheeXMLObject:delete()

            configMass = configMass + mass
        end)
    end

    return configMass
end


---
function Wheels.loadSpecValueWheels(xmlFile, customEnvironment, baseDir)
    -- No data to load as this spec is only for existing items
    return nil
end


---
function Wheels.getSpecValueWheels(storeItem, realItem)
    if realItem == nil then
        return nil
    end

    local tireNames = Wheels.getTireNames(realItem)
    if tireNames == nil then
        return nil
    end

    return table.concatKeys(tireNames, " / ")
end


































---Create wheel config save if mappings
-- @param table xmlFile xml file object
-- @return table configurationSaveIdToIndex save id to config index mapping
-- @return table configurationIndexToParentConfigIndex config index to base config mapping
function Wheels.createConfigToParentConfigMapping(xmlFile)
    local configurationSaveIdToIndex = {}
    local configurationIndexToParentConfigIndex = {}

    xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(index, key)
        local saveId = xmlFile:getValue(key .. "#saveId", tostring(index))
        configurationSaveIdToIndex[saveId] = index
    end)

    xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(index, key)
        XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".wheels.foliageBendingModifier", key .. ".foliageBendingModifier") --FS19 to FS22

        local baseConfigId = xmlFile:getValue(key .. ".wheels#baseConfig")
        if baseConfigId ~= nil then
            local baseIndex = configurationSaveIdToIndex[baseConfigId]
            if index == baseIndex then
                Logging.xmlError(xmlFile, "Wheel configuration %s references itself as baseConfig! Ignoring this reference", key)
            else
                configurationIndexToParentConfigIndex[index] = baseIndex
            end
        end
    end)

    return configurationIndexToParentConfigIndex
end
