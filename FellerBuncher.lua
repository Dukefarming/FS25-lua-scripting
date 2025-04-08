
















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function FellerBuncher.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end


---
function FellerBuncher.initSpecialization()
    g_storeManager:addSpecType("fellerBuncherMaxTreeSize", "shopListAttributeIconMaxTreeSize", FellerBuncher.loadSpecValueMaxTreeSize, FellerBuncher.getSpecValueMaxTreeSize, StoreSpecies.VEHICLE)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FellerBuncher")

    schema:register(XMLValueType.INT, "vehicle.fellerBuncher#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher#maxRadius", "Max. tree radius that can be cut", 1)
    schema:register(XMLValueType.STRING, "vehicle.fellerBuncher#releaseInputAction", "Name of input action to release the tree(s)", "IMPLEMENT_EXTRA2")
    schema:register(XMLValueType.STRING, "vehicle.fellerBuncher#cutInputAction", "Name of input action to cut the tree (if not defined the trees are automatically cut after cutNode#duration)")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.cutNode#node", "Cut node - Used for tree detection and actual cutting")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.cutNode#sizeY", "Cut node size y", 2)
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.cutNode#sizeZ", "Cut node size z", 2)
    schema:register(XMLValueType.TIME, "vehicle.fellerBuncher.cutNode#duration", "Cut duration", 1)

    schema:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.cutNode.cutCollision#node", "Cut collision node - Node is moved during cutting process")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.fellerBuncher.cutNode.cutCollision#startTrans", "Start translation")
    schema:register(XMLValueType.VECTOR_TRANS, "vehicle.fellerBuncher.cutNode.cutCollision#endTrans", "end translation")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.mountNode#node", "Mount node - Detects trees and mounts them to the parent component")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mountNode#sizeY", "Mount node size y", 2)
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mountNode#sizeZ", "Mount node size z", 2)

    schema:register(XMLValueType.NODE_INDEX, "vehicle.fellerBuncher.treeMoveDirectionNode#node", "Provides direction in which the tree is moved while mounting")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeMoveDirectionNode#distance", "How far the tree is moved")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeMoveDirectionNode#liftDistance", "How far the tree is lifted")

    schema:register(XMLValueType.STRING, "vehicle.fellerBuncher.mainGrab#animationName", "Main grab animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mainGrab#speedScale", "Main grab animation speed", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mainGrab#releaseSpeedScale", "Main grab animation release speed", 1)
    schema:register(XMLValueType.VECTOR_N, "vehicle.fellerBuncher.mainGrab#componentJointIndices", "Component joint indices to change the damping rate while main grab is closed")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.mainGrab#dampingFactor", "Damping factor for component joint index", 20)

    schema:register(XMLValueType.STRING, "vehicle.fellerBuncher.cutAnimation#animationName", "Cut animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.cutAnimation#speedScale", "Cut animation speed scale", 1)

    schema:register(XMLValueType.TIME, "vehicle.fellerBuncher.unmount#delay", "Delay between unmounting each tree", 0.4)
    schema:register(XMLValueType.STRING, "vehicle.fellerBuncher.unmount#animationName", "Animation played after the joint releases")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.unmount#speedScale", "Animation speed", 1)

    schema:register(XMLValueType.STRING, "vehicle.fellerBuncher.treeSlot(?).grab#animationName", "Grab animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeSlot(?).grab#speedScale", "Grab animation speed", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.fellerBuncher.treeSlot(?).grab#releaseSpeedScale", "Grab animation release speed", 1)

    SoundManager.registerSampleXMLPaths(schema, "vehicle.fellerBuncher.sounds", "cut")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.fellerBuncher.sounds", "saw")

    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.fellerBuncher.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.fellerBuncher.effects")

    schema:setXMLSpecializationType()
end


---
function FellerBuncher.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setFellerBuncherGrabState", FellerBuncher.setFellerBuncherGrabState)
    SpecializationUtil.registerFunction(vehicleType, "getIsFellerBuncherReadyForCut", FellerBuncher.getIsFellerBuncherReadyForCut)
    SpecializationUtil.registerFunction(vehicleType, "getFellerBuncherCanCutSplitShape", FellerBuncher.getFellerBuncherCanCutSplitShape)
    SpecializationUtil.registerFunction(vehicleType, "cutTree", FellerBuncher.cutTree)
    SpecializationUtil.registerFunction(vehicleType, "fellerBuncherSplitShapeCallback", FellerBuncher.fellerBuncherSplitShapeCallback)
    SpecializationUtil.registerFunction(vehicleType, "doMountProcess", FellerBuncher.doMountProcess)
    SpecializationUtil.registerFunction(vehicleType, "mountTreeInRange", FellerBuncher.mountTreeInRange)
    SpecializationUtil.registerFunction(vehicleType, "releaseMountedTrees", FellerBuncher.releaseMountedTrees)
    SpecializationUtil.registerFunction(vehicleType, "releaseMainArmTree", FellerBuncher.releaseMainArmTree)
    SpecializationUtil.registerFunction(vehicleType, "releaseNextTreeSlot", FellerBuncher.releaseNextTreeSlot)
    SpecializationUtil.registerFunction(vehicleType, "onFellerBuncherTreesChanged", FellerBuncher.onFellerBuncherTreesChanged)
    SpecializationUtil.registerFunction(vehicleType, "getNumLoadedTrees", FellerBuncher.getNumLoadedTrees)
    SpecializationUtil.registerFunction(vehicleType, "onFellerBuncherTreeShapeCut", FellerBuncher.onFellerBuncherTreeShapeCut)
    SpecializationUtil.registerFunction(vehicleType, "onFellerBuncherTreeShapeMounted", FellerBuncher.onFellerBuncherTreeShapeMounted)
end


---
function FellerBuncher.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", FellerBuncher.getCanToggleTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", FellerBuncher.registerLoweringActionEvent)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsAutoTreeAlignment", FellerBuncher.getSupportsAutoTreeAlignment)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAutoAlignHasValidTree", FellerBuncher.getAutoAlignHasValidTree)
end


