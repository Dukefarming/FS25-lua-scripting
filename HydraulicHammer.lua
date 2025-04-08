














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function HydraulicHammer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end


---
function HydraulicHammer.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HydraulicHammer")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.hydraulicHammer.workNode#node", "Cut node where raycast is fired from on -y axis")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.hydraulicHammer.workNode#hitAlignedNode", "Node will be moved and aligned to hit position and normal of worknode raycast")
    schema:register(XMLValueType.FLOAT, "vehicle.hydraulicHammer.workNode#destructionAmountPerHit", "Damage done to object per hit", 5)
    schema:register(XMLValueType.TIME, "vehicle.hydraulicHammer.workNode#hitIntervalMin", "Minimum time between cuts in seconds", 0.15)
    schema:register(XMLValueType.TIME, "vehicle.hydraulicHammer.workNode#hitIntervalMax", "Maximum time between cuts in seconds", 0.25)
    schema:register(XMLValueType.FLOAT, "vehicle.hydraulicHammer.workNode#raycastDistance", "Raycast distance in meters", 0.3)
    schema:register(XMLValueType.STRING, "vehicle.hydraulicHammer.workNode#supportedTypes", "Supported destructible types")

    EffectManager.registerEffectXMLPaths(schema, "vehicle.hydraulicHammer.workNode.effects")

    SoundManager.registerSampleXMLPaths(schema, "vehicle.hydraulicHammer.sounds", "start")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.hydraulicHammer.sounds", "stop")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.hydraulicHammer.sounds", "idle")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.hydraulicHammer.sounds", "work")
    schema:register(XMLValueType.FLOAT, "vehicle.hydraulicHammer.sounds.work.progressPitch#factor", "Factor applied to sample pitch depending on destruction progress (0-1)")

    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.hydraulicHammer.animationNodes")

    schema:register(XMLValueType.STRING, "vehicle.hydraulicHammer.hitAnimation#name", "name of hit animation")

    schema:setXMLSpecializationType()
end


---
function HydraulicHammer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "hydraulicHammerRaycastCallback", HydraulicHammer.hydraulicHammerRaycastCallback)
end


---
function HydraulicHammer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", HydraulicHammer.getDirtMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", HydraulicHammer.getWearMultiplier)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", HydraulicHammer.getConsumingLoad)
end


---
function HydraulicHammer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HydraulicHammer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", HydraulicHammer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HydraulicHammer)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", HydraulicHammer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", HydraulicHammer)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", HydraulicHammer)
end


---Called on loading
-- @param table savegame savegame
function HydraulicHammer:onLoad(savegame)
    local spec = self.spec_hydraulicHammer

    local node = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(self.xmlFile, "Missing 'node' for 'vehicle.hydraulicHammer.workNode'!")
    end

    local workNode = {}
    workNode.node = node
    workNode.destructionAmount = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#destructionAmountPerHit", 1)
    workNode.hitIntervalMin = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#hitIntervalMin", 0.15)
    workNode.hitIntervalMax = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#hitIntervalMax", 0.25)
    workNode.raycastDistance = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#raycastDistance", 0.4)
    workNode.hitAlignedNode = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#hitAlignedNode", nil, self.components, self.i3dMappings)
    if workNode.hitAlignedNode ~= nil then
        workNode.hitAlignedNodeParent = getParent(workNode.hitAlignedNode)
    end
    workNode.lastWorkTime = -1000
    workNode.nextHitTime = 0
    spec.workNode = workNode

    local supportedDestructibleTypes = self.xmlFile:getValue("vehicle.hydraulicHammer.workNode#supportedTypes")
    if supportedDestructibleTypes ~= nil then
        spec.supportedDestructibleTypes = table.toSet(string.split(supportedDestructibleTypes, " "))
    end

    spec.raycastCollisionMask = CollisionFlag.STATIC_OBJECT
    spec.lastProgress = 0

    if self.isClient then
        workNode.effects = g_effectManager:loadEffect(self.xmlFile,"vehicle.hydraulicHammer.workNode.effects", self.components, self, self.i3dMappings)
        g_effectManager:setEffectTypeInfo(workNode.effects, FillType.STONE)

        spec.samples = {}
        spec.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop  = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "stop",  self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.idle  = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "idle",  self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.work  = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.hydraulicHammer.sounds", "work",  self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        if spec.samples.work ~= nil then
            spec.samples.work.progressPitchFactor = self.xmlFile:getValue("vehicle.hydraulicHammer.sounds.work.progressPitch#factor", 0)
        end

        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile,"vehicle.hydraulicHammer.animationNodes", self.components, self, self.i3dMappings)

        local hitAnimationName = self.xmlFile:getValue("vehicle.hydraulicHammer.hitAnimation#name")
        if self:getAnimationExists(hitAnimationName) then
            spec.hitAnimationName = hitAnimationName
        end
    end

    spec.warningNoAccess = g_i18n:getText("warning_youDontHaveAccessToThisLand")
    spec.warningToolNotSupportingObject = g_i18n:getText("warning_toolDoesNotSupportThisObject")
end


---Called on deleting
function HydraulicHammer:onDelete()
    local spec = self.spec_hydraulicHammer
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)

    if spec.workNode ~= nil then
        g_effectManager:deleteEffects(spec.workNode.effects)
    end
end


