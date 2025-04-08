














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableSolarPanels.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableIncomePerHour, specializations)
end


---
function PlaceableSolarPanels.initSpecialization()
    g_placeableConfigurationManager:addConfigurationType("solarPanels", g_i18n:getText("configuration_solarPanel"), "solarPanels", PlaceableConfigurationItem)
end


---
function PlaceableSolarPanels.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getIncomePerHour", PlaceableSolarPanels.getIncomePerHour)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableSolarPanels.getNeedHourChanged)
end


---
function PlaceableSolarPanels.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "updateHeadRotation", PlaceableSolarPanels.updateHeadRotation)
end


---
function PlaceableSolarPanels.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSolarPanels)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSolarPanels)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSolarPanels)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSolarPanels)
    SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableSolarPanels)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableSolarPanels)
end


---
function PlaceableSolarPanels.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("SolarPanels")

    basePath = basePath .. ".solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(?)"
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#headNode", "Head Node")
    schema:register(XMLValueType.ANGLE, basePath .. "#randomHeadOffsetRange", "Range of random offset", 15)
    schema:register(XMLValueType.ANGLE, basePath .. "#rotationSpeed", "Rotation Speed (deg/sec)", 5)
    schema:register(XMLValueType.BOOL, basePath .. "#isActive", "If solar panels are available", false)
    schema:register(XMLValueType.FLOAT, basePath .. "#incomePerHour", "Income per hour")
    schema:setXMLSpecializationType()
end


---
function PlaceableSolarPanels.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("SolarPanels")
    schema:register(XMLValueType.FLOAT, basePath .. "#headRotationRandom", "Head random rotation")
    schema:setXMLSpecializationType()
end


---
function PlaceableSolarPanels:onLoad(savegame)
    local spec = self.spec_solarPanels
    local xmlFile = self.xmlFile

    local solarPanelsConfigurationId = Utils.getNoNil(self.configurations["solarPanels"], 1)
    local configKey = string.format("placeable.solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(%d)", solarPanelsConfigurationId - 1)
    local hasSolarPanels = xmlFile:getValue(configKey .. "#isActive", false)

    spec.headNode = xmlFile:getValue(configKey .. "#headNode", nil, self.components, self.i3dMappings)
    if spec.headNode ~= nil then
        hasSolarPanels = true

        spec.randomHeadOffsetRange = xmlFile:getValue(configKey .. "#randomHeadOffsetRange", 15)
        spec.rotationSpeed = xmlFile:getValue(configKey .. "#rotationSpeed", 5) / 1000

        local rotVariation = spec.randomHeadOffsetRange * 0.5
        spec.headRotationRandom = math.random(-1, 1) * rotVariation -- default random -7.5 - 7.5 degrees offset

        spec.currentRotation = spec.headRotationRandom
        spec.targetRotation = spec.headRotationRandom
    end

    spec.incomePerHour = xmlFile:getValue(configKey .. "#incomePerHour", 0)
    spec.hasSolarPanels = hasSolarPanels

    if not hasSolarPanels then
        SpecializationUtil.removeEventListener(self, "onFinalizePlacement", PlaceableSolarPanels)
        SpecializationUtil.removeEventListener(self, "onReadStream", Cover)
        SpecializationUtil.removeEventListener(self, "onWriteStream", Cover)
        SpecializationUtil.removeEventListener(self, "onUpdate", Cover)
        SpecializationUtil.removeEventListener(self, "onHourChanged", Cover)
    end
end


---
function PlaceableSolarPanels:onFinalizePlacement()
    self:updateHeadRotation()
end


---
function PlaceableSolarPanels:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_solarPanels
    local headRotationRandom = xmlFile:getValue(key.."#headRotationRandom")
    if headRotationRandom == nil then
        spec.headRotationRandom = headRotationRandom
    end
end


---
function PlaceableSolarPanels:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_solarPanels
    if spec.headNode ~= nil then
        xmlFile:setValue(key .. "#headRotationRandom", spec.headRotationRandom)
    end
end


---
function PlaceableSolarPanels:onReadStream(streamId, connection)
    local spec = self.spec_solarPanels
    if spec.headNode ~= nil then
        spec.headRotationRandom = NetworkUtil.readCompressedAngle(streamId)
    end
end


---
function PlaceableSolarPanels:onWriteStream(streamId, connection)
    local spec = self.spec_solarPanels
    if spec.headNode ~= nil then
        NetworkUtil.writeCompressedAngle(streamId, spec.headRotationRandom)
    end
end


---
function PlaceableSolarPanels:onUpdate(dt)
    local spec = self.spec_solarPanels
    if spec.targetRotation ~= spec.currentRotation then
        local limitFunc = math.min
        local direction = 1
        if spec.targetRotation < spec.currentRotation then
            limitFunc = math.max
            direction = -1
        end

        spec.currentRotation = limitFunc(spec.currentRotation + spec.rotationSpeed * dt * direction, spec.targetRotation)
        local dx,_,dz = worldDirectionToLocal(getParent(spec.headNode), math.sin(spec.currentRotation), 0, math.cos(spec.currentRotation))
        setDirection(spec.headNode, dx, 0, dz, 0, 1, 0)

        if spec.targetRotation ~= spec.currentRotation then
            self:raiseActive()
        end
    end
end


---
function PlaceableSolarPanels:onHourChanged()
    self:updateHeadRotation()
end


---
function PlaceableSolarPanels:updateHeadRotation()
    local spec = self.spec_solarPanels
    if spec.headNode ~= nil and g_currentMission ~= nil and g_currentMission.environment ~= nil then

        local sunLight = g_currentMission.environment.lighting.sunLightId
        if sunLight ~= nil then
            local dx, _, dz = localDirectionToWorld(sunLight, 0, 0, 1)
            local headRotation = math.atan2(dx, dz)
            if math.abs(dx) > 0.3 then
                headRotation = headRotation + spec.headRotationRandom

                spec.targetRotation = headRotation
                self:raiseActive()
            end
        end
    end
end


---
function PlaceableSolarPanels:getIncomePerHour(superFunc)
    local spec = self.spec_solarPanels

    local incomePerHour = superFunc(self)

    if spec.hasSolarPanels then
        local factor = 0
        local environment = g_currentMission.environment
        if environment.isSunOn then
            factor = 1
        end

        if environment.currentSeason == Season.WINTER then
            factor = factor * 0.75
        end

        if environment.weather:getIsRaining() then
            factor = factor * 0.1
        end

        incomePerHour = incomePerHour + spec.incomePerHour * factor
    end

    return incomePerHour
end


---
function PlaceableSolarPanels:getNeedHourChanged(superFunc)
    return self.spec_solarPanels.hasSolarPanels
end
