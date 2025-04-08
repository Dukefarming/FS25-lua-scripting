



















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function RidgeFormer.prerequisitesPresent(specializations)
    return true
end


---
function RidgeFormer.initSpecialization()
    g_workAreaTypeManager:addWorkAreaType("ridgeFormer", true, true, true)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("RidgeFormer")

    SoundManager.registerSampleXMLPaths(schema, "vehicle.ridgeFormer.sounds", "work")

    schema:setXMLSpecializationType()
end


---
function RidgeFormer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "processRidgeFormerArea", RidgeFormer.processRidgeFormerArea)
end


---
function RidgeFormer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", RidgeFormer.doCheckSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", RidgeFormer.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", RidgeFormer.getWearMultiplier)
end


---
function RidgeFormer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", RidgeFormer)
    SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", RidgeFormer)
end


---
function RidgeFormer:onLoad(savegame)
    local spec = self.spec_ridgeFormer

    spec.stoneLastState = 0
    spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("SOWINGMACHINE")

    if self.addAIGroundTypeRequirements ~= nil then
        self:addAIGroundTypeRequirements(RidgeFormer.AI_REQUIRED_GROUND_TYPES)
    end

    if self.isClient then
        spec.samples = {}
        spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ridgeFormer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.isWorkSamplePlaying = false
    end
end


---Called on deleting
function RidgeFormer:onDelete()
    local spec = self.spec_ridgeFormer
    g_soundManager:deleteSamples(spec.samples)
end


---
function RidgeFormer:onDeactivate()
    if self.isClient then
        local spec = self.spec_ridgeFormer
        g_soundManager:stopSamples(spec.samples)
        spec.isWorkSamplePlaying = false
    end
end


---
function RidgeFormer:onStartWorkAreaProcessing(dt)
    local spec = self.spec_ridgeFormer
    spec.isWorking = false
end


---
function RidgeFormer:onEndWorkAreaProcessing(dt)
    local spec = self.spec_ridgeFormer

    if self.isClient then
        if spec.isWorking then
            if not spec.isWorkSamplePlaying then
                g_soundManager:playSample(spec.samples.work)
                spec.isWorkSamplePlaying = true
            end
        else
            if spec.isWorkSamplePlaying then
                g_soundManager:stopSample(spec.samples.work)
                spec.isWorkSamplePlaying = false
            end
        end
    end
end


---
function RidgeFormer:processRidgeFormerArea(workArea, dt)
    local spec = self.spec_ridgeFormer

    local changedArea, totalArea = 0, 0
    spec.isWorking = self:getLastSpeed() > 0.5
    if not spec.isWorking then
        spec.stoneLastState = 0

        return changedArea, totalArea
    end

    local sx, _, sz = getWorldTranslation(workArea.start)
    local wx, _, wz = getWorldTranslation(workArea.width)
    local hx, _, hz = getWorldTranslation(workArea.height)

    local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
    local angleRad = MathUtil.getYRotationFromDirection(dx, dz)
    local snapAngle = math.pi * 0.5 -- 90 deg
    angleRad = math.floor(angleRad / snapAngle + 0.5) * snapAngle
    local angle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())

    changedArea, totalArea = FSDensityMapUtil.updateRidgeFormerArea(sx, sz, wx, wz, hx, hz, angle)

    spec.stoneLastState = FSDensityMapUtil.getStoneArea(sx, sz, wx, wz, hx, hz)

    -- remove tireTracks
    FSDensityMapUtil.eraseTireTrack(sx, sz, wx, wz, hx, hz)

    return changedArea, totalArea
end


---
function RidgeFormer:doCheckSpeedLimit(superFunc)
    local spec = self.spec_ridgeFormer
    return superFunc(self) or (self:getIsImplementChainLowered() and spec.isWorking)
end


---
function RidgeFormer:getDirtMultiplier(superFunc)
    local spec = self.spec_ridgeFormer
    local multiplier = superFunc(self)

    if self.movingDirection > 0 and spec.isWorking then
        multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
    end

    return multiplier
end


---Returns current wear multiplier
-- @return float dirtMultiplier current wear multiplier
function RidgeFormer:getWearMultiplier(superFunc)
    local spec = self.spec_ridgeFormer
    local multiplier = superFunc(self)

    if self.movingDirection > 0 and spec.isWorking then
        local stoneMultiplier = 1
        if spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil then
            stoneMultiplier = spec.stoneWearMultiplierData[spec.stoneLastState] or 1
        end

        multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * stoneMultiplier
    end

    return multiplier
end