---Called on update
function HydraulicHammer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self:getIsTurnedOn() then
        local spec = self.spec_hydraulicHammer

        local workNode = spec.workNode
        if g_time >= workNode.nextHitTime then
            g_effectManager:stopEffects(spec.workNode.effects)

            local x,y,z = getWorldTranslation(workNode.node)
            local dx,dy,dz = localDirectionToWorld(workNode.node, 0,-1,0)

            raycastClosest(x,y,z, dx,dy,dz, workNode.raycastDistance, "hydraulicHammerRaycastCallback", self, spec.raycastCollisionMask)
        end
    end
end


---Callback function for raycast
function HydraulicHammer:hydraulicHammerRaycastCallback(actorId, x,y,z, distance, nx,ny,nz, subShapeIndex, shapeId, isLast)
    local spec = self.spec_hydraulicHammer

    local destructible, errorCode = g_currentMission.destructibleMapObjectSystem:getDestructibleFromNode(actorId, spec.supportedDestructibleTypes)
    if destructible ~= nil then
        local ownerFarmId = self:getOwnerFarmId()
        if not g_currentMission.accessHandler:canFarmAccessLand(ownerFarmId, x, z) and not g_missionManager:getIsMissionDestructible(ownerFarmId, destructible)  then
            if self:getRootVehicle() == g_localPlayer:getCurrentVehicle() then  -- only display a warning if the player is controlling the vehicle
                g_currentMission:showBlinkingWarning(spec.warningNoAccess, 1000)
            end
            return false
        end

        spec.lastProgress = g_currentMission.destructibleMapObjectSystem:addDestructibleDamage(destructible, spec.workNode.destructionAmount)

        if self.isClient then
            if spec.hitAnimationName ~= nil then
                self:playAnimation(spec.hitAnimationName, 1, 0, true)
            end

            -- shift pitch based on destruction progress
            if spec.samples.work ~= nil then
                g_soundManager:setSamplePitchOffset(spec.samples.work, spec.samples.work.progressPitchFactor * spec.lastProgress)
                g_soundManager:playSample(spec.samples.work)
            end

            if spec.workNode.hitAlignedNode ~= nil then
                -- place node on raycast hit pos + normal
                setWorldTranslation(spec.workNode.hitAlignedNode, x,y,z)
                local dx,dy,dz = worldDirectionToLocal(spec.workNode.hitAlignedNodeParent, -nx,-ny,-nz)
                local ux,uy,uz = worldDirectionToLocal(spec.workNode.hitAlignedNodeParent, 0,1,0)
                setDirection(spec.workNode.hitAlignedNode, dx,dy,dz, ux,uy,uz)

                -- reset effect as its burst based
                g_effectManager:resetEffects(spec.workNode.effects)

                g_effectManager:startEffects(spec.workNode.effects)
            end
        end

        spec.workNode.lastWorkTime = g_time
        spec.workNode.nextHitTime = g_time + math.random(spec.workNode.hitIntervalMin, spec.workNode.hitIntervalMax)

        return false  -- stop raycast callbacks
    else  -- no valid destructible found
        if errorCode == DestructibleMapObjectSystem.ERROR_WRONG_DESTRUCTIBLE_TYPE then
            if self:getRootVehicle() == g_localPlayer:getCurrentVehicle() then  -- only display a warning if the player is controlling the vehicle
                g_currentMission:showBlinkingWarning(spec.warningToolNotSupportingObject, 1000)
            end
            return false
        end
    end
    return true
end


---Called on deactivate
function HydraulicHammer:onDeactivate()
    if self.isClient then
        local spec = self.spec_hydraulicHammer
        g_effectManager:stopEffects(spec.workNode.effects)
    end
end


---Called on turn on
function HydraulicHammer:onTurnedOn()
    if self.isClient then
        local spec = self.spec_hydraulicHammer
        g_soundManager:stopSamples(spec.samples)
        g_soundManager:playSample(spec.samples.start)
        g_soundManager:playSample(spec.samples.idle, 0, spec.samples.start)
        g_animationManager:startAnimations(spec.animationNodes)
    end
end


---Called on turn off
function HydraulicHammer:onTurnedOff()
    if self.isClient then
        local spec = self.spec_hydraulicHammer
        g_effectManager:stopEffects(spec.workNode.effects)

        g_soundManager:stopSamples(spec.samples)
        g_soundManager:playSample(spec.samples.stop)
        g_animationManager:stopAnimations(spec.animationNodes)

        if spec.hitAnimationName then
            self:stopAnimation(spec.hitAnimationName)
        end
    end
end


---Returns current dirt multiplier
-- @return float dirtMultiplier current dirt multiplier
function HydraulicHammer:getDirtMultiplier(superFunc)
    local multiplier = superFunc(self)

    local spec = self.spec_hydraulicHammer
    if spec.workNode.lastWorkTime + 500 > g_time then
        multiplier = multiplier + self:getWorkDirtMultiplier()
    end

    return multiplier
end


---Returns current wear multiplier
-- @return float wearMultiplier current wear multiplier
function HydraulicHammer:getWearMultiplier(superFunc)
    local multiplier = superFunc(self)

    local spec = self.spec_hydraulicHammer
    if spec.workNode.lastWorkTime + 500 > g_time then
        multiplier = multiplier + self:getWorkWearMultiplier()
    end

    return multiplier
end


---
function HydraulicHammer:getConsumingLoad(superFunc)
    local value, count = superFunc(self)

    local spec = self.spec_hydraulicHammer
    if spec.workNode.lastWorkTime + 500 > g_time then
        return value + 1, count+  1
    end

    return value, count
end
