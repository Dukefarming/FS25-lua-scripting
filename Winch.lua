

























---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function Winch.prerequisitesPresent(specializations)
    return true
end


---
function Winch.initSpecialization()
    if g_iconGenerator == nil then
        g_vehicleConfigurationManager:addConfigurationType("winch", g_i18n:getText("configuration_winch"), "winch", VehicleConfigurationItem)
    end

    g_storeManager:addSpecType("winchMaxMass", "shopListAttributeIconWinchMaxMass", Winch.loadSpecValueMaxMass, Winch.getSpecValueMaxMass, StoreSpecies.VEHICLE)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Winch")

    Winch.registerXMLPaths(schema, "vehicle.winch")
    Winch.registerXMLPaths(schema, "vehicle.winch.winchConfigurations.winchConfiguration(?)")

    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.winch.winchConfigurations.winchConfiguration(?)")

    schema:setXMLSpecializationType()
end


---
function Winch.registerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.INT, baseKey .. "#controlGroupIndex", "Winch controls are only active while this cylindered control group is used")

    schema:register(XMLValueType.INT, baseKey .. ".rope(?)#maxNumTrees", "Max. number of trees that can be attached", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#maxTreeMass", "Max. tree mass that can be attached (to)", 1)

    schema:register(XMLValueType.NODE_INDEX, baseKey .. ".rope(?)#node", "Outgoing node for the rope")
    schema:register(XMLValueType.NODE_INDEX, baseKey .. ".rope(?)#triggerNode", "Trigger node to pickup the rope as player")

    schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#minLength", "Minimum length of the rope", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#maxLength", "Maximum length of the rope", 30)
    schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#maxSubLength", "Maximum length of the rope from tree to tree when attaching multiple trees to one rope", 2)

    schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#speed", "Speed when pulling the rope [m/sec]", 1.5)
    schema:register(XMLValueType.FLOAT, baseKey .. ".rope(?)#acceleration", "Acceleration (time in seconds until full speed is reached)", 1.5)

    ForestryPhysicsRope.registerXMLPaths(schema, baseKey .. ".rope(?).mainRope")
    ForestryPhysicsRope.registerXMLPaths(schema, baseKey .. ".rope(?).setupRope")

    schema:register(XMLValueType.INT, baseKey .. ".rope(?).componentJoint(?)#jointIndex", "Index of component joint")
    schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".rope(?).componentJoint(?)#limitActive", "Rotation limit of component joint while tree is attached")
    schema:register(XMLValueType.VECTOR_ROT, baseKey .. ".rope(?).componentJoint(?)#limitInactive", "Rotation limit of component joint while no tree is attached")

    schema:register(XMLValueType.NODE_INDEX, baseKey .. ".rope(?).attach#node", "Outgoing node for tree attach rope (used for dummy rope display)")
    schema:register(XMLValueType.TIME, baseKey .. ".rope(?).attach#time", "Time until the tree is fully attached", 0.5)
    TargetTreeMarker.registerXMLPaths(schema, baseKey .. ".rope(?).attach.marker")

    ForestryHook.registerXMLPaths(schema, baseKey .. ".rope(?).treeHook")

    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseKey .. ".rope(?)")

    SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "pullRope")
    SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "releaseRope")
    SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "attachTree")
    SoundManager.registerSampleXMLPaths(schema, baseKey .. ".rope(?).sounds", "detachTree")

    AnimationManager.registerAnimationNodesXMLPaths(schema, baseKey .. ".rope(?).animationNodes")

    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".winch#ropeIndices", "List of rope indices which are update while moving part changes")
    end)

    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. ".winch#ropeIndices", "List of rope indices which are update while moving part changes")
    end)

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    local key = "vehicles.vehicle(?).winch"
    schemaSavegame:register(XMLValueType.INT, key .. ".rope(?)#index", "Rope index")
    schemaSavegame:register(XMLValueType.VECTOR_TRANS, key .. ".rope(?).attachedTree(?)#translation", "Translation of attached tree")
    schemaSavegame:register(XMLValueType.INT, key .. ".rope(?).attachedTree(?)#splitShapePart1", "Split shape data part 1")
    schemaSavegame:register(XMLValueType.INT, key .. ".rope(?).attachedTree(?)#splitShapePart2", "Split shape data part 2")
    schemaSavegame:register(XMLValueType.INT, key .. ".rope(?).attachedTree(?)#splitShapePart3", "Split shape data part 3")
    ForestryPhysicsRope.registerSavegameXMLPaths(schemaSavegame, key .. ".rope(?).attachedTree(?).physicsRope")
end


---
function Winch.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadWinchRopeFromXML", Winch.loadWinchRopeFromXML)
    SpecializationUtil.registerFunction(vehicleType, "setWinchTreeAttachMode", Winch.setWinchTreeAttachMode)
    SpecializationUtil.registerFunction(vehicleType, "getIsWinchAttachModeActive", Winch.getIsWinchAttachModeActive)
    SpecializationUtil.registerFunction(vehicleType, "getCanAttachWinchTree", Winch.getCanAttachWinchTree)
    SpecializationUtil.registerFunction(vehicleType, "onAttachTreeInputEvent", Winch.onAttachTreeInputEvent)
    SpecializationUtil.registerFunction(vehicleType, "getWinchRopeSpeedFactor", Winch.getWinchRopeSpeedFactor)
    SpecializationUtil.registerFunction(vehicleType, "getIsWinchTreeAttachAllowed", Winch.getIsWinchTreeAttachAllowed)
    SpecializationUtil.registerFunction(vehicleType, "showWinchTreeMountFailedWarning", Winch.showWinchTreeMountFailedWarning)
    SpecializationUtil.registerFunction(vehicleType, "attachTreeToWinch", Winch.attachTreeToWinch)
    SpecializationUtil.registerFunction(vehicleType, "detachTreeFromWinch", Winch.detachTreeFromWinch)
    SpecializationUtil.registerFunction(vehicleType, "setWinchControlInput", Winch.setWinchControlInput)
    SpecializationUtil.registerFunction(vehicleType, "onWinchPlayerTriggerCallback", Winch.onWinchPlayerTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "onWinchTreeRaycastCallback", Winch.onWinchTreeRaycastCallback)
    SpecializationUtil.registerFunction(vehicleType, "onWinchTreeShapeCut", Winch.onWinchTreeShapeCut)
    SpecializationUtil.registerFunction(vehicleType, "onWinchTreeShapeMounted", Winch.onWinchTreeShapeMounted)