---
function FellerBuncher.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", FellerBuncher)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", FellerBuncher)
end


---
function FellerBuncher:onLoad(savegame)
    local spec = self.spec_fellerBuncher

    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.fellerBuncher#fillUnitIndex")
    spec.maxRadius = self.xmlFile:getValue("vehicle.fellerBuncher#maxRadius", 1)
    spec.releaseInputAction = InputAction[self.xmlFile:getValue("vehicle.fellerBuncher#releaseInputAction", "IMPLEMENT_EXTRA2")] or InputAction.IMPLEMENT_EXTRA2
    local cutInputActionStr = self.xmlFile:getValue("vehicle.fellerBuncher#cutInputAction")
    if cutInputActionStr ~= nil then
        spec.cutInputAction = InputAction[cutInputActionStr]
    end

    spec.cutNode = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#node", nil, self.components, self.i3dMappings)
    spec.cutNodeSizeY = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#sizeY", 2)
    spec.cutNodeSizeZ = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#sizeZ", 2)
    spec.cutDuration = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode#duration", 1)
    spec.cutTimer = 0
    spec.effectState = false
    spec.lastEffectState = false

    spec.cutCollisionNode = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode.cutCollision#node", nil, self.components, self.i3dMappings)
    spec.cutCollisionNodeStartTrans = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode.cutCollision#startTrans", nil, true)
    spec.cutCollisionNodeEndTrans = self.xmlFile:getValue("vehicle.fellerBuncher.cutNode.cutCollision#endTrans", nil, true)

    spec.mountNode = self.xmlFile:getValue("vehicle.fellerBuncher.mountNode#node", nil, self.components, self.i3dMappings)
    spec.mountComponent = self:getParentComponent(spec.mountNode or self.rootNode)
    spec.mountNodeSizeY = self.xmlFile:getValue("vehicle.fellerBuncher.mountNode#sizeY", 2)
    spec.mountNodeSizeZ = self.xmlFile:getValue("vehicle.fellerBuncher.mountNode#sizeZ", 2)

    spec.treeMoveDirectionNode = self.xmlFile:getValue("vehicle.fellerBuncher.treeMoveDirectionNode#node", nil, self.components, self.i3dMappings)
    spec.treeMoveDirectionDistance = self.xmlFile:getValue("vehicle.fellerBuncher.treeMoveDirectionNode#distance", 0.05)
    spec.treeMoveDirectionLiftDistance = self.xmlFile:getValue("vehicle.fellerBuncher.treeMoveDirectionNode#liftDistance", 0.05)

    spec.mainGrab = {}
    spec.mainGrab.animationName = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#animationName")
    spec.mainGrab.speedScale = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#speedScale", 1)
    spec.mainGrab.releaseSpeedScale = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#releaseSpeedScale", 1)
    spec.mainGrab.componentJointIndices = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#componentJointIndices", nil, true)
    spec.mainGrab.dampingFactor = self.xmlFile:getValue("vehicle.fellerBuncher.mainGrab#dampingFactor", 20)
    spec.mainGrab.jointIndex = 0
    spec.mainGrab.jointNode = nil
    spec.mainGrab.shapeId = nil
    spec.mainGrab.isUsed = false

    spec.cutAnimation = {}
    spec.cutAnimation.animationName = self.xmlFile:getValue("vehicle.fellerBuncher.cutAnimation#animationName")
    spec.cutAnimation.speedScale = self.xmlFile:getValue("vehicle.fellerBuncher.cutAnimation#speedScale", 1)

    spec.foundSplitShape = nil
    spec.foundSplitShapeIsTree = false
    spec.mountProcessInProgress = false
    spec.mountProcessSplitShape = nil
    spec.mountProcessTreeSlot = nil

    spec.unmountProcessInProgress = false
    spec.unmountProcessAnimationPlayed = false
    spec.unmountProcessTimer = 0
    spec.unmountProcessDelay = self.xmlFile:getValue("vehicle.fellerBuncher.unmount#delay", 0.4)
    spec.unmountProcessAnimation = self.xmlFile:getValue("vehicle.fellerBuncher.unmount#animationName")
    spec.unmountProcessAnimationSpeedScale = self.xmlFile:getValue("vehicle.fellerBuncher.unmount#speedScale", 1)

    spec.treeSlots = {}
    self.xmlFile:iterate("vehicle.fellerBuncher.treeSlot", function(index, key)
        local treeSlot = {}
        treeSlot.animationName = self.xmlFile:getValue(key .. ".grab#animationName")
        treeSlot.speedScale = self.xmlFile:getValue(key .. ".grab#speedScale", 1)
        treeSlot.releaseSpeedScale = self.xmlFile:getValue(key .. ".grab#releaseSpeedScale", 1)
        if treeSlot.animationName ~= nil then
            treeSlot.isUsed = false
            treeSlot.jointIndex = 0
            treeSlot.jointNode = nil
            treeSlot.shapeId = nil
            table.insert(spec.treeSlots, treeSlot)
        end
    end)

    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.fellerBuncher.animationNodes", self.components, self, self.i3dMappings)
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.fellerBuncher.effects", self.components, self, self.i3dMappings)

        spec.samples = {}
        spec.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fellerBuncher.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.saw = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.fellerBuncher.sounds", "saw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    spec.texts = {}
    spec.texts.actionRelease = g_i18n:getText("action_releaseTrees", self.customEnvironment)
    spec.texts.actionCutTree = g_i18n:getText("action_woodHarvesterCut", self.customEnvironment)
    spec.texts.warningNoAccess = g_i18n:getText("warning_youAreNotAllowedToCutThisTree", self.customEnvironment)
    spec.texts.warningNoPermission = g_i18n:getText("shop_messageNoPermissionGeneral", self.customEnvironment)
    spec.texts.treeTooThick = g_i18n:getText("warning_treeTooThick", self.customEnvironment)

    g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onFellerBuncherTreeShapeCut, self)
    g_messageCenter:subscribe(MessageType.TREE_SHAPE_MOUNTED, self.onFellerBuncherTreeShapeMounted, self)

    spec.dirtyFlag = self:getNextDirtyFlag()
