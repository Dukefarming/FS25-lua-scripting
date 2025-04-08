














---
function HandToolMotorized.registerXMLPaths(xmlSchema)

    xmlSchema:setXMLSpecializationType("HandToolMotorized")

    local basePath = "handTool.motorized"
    xmlSchema:register(XMLValueType.FLOAT, basePath .. ".motor#startTime", "The amount of milliseconds it takes for the motor to start", 0, false)
    xmlSchema:register(XMLValueType.FLOAT, basePath .. ".motor#minRPM", "The RPM of the tool when it is not being used", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, basePath .. ".motor#maxRPM", "The RPM of the tool when it has no load and is being used", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, basePath .. ".motor#rpmGainSpeed", "The amount of RPM that can be gained per second", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, basePath .. ".motor#rpmLossSpeed", "The amount of RPM that can be lost per second", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, basePath .. ".motor#rpmVariability", "Variability in rpm while the tool has full load", 0)
    xmlSchema:register(XMLValueType.FLOAT, basePath .. ".motor#rpmVariabilityChange", "Variability change factor (the higher, the faster changes the random variability)", 1)
    xmlSchema:register(XMLValueType.VECTOR_3, basePath .. ".vibrations#amount", "The base vibration amount along the 3 axes of the tool", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, basePath .. ".vibrations#node", "The name of the node that is vibrated", nil, false)

    SoundManager.registerSampleXMLPaths(xmlSchema, basePath .. ".sounds", "start")
    SoundManager.registerSampleXMLPaths(xmlSchema, basePath .. ".sounds", "stop")
    SoundManager.registerSampleXMLPaths(xmlSchema, basePath .. ".sounds", "idle")

    EffectManager.registerEffectXMLPaths(xmlSchema, basePath .. ".exhaustEffects")

    xmlSchema:setXMLSpecializationType()
end


---
function HandToolMotorized.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "getTimeToReachRPM", HandToolMotorized.getTimeToReachRPM)
    SpecializationUtil.registerFunction(handToolType, "getRPMGainPerSecond", HandToolMotorized.getRPMGainPerSecond)
    SpecializationUtil.registerFunction(handToolType, "setRPMGainPerSecond", HandToolMotorized.setRPMGainPerSecond)
    SpecializationUtil.registerFunction(handToolType, "getRPMLossPerSecond", HandToolMotorized.getRPMLossPerSecond)
    SpecializationUtil.registerFunction(handToolType, "setRPMLossPerSecond", HandToolMotorized.setRPMLossPerSecond)
    SpecializationUtil.registerFunction(handToolType, "getCurrentLoad", HandToolMotorized.getCurrentLoad)
    SpecializationUtil.registerFunction(handToolType, "setCurrentLoad", HandToolMotorized.setCurrentLoad)
    SpecializationUtil.registerFunction(handToolType, "getCurrentRPM", HandToolMotorized.getCurrentRPM)
    SpecializationUtil.registerFunction(handToolType, "setCurrentRPM", HandToolMotorized.setCurrentRPM)
    SpecializationUtil.registerFunction(handToolType, "getMinRPM", HandToolMotorized.getMinRPM)
    SpecializationUtil.registerFunction(handToolType, "getTargetRPM", HandToolMotorized.getTargetRPM)
    SpecializationUtil.registerFunction(handToolType, "getMaxRPM", HandToolMotorized.getMaxRPM)
    SpecializationUtil.registerFunction(handToolType, "setTargetRPM", HandToolMotorized.setTargetRPM)
    SpecializationUtil.registerFunction(handToolType, "setTargetRPMToIdle", HandToolMotorized.setTargetRPMToIdle)
    SpecializationUtil.registerFunction(handToolType, "setTargetRPMToMax", HandToolMotorized.setTargetRPMToMax)

    SpecializationUtil.registerFunction(handToolType, "updateRPM", HandToolMotorized.updateRPM)
    SpecializationUtil.registerFunction(handToolType, "updateSounds", HandToolMotorized.updateSounds)
    SpecializationUtil.registerFunction(handToolType, "updateVibrations", HandToolMotorized.updateVibrations)
end


---
function HandToolMotorized.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolMotorized)
    SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolMotorized)
end


---
function HandToolMotorized.prerequisitesPresent(specializations)
    return true
end