end


---
function Winch.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", Winch.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", Winch.updateExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", Winch.getDoConsumePtoPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Winch.getConsumingLoad)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowerTakeOffActive", Winch.getIsPowerTakeOffActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Winch.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Winch.removeFromPhysics)
end


---
function Winch.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Winch)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Winch)
end


---
function Winch:onLoad(savegame)
    local spec = self.spec_winch

    spec.texts = {}

    local configurationId = Utils.getNoNil(self.configurations["winch"], 1)
    local configKey = string.format("vehicle.winch.winchConfigurations.winchConfiguration(%d)", configurationId - 1)
    ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.winch.winchConfigurations.winchConfiguration", configurationId, self.components, self)

    spec.controlGroupIndex = self.xmlFile:getValue("vehicle.winch#controlGroupIndex", self.xmlFile:getValue(configKey .. "#controlGroupIndex"))

    spec.ropes = {}
    for _, ropeKey in self.xmlFile:iterator("vehicle.winch.rope") do
        local rope = {}
        if self:loadWinchRopeFromXML(self.xmlFile, ropeKey, rope) then
            table.insert(spec.ropes, rope)
            rope.index = #spec.ropes
        end
    end

    for _, ropeKey in self.xmlFile:iterator(configKey .. ".rope") do
        local rope = {}
        if self:loadWinchRopeFromXML(self.xmlFile, ropeKey, rope) then
            table.insert(spec.ropes, rope)
            rope.index = #spec.ropes
        end
    end

    if #spec.ropes > 0 then
        spec.hasRopes = true

        spec.texts.startAttachMode = g_i18n:getText("input_WINCH_ATTACH_MODE")
        spec.texts.stopAttachMode = g_i18n:getText("winch_releaseRope")
        spec.texts.attachTree = g_i18n:getText("input_WINCH_ATTACH")
        spec.texts.attachAnotherTree = g_i18n:getText("winch_attachAnotherTree")
        spec.texts.detachTree = g_i18n:getText("input_WINCH_DETACH")
        spec.texts.control = g_i18n:getText("winch_control")
        spec.texts.warningTooHeavy = g_i18n:getText("winch_treeTooHeavy")
        spec.texts.warningMaxNumTreesReached = g_i18n:getText("winch_maxNumTreesReached")
        spec.texts.warningMaxLengthReached = g_i18n:getText("winch_ropeMaxLengthReached")

        spec.treeRaycast = {}
        spec.treeRaycast.hasStarted = false
        spec.treeRaycast.startPos = {0, 0, 0}
        spec.treeRaycast.treeTargetPos = {0, 0, 0}
        spec.treeRaycast.treeCenterPos = {0, 0, 0}
        spec.treeRaycast.treeUp = {0, 1, 0}
        spec.treeRaycast.treeRadius = 1
        spec.treeRaycast.maxDistance = math.huge

        spec.splitShapesToAttach = {}

        spec.isAttachable = SpecializationUtil.hasSpecialization(Attachable, self.specializations)

        g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onWinchTreeShapeCut, self)
        g_messageCenter:subscribe(MessageType.TREE_SHAPE_MOUNTED, self.onWinchTreeShapeMounted, self)

        spec.dirtyFlag = self:getNextDirtyFlag()
        spec.ropeDirtyFlag = self:getNextDirtyFlag()
    else
        SpecializationUtil.removeEventListener(self, "onLoadFinished", Winch)
        SpecializationUtil.removeEventListener(self, "onDelete", Winch)
        SpecializationUtil.removeEventListener(self, "onReadStream", Winch)
        SpecializationUtil.removeEventListener(self, "onWriteStream", Winch)
        SpecializationUtil.removeEventListener(self, "onReadUpdateStream", Winch)
        SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", Winch)
        SpecializationUtil.removeEventListener(self, "onPostUpdate", Winch)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Winch)
    end
end