end


---Called on deleting
function FellerBuncher:onDelete()
    local spec = self.spec_fellerBuncher

    if spec.treeSlots ~= nil then
        self:releaseMainArmTree()
        while self:releaseNextTreeSlot() do
        end
    end

    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSamples(spec.samples)
    g_animationManager:deleteAnimations(spec.animationNodes)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FellerBuncher:onReadStream(streamId, connection)
    local spec = self.spec_fellerBuncher
    spec.effectState = streamReadBool(streamId)
    spec.mainGrab.isUsed = streamReadBool(streamId)
    for i=1, #spec.treeSlots do
        spec.treeSlots[i].isUsed = streamReadBool(streamId)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FellerBuncher:onWriteStream(streamId, connection)
    local spec = self.spec_fellerBuncher
    streamWriteBool(streamId, spec.effectState)
    streamWriteBool(streamId, spec.mainGrab.isUsed)
    for i=1, #spec.treeSlots do
        streamWriteBool(streamId, spec.treeSlots[i].isUsed)
    end
end


---
function FellerBuncher:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local spec = self.spec_fellerBuncher
            spec.effectState = streamReadBool(streamId)
            spec.mainGrab.isUsed = streamReadBool(streamId)
            for i=1, #spec.treeSlots do
                spec.treeSlots[i].isUsed = streamReadBool(streamId)
            end

            FellerBuncher.updateActionEvents(self)
        end
    end
end


---
function FellerBuncher:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_fellerBuncher
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.effectState)
            streamWriteBool(streamId, spec.mainGrab.isUsed)
            for i=1, #spec.treeSlots do
                streamWriteBool(streamId, spec.treeSlots[i].isUsed)
            end
        end
    end
end


