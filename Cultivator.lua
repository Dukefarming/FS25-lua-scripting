














































---Called on specialization initializing
function Cultivator.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("cultivator", true, true, true)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Cultivator")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.cultivator.directionNode#node", "Direction node")
    schema:register(XMLValueType.BOOL, "vehicle.cultivator.onlyActiveWhenLowered#value", "Only active when lowered", true)
    schema:register(XMLValueType.BOOL, "vehicle.cultivator#isSubsoiler", "Is subsoiler", false)
    schema:register(XMLValueType.BOOL, "vehicle.cultivator#useDeepMode", "If true the implement acts like a cultivator. If false it's a discharrow or seedbed combination", true)
    schema:register(XMLValueType.BOOL, "vehicle.cultivator#isPowerHarrow", "If this is set the cultivator works standalone like a cultivator, but as soon as a sowing machine is attached to it, it's only using the sowing machine", false)

    SoundManager.registerSampleXMLPaths(schema, "vehicle.cultivator.sounds", "work(?)")

    schema:addDelayedRegistrationFunc("WorkMode:workMode", function(cSchema, cKey)
        cSchema:register(XMLValueType.BOOL, cKey .. "#useDeepMode", "If true the implement acts like a cultivator. If false it's a discharrow or seedbed combination")
    end)

    schema:setXMLSpecializationType()
end


---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function Cultivator.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end


---
function Cultivator.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processCultivatorArea", Cultivator.processCultivatorArea)
    SpecializationUtil.registerFunction(vehicleType, "processVineCultivatorArea", Cultivator.processVineCultivatorArea)
    SpecializationUtil.registerFunction(vehicleType, "getCultivatorLimitToField", Cultivator.getCultivatorLimitToField)
    SpecializationUtil.registerFunction(vehicleType, "getUseCultivatorAIRequirements", Cultivator.getUseCultivatorAIRequirements)
    SpecializationUtil.registerFunction(vehicleType, "updateCultivatorAIRequirements", Cultivator.updateCultivatorAIRequirements)
    SpecializationUtil.registerFunction(vehicleType, "updateCultivatorEnabledState", Cultivator.updateCultivatorEnabledState)
    SpecializationUtil.registerFunction(vehicleType, "getIsCultivationEnabled", Cultivator.getIsCultivationEnabled)
end


---
function Cultivator.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cultivator.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cultivator.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cultivator.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cultivator.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cultivator.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkModeFromXML", Cultivator.loadWorkModeFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", Cultivator.getAIImplementUseVineSegment)
end


---
function Cultivator.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cultivator)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cultivator)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cultivator)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cultivator)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cultivator)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cultivator)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Cultivator)
    SpecializationUtil.registerEventListener(vehicleType, "onWorkModeChanged", Cultivator)
end


---Called on loading
-- @param table savegame savegame
function Cultivator:onLoad(savegame)

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cultivator.directionNode#index", "vehicle.cultivator.directionNode#node") --FS17 to FS19

    if self:getGroundReferenceNodeFromIndex(1) == nil then
        printWarning("Warning: No ground reference nodes in  "..self.configFileName)
    end

    local spec = self.spec_cultivator

    if self.isClient then
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.cultivator.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.isWorkSamplePlaying = false
    end

    spec.directionNode = self.xmlFile:getValue("vehicle.cultivator.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
    spec.onlyActiveWhenLowered = self.xmlFile:getValue("vehicle.cultivator.onlyActiveWhenLowered#value", true)
    spec.isSubsoiler = self.xmlFile:getValue("vehicle.cultivator#isSubsoiler", false)
    spec.isPowerHarrow = self.xmlFile:getValue("vehicle.cultivator#isPowerHarrow", false)
    spec.useDeepMode = self.xmlFile:getValue("vehicle.cultivator#useDeepMode", true)

    self:updateCultivatorAIRequirements()

    spec.isEnabled = true
    spec.startActivationTimeout = 2000
    spec.startActivationTime = 0
    spec.hasGroundContact = false
    spec.isWorking = false
    spec.limitToField = true

    spec.workAreaParameters = {}
    spec.workAreaParameters.limitToField = self:getCultivatorLimitToField()
    spec.workAreaParameters.angle = 0
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    spec.workAreaParameters.lastTotalArea = 0
end


---Called on deleting
function Cultivator:onDelete()
    local spec = self.spec_cultivator
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples.work)
    end
end