---
function Winch:onLoadFinished(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local specKey = savegame.key .. ".winch"

        savegame.xmlFile:iterate(specKey .. ".rope", function(_, ropeKey)
            local ropeIndex = savegame.xmlFile:getValue(ropeKey .. "#index", 1)
            savegame.xmlFile:iterate(ropeKey .. ".attachedTree", function(_, attachedTreeKey)
                local translation = savegame.xmlFile:getValue(attachedTreeKey .. "#translation", nil, true)
                if translation ~= nil then
                    local splitShapePart1 = savegame.xmlFile:getValue(attachedTreeKey .. "#splitShapePart1")
                    if splitShapePart1 ~= nil then
                        local splitShapePart2 = savegame.xmlFile:getValue(attachedTreeKey .. "#splitShapePart2")
                        local splitShapePart3 = savegame.xmlFile:getValue(attachedTreeKey .. "#splitShapePart3")

                        local positionData = ForestryPhysicsRope.loadPositionDataFromSavegame(savegame.xmlFile, attachedTreeKey .. ".physicsRope")

                        local shapeId = getShapeFromSaveableSplitShapeId(splitShapePart1, splitShapePart2, splitShapePart3)
                        if shapeId ~= nil and shapeId ~= 0 then
                            self:attachTreeToWinch(shapeId, translation[1], translation[2], translation[3], ropeIndex, positionData, true)
                        end
                    end
                end
            end)
        end)
    end
end


---Called on deleting
function Winch:onDelete()
    local spec = self.spec_winch

    if spec.ropes ~= nil then
        for i=1, #spec.ropes do
            local rope = spec.ropes[i]

            self:detachTreeFromWinch(i, true)

            removeTrigger(rope.triggerNode)

            rope.mainRope:delete()
            rope.setupRope:delete()
            rope.attachMarker:delete()
            rope.hookData:delete()

            if self.isClient then
                g_soundManager:deleteSamples(rope.samples)
                g_animationManager:deleteAnimations(rope.animationNodes)
            end

            g_currentMission.activatableObjectsSystem:removeActivatable(rope.attachTreeActivatable)
            g_currentMission.activatableObjectsSystem:removeActivatable(rope.controlActivatable)
        end
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function Winch:onReadStream(streamId, connection)
    local spec = self.spec_winch
    for ropeIndex=1, #spec.ropes do
        local rope = spec.ropes[ropeIndex]
        if streamReadBool(streamId) then
            local numTrees = streamReadUIntN(streamId, rope.maxTreeBits) + 1
            for j=1, numTrees do
                local x, y, z = streamReadFloat32(streamId), streamReadFloat32(streamId), streamReadFloat32(streamId)

                local splitShapeId, splitShapeId1, splitShapeId2 = readSplitShapeIdFromStream(streamId)
                if splitShapeId ~= 0 then
                    x, y, z = localToWorld(splitShapeId, x, y, z)
                    self:attachTreeToWinch(splitShapeId, x, y, z, ropeIndex, nil, true)
                elseif splitShapeId1 ~= 0 then
                    table.insert(spec.splitShapesToAttach, {splitShapeId1=splitShapeId1, splitShapeId2=splitShapeId2, x=x, y=y, z=z, ropeIndex=ropeIndex})
                end
            end
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function Winch:onWriteStream(streamId, connection)
    local spec = self.spec_winch

    for i=1, #spec.ropes do
        local rope = spec.ropes[i]
        if streamWriteBool(streamId, #rope.attachedTrees > 0) then
            streamWriteUIntN(streamId, #rope.attachedTrees - 1, rope.maxTreeBits)

            for j=1, #rope.attachedTrees do
                local attachData = rope.attachedTrees[j]

                local x, y, z = worldToLocal(attachData.treeId, getWorldTranslation(attachData.activeHookData.hookId))
                streamWriteFloat32(streamId, x)
                streamWriteFloat32(streamId, y)
                streamWriteFloat32(streamId, z)

                writeSplitShapeIdToStream(streamId, attachData.treeId)
            end
        end
    end
end


---
function Winch:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_winch

    if not connection:getIsServer() then
        if streamReadBool(streamId) then
            for i=1, #spec.ropes do
                self:setWinchControlInput(i, streamReadUIntN(streamId, 2) - 1)
            end
        end
    else
        if streamReadBool(streamId) then
            for i=1, #spec.ropes do
                local rope = spec.ropes[i]
                rope.controlDirection = streamReadUIntN(streamId, 2) - 1
                rope.lastControlTimer = 500

                if rope.controlDirection > 0 then
                    if not g_soundManager:getIsSamplePlaying(rope.samples.pullRope) then
                        g_soundManager:playSample(rope.samples.pullRope)
                        g_soundManager:stopSample(rope.samples.releaseRope)
                    end
                    g_animationManager:startAnimations(rope.animationNodes)
                elseif rope.controlDirection < 0 then
                    if not g_soundManager:getIsSamplePlaying(rope.samples.releaseRope) then
                        g_soundManager:playSample(rope.samples.releaseRope)
                        g_soundManager:stopSample(rope.samples.pullRope)
                    end
                    g_animationManager:startAnimations(rope.animationNodes)
                end
            end
        end

        if streamReadBool(streamId) then
            for i=1, #spec.ropes do
                local rope = spec.ropes[i]
                rope.mainRope:readUpdateStream(streamId)
            end
        end
    end
end


---
function Winch:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_winch

    if connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            for i=1, #spec.ropes do
                streamWriteUIntN(streamId, math.sign(spec.ropes[i].controlInputSent) + 1, 2)
            end
        end
    else
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            for i=1, #spec.ropes do
                streamWriteUIntN(streamId, math.sign(spec.ropes[i].controlDirection) + 1, 2)
            end
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, spec.ropeDirtyFlag) ~= 0) then
            for i=1, #spec.ropes do
                local rope = spec.ropes[i]
                rope.mainRope:writeUpdateStream(streamId)
            end
        end
    end
end


---
function Winch:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_winch

    local saveIndex = 0
    for i=1, #spec.ropes do
        local rope = spec.ropes[i]
        if #rope.attachedTrees > 0 then
            local ropeKey = string.format("%s.rope(%d)", key, saveIndex)
            xmlFile:setValue(ropeKey.."#index", i)

            for j=1, #rope.attachedTrees do
                local attachData = rope.attachedTrees[j]
                local treeKey = string.format("%s.attachedTree(%d)", ropeKey, j - 1)
                xmlFile:setValue(treeKey.."#translation", getWorldTranslation(attachData.activeHookData.hookId))

                local splitShapePart1, splitShapePart2, splitShapePart3 = getSaveableSplitShapeId(attachData.treeId)
                if splitShapePart1 ~= 0 and splitShapePart1 ~= nil then
                    xmlFile:setValue(treeKey .. "#splitShapePart1", splitShapePart1)
                    xmlFile:setValue(treeKey .. "#splitShapePart2", splitShapePart2)
                    xmlFile:setValue(treeKey .. "#splitShapePart3", splitShapePart3)
                end

                rope.mainRope:saveToXMLFile(xmlFile, treeKey .. ".physicsRope")
            end

            saveIndex = saveIndex + 1
        end
    end
end


---
function Winch:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_winch

    if not self.isServer then
        for i=#spec.splitShapesToAttach, 1, -1 do
            local attachData = spec.splitShapesToAttach[i]
            local splitShapeId = resolveStreamSplitShapeId(attachData.splitShapeId1, attachData.splitShapeId2)
            if splitShapeId ~= 0 then
                local x, y, z = localToWorld(splitShapeId, attachData.x, attachData.y, attachData.z)
                self:attachTreeToWinch(splitShapeId, x, y, z, attachData.ropeIndex, nil, true)

                table.remove(spec.splitShapesToAttach, i)
            end
        end
    else
        for i=1, #spec.ropes do
            local rope = spec.ropes[i]
            for j=1, #rope.attachedTrees do
                local attachData = rope.attachedTrees[j]
                if attachData.treeId == nil or not entityExists(attachData.treeId) then
                    -- in case the tree was removed while it was attached (e.g. sold)
                    self:detachTreeFromWinch()
                    break
                end
            end
        end
    end

    for i=1, #spec.ropes do
        local rope = spec.ropes[i]
        if rope.isAttachModeActive then
            local player = g_localPlayer
            if player ~= nil then
                if not player:getIsHoldingHandTool() and player.isControlled then
                    local cameraNode = player:getCurrentCameraNode()
                    local x, y, z = localToWorld(cameraNode, 0, 0, 1.0)
                    local dx, dy, dz = localDirectionToWorld(cameraNode, 0, 0, -1)

                    local sx, sy, sz
                    if #rope.attachedTrees > 0 then
                        local rootData = rope.attachedTrees[1]
                        sx, sy, sz = rootData.activeHookData:getRopeTargetPosition()
                    else
                        sx, sy, sz = getWorldTranslation(rope.attachNode)
                    end

                    local maxRopeLength = #rope.attachedTrees > 0 and rope.maxSubLength or rope.maxLength
                    local lengthExtension = #rope.attachedTrees > 0 and 2 or 7.5

                    if not spec.treeRaycast.hasStarted then
                        spec.treeRaycast.hasStarted = true
                        spec.treeRaycast.isFirstAttachment = #rope.attachedTrees == 0
                        spec.treeRaycast.maxDistance = maxRopeLength
                        spec.treeRaycast.startPos[1], spec.treeRaycast.startPos[2], spec.treeRaycast.startPos[3] = sx, sy, sz

                        raycastClosestAsync(x, y, z, dx, dy, dz,  Winch.TREE_RAYCAST_DISTANCE, "onWinchTreeRaycastCallback", self, CollisionFlag.TREE)
                    end

                    if rope.setupRope.physicsRopeIndex == nil then
                        local kinematicHelperNode = player.hands.spec_hands.kinematicNode

                        if #rope.attachedTrees == 0 then
                            rope.setupRope:setMaxLength(rope.maxLength + lengthExtension)
                            rope.setupRope:create(kinematicHelperNode, kinematicHelperNode, nil, nil, false)
                        else
                            local rootData = rope.attachedTrees[1]
                            rope.setupRope:setMaxLength(math.max(rope.maxSubLength, calcDistanceFrom(kinematicHelperNode, rootData.activeHookData:getRopeTarget())) + lengthExtension)
                            rope.setupRope:create(kinematicHelperNode, kinematicHelperNode, rootData.treeId, rootData.activeHookData:getRopeTarget(), false)
                        end

                        rope.setupRope:setUseDynamicLength(true)
                    end

                    local lengthPercentage = rope.setupRope:getRopeDirectLengthPercentage(rope.setupRope.maxLength - lengthExtension)
                    if lengthPercentage > 1 then
                        if (lengthPercentage - 1) * maxRopeLength > lengthExtension * 0.75 then
                            self:setWinchTreeAttachMode(rope, false)
                            spec.treeRaycast.lastValidTree = nil
                        else
                            g_currentMission:showBlinkingWarning(spec.texts.warningMaxLengthReached, 1000)
                        end
                    end

                    if spec.treeRaycast.lastValidTree ~= nil then
                        rope.setupRope:setEmissiveColor(0, 1, 0, 1)
                    elseif spec.treeRaycast.lastInValidTree ~= nil then
                        rope.setupRope:setEmissiveColor(1, 0, 0, 1)
                    else
                        local r, g, b, a = 0, 1, 0, 1
                        if lengthPercentage > 1 then
                            r, g, b, a = 1, 0, 0, 1
                        end
                        rope.setupRope:setEmissiveColor(r, g, b, a)
                    end
                else
                    self:setWinchTreeAttachMode(rope, false)
                    spec.treeRaycast.lastValidTree = nil
                end
            end

            if spec.treeRaycast.lastValidTree ~= nil then
                rope.attachMarker:setIsActive(true)
                rope.attachMarker:setPosition(spec.treeRaycast.treeCenterPos[1], spec.treeRaycast.treeCenterPos[2], spec.treeRaycast.treeCenterPos[3], spec.treeRaycast.treeUp[1], spec.treeRaycast.treeUp[2], spec.treeRaycast.treeUp[3], spec.treeRaycast.treeRadius)
            else
                rope.attachMarker:setIsActive(false)
            end

            self:raiseActive()
        end

        if rope.lastControlTimer > 0 then
            rope.lastControlTimer = rope.lastControlTimer - dt
            if rope.lastControlTimer <= 0 then
                rope.controlDirection = 0
                rope.curSpeedAlpha = 0

                g_soundManager:stopSample(rope.samples.pullRope)
                g_soundManager:stopSample(rope.samples.releaseRope)
                g_animationManager:stopAnimations(rope.animationNodes)
            end

            self:raiseActive()
        end
    end
end


---
function Winch:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_winch
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local actionsAllowed = true
            if spec.controlGroupIndex ~= nil then
                if spec.controlGroupIndex ~= self.spec_cylindered.currentControlGroupIndex then
                    actionsAllowed = false
                end
            end

            if actionsAllowed then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.WINCH_CONTROL_VEHICLE, self, Winch.actionEventControl, false, false, true, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, spec.texts.control)

                _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.WINCH_DETACH, self, Winch.actionEventDetach, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, spec.texts.detachTree)

                Winch.updateActionEvents(self)
            end
        end
    end
