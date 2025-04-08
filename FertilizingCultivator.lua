













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function FertilizingCultivator.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Cultivator, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations)
end


---
function FertilizingCultivator.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FertilizingCultivator")

    schema:register(XMLValueType.BOOL, "vehicle.fertilizingCultivator#needsSetIsTurnedOn", "Needs to be turned on to spray", false)

    schema:setXMLSpecializationType()
end


---
function FertilizingCultivator.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea",                    FertilizingCultivator.processCultivatorArea)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", FertilizingCultivator.setSprayerAITerrainDetailProhibitedRange)
end


---
function FertilizingCultivator.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingCultivator)
end


---
function FertilizingCultivator:onLoad(savegame)
    local spec = self.spec_fertilizingCultivator
    spec.needsSetIsTurnedOn = self.xmlFile:getValue("vehicle.fertilizingCultivator#needsSetIsTurnedOn", false)
    self.spec_sprayer.useSpeedLimit = false

    self:clearAITerrainDetailRequiredRange()
    self:updateCultivatorAIRequirements()
end


---
function FertilizingCultivator:processCultivatorArea(superFunc, workArea, dt)
    local spec = self.spec_fertilizingCultivator
    local specCultivator = self.spec_cultivator
    local specSpray = self.spec_sprayer

    local xs,_,zs = getWorldTranslation(workArea.start)
    local xw,_,zw = getWorldTranslation(workArea.width)
    local xh,_,zh = getWorldTranslation(workArea.height)

    local cultivatorParams = specCultivator.workAreaParameters
    local sprayerParams = specSpray.workAreaParameters

    -- stop the sowing machine if the fertilizer tank was filled and got empty
    -- do not stop if the tank was all the time empty
    if (specSpray.isSlurryTanker and g_currentMission.missionInfo.helperSlurrySource == 1)
    or (specSpray.isManureSpreader and g_currentMission.missionInfo.helperManureSource == 1)
    or (specSpray.isFertilizerSprayer and not g_currentMission.missionInfo.helperBuyFertilizer) then
        if self:getIsAIActive() then
            if sprayerParams.sprayFillType == nil or sprayerParams.sprayFillType == FillType.UNKNOWN then
                if sprayerParams.lastAIHasSprayed ~= nil then
                    local rootVehicle = self.rootVehicle
                    rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
                    sprayerParams.lastAIHasSprayed = nil
                end
            else
                sprayerParams.lastAIHasSprayed = true
            end
        end
    end

    -- we need to use fertilizer as spraying type because fertilizer is the final blocking value
    local sprayTypeIndex = SprayType.FERTILIZER

    if sprayerParams.sprayFillLevel <= 0 or (spec.needsSetIsTurnedOn and not self:getIsTurnedOn()) then
        sprayTypeIndex = nil
    end

    local cultivatorChangedArea, cultivatorTotalArea = 0, 0
    if specCultivator.isEnabled then
        if specCultivator.useDeepMode then
            cultivatorChangedArea, cultivatorTotalArea = FSDensityMapUtil.updateCultivatorArea(xs, zs, xw, zw, xh, zh, not cultivatorParams.limitToField, cultivatorParams.limitFruitDestructionToField, cultivatorParams.angle, sprayTypeIndex)
            cultivatorChangedArea = cultivatorChangedArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
        else
            cultivatorChangedArea, cultivatorTotalArea = FSDensityMapUtil.updateDiscHarrowArea(xs, zs, xw, zw, xh, zh, not cultivatorParams.limitToField, cultivatorParams.limitFruitDestructionToField, cultivatorParams.angle, sprayTypeIndex)
            cultivatorChangedArea = cultivatorChangedArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
        end

        cultivatorParams.lastChangedArea = cultivatorParams.lastChangedArea + cultivatorChangedArea
        cultivatorParams.lastTotalArea = cultivatorParams.lastTotalArea + cultivatorTotalArea
        cultivatorParams.lastStatsArea = cultivatorParams.lastStatsArea + cultivatorChangedArea
    end

    if specCultivator.isSubsoiler then
        FSDensityMapUtil.updateSubsoilerArea(xs, zs, xw, zw, xh, zh)
    end

    FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

    if sprayTypeIndex ~= nil then
        local sprayAmount = specSpray.doubledAmountIsActive and 2 or 1
        local sprayChangedArea, sprayTotalArea = FSDensityMapUtil.updateSprayArea(xs, zs, xw, zw, xh, zh, sprayTypeIndex, sprayAmount)

        sprayerParams.lastChangedArea = sprayerParams.lastChangedArea + sprayChangedArea
        sprayerParams.lastTotalArea = sprayerParams.lastTotalArea + sprayTotalArea
        sprayerParams.lastStatsArea = 0
        sprayerParams.isActive = true
    end

    specCultivator.isWorking = self:getLastSpeed() > 0.5

    return cultivatorChangedArea, cultivatorTotalArea
end


---
function FertilizingCultivator:setSprayerAITerrainDetailProhibitedRange(superFunc, fillType)
    if self.addAITerrainDetailProhibitedRange ~= nil then
        self:clearAITerrainDetailProhibitedRange()

        local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
        if sprayTypeDesc ~= nil then
            local mission = g_currentMission
            local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
            local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
            local sprayLevelMaxValue = mission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
            self:addAIFruitProhibitions(0, sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
            self:addAIFruitProhibitions(0, sprayLevelMaxValue, sprayLevelMaxValue, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
        end
    end
end