---
function FellerBuncher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_fellerBuncher
    local lastFoundSplitShape = spec.foundSplitShape
    spec.foundSplitShape = nil

    if self.isServer then
        local isCutting = false
        if self:getIsFellerBuncherReadyForCut() then
            if spec.cutNode ~= nil then
                local cx, cy, cz = getWorldTranslation(spec.cutNode)
                local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
                local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)

                --#debug local zx, zy, zz = localDirectionToWorld(spec.cutNode, 0,0,1)
                --#debug DebugUtil.drawDebugNode(spec.cutNode, "", false)
                --#debug DebugUtil.drawDebugAreaRectangle(cx, cy, cz, cx + zx * spec.cutNodeSizeZ, cy + zy * spec.cutNodeSizeZ, cz + zz * spec.cutNodeSizeZ, cx + yx * spec.cutNodeSizeY, cy + yy * spec.cutNodeSizeY, cz + yz * spec.cutNodeSizeY, false, 1, 0, 0)

                local splitShapeId, minY, maxY, minZ, maxZ = findSplitShape(cx, cy, cz, nx, ny, nz, yx, yy, yz, spec.cutNodeSizeY, spec.cutNodeSizeZ)
                if splitShapeId ~= 0 then
                    --#debug local radius = math.max(maxY-minY, maxZ-minZ) * 0.5
                    --#debug local x1, y1, z1 = localToWorld(spec.cutNode, yOffset or 0, minY, minZ)
                    --#debug local x2, y2, z2 = localToWorld(spec.cutNode, yOffset or 0, minY, maxZ)
                    --#debug local x3, y3, z3 = localToWorld(spec.cutNode, yOffset or 0, maxY, minZ)
                    --#debug Utils.renderTextAtWorldPosition((x1+x3) / 2, (y1+y3) / 2, (z1+z3) / 2, string.format("diam: %.2f/%.2f", radius*2, spec.maxRadius*2), getCorrectTextSize(0.012), 0)
                    --#debug DebugUtil.drawDebugAreaRectangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, false, 0, 1, 0)

                    local isAllowed, warning = self:getFellerBuncherCanCutSplitShape(splitShapeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ)
                    if isAllowed then
                        spec.foundSplitShape = splitShapeId
                        spec.foundSplitShapeIsTree = getRigidBodyType(splitShapeId) == RigidBodyType.STATIC
                        if spec.cutInputAction == nil then
                            isCutting = true
                            spec.cutTimer = spec.cutTimer + dt
                            if spec.cutTimer > spec.cutDuration then
                                self:cutTree()
                                spec.cutTimer = 0
                            end

                            if spec.cutCollisionNode ~= nil then
                                setTranslation(spec.cutCollisionNode, MathUtil.vector3ArrayLerp(spec.cutCollisionNodeStartTrans, spec.cutCollisionNodeEndTrans, spec.cutTimer / spec.cutDuration))
                            end
                        end
                    else
                        if isActiveForInputIgnoreSelection and warning ~= nil then
                            g_currentMission:showBlinkingWarning(warning, 100)
                        end
                    end
                end
            end

            if not isCutting then
                spec.cutTimer = 0
            end
        elseif spec.mountProcessInProgress then
            if spec.mountProcessSplitShape ~= nil then
                local dx, dy, dz = localDirectionToWorld(spec.treeMoveDirectionNode, 0, 0, getMass(spec.mountProcessSplitShape) * 10)
                local cx, cy, cz = worldToLocal(spec.mountProcessSplitShape, localToWorld(spec.treeMoveDirectionNode, 0, 1, 0))
                addForce(spec.mountProcessSplitShape, dx, dy, dz, cx, cy, cz, true)
            end
        elseif spec.unmountProcessInProgress then
            spec.unmountProcessTimer = math.max(spec.unmountProcessTimer - dt, 0)
            if spec.unmountProcessTimer <= 0 then
                if self:getNumLoadedTrees() > 0 then
                    if not self:releaseNextTreeSlot() then
                        spec.unmountProcessInProgress = false

                        if not self:getIsTurnedOn() then
                            self:setFellerBuncherGrabState(false)
                        end
                    end

                    spec.unmountProcessTimer = spec.unmountProcessDelay
                else
                    local isUnloading = self:getIsAnimationPlaying(spec.mainGrab.animationName)
                    for i=1, #spec.treeSlots do
                        isUnloading = isUnloading or self:getIsAnimationPlaying(spec.treeSlots[i].animationName)
                    end

                    if not isUnloading and not spec.unmountProcessAnimationPlayed then
                        if spec.unmountProcessAnimation ~= nil and not self:getIsAnimationPlaying(spec.unmountProcessAnimation) then
                            self:playAnimation(spec.unmountProcessAnimation, spec.unmountProcessAnimationSpeedScale, 0, true)
                        end
                        spec.unmountProcessAnimationPlayed = true
                    end

                    local isFinished = false
                    if not isUnloading and spec.unmountProcessAnimationPlayed then
                        if spec.unmountProcessAnimation ~= nil then
                            if not self:getIsAnimationPlaying(spec.unmountProcessAnimation) then
                                if self:getAnimationTime(spec.unmountProcessAnimation) > 0.99 then
                                    self:playAnimation(spec.unmountProcessAnimation, -spec.unmountProcessAnimationSpeedScale, 1, true)
                                else
                                    isFinished = true
                                end
                            end
                        else
                            isFinished = true
                        end
                    end

                    if isFinished then
                        spec.unmountProcessInProgress = false
                        if not self:getIsTurnedOn() then
                            self:setFellerBuncherGrabState(false)
                        end
                    end
                end
            end
        else
            spec.cutTimer = 0
        end

        -- in case the tree is deleted (e.g. driving into sell trigger or container loading trigger)
        if spec.mainGrab.shapeId ~= nil and not entityExists(spec.mainGrab.shapeId) then
            self:releaseMountedTrees()
        else
            for i=1, #spec.treeSlots do
                if spec.treeSlots[i].shapeId ~= nil and not entityExists(spec.treeSlots[i].shapeId) then
                    self:releaseMountedTrees()
                    break
                end
            end
        end
    else
        if isActiveForInputIgnoreSelection then
            if spec.cutNode ~= nil then
                local cx, cy, cz = getWorldTranslation(spec.cutNode)
                local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
                local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)

                --#debug local zx, zy, zz = localDirectionToWorld(spec.cutNode, 0,0,1)
                --#debug DebugUtil.drawDebugNode(spec.cutNode, "", false)
                --#debug DebugUtil.drawDebugAreaRectangle(cx, cy, cz, cx + zx * spec.cutNodeSizeZ, cy + zy * spec.cutNodeSizeZ, cz + zz * spec.cutNodeSizeZ, cx + yx * spec.cutNodeSizeY, cy + yy * spec.cutNodeSizeY, cz + yz * spec.cutNodeSizeY, false, 1, 0, 0)

                local splitShapeId, minY, maxY, minZ, maxZ = findSplitShape(cx, cy, cz, nx, ny, nz, yx, yy, yz, spec.cutNodeSizeY, spec.cutNodeSizeZ)
                if splitShapeId ~= 0 then
                    --#debug local radius = math.max(maxY-minY, maxZ-minZ) * 0.5
                    --#debug local x1, y1, z1 = localToWorld(spec.cutNode, yOffset or 0, minY, minZ)
                    --#debug local x2, y2, z2 = localToWorld(spec.cutNode, yOffset or 0, minY, maxZ)
                    --#debug local x3, y3, z3 = localToWorld(spec.cutNode, yOffset or 0, maxY, minZ)
                    --#debug Utils.renderTextAtWorldPosition((x1+x3) / 2, (y1+y3) / 2, (z1+z3) / 2, string.format("diam: %.2f/%.2f", radius*2, spec.maxRadius*2), getCorrectTextSize(0.012), 0)
                    --#debug DebugUtil.drawDebugAreaRectangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, false, 0, 1, 0)

                    local isAllowed, warning = self:getFellerBuncherCanCutSplitShape(splitShapeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ)
                    if isAllowed then
                        spec.foundSplitShape = splitShapeId
                    else
                        if warning ~= nil then
                            g_currentMission:showBlinkingWarning(warning, 100)
                        end
                    end
                end
            end
        end
    end

    if lastFoundSplitShape ~= spec.foundSplitShape then
        FellerBuncher.updateActionEvents(self)
    end

    -- effect and sound for cut
    if self.isServer then
        spec.effectState = spec.cutTimer > 0
    end

    if spec.effectState ~= spec.lastEffectState then
        spec.lastEffectState = spec.effectState
        self:raiseDirtyFlags(spec.dirtyFlag)

        if self.isClient then
            if spec.effectState then
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
end