end


---
function Winch.actionEventControl(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_winch
    for i=1, #spec.ropes do
        self:setWinchControlInput(i, inputValue)
    end
end


---
function Winch.actionEventDetach(self, actionName, inputValue, callbackState, isAnalog)
    self:detachTreeFromWinch()
end


---
function Winch.updateActionEvents(self)
    if self.isClient then
        local spec = self.spec_winch

        local treesAttached = false
        for i=1, #spec.ropes do
            if #spec.ropes[i].attachedTrees > 0 then
                treesAttached = true
                break
            end
        end

        local actionEventControl = spec.actionEvents[InputAction.WINCH_CONTROL_VEHICLE]
        if actionEventControl ~= nil then
            g_inputBinding:setActionEventActive(actionEventControl.actionEventId, treesAttached)
        end

        local actionEventDetach = spec.actionEvents[InputAction.WINCH_DETACH]
        if actionEventDetach ~= nil then
            g_inputBinding:setActionEventActive(actionEventDetach.actionEventId, treesAttached)
        end
    end
end


---
function Winch:loadWinchRopeFromXML(xmlFile, key, rope)
    rope.ropeNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    rope.triggerNode = xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings)

    rope.maxNumTrees = xmlFile:getValue(key .. "#maxNumTrees", 1)
    rope.maxTreeBits = math.ceil(math.sqrt(rope.maxNumTrees))

    rope.maxTreeMass = xmlFile:getValue(key .. "#maxTreeMass", 1)
    rope.minLength = xmlFile:getValue(key .. "#minLength", 1)
    rope.maxLength = xmlFile:getValue(key .. "#maxLength", 30)
    rope.maxSubLength = xmlFile:getValue(key .. "#maxSubLength", 2)
    rope.speed = xmlFile:getValue(key .. "#speed", 1.5) * 0.001
    rope.acceleration = (1 / xmlFile:getValue(key .. "#acceleration", 1.5)) * 0.001
    rope.curSpeedAlpha = 0

    rope.attachNode = xmlFile:getValue(key .. ".attach#node", nil, self.components, self.i3dMappings)
    if rope.ropeNode == nil or rope.triggerNode == nil or rope.attachNode == nil then
        return false
    end

    addTrigger(rope.triggerNode, "onWinchPlayerTriggerCallback", self)

    rope.jointComponent = self:getParentComponent(rope.ropeNode)

    rope.mainRope = ForestryPhysicsRope.new(self, rope.jointComponent, rope.ropeNode, self.isServer)
    rope.mainRope:loadFromXML(xmlFile, key .. ".mainRope", rope.minLength, rope.maxLength)

    rope.setupRope = ForestryPhysicsRope.new(self, rope.jointComponent, rope.ropeNode, true)
    rope.setupRope:loadFromXML(xmlFile, key .. ".setupRope", rope.minLength, rope.maxLength)

    rope.componentJoints = {}
    xmlFile:iterate(key .. ".componentJoint", function(_, jointKey)
        local componentJoint = {}
        componentJoint.index = xmlFile:getValue(jointKey .. "#jointIndex")
        if componentJoint.index ~= nil then
            componentJoint.jointDesc = self.componentJoints[componentJoint.index]
            componentJoint.limitActive = xmlFile:getValue(jointKey .. "#limitActive", nil, true)
            componentJoint.limitInactive = xmlFile:getValue(jointKey .. "#limitInactive", nil, true)
            if componentJoint.limitActive ~= nil and componentJoint.limitInactive ~= nil then
                table.insert(rope.componentJoints, componentJoint)
            end
        end
    end)

    rope.attachMarker = TargetTreeMarker.new(self, self.rootNode)
    rope.attachMarker:loadFromXML(xmlFile, key .. ".attach.marker")
    rope.attachTime = xmlFile:getValue(key .. ".attach#time", 0.5)

    rope.hookData = ForestryHook.new(self, self.rootNode)
    rope.hookData:loadFromXML(xmlFile, key .. ".treeHook")
    rope.hookData:setVisibility(false)

    rope.changeObjects = {}
    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, rope.changeObjects, self.components, self)
    ObjectChangeUtil.setObjectChanges(rope.changeObjects, false, self, self.setMovingToolDirty)

    rope.isPlayerInRange = false
    rope.isAttachModeActive = false

    rope.attachedTrees = {}

    rope.controlDirection = 0
    rope.lastControlTimer = 0

    rope.controlInputSent = 0

    rope.samples = {}
    if self.isClient then
        rope.samples.pullRope = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "pullRope", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        rope.samples.releaseRope = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "releaseRope", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
        rope.samples.attachTree = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "attachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        rope.samples.detachTree = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "detachTree", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)

        rope.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
    end

    rope.attachTreeActivatable = WinchAttachTreeActivatable.new(self, rope)
    rope.controlActivatable = WinchControlRopeActivatable.new(self, rope)

    return true
