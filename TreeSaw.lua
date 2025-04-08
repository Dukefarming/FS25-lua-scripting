













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function TreeSaw.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end


---
function TreeSaw.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TreeSaw")

    SoundManager.registerSampleXMLPaths(schema, "vehicle.treeSaw.sounds", "cut")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.treeSaw.sounds", "saw")

    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.treeSaw.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.treeSaw.effects")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.treeSaw.cutNode#node", "Cut node")
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#sizeY", "Size Y", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#sizeZ", "Size Z", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#lengthAboveThreshold", "Min. tree length above cut node", 0.3)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#lengthBelowThreshold", "Min. tree length below cut node", 0.3)
    schema:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#timer", "Cut delay (sec.)", 1)

    schema:setXMLSpecializationType()
end


---
function TreeSaw.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TreeSaw)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TreeSaw)
end


---Called on loading
-- @param table savegame savegame
function TreeSaw:onLoad(savegame)
    local spec = self.spec_treeSaw

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.treeSaw.animationNodes.animationNode", "stumbCutter") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.cutParticleSystems.emitterShape(0)", "vehicle.treeSaw.effects.effectNode") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.sawSound", "vehicle.treeSaw.sounds.saw") --FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.cutSound", "vehicle.treeSaw.sounds.cut") --FS17 to FS19

    local baseKey = "vehicle.treeSaw"

    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey..".animationNodes", self.components, self, self.i3dMappings)
        spec.effects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".effects", self.components, self, self.i3dMappings)

        spec.samples = {}
        spec.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.saw = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "saw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    spec.cutNode = self.xmlFile:getValue(baseKey .. ".cutNode#node", nil, self.components, self.i3dMappings)
    spec.cutSizeY = self.xmlFile:getValue(baseKey .. ".cutNode#sizeY", 1)
    spec.cutSizeZ = self.xmlFile:getValue(baseKey .. ".cutNode#sizeZ", 1)
    spec.lengthAboveThreshold = self.xmlFile:getValue(baseKey .. ".cutNode#lengthAboveThreshold", 0.3)
    spec.lengthBelowThreshold = self.xmlFile:getValue(baseKey .. ".cutNode#lengthBelowThreshold", 0.3)
    spec.cutTimerDuration = self.xmlFile:getValue(baseKey .. ".cutNode#timer", 1) * 1000

    spec.curSplitShape = nil
    spec.cutTimer = -1
    spec.isCutting = false
    spec.warnTreeNotOwned = false
end


---Called on deleting
function TreeSaw:onDelete()
    local spec = self.spec_treeSaw
    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
end


---Called on on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function TreeSaw:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        local spec = self.spec_treeSaw
        spec.isCutting = streamReadBool(streamId)
    end
end