---
function FellerBuncher:onTurnedOn()
    local spec = self.spec_fellerBuncher

    if self:getNumLoadedTrees() == 0 then
        self:setFellerBuncherGrabState(true)
    end

    if self.isClient then
        g_animationManager:startAnimations(spec.animationNodes)
        g_soundManager:playSample(spec.samples.saw)
    end
end


---
function FellerBuncher:onTurnedOff()
    local spec = self.spec_fellerBuncher

    if self:getNumLoadedTrees() == 0 then
        self:setFellerBuncherGrabState(false)
    end

    if self.isClient then
        g_animationManager:stopAnimations(spec.animationNodes)
        g_effectManager:stopEffects(spec.effects)
        g_soundManager:stopSamples(spec.samples)
    end
end


---
function FellerBuncher:onFinishAnimation(name)
    local spec = self.spec_fellerBuncher
    if spec.mountProcessInProgress then
        if name == spec.mainGrab.animationName then
            for i=1, #spec.treeSlots do
                local treeSlot = spec.treeSlots[i]
                if not treeSlot.isUsed then
                    self:playAnimation(treeSlot.animationName, -treeSlot.speedScale, self:getAnimationTime(treeSlot.animationName), true)
                    spec.mountProcessTreeSlot = treeSlot
                    break
                end
            end

            if spec.mountProcessTreeSlot == nil and spec.mainGrab.jointIndex == 0 then
                spec.mainGrab.jointIndex, spec.mainGrab.jointNode, spec.mainGrab.shapeId = self:mountTreeInRange()
                if spec.mainGrab.jointIndex == 0 then
                    self:playAnimation(spec.mainGrab.animationName, spec.mainGrab.speedScale, self:getAnimationTime(spec.mainGrab.animationName), true)
                    self:playAnimation(spec.cutAnimation.animationName, spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.animationName), true)
                else
                    spec.mainGrab.isUsed = true
                    self:onFellerBuncherTreesChanged()

                    if self.isServer then
                        if spec.mainGrab.componentJointIndices ~= nil then
                            for j=1, #spec.mainGrab.componentJointIndices do
                                local componentJoint = self.componentJoints[spec.mainGrab.componentJointIndices[j]]
                                if componentJoint ~= nil then
                                    for i=1, 3 do
                                        setJointRotationLimitSpring(componentJoint.jointIndex, i-1, componentJoint.rotLimitSpring[i], componentJoint.rotLimitDamping[i]*spec.mainGrab.dampingFactor)
                                    end
                                end
                            end
                        end
                    end
                end

                spec.mountProcessInProgress = false
                spec.mountProcessSplitShape = nil
            end
        elseif spec.mountProcessTreeSlot ~= nil and name == spec.mountProcessTreeSlot.animationName then
            self:playAnimation(spec.mainGrab.animationName, spec.mainGrab.speedScale, self:getAnimationTime(spec.mainGrab.animationName), true)
            self:playAnimation(spec.cutAnimation.animationName, spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.animationName), true)

            local treeSlot = spec.mountProcessTreeSlot
            treeSlot.jointIndex, treeSlot.jointNode, treeSlot.shapeId = self:mountTreeInRange()
            if treeSlot.jointIndex ~= 0 then
                treeSlot.isUsed = true
                self:onFellerBuncherTreesChanged()
            else
                self:playAnimation(treeSlot.animationName, treeSlot.speedScale, self:getAnimationTime(treeSlot.animationName), true)
            end

            spec.mountProcessInProgress = false
            spec.mountProcessSplitShape = nil
            spec.mountProcessTreeSlot = nil
        end
    end