end


---
function Winch:setWinchTreeAttachMode(rope, state)
    if state == nil then
        state = not rope.isAttachModeActive
    end

    if state ~= rope.isAttachModeActive then
        if state then
            g_currentMission.activatableObjectsSystem:removeActivatable(rope.controlActivatable)
            g_currentMission.activatableObjectsSystem:removeActivatable(rope.attachTreeActivatable)
            g_currentMission.activatableObjectsSystem:addActivatable(rope.attachTreeActivatable)

            self:raiseActive()
        else
            rope.attachMarker:setIsActive(false)
            rope.setupRope:destroy()

            if not rope.isPlayerInRange then
                g_currentMission.activatableObjectsSystem:removeActivatable(rope.attachTreeActivatable)
            end

            if #rope.attachedTrees > 0 then
                g_currentMission.activatableObjectsSystem:addActivatable(rope.controlActivatable)
            end
        end

        rope.isAttachModeActive = state
    end
end


---
function Winch:getIsWinchAttachModeActive(rope)
    return rope.isAttachModeActive
end


---
function Winch:getCanAttachWinchTree(rope)
    if rope.isAttachModeActive then
        local spec = self.spec_winch
        return spec.treeRaycast.lastValidTree ~= nil
    end

    return false
end


---
function Winch:onAttachTreeInputEvent(rope)
    if rope.isAttachModeActive then
        local spec = self.spec_winch
        if spec.treeRaycast.lastValidTree ~= nil then
            if g_server ~= nil then
                local isAllowed, reason = self:getIsWinchTreeAttachAllowed(rope.index, spec.treeRaycast.lastValidTree)
                if isAllowed then
                    self:attachTreeToWinch(spec.treeRaycast.lastValidTree, spec.treeRaycast.treeTargetPos[1], spec.treeRaycast.treeTargetPos[2], spec.treeRaycast.treeTargetPos[3], rope.index, nil)
                else
                    self:showWinchTreeMountFailedWarning(rope.index, reason)
                end
            else
                g_client:getServerConnection():sendEvent(TreeAttachRequestEvent.new(self, spec.treeRaycast.lastValidTree, spec.treeRaycast.treeTargetPos[1], spec.treeRaycast.treeTargetPos[2], spec.treeRaycast.treeTargetPos[3], rope.index, rope.setupRope))
            end

            self:setWinchTreeAttachMode(rope, false)
            spec.treeRaycast.lastValidTree = nil
        end
    end