---Called on on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function TreeSaw:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_treeSaw
        streamWriteBool(streamId, spec.isCutting)
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function TreeSaw:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_treeSaw

    -- Verify that the split shapes still exist (possible that someone has cut them)
    if self.isServer then
        if spec.curSplitShape ~= nil then
            if not entityExists(spec.curSplitShape) then
                spec.curSplitShape = nil
                if g_server ~= nil then
                    spec.cutTimer = -1
                end
            end
        end

        spec.isCutting = spec.curSplitShape ~= nil
        if spec.curSplitShape ~= nil then
            if spec.cutTimer > 0 then
                spec.cutTimer = math.max(spec.cutTimer - dt, 0)
            end

            -- cut
            if  spec.cutTimer == 0 then
                spec.cutTimer = -1

                local x,y,z = getWorldTranslation(spec.cutNode)
                local nx,ny,nz = localDirectionToWorld(spec.cutNode, 1,0,0)
                local yx,yy,yz = localDirectionToWorld(spec.cutNode, 0,1,0)

                ChainsawUtil.cutSplitShape(spec.curSplitShape, x,y,z, nx,ny,nz, yx,yy,yz, spec.cutSizeY, spec.cutSizeZ, self:getActiveFarm())
                spec.curSplitShape = nil
            end
        end
    end

    -- effect and sound for cut
    if self.isClient then
        if spec.cutTimer > 0 then
            g_effectManager:setEffectTypeInfo(spec.effects, FillType.WOODCHIPS)
            g_effectManager:startEffects(spec.effects)
            if not g_soundManager:getIsSamplePlaying(spec.samples.cut) then
                g_soundManager:playSample(spec.samples.cut)
            end
        else
            g_effectManager:stopEffects(spec.effects)
            if g_soundManager:getIsSamplePlaying(spec.samples.cut) then
                g_soundManager:stopSample(spec.samples.cut)
            end
        end
    end
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function TreeSaw:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_treeSaw
    spec.warnTreeNotOwned = false

    if self:getIsTurnedOn() then
        if spec.cutNode ~= nil then
            local x,y,z = getWorldTranslation(spec.cutNode)
            local nx,ny,nz = localDirectionToWorld(spec.cutNode, 1,0,0)
            local yx,yy,yz = localDirectionToWorld(spec.cutNode, 0,1,0)

            if spec.curSplitShape == nil then
                local shape, _, _, _, _ = findSplitShape(x,y,z, nx,ny,nz, yx,yy,yz, spec.cutSizeY, spec.cutSizeZ)
                if shape ~= 0 then
                    if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x, z) then
                        spec.curSplitShape = shape
                        spec.cutTimer = spec.cutTimerDuration
                    else
                        spec.warnTreeNotOwned = true
                    end
                end
            elseif not entityExists(spec.curSplitShape) then
                spec.curSplitShape = nil
            end

            if spec.curSplitShape ~= nil then
                local minY,maxY, minZ,maxZ = testSplitShape(spec.curSplitShape, x,y,z, nx,ny,nz, yx,yy,yz, spec.cutSizeY, spec.cutSizeZ)
                if minY == nil then
                    spec.curSplitShape = nil
                else
                    -- check if cut would be below y=0 (tree CoSy)
                    local cutTooLow = false
                    local _,ly,_ = localToLocal(spec.cutNode, spec.curSplitShape, 0,minY,minZ)
                    cutTooLow = cutTooLow or ly < 0.01
                    _,ly,_ = localToLocal(spec.cutNode, spec.curSplitShape, 0,minY,maxZ)
                    cutTooLow = cutTooLow or ly < 0.01
                    _,ly,_ = localToLocal(spec.cutNode, spec.curSplitShape, 0,maxY,minZ)
                    cutTooLow = cutTooLow or ly < 0.01
                     _,ly,_ = localToLocal(spec.cutNode, spec.curSplitShape, 0,maxY,maxZ)
                    cutTooLow = cutTooLow or ly < 0.01
                    if cutTooLow then
                        spec.curSplitShape = nil
                    end
                end
            end

            if spec.curSplitShape ~= nil then
                local lenBelow, lenAbove = getSplitShapePlaneExtents(spec.curSplitShape, x,y,z, nx,ny,nz)
                if lenAbove < spec.lengthAboveThreshold or lenBelow < spec.lengthBelowThreshold then
                    spec.curSplitShape = nil
                end
            end

            if spec.curSplitShape == nil and spec.cutTimer > -1 then
                spec.cutTimer = -1
            end
        end
    end
end


---Called on draw
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function TreeSaw:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_treeSaw

    if spec.isCutting then
        g_currentMission:addExtraPrintText(g_i18n:getText("info_cutting"))
    end

    if spec.warnTreeNotOwned then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 1000)
    end
end


---Called on deactivate
function TreeSaw:onDeactivate()
    local spec = self.spec_treeSaw

    spec.curSplitShape = nil
    spec.cutTimer = -1
end


---Called on turn on
function TreeSaw:onTurnedOn()
    if self.isClient then
        local spec = self.spec_treeSaw
        g_animationManager:startAnimations(spec.animationNodes)
        g_soundManager:playSample(spec.samples.saw)
    end
end


---Called on turn off
function TreeSaw:onTurnedOff()
    local spec = self.spec_treeSaw

    spec.curSplitShape = nil
    spec.cutTimer = -1

    if self.isClient then
        g_animationManager:stopAnimations(spec.animationNodes)
        g_effectManager:stopEffects(spec.effects)
        g_soundManager:stopSamples(spec.samples)
    end
end