end


---
function FellerBuncher:setFellerBuncherGrabState(state)
    local spec = self.spec_fellerBuncher
    if state then
        self:playAnimation(spec.mainGrab.animationName, spec.mainGrab.speedScale, self:getAnimationTime(spec.mainGrab.animationName), true)
        for i=1, #spec.treeSlots do
            local treeSlot = spec.treeSlots[i]
            self:playAnimation(treeSlot.animationName, treeSlot.speedScale, self:getAnimationTime(treeSlot.animationName), true)
        end
        self:playAnimation(spec.cutAnimation.animationName, spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.animationName), true)
    else
        self:playAnimation(spec.mainGrab.animationName, -spec.mainGrab.speedScale, self:getAnimationTime(spec.mainGrab.animationName), true)
        for i=1, #spec.treeSlots do
            local treeSlot = spec.treeSlots[i]
            self:playAnimation(treeSlot.animationName, -treeSlot.speedScale, self:getAnimationTime(treeSlot.animationName), true)
        end
        self:playAnimation(spec.cutAnimation.animationName, -spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.animationName), true)
    end
end


---
function FellerBuncher:getIsFellerBuncherReadyForCut()
    local spec = self.spec_fellerBuncher

    if spec.mountProcessInProgress then
        return false
    end

    if spec.unmountProcessInProgress then
        return false
    end

    if self:getIsAnimationPlaying(spec.mainGrab.animationName) then
        return false
    end

    if not self:getIsTurnedOn() then
        return false
    end

    if self:getNumLoadedTrees() >= #spec.treeSlots + 1 then
        return false
    end

    return true
end


---
function FellerBuncher:getFellerBuncherCanCutSplitShape(splitShapeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, minY, maxY, minZ, maxZ)
    local spec = self.spec_fellerBuncher
    if WoodHarvester.getCanSplitShapeBeAccessed(self, cx, cz, splitShapeId) then
        local radius = math.max(maxY-minY, maxZ-minZ) * 0.5
        if radius > spec.maxRadius then
            return false, spec.texts.treeTooThick
        end

        if splitShapeId == spec.mainGrab.shapeId then
            return false
        end

        for i=1, #spec.treeSlots do
            if splitShapeId == spec.treeSlots[i].shapeId then
                return false
            end
        end

        local lenBelow, lenAbove = getSplitShapePlaneExtents(splitShapeId, cx, cy, cz, nx, ny, nz)
        if lenBelow ~= nil and lenBelow > 0.15 and lenAbove > 0.15 then
            return true
        else
            return false
        end
    else
        if not g_currentMission:getHasPlayerPermission("cutTrees", self:getOwnerConnection()) then
            return false, spec.texts.warningNoPermission
        end
    end

    return false, spec.texts.warningNoAccess
end


---
function FellerBuncher:cutTree(noEventSend)
    local spec = self.spec_fellerBuncher
    if spec.foundSplitShape ~= nil then
        if self.isServer then
            local stats = g_currentMission:farmStats(self:getActiveFarm())

            -- increase tree cut counter for achievements
            local cutTreeCount = stats:updateStats("cutTreeCount", 1)

            g_achievementManager:tryUnlock("CutTreeFirst", cutTreeCount)
            g_achievementManager:tryUnlock("CutTree", cutTreeCount)

            -- update the types of trees cut so far (achievement)
            local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(spec.foundSplitShape))
            if splitType ~= nil then
                stats:updateTreeTypesCut(splitType.name)
            end

            local cx, cy, cz = getWorldTranslation(spec.cutNode)
            local nx, ny, nz = localDirectionToWorld(spec.cutNode, 1, 0, 0)
            local yx, yy, yz = localDirectionToWorld(spec.cutNode, 0, 1, 0)
            splitShape(spec.foundSplitShape, cx, cy, cz, nx, ny, nz, yx, yy, yz, spec.cutNodeSizeY, spec.cutNodeSizeZ, "fellerBuncherSplitShapeCallback", self)
        end

        spec.foundSplitShape = nil
    end

    self:playAnimation(spec.cutAnimation.animationName, -spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.animationName), true)

    if spec.cutInputAction ~= nil then
        if self.isClient then
            g_soundManager:playSample(spec.samples.cut)
        end
    end

    FellerBuncherCutEvent.sendEvent(self, noEventSend)