end


---
function Winch:getWinchRopeSpeedFactor(param)
    local spec = self.spec_winch
    for i=1, #spec.ropes do
        if tostring(i) == param then
            return spec.ropes[i].controlDirection
        end
    end

    return 1
end


---
function Winch:getIsWinchTreeAttachAllowed(ropeIndex, splitShapeId)
    local spec = self.spec_winch

    local rope = spec.ropes[ropeIndex]
    if rope ~= nil then
        local mass = getMass(splitShapeId)
        for i=1, #rope.attachedTrees do
            mass = mass + getMass(rope.attachedTrees[i].treeId)
        end
        if mass > rope.maxTreeMass then
            return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY
        end

        if #rope.attachedTrees >= rope.maxNumTrees then
            return false, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_MANY
        end
    end

    return true, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_DEFAULT
end


---
function Winch:showWinchTreeMountFailedWarning(ropeIndex, reason)
    local spec = self.spec_winch
    local rope = spec.ropes[ropeIndex]
    if rope ~= nil then
        if reason == TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_HEAVY then
            g_currentMission:showBlinkingWarning(string.format(spec.texts.warningTooHeavy, rope.maxTreeMass), 2500)
        elseif reason == TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_TOO_MANY then
            g_currentMission:showBlinkingWarning(spec.texts.warningMaxNumTreesReached, 2500)
        end
    end
end


---
function Winch:attachTreeToWinch(splitShapeId, x, y, z, ropeIndex, setupRopeData, noEventSend)
    local rope = self.spec_winch.ropes[ropeIndex]
    if rope ~= nil then
        local attachData = {}
        attachData.activeHookData = rope.hookData:clone()
        local centerX, _, _ = attachData.activeHookData:mountToTree(splitShapeId, x, y, z, 4)
        if centerX == nil then
            return
        end

        if #rope.attachedTrees == 0 then
            attachData.activeHookData:setTargetNode(rope.ropeNode, true)

            if setupRopeData ~= nil then
                rope.mainRope:applySavegamePositions(setupRopeData)
            else
                rope.mainRope:copyNodePositions(rope.setupRope, true)
            end

            rope.mainRope:create(splitShapeId, attachData.activeHookData:getRopeTarget(), nil, nil, true, true)
        else
            local rootData = rope.attachedTrees[1]
            attachData.activeHookData:setTargetNode(rootData.activeHookData:getRopeTarget(), true)

            local startActor = splitShapeId
            local startNode = attachData.activeHookData:getRopeTarget()

            local endActor = rootData.treeId
            local endNode = rootData.activeHookData:getRopeTarget()

            local additionalRope = rope.mainRope:clone(startActor, startNode, calcDistanceFrom(startNode, endNode))
            additionalRope:create(endActor, endNode)

            attachData.additionalRope = additionalRope
        end

        attachData.treeId = splitShapeId

        table.insert(rope.attachedTrees, attachData)

        for j=1, #rope.componentJoints do
            local componentJoint = rope.componentJoints[j]
            local limit = componentJoint.limitActive
            self:setComponentJointRotLimit(componentJoint.jointDesc, 1, -limit[1], limit[1])
            self:setComponentJointRotLimit(componentJoint.jointDesc, 2, -limit[2], limit[2])
            self:setComponentJointRotLimit(componentJoint.jointDesc, 3, -limit[3], limit[3])
        end

        ObjectChangeUtil.setObjectChanges(rope.changeObjects, true, self, self.setMovingToolDirty)

        if self.isClient then
            if rope.samples.attachTree ~= nil and rope.samples.attachTree.soundNode ~= nil then
                g_soundManager:playSample(rope.samples.attachTree)
                setWorldTranslation(rope.samples.attachTree.soundNode, x, y, z)
            end
        end

        g_currentMission.activatableObjectsSystem:removeActivatable(rope.controlActivatable)
        g_currentMission.activatableObjectsSystem:addActivatable(rope.controlActivatable)

        g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, splitShapeId, self)

        Winch.updateActionEvents(self)
        TreeAttachEvent.sendEvent(self, splitShapeId, x, y, z, ropeIndex, noEventSend)
    end
end