---
function HandToolMotorized:onLoad(xmlFile, baseDirectory)

    local spec = self.spec_motorized

    spec.dirtyFlag = self:getNextDirtyFlag()

    spec.currentLoad = 0

    spec.startTime = xmlFile:getValue("handTool.motorized.motor#startTime", 0)
    spec.minRPM = xmlFile:getValue("handTool.motorized.motor#minRPM", 10)
    spec.maxRPM = xmlFile:getValue("handTool.motorized.motor#maxRPM", 100)

    spec.rpmGainPerSecond = xmlFile:getValue("handTool.motorized.motor#rpmGainSpeed", spec.maxRPM - spec.minRPM)
    spec.rpmLossPerSecond = xmlFile:getValue("handTool.motorized.motor#rpmLossSpeed", spec.maxRPM - spec.minRPM)

    spec.rpmVariability = xmlFile:getValue("handTool.motorized.motor#rpmVariability", 0)
    spec.rpmVariabilityChange = xmlFile:getValue("handTool.motorized.motor#rpmVariabilityChange", 1)

    spec.currentRPM = spec.minRPM
    spec.targetRPM = spec.currentRPM
    spec.vibrationNode = xmlFile:getValue("handTool.motorized.vibrations#node", nil, self.components, self.i3dMappings)

    spec.vibrationAmountX, spec.vibrationAmountY, spec.vibrationAmountZ = xmlFile:getValue("handTool.motorized.vibrations#amount", "0 0 0")

    if self.isClient then
        local baseKey = "sounds.motorized.sounds"
        spec.samples = {}
        spec.samples.start = g_soundManager:loadSampleFromXML(xmlFile, baseKey, "start", baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.idle = g_soundManager:loadSampleFromXML(xmlFile, baseKey, "idle", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop = g_soundManager:loadSampleFromXML(xmlFile, baseKey, "stop", baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)

        self.exhaustEffects = g_effectManager:loadEffect(xmlFile, "handTool.motorized.exhaustEffects", self.components, self, self.i3dMappings)
    end
end


---
function HandToolMotorized:onDelete()
    if self.isClient then
        local spec = self.spec_motorized
        g_soundManager:deleteSamples(spec.samples)
        g_effectManager:deleteEffects(spec.fillEffects)
    end
end


---
function HandToolMotorized:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_motorized
    if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
        NetworkUtil.writeCompressedPercentages(streamId, MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM), 8)
        NetworkUtil.writeCompressedPercentages(streamId, spec.currentLoad, 8)
    end
end


---
function HandToolMotorized:onReadUpdateStream(streamId, timestamp, connection)
    if streamReadBool(streamId) then
        local spec = self.spec_motorized
        local currentRPM = NetworkUtil.readCompressedPercentages(streamId, 8) * (spec.maxRPM - spec.minRPM) + spec.minRPM
        local currentLoad = NetworkUtil.readCompressedPercentages(streamId, 8)

        local carryingPlayer = self:getCarryingPlayer()
        if not connection:getIsServer() or (carryingPlayer ~= nil and not carryingPlayer.isOwner) then
            self:setCurrentRPM(currentRPM)
            self:setCurrentLoad(currentLoad)
        end
    end
end


---
function HandToolMotorized:onHeldStart()
    if self.isClient then
        local spec = self.spec_motorized
        local samples = spec.samples
        if not g_soundManager:getIsSamplePlaying(samples.idle) then
            g_soundManager:stopSample(samples.stop)
            g_soundManager:playSample(samples.start)
            g_soundManager:playSample(samples.idle, 0, samples.start)
        end
        g_effectManager:startEffects(spec.exhaustEffects)
    end
end


---
function HandToolMotorized:onHeldEnd()
    if self.isClient then
        local spec = self.spec_motorized
        local samples = spec.samples
        g_soundManager:stopSample(samples.start)
        g_soundManager:stopSample(samples.idle)
        g_soundManager:playSample(samples.stop)
        g_effectManager:stopEffects(spec.exhaustEffects)
    end
end


---
function HandToolMotorized:onUpdate(dt)
    self:updateRPM(dt)

    if self.isClient then
        self:updateSounds(dt)
        self:updateVibrations(dt)
    end
end


---
function HandToolMotorized:updateRPM(dt)
    local spec = self.spec_motorized
    if spec.currentRPM ~= spec.targetRPM then
        local targetRPM = spec.targetRPM
        if spec.rpmVariability > 0 then
            local t = g_currentMission.time * spec.rpmVariabilityChange
            local randomOffset = math.abs(math.sin(t * 0.00157) * 0.4 + math.sin(t * 0.00414) * 0.4 + math.sin(t * 0.00628) * 0.2)
            randomOffset = randomOffset * (spec.targetRPM / spec.maxRPM)
            randomOffset = randomOffset * (0.1 + spec.currentLoad * 0.9)
            targetRPM = targetRPM - randomOffset * spec.maxRPM * spec.rpmVariability
        end

        local direction = math.sign(targetRPM - spec.currentRPM)
        local limit = direction > 0 and math.min or math.max

        local change = direction >= 0 and spec.rpmGainPerSecond or spec.rpmLossPerSecond

        local currentRPM = limit(spec.currentRPM + change * dt * 0.001 * direction, targetRPM)

        self:setCurrentRPM(currentRPM)
    end
end


---
function HandToolMotorized:updateSounds(dt)
    local spec = self.spec_motorized
    local rpmPercentage = MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM)
    g_soundManager:setSampleLoopSynthesisParameters(spec.samples.idle, rpmPercentage, self:getCurrentLoad())