---
function Cultivator:processCultivatorArea(workArea, dt)
    local spec = self.spec_cultivator

    local realArea, area = 0, 0
    local xs,_,zs = getWorldTranslation(workArea.start)
    local xw,_,zw = getWorldTranslation(workArea.width)
    local xh,_,zh = getWorldTranslation(workArea.height)

    if spec.isEnabled then
        local params = spec.workAreaParameters

        if spec.useDeepMode then
            realArea, area = FSDensityMapUtil.updateCultivatorArea(xs,zs, xw,zw, xh,zh, not params.limitToField, params.limitFruitDestructionToField, params.angle, nil)
            realArea = realArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh, true)
        else
            realArea, area = FSDensityMapUtil.updateDiscHarrowArea(xs,zs, xw,zw, xh,zh, not params.limitToField, params.limitFruitDestructionToField, params.angle, nil)
            realArea = realArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh, true)
        end

        params.lastChangedArea = params.lastChangedArea + realArea
        params.lastStatsArea = params.lastStatsArea + realArea
        params.lastTotalArea = params.lastTotalArea + area
    end

    if spec.isSubsoiler then
        FSDensityMapUtil.updateSubsoilerArea(xs, zs, xw, zw, xh, zh)
    end

    FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

    spec.isWorking = self:getLastSpeed() > 0.5

    return realArea, area
end


---
function Cultivator:processVineCultivatorArea(workArea, dt)
    local spec = self.spec_cultivator

    if spec.isEnabled then
        local xs, _, zs = getWorldTranslation(workArea.start)
        local xw, _, zw = getWorldTranslation(workArea.width)
        local xh, _, zh = getWorldTranslation(workArea.height)

        FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh, false)
    end

    return 0, 0
end


---Returns if cultivator is limited to the field
-- @return boolean isLimited is limited to field
function Cultivator:getCultivatorLimitToField()
    return self.spec_cultivator.limitToField
end


---Returns if cultivator ai requirements should be used
-- @return boolean useAIRequirements use ai requirements
function Cultivator:getUseCultivatorAIRequirements()
    return true
end


---Update cultivator ai requirements and optional exclude the given ground type
function Cultivator:updateCultivatorAIRequirements()
    if self:getUseCultivatorAIRequirements() then
        if self.addAITerrainDetailRequiredRange ~= nil then
            local hasSowingMachine = false
            local excludedType1, excludedType2

            -- for the sowing machine check we only check if the sowing machine is directly attached to the cultivator,
            -- otherwise we allow the combination as 'direct seeding'
            local vehicles = self:getChildVehicles()
            for i=1, #vehicles do
                if SpecializationUtil.hasSpecialization(SowingMachine, vehicles[i].specializations) then
                    if vehicles[i]:getAIRequiresTurnOn() or vehicles[i]:getUseSowingMachineAIRequirements() then
                        hasSowingMachine = true
                    end
                end
            end

            local vehicles = self.rootVehicle:getChildVehicles()
            for i=1, #vehicles do
                if SpecializationUtil.hasSpecialization(Roller, vehicles[i].specializations) then
                    excludedType1 = FieldGroundType.ROLLER_LINES
                    excludedType2 = FieldGroundType.ROLLED_SEEDBED
                end
            end

            -- if we also have a active sowing machine attached the sowingMachine is fully handling it
            if not hasSowingMachine then
                if self.spec_cultivator.useDeepMode then
                    self:addAIGroundTypeRequirements(Cultivator.AI_REQUIRED_GROUND_TYPES_DEEP, excludedType1, excludedType2)
                else
                    self:addAIGroundTypeRequirements(Cultivator.AI_REQUIRED_GROUND_TYPES_FLAT, excludedType1, excludedType2)
                end
            else
                self:clearAITerrainDetailRequiredRange()
            end
        end
    end
end










































---Returns if speed limit should be checked
-- @return boolean checkSpeedlimit check speed limit
function Cultivator:doCheckSpeedLimit(superFunc)
    return superFunc(self) or self:getIsImplementChainLowered()
end


---Returns current dirt multiplier
-- @return float dirtMultiplier current dirt multiplier
function Cultivator:getDirtMultiplier(superFunc)
    local spec = self.spec_cultivator

    local multiplier = superFunc(self)
    if spec.isWorking then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / spec.speedLimit
    end

    return multiplier
end


---Returns current wear multiplier
-- @return float dirtMultiplier current wear multiplier
function Cultivator:getWearMultiplier(superFunc)
    local spec = self.spec_cultivator
    local multiplier = superFunc(self)

    if spec.isWorking then
        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / spec.speedLimit
    end

    return multiplier
end


---Loads work areas from xml
-- @param table workArea workArea
-- @param integer xmlFile id of xml object
-- @param string key key
-- @return boolean success success
function Cultivator:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local retValue = superFunc(self, workArea, xmlFile, key)

    if workArea.type == WorkAreaType.DEFAULT then
        workArea.type = WorkAreaType.CULTIVATOR
    end

    return retValue
end


---
function Cultivator:getIsWorkAreaActive(superFunc, workArea)
    if workArea.type == WorkAreaType.CULTIVATOR then
        local spec = self.spec_cultivator

        if spec.startActivationTime > g_currentMission.time then
            return false
        end

        if spec.onlyActiveWhenLowered and self.getIsLowered ~= nil then
            if not self:getIsLowered(false) then
                return false
            end
        end
    end

    return superFunc(self, workArea)