---
function Winch:detachTreeFromWinch(ropeIndex, noEventSend)
    local spec = self.spec_winch
    for i=1, #spec.ropes do
        if ropeIndex == nil or i == ropeIndex then
            local rope = spec.ropes[i]

            if rope.isAttachModeActive then
                self:setWinchTreeAttachMode(rope, false)
            end

            for ti=#rope.attachedTrees, 1, -1 do
                local attachData = rope.attachedTrees[ti]

                if not self.isDeleting then
                    if ti == 1 and self.isClient then
                        local x, y, z = attachData.activeHookData:getRopeTargetPosition()
                        if rope.samples.detachTree ~= nil and rope.samples.detachTree.soundNode ~= nil then
                            if not g_soundManager:getIsSamplePlaying(rope.samples.pullRope) then
                                g_soundManager:playSample(rope.samples.detachTree)
                                setWorldTranslation(rope.samples.detachTree.soundNode, x, y, z)
                            end
                        end
                    end
                end

                if attachData.additionalRope ~= nil then
                    attachData.additionalRope:destroy()
                    attachData.additionalRope:delete()
                    attachData.additionalRope = nil
                end

                attachData.activeHookData:delete()
                rope.mainRope:destroy()

                rope.attachedTrees[ti] = nil
            end

            if self.isServer then
                for j=1, #rope.componentJoints do
                    local componentJoint = rope.componentJoints[j]
                    local limit = componentJoint.limitInactive
                    self:setComponentJointRotLimit(componentJoint.jointDesc, 1, -limit[1], limit[1])
                    self:setComponentJointRotLimit(componentJoint.jointDesc, 2, -limit[2], limit[2])
                    self:setComponentJointRotLimit(componentJoint.jointDesc, 3, -limit[3], limit[3])
                end
            end

            ObjectChangeUtil.setObjectChanges(rope.changeObjects, false, self, self.setMovingToolDirty)

            g_currentMission.activatableObjectsSystem:removeActivatable(rope.controlActivatable)
            if rope.isPlayerInRange then
                g_currentMission.activatableObjectsSystem:addActivatable(rope.attachTreeActivatable)
            end
        end
    end

    Winch.updateActionEvents(self)
    TreeDetachEvent.sendEvent(self, ropeIndex, noEventSend)
end


---
function Winch:setWinchControlInput(ropeIndex, direction)
    local spec = self.spec_winch
    if not spec.isAttachable or self:getAttacherVehicle() ~= nil then
        local rope = spec.ropes[ropeIndex]
        if rope ~= nil then
            if self.isServer then
                if direction ~= 0 then
                    if #rope.attachedTrees >= 1 then
                        if direction ~= 0 then
                            rope.curSpeedAlpha = math.min(rope.curSpeedAlpha + g_currentDt * rope.acceleration, 1)
                        end

                        local controlDirection = rope.mainRope:adjustLength(-(rope.speed * rope.curSpeedAlpha) * g_currentDt * direction)
                        if controlDirection ~= 0 then
                            rope.controlDirection = controlDirection
                            rope.lastControlTimer = 500
                        end

                        if self.isClient then
                            if rope.controlDirection > 0 then
                                if not g_soundManager:getIsSamplePlaying(rope.samples.pullRope) then
                                    g_soundManager:playSample(rope.samples.pullRope)
                                    g_soundManager:stopSample(rope.samples.releaseRope)
                                end
                                g_animationManager:startAnimations(rope.animationNodes)
                            elseif rope.controlDirection < 0 then
                                if not g_soundManager:getIsSamplePlaying(rope.samples.releaseRope) then
                                    g_soundManager:playSample(rope.samples.releaseRope)
                                    g_soundManager:stopSample(rope.samples.pullRope)
                                end
                                g_animationManager:startAnimations(rope.animationNodes)
                            end
                        end

                        self:raiseDirtyFlags(spec.dirtyFlag)
                        self:raiseDirtyFlags(spec.ropeDirtyFlag)
                    end
                end
            else
                rope.controlInputSent = direction
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
        end
    end
end


---Callback when trigger changes state
-- @param integer triggerId
-- @param integer otherId
-- @param boolean onEnter
-- @param boolean onLeave
-- @param boolean onStay
function Winch:onWinchPlayerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    local spec = self.spec_winch
    if not spec.isAttachable or self:getAttacherVehicle() ~= nil then
        if onEnter or onLeave then
            if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
                for i=1, #spec.ropes do
                    local rope = spec.ropes[i]
                    if rope.triggerNode == triggerId then
                        if onEnter then
                            rope.isPlayerInRange = true

                            g_currentMission.activatableObjectsSystem:addActivatable(rope.attachTreeActivatable)
                        else
                            rope.isPlayerInRange = false
                            if not rope.isAttachModeActive then
                                g_currentMission.activatableObjectsSystem:removeActivatable(rope.attachTreeActivatable)
                            end
                        end

                        break
                    end
                end
            end
        end
    end
end


---
function Winch:onWinchTreeRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    local spec = self.spec_winch
    if hitObjectId ~= 0 and getHasClassId(hitObjectId, ClassIds.SHAPE) and getSplitType(hitObjectId) ~= 0 then
        if isLast then
            spec.treeRaycast.hasStarted = false

            if getRigidBodyType(shapeId) == RigidBodyType.STATIC then
                if not spec.treeRaycast.isFirstAttachment then
                    spec.treeRaycast.lastValidTree = nil
                    return false
                end
            end

            for i=1, #spec.ropes do
                local rope = spec.ropes[i]
                for j=1, #rope.attachedTrees do
                    local attachData = rope.attachedTrees[j]
                    if attachData.treeId == hitObjectId then
                        spec.treeRaycast.lastValidTree = nil
                        return false
                    end
                end
            end

            local centerX, centerY, centerZ, upX, upY, upZ, radius = SplitShapeUtil.getTreeOffsetPosition(hitObjectId, x, y, z, 4, 0.15)
            if centerX ~= nil then
                local distanceToStart = MathUtil.vector3Length(spec.treeRaycast.startPos[1]-x, spec.treeRaycast.startPos[2]-y, spec.treeRaycast.startPos[3]-z)
                if distanceToStart > spec.treeRaycast.maxDistance then
                    spec.treeRaycast.lastInValidTree = hitObjectId
                    spec.treeRaycast.lastValidTree = nil
                else
                    spec.treeRaycast.lastValidTree = hitObjectId
                    spec.treeRaycast.lastInValidTree = nil
                end

                spec.treeRaycast.treeTargetPos[1] = x
                spec.treeRaycast.treeTargetPos[2] = y
                spec.treeRaycast.treeTargetPos[3] = z
                spec.treeRaycast.treeCenterPos[1] = centerX
                spec.treeRaycast.treeCenterPos[2] = centerY
                spec.treeRaycast.treeCenterPos[3] = centerZ
                spec.treeRaycast.treeUp[1] = upX
                spec.treeRaycast.treeUp[2] = upY
                spec.treeRaycast.treeUp[3] = upZ
                spec.treeRaycast.treeRadius = radius
                self:raiseActive()
            else
                spec.treeRaycast.lastValidTree = nil
            end
        end

        return false
    end

    if isLast then
        spec.treeRaycast.hasStarted = false
        spec.treeRaycast.lastValidTree = nil
        spec.treeRaycast.lastInValidTree = nil
    end