end


---
function HandToolMotorized:updateVibrations(dt)
    local spec = self.spec_motorized

    -- Calculate the vibration to apply based on the RPM. At the maximum RPM, the vibrations are very low, and at idle it is at max.
    local rpmAmount = 1 - math.clamp(MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM), 0, 1)
    local vibrationScale = MathUtil.lerp(0.05, 1.0, rpmAmount) * (1 - spec.currentLoad)
    local vibrationX = MathUtil.randomFloat(-spec.vibrationAmountX, spec.vibrationAmountX) * vibrationScale
    local vibrationY = MathUtil.randomFloat(-spec.vibrationAmountY, spec.vibrationAmountY) * vibrationScale
    local vibrationZ = MathUtil.randomFloat(-spec.vibrationAmountZ, spec.vibrationAmountZ) * vibrationScale

    -- Set the local translation of the chainsaw based on the vibration.
    setTranslation(spec.vibrationNode, vibrationX, vibrationY, vibrationZ)
end


---Calculates the time in seconds that it would take for this motor to reach the given rpm.
-- @param float rpm The target rpm.
-- @return float startupTime The time in seconds that it would take to reach the given rpm.
function HandToolMotorized:getTimeToReachRPM(rpm)

    local spec = self.spec_motorized

    if spec.currentRPM == rpm then
        return 0
    end

    -- Calculate the difference between the current RPM and the target, as well as if the RPM has to slow down or speed up.
    local rpmDelta = rpm - spec.currentRPM
    local rpmDirection = math.sign(rpmDelta)

    -- Calculate the speed to use for the RPM.
    local rpmPerSecond = rpmDirection >= 0 and spec.rpmGainPerSecond or spec.rpmLossPerSecond

    return math.abs(rpmDelta) / rpmPerSecond
end


---
function HandToolMotorized:getRPMGainPerSecond()
    return self.spec_motorized.rpmGainPerSecond
end


---
function HandToolMotorized:setRPMGainPerSecond(rpmGainPerSecond)
    self.spec_motorized.rpmGainPerSecond = rpmGainPerSecond
end


---
function HandToolMotorized:getRPMLossPerSecond()
    return self.spec_motorized.rpmLossPerSecond
end


---
function HandToolMotorized:setRPMLossPerSecond(rpmLossPerSecond)
    self.spec_motorized.rpmLossPerSecond = rpmLossPerSecond
end


---
function HandToolMotorized:getCurrentLoad()
    return self.spec_motorized.currentLoad
end


---
function HandToolMotorized:setCurrentLoad(currentLoad)
    local spec = self.spec_motorized

    currentLoad = math.clamp(currentLoad, 0, 1)
    if math.abs(spec.currentLoad - currentLoad) > 0.01 then
        local carryingPlayer = self:getCarryingPlayer()
        if self.isServer or (carryingPlayer ~= nil and carryingPlayer.isOwner) then
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end

    spec.currentLoad = currentLoad
end


---
function HandToolMotorized:getCurrentRPM()
    return self.spec_motorized.currentRPM
end


---
function HandToolMotorized:setCurrentRPM(currentRPM)
    local spec = self.spec_motorized

    currentRPM = math.clamp(currentRPM, spec.minRPM, spec.maxRPM)

    if math.abs(spec.currentRPM - currentRPM) > 1 then
        local carryingPlayer = self:getCarryingPlayer()
        if self.isServer or (carryingPlayer ~= nil and carryingPlayer.isOwner) then
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end

    spec.currentRPM = currentRPM
end


---
function HandToolMotorized:getTargetRPM()
    return self.spec_motorized.targetRPM
end


---
function HandToolMotorized:getMaxRPM()
    return self.spec_motorized.maxRPM
end


---
function HandToolMotorized:getMinRPM()
    return self.spec_motorized.minRPM
end


---
function HandToolMotorized:setTargetRPM(targetRPM)
    local spec = self.spec_motorized

    spec.targetRPM = math.clamp(targetRPM, spec.minRPM, spec.maxRPM)
end


---
function HandToolMotorized:setTargetRPMToIdle()
    self:setTargetRPM(self.spec_motorized.minRPM)
end


---
function HandToolMotorized:setTargetRPMToMax()
    self:setTargetRPM(self.spec_motorized.maxRPM)
end


---
function HandToolMotorized:onDebugDraw(x, y, textSize)

    local spec = self.spec_motorized
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Current RPM: %d", spec.currentRPM))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Target RPM: %d", spec.targetRPM))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Current Load: %d%%", spec.currentLoad * 100))

    local rpmAmount = 1 - math.clamp(MathUtil.inverseLerp(spec.minRPM, spec.maxRPM, spec.currentRPM), 0, 1)
    local vibrationScale = MathUtil.lerp(0.05, 1.0, rpmAmount) * (1 - spec.currentLoad)
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Vibration: %d%%", vibrationScale * 100))

    return y
end