end


---
function Cultivator:loadWorkModeFromXML(superFunc, xmlFile, key, workMode)
    if not superFunc(self, xmlFile, key, workMode) then
        return false
    end

    workMode.useDeepMode = xmlFile:getValue(key .. "#useDeepMode")

    return true
end


---
function Cultivator:getAIImplementUseVineSegment(superFunc, placeable, segment, segmentSide)
    local startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = placeable:getSegmentSideArea(segment, segmentSide)

    local area, areaTotal = AIVehicleUtil.getAIAreaOfVehicle(self, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    if areaTotal > 0 then
        return (area / areaTotal) > 0.01
    end

    return false
end


---Called if vehicle gets attached
-- @param table attacherVehicle attacher vehicle
-- @param integer inputJointDescIndex index of input attacher joint
-- @param integer jointDescIndex index of attacher joint it gets attached to
function Cultivator:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
    local spec = self.spec_cultivator
    spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
end


---
function Cultivator:onDeactivate()
    if self.isClient then
        local spec = self.spec_cultivator
        g_soundManager:stopSamples(spec.samples.work)
        spec.isWorkSamplePlaying = false
    end
end


---
function Cultivator:onStartWorkAreaProcessing(dt)
    local spec = self.spec_cultivator

    spec.isWorking = false

    local limitToField = self:getCultivatorLimitToField()
    local limitFruitDestructionToField = limitToField
    if not g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection()) then
        limitToField = true
        limitFruitDestructionToField = true
    end

    local dx,_,dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
    local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())

    spec.workAreaParameters.limitToField = limitToField
    spec.workAreaParameters.limitFruitDestructionToField = limitFruitDestructionToField
    spec.workAreaParameters.angle = angle
    spec.workAreaParameters.lastChangedArea = 0
    spec.workAreaParameters.lastStatsArea = 0
    spec.workAreaParameters.lastTotalArea = 0
end


---
function Cultivator:onEndWorkAreaProcessing(dt)
    local spec = self.spec_cultivator

    if self.isServer then
        local farmId = self:getLastTouchedFarmlandFarmId()
        local lastStatsArea = spec.workAreaParameters.lastStatsArea

        if lastStatsArea > 0 then
            local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm()) -- 4096px are mapped to 2048m
            g_farmManager:updateFarmStats(farmId, "cultivatedHectares", ha)
            self:updateLastWorkedArea(lastStatsArea)
        end

        if spec.isWorking then
            g_farmManager:updateFarmStats(farmId, "cultivatedTime", dt/(1000*60))
        end
    end

    if self.isClient then
        if spec.isWorking then
            if not spec.isWorkSamplePlaying then
                g_soundManager:playSamples(spec.samples.work)
                spec.isWorkSamplePlaying = true
            end
        else
            if spec.isWorkSamplePlaying then
                g_soundManager:stopSamples(spec.samples.work)
                spec.isWorkSamplePlaying = false
            end
        end
    end
end


---
function Cultivator:onStateChange(state, data)
    if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH or state == VehicleStateChange.AI_START_LINE then
        self:updateCultivatorAIRequirements()
        self:updateCultivatorEnabledState()
    end

    -- turn on attached sowing machines while we turn on the power harrow and vice versa
    if self.isServer then
        if state == VehicleStateChange.TURN_ON or state == VehicleStateChange.TURN_OFF then
            local spec = self.spec_cultivator
            if spec.isPowerHarrow then
                if data == self and self.getAttachedImplements ~= nil then
                    for _, implement in pairs(self:getAttachedImplements()) do
                        local vehicle = implement.object
                        if vehicle ~= nil then
                            if state == VehicleStateChange.TURN_ON then
                                vehicle:setIsTurnedOn(true)
                            else
                                if vehicle:getIsTurnedOn() then
                                    vehicle:setIsTurnedOn(false)
                                end
                            end
                        end
                    end
                elseif data.getAttacherVehicle ~= nil then
                    local attacherVehicle = data:getAttacherVehicle()
                    if attacherVehicle ~= nil then
                        if attacherVehicle == self then
                            if state == VehicleStateChange.TURN_ON then
                                self:setIsTurnedOn(true)
                            else
                                if self:getIsTurnedOn() then
                                    self:setIsTurnedOn(false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end


---
function Cultivator:onWorkModeChanged(workMode, oldWorkMode)
    if workMode.useDeepMode ~= nil then
        self.spec_cultivator.useDeepMode = workMode.useDeepMode
        self:updateCultivatorAIRequirements()
    end
end


---Returns default speed limit
-- @return float speedLimit speed limit
function Cultivator.getDefaultSpeedLimit()
    return 15
end