end



---
function Winch:onWinchTreeShapeCut(oldShape, shape)
    if self.isServer then
        local spec = self.spec_winch
        for i=1, #spec.ropes do
            local rope = spec.ropes[i]
            for j=1, #rope.attachedTrees do
                local attachData = rope.attachedTrees[j]
                if attachData.treeId == oldShape then
                    self:detachTreeFromWinch() -- detach all trees while one of them has been cut
                    break
                end
            end
        end
    end
end


---
function Winch:onWinchTreeShapeMounted(shape, mountVehicle)
    if mountVehicle ~= self and self.isServer then
        local spec = self.spec_winch
        for i=1, #spec.ropes do
            local rope = spec.ropes[i]
            for j=1, #rope.attachedTrees do
                local attachData = rope.attachedTrees[j]
                if attachData.treeId == shape then
                    self:detachTreeFromWinch() -- detach all trees while one of them has been mounted
                    break
                end
            end
        end
    end
end


---
function Winch:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end

    entry.winchRopeIndices = xmlFile:getValue(baseName.. ".winch#ropeIndices", nil, true)

    return true
end


---
function Winch:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)

    if part.winchRopeIndices ~= nil then
        for i=1, #part.winchRopeIndices do
            local index = part.winchRopeIndices[i]
            local rope = self.spec_winch.ropes[index]
            if rope ~= nil and rope.mainRope ~= nil then
                rope.mainRope:updateAnchorNodes()
            end
        end
    end
end


---Returns if should consume pto power
-- @return boolean consume consumePtoPower
function Winch:getDoConsumePtoPower(superFunc)
    local spec = self.spec_winch
    if spec.hasRopes then
        for i=1, #spec.ropes do
            if #spec.ropes[i].attachedTrees > 0 then
                return true
            end
        end
    end

    return superFunc(self)
end


---
function Winch:getConsumingLoad(superFunc)
    local value, count = superFunc(self)

    local loadPercentage = 0
    local spec = self.spec_winch
    if spec.hasRopes then
        for i=1, #spec.ropes do
            if spec.ropes[i].lastControlTimer > 0 then
                loadPercentage = 1
            end
        end
    end

    return value + loadPercentage, count + 1
end


---
function Winch:getIsPowerTakeOffActive(superFunc)
    local spec = self.spec_winch
    if spec.hasRopes then
        for i=1, #spec.ropes do
            if #spec.ropes[i].attachedTrees > 0 then
                return true
            end
        end
    end

    return superFunc(self)
end


---
function Winch:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end

    for _, rope in ipairs(self.spec_winch.ropes) do
        if #rope.attachedTrees > 0 then
            local attachData = rope.attachedTrees[1]
            rope.mainRope:create(attachData.treeId, attachData.activeHookData:getRopeTarget(), nil, nil, true, true)
        end
    end

    return true
end


---
function Winch:removeFromPhysics(superFunc)
    for _, rope in ipairs(self.spec_winch.ropes) do
        if #rope.attachedTrees > 0 then
            rope.mainRope:destroy()
        end
    end

    return superFunc(self)
end


---
function Winch.loadSpecValueMaxMass(xmlFile, customEnvironment, baseDir)
    local maxTreeMass = 0
    xmlFile:iterate("vehicle.winch.rope", function(_, ropeKey)
        maxTreeMass = math.max(xmlFile:getValue(ropeKey .. "#maxTreeMass", 0), maxTreeMass)
    end)

    local massByConfig = {}
    xmlFile:iterate("vehicle.winch.winchConfigurations.winchConfiguration", function(index, configKey)
        local maxConfigLength = 0
        xmlFile:iterate(configKey .. ".rope", function(_, ropeKey)
            maxConfigLength = math.max(xmlFile:getValue(ropeKey .. "#maxTreeMass", 0), maxConfigLength)
        end)
        massByConfig[index] = maxConfigLength
    end)

    return {maxTreeMass=maxTreeMass, massByConfig=massByConfig}
end


---
function Winch.getSpecValueMaxMass(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem.specs.winchMaxMass ~= nil then
        local maxTreeMass = storeItem.specs.winchMaxMass.maxTreeMass
        if configurations ~= nil then
            local configId = configurations["winch"]
            maxTreeMass = storeItem.specs.winchMaxMass.massByConfig[configId] or maxTreeMass
        else
            for _, length in pairs(storeItem.specs.winchMaxMass.massByConfig) do
                maxTreeMass = math.max(length, maxTreeMass)
            end
        end

        local str = string.format("%.1f%s", maxTreeMass, g_i18n:getText("unit_tonsShort"))
        if returnValues and returnRange then
            return maxTreeMass, maxTreeMass, str
        elseif returnValues then
            return maxTreeMass, str
        elseif maxTreeMass ~= 0 then
            return str
        end
    end
end