end


---
function FellerBuncher:fellerBuncherSplitShapeCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    local spec = self.spec_fellerBuncher

    g_currentMission:addKnownSplitShape(shape)
    g_treePlantManager:addingSplitShape(shape, spec.foundSplitShape, spec.foundSplitShapeIsTree)

    if isAbove then
        self:doMountProcess(shape)
    end
end


---
function FellerBuncher:doMountProcess(shape, noEventSend)
    local spec = self.spec_fellerBuncher
    self:playAnimation(spec.mainGrab.animationName, -spec.mainGrab.speedScale, self:getAnimationTime(spec.mainGrab.animationName), true)
    spec.mountProcessInProgress = true
    spec.mountProcessSplitShape = shape

    local x, y, z = getTranslation(shape)
    local dx, dy, dz = localDirectionToWorld(spec.treeMoveDirectionNode, 0, 0, 1)
    setTranslation(shape, x + dx * spec.treeMoveDirectionDistance, y + dy * spec.treeMoveDirectionDistance + spec.treeMoveDirectionLiftDistance, z + dz * spec.treeMoveDirectionDistance)
end


---
function FellerBuncher:mountTreeInRange()
    local spec = self.spec_fellerBuncher
    if spec.mountNode ~= nil then
        local cx, cy, cz = getWorldTranslation(spec.mountNode)
        local nx, ny, nz = localDirectionToWorld(spec.mountNode, 1, 0, 0)
        local yx, yy, yz = localDirectionToWorld(spec.mountNode, 0, 1, 0)
        local minY, maxY, minZ, maxZ = testSplitShape(spec.mountProcessSplitShape, cx, cy, cz, nx, ny, nz, yx, yy, yz, spec.mountNodeSizeY, spec.mountNodeSizeZ)
        if minY ~= nil then
            local jointNode = createTransformGroup("jointNode")
            link(spec.mountNode, jointNode)
            setTranslation(jointNode, 0, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5)

            local constr = JointConstructor.new()
            constr:setActors(spec.mountComponent, spec.mountProcessSplitShape)
            constr:setJointTransforms(jointNode, jointNode)

            constr:setRotationLimit(0, 0, 0)
            constr:setRotationLimit(1, 0, 0)
            constr:setRotationLimit(2, 0, 0)

            constr:setEnableCollision(true)

            local springForce = 7500
            local springDamping = 1500
            constr:setRotationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)
            constr:setTranslationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)

            g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, spec.mountProcessSplitShape, self)

            return constr:finalize(), jointNode, spec.mountProcessSplitShape
        end
    end

    return 0, nil
end


---
function FellerBuncher:releaseMountedTrees(noEventSend)
    local spec = self.spec_fellerBuncher

    if self.isServer then
        spec.unmountProcessInProgress = true
        spec.unmountProcessAnimationPlayed = false
        spec.unmountProcessTimer = spec.unmountProcessDelay

        if not self:releaseMainArmTree() then
            self:releaseNextTreeSlot()
        end
    end

    FellerBuncherReleaseEvent.sendEvent(self, noEventSend)
end


---
function FellerBuncher:releaseMainArmTree()
    local spec = self.spec_fellerBuncher
    local wasUsed = spec.mainGrab.isUsed

    self:playAnimation(spec.mainGrab.animationName, spec.mainGrab.releaseSpeedScale, self:getAnimationTime(spec.mainGrab.animationName), true)
    self:playAnimation(spec.cutAnimation.animationName, spec.cutAnimation.speedScale, self:getAnimationTime(spec.cutAnimation.animationName), true)

    if spec.mainGrab.jointIndex ~= 0 then
        removeJoint(spec.mainGrab.jointIndex)
        spec.mainGrab.jointIndex = 0
    end

    if spec.mainGrab.jointNode ~= nil then
        delete(spec.mainGrab.jointNode)
        spec.mainGrab.jointNode = nil
    end

    spec.mainGrab.shapeId = nil
    spec.mainGrab.isUsed = false

    if self.isServer then
        if self.isServer then
            if spec.mainGrab.componentJointIndices ~= nil then
                for j=1, #spec.mainGrab.componentJointIndices do
                    local componentJoint = self.componentJoints[spec.mainGrab.componentJointIndices[j]]
                    if componentJoint ~= nil then
                        for i=1, 3 do
                            setJointRotationLimitSpring(componentJoint.jointIndex, i-1, componentJoint.rotLimitSpring[i], componentJoint.rotLimitDamping[i])
                        end
                    end
                end
            end
        end
    end

    self:onFellerBuncherTreesChanged()

    return wasUsed
end


