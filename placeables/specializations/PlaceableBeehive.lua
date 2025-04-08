














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableBeehive.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableBeehive.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getBeehiveInfluenceFactor", PlaceableBeehive.getBeehiveInfluenceFactor)
    SpecializationUtil.registerFunction(placeableType, "updateBeehiveState", PlaceableBeehive.updateBeehiveState)
    SpecializationUtil.registerFunction(placeableType, "getHoneyAmountToSpawn", PlaceableBeehive.getHoneyAmountToSpawn)
end


---
function PlaceableBeehive.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableBeehive.updateInfo)
end


---
function PlaceableBeehive.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBeehive)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBeehive)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBeehive)
    SpecializationUtil.registerEventListener(placeableType, "onBuy", PlaceableBeehive)
end


---
function PlaceableBeehive.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Beehive")

    schema:register(XMLValueType.FLOAT, basePath .. ".beehive#actionRadius", "Bees action radius")
    schema:register(XMLValueType.FLOAT, basePath .. ".beehive#litersHoneyPerDay", "Beehive honey production per active day")

    EffectManager.registerEffectXMLPaths(schema, basePath .. ".beehive.effects")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".beehive.sounds", "idle")
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableBeehive:onLoad(savegame)
    local spec = self.spec_beehive
    local xmlFile = self.xmlFile

    spec.environment = g_currentMission.environment

    spec.isFxActive = false
    spec.isProductionActive = false
    spec.actionRadius = xmlFile:getFloat("placeable.beehive#actionRadius", 25)
    spec.honeyPerHour = xmlFile:getFloat("placeable.beehive#litersHoneyPerDay", 10) / 24

    -- info hud
    spec.infoTableRange = {title=g_i18n:getText("infohud_range"), text=g_i18n:formatNumber(spec.actionRadius, 0) .. "m"}
    spec.infoTableNoSpawnerA = {title=g_i18n:getText("infohud_beehive_noPalletLocationA"), accentuate=true}
    spec.infoTableNoSpawnerB = {title=g_i18n:getText("infohud_beehive_noPalletLocationB"), accentuate=true}
    spec.honeyAtPalletLocation = {title="", text=g_i18n:getText("infohud_beehive_honeyAtPalletLocation")}

    -- store this information on load for more performant access during runtime
    spec.actionRadiusSquared = spec.actionRadius^2
    local wx, _, wz = getWorldTranslation(self.rootNode)
    spec.wx, spec.wz = wx, wz

    if self.isClient then
        spec.effects = g_effectManager:loadEffect(xmlFile, "placeable.beehive.effects", self.components, self, self.i3dMappings)
        g_effectManager:setEffectTypeInfo(spec.effects, FillType.UNKNOWN)

        spec.samples = {}
        spec.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, "placeable.beehive.sounds", "idle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
    end

    spec.lastDayTimeHoneySpawned = -1
end


---
function PlaceableBeehive:onDelete()
    local spec = self.spec_beehive
    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSamples(spec.samples)

    g_currentMission.beehiveSystem:removeBeehive(self)
end


---
function PlaceableBeehive:onFinalizePlacement()
    local spec = self.spec_beehive

    spec.lastDayTimeHoneySpawned = spec.environment.dayTime
    g_currentMission.beehiveSystem:addBeehive(self)

    self:updateBeehiveState()
end


---Returns factor (0..1) on the impact of the beehive for given world location wx wz
-- factor is linear based on beehive action radius
function PlaceableBeehive:getBeehiveInfluenceFactor(wx, wz)
    local spec = self.spec_beehive

    local distanceToPointSquared = MathUtil.getPointPointDistanceSquared(spec.wx, spec.wz, wx, wz)
    if distanceToPointSquared <= spec.actionRadiusSquared then
        return 1 - (distanceToPointSquared * 0.85 / spec.actionRadiusSquared)  -- reduce actual distance to increase returned factor
    end

    return 0
end


---
function PlaceableBeehive:updateBeehiveState()
    local spec = self.spec_beehive
    local beehiveSystem = g_currentMission.beehiveSystem
    spec.isProductionActive = beehiveSystem.isProductionActive

    if spec.isFxActive ~= beehiveSystem.isFxActive then
        spec.isFxActive = beehiveSystem.isFxActive

        if self.isClient then
            if beehiveSystem.isFxActive then
                g_effectManager:startEffects(spec.effects)
                g_soundManager:playSample(spec.samples.idle, 0)
            else
                g_effectManager:stopEffects(spec.effects)
                g_soundManager:stopSample(spec.samples.idle)
            end
        end
    end
end


---
function PlaceableBeehive:getHoneyAmountToSpawn()
    local spec = self.spec_beehive
    if spec.isProductionActive then
        local hours = math.min(math.abs(((spec.environment.dayTime - spec.lastDayTimeHoneySpawned) / 1000 / 60 / 60)), 1)  -- max should be one hour since since it called at least each hour
        local amount = spec.honeyPerHour * hours * g_currentMission.environment.timeAdjustment
        spec.lastDayTimeHoneySpawned = spec.environment.dayTime
        return amount
    end
    return 0
end


---
function PlaceableBeehive:updateInfo(superFunc, infoTable)
    local spec = self.spec_beehive
    table.insert(infoTable, spec.infoTableRange)

    local owner = self:getOwnerFarmId()
    if owner == g_currentMission:getFarmId() then
        local spawner = g_currentMission.beehiveSystem:getFarmBeehivePalletSpawner(owner)
        if spawner == nil then
            table.insert(infoTable, spec.infoTableNoSpawnerA)
            table.insert(infoTable, spec.infoTableNoSpawnerB)
        else
            table.insert(infoTable, spec.honeyAtPalletLocation)
            --TODO: spawner is full warning
        end
    end
end


---
function PlaceableBeehive:onBuy()
    local serverFarmId = g_currentMission:getFarmId()
    local numBeehives = 0
    for _, existingPlaceable in ipairs(g_currentMission.placeableSystem.placeables) do
        if existingPlaceable:getOwnerFarmId() == serverFarmId then
            if existingPlaceable.spec_beehive ~= nil then
                numBeehives = numBeehives + 1
            end
        end
    end
    g_achievementManager:tryUnlock("NumBeehives", numBeehives)
end