---
function FellerBuncher:releaseNextTreeSlot()
    local spec = self.spec_fellerBuncher
    for i=1, #spec.treeSlots do
        local treeSlot = spec.treeSlots[i]
        if treeSlot.isUsed then
            self:playAnimation(treeSlot.animationName, treeSlot.releaseSpeedScale, self:getAnimationTime(treeSlot.animationName), true)

            if treeSlot.jointIndex ~= 0 then
                removeJoint(treeSlot.jointIndex)
                treeSlot.jointIndex = 0
            end

            if treeSlot.jointNode ~= nil then
                delete(treeSlot.jointNode)
                treeSlot.jointNode = nil
            end

            treeSlot.shapeId = nil
            treeSlot.isUsed = false

            self:onFellerBuncherTreesChanged()

            return true
        end
    end

    return false
end


---
function FellerBuncher:onFellerBuncherTreesChanged()
    local spec = self.spec_fellerBuncher

    if spec.fillUnitIndex ~= nil then
        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)
        self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, self:getNumLoadedTrees(), self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)
    end

    FellerBuncher.updateActionEvents(self)
    self:raiseDirtyFlags(spec.dirtyFlag)
end


---
function FellerBuncher:getNumLoadedTrees()
    local spec = self.spec_fellerBuncher
    local numTrees = 0
    if spec.mainGrab.isUsed then
        numTrees = numTrees + 1
    end

    for i=1, #spec.treeSlots do
        if spec.treeSlots[i].isUsed then
            numTrees = numTrees + 1
        end
    end

    return numTrees
end


---
function FellerBuncher:onFellerBuncherTreeShapeCut(oldShape, shape)
    if self.isServer then
        local spec = self.spec_fellerBuncher
        if oldShape == spec.mainGrab.shapeId then
            self:releaseMountedTrees()
            return
        end

        for i=1, #spec.treeSlots do
            if oldShape == spec.treeSlots[i].shapeId then
                self:releaseMountedTrees()
                return
            end
        end
    end
end


---
function FellerBuncher:onFellerBuncherTreeShapeMounted(shape, mountVehicle)
    if mountVehicle ~= self and self.isServer then
        local spec = self.spec_fellerBuncher
        if shape == spec.mainGrab.shapeId then
            self:releaseMountedTrees()
            return
        end

        for i=1, #spec.treeSlots do
            if shape == spec.treeSlots[i].shapeId then
                self:releaseMountedTrees()
                return
            end
        end
    end
end


---
function FellerBuncher:getCanToggleTurnedOn(superFunc)
    local spec = self.spec_fellerBuncher

    if spec.mountProcessInProgress then
        return false
    end

    if self:getIsAnimationPlaying(spec.mainGrab.animationName) then
        return false
    end

    if spec.unmountProcessInProgress then
        return false
    end

    return superFunc(self)
end


---
function FellerBuncher:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end


---
function FellerBuncher:getSupportsAutoTreeAlignment(superFunc)
    return true
end


---
function FellerBuncher:getAutoAlignHasValidTree(superFunc, radius)
    local spec = self.spec_fellerBuncher
    return spec.foundSplitShape ~= nil, radius <= spec.maxRadius
end


---
function FellerBuncher:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_fellerBuncher
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.releaseInputAction, self, FellerBuncher.actionEventReleaseTrees, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            g_inputBinding:setActionEventText(actionEventId, spec.texts.actionRelease)

            if spec.cutInputAction ~= nil then
                _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.cutInputAction, self, FellerBuncher.actionEventCutTree, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, spec.texts.actionCutTree)
            end

            FellerBuncher.updateActionEvents(self)
        end
    end
end


---
function FellerBuncher.actionEventReleaseTrees(self, actionName, inputValue, callbackState, isAnalog)
    self:releaseMountedTrees()
end


---
function FellerBuncher.actionEventCutTree(self, actionName, inputValue, callbackState, isAnalog)
    self:cutTree()
end


---
function FellerBuncher.updateActionEvents(self)
    if self.isClient then
        local spec = self.spec_fellerBuncher
        local actionEvent = spec.actionEvents[spec.releaseInputAction]
        if actionEvent ~= nil then
            local treesMounted = spec.mainGrab.isUsed
            if not treesMounted then
                for i=1, #spec.treeSlots do
                    if spec.treeSlots[i].isUsed then
                        treesMounted = true
                        break
                    end
                end
            end

            g_inputBinding:setActionEventActive(actionEvent.actionEventId, treesMounted)
        end

        actionEvent = spec.actionEvents[spec.cutInputAction]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.foundSplitShape ~= nil)
        end
    end
end


---
function FellerBuncher.loadSpecValueMaxTreeSize(xmlFile, customEnvironment, baseDir)
    return xmlFile:getValue("vehicle.fellerBuncher#maxRadius")
end


---
function FellerBuncher.getSpecValueMaxTreeSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.fellerBuncherMaxTreeSize ~= nil then
        local value = storeItem.specs.fellerBuncherMaxTreeSize * 2 * 100
        local str = string.format("%d%s", MathUtil.round(value), g_i18n:getText("unit_cmShort"))
        if returnValues and returnRange then
            return value, value, str
        elseif returnValues then
            return value, str
        else
            return str
        end
    end
end
