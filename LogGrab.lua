


















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function LogGrab.prerequisitesPresent(specializations)
    return true
end


---Called while initializing the specialization
function LogGrab.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("logGrab", g_i18n:getText("shop_configuration"), "logGrab", VehicleConfigurationItem)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("LogGrab")

    LogGrab.registerLogGrabXMLPaths(schema, "vehicle.logGrab.grab(?)")
    LogGrab.registerLogGrabXMLPaths(schema, "vehicle.logGrab.logGrabConfigurations.logGrabConfiguration(?).grab(?)")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    local key = "vehicles.vehicle(?).logGrab"
    schemaSavegame:register(XMLValueType.BOOL, key .. ".grab(?)#state", "Grab claw state")
end


---
function LogGrab.registerLogGrabXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#jointNode", "Joint node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#jointRoot", "Joint root node")
    schema:register(XMLValueType.BOOL, basePath .. "#lockAllAxis", "Lock all axis", false)
    schema:register(XMLValueType.BOOL, basePath .. "#limitYAxis", "Limit joint y axis movement (only allows movement up, but not down)", false)
    schema:register(XMLValueType.ANGLE, basePath .. "#rotLimit", "Defines the rotation limit on all axis", 10)
    schema:register(XMLValueType.BOOL, basePath .. "#unmountOnTreeCut", "Unmount trees while the wood harvester cuts the tree (only if the vehicle is a wood harvester as well)", false)
    schema:register(XMLValueType.FLOAT, basePath .. "#foldMinLimit", "Min. folding time to attach trees", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#foldMaxLimit", "Max. folding time to attach trees", 1)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".trigger#node", "Trigger node")

    schema:register(XMLValueType.INT, basePath .. ".claw(?)#componentJointIndex", "Component joint index")
    schema:register(XMLValueType.FLOAT, basePath .. ".claw(?)#dampingFactor", "Damping factor", 20)
    schema:register(XMLValueType.INT, basePath .. ".claw(?)#axis", "Grab axis", 1)
    schema:register(XMLValueType.ANGLE, basePath .. ".claw(?)#rotationOffsetThreshold", "Rotation offset threshold", 10)
    schema:register(XMLValueType.BOOL, basePath .. ".claw(?)#rotationOffsetInverted", "Invert threshold", false)
    schema:register(XMLValueType.FLOAT, basePath .. ".claw(?)#rotationOffsetTime", "Rotation offset time until mount", 1000)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".claw(?).movingTool(?)#node", "Node of moving tool to block while limit is exceeded")
    schema:register(XMLValueType.FLOAT, basePath .. ".claw(?).movingTool(?)#direction", "Direction to block the moving tool", 1)
    schema:register(XMLValueType.INT, basePath .. ".claw(?).movingTool(?)#closeDirection", "Direction in which the grab is closed (if defined the trees are locked while fully closed)")

    schema:register(XMLValueType.STRING, basePath .. ".clawAnimation#name", "Claw animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#speedScale", "Animation speed scale", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".clawAnimation#initialState", "Initial state of the grab (true: closed, false: open)", true)
    schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#lockTime", "Animation time when trees are locked", 1)
    schema:register(XMLValueType.STRING, basePath .. ".clawAnimation#inputAction", "Input action to toggle animation", "IMPLEMENT_EXTRA2")
    schema:register(XMLValueType.INT, basePath .. ".clawAnimation#controlGroupIndex", "Control group that needs to be active")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".clawAnimation#textPos", "Input text to open the claw", "action_foldBenchPos")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".clawAnimation#textNeg", "Input text to close the claw", "action_foldBenchNeg")
    schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#foldMinLimit", "Min. folding time to control claw", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".clawAnimation#foldMaxLimit", "Max. folding time to control claw", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".clawAnimation#openDuringFolding", "Claw will be opened during folding", false)
    schema:register(XMLValueType.BOOL, basePath .. ".clawAnimation#closeDuringFolding", "Claw will be closed during folding", false)

    schema:register(XMLValueType.STRING, basePath .. ".lockAnimation#name", "Lock animation played while tree joints are created and revered while joints are removed")
    schema:register(XMLValueType.FLOAT, basePath .. ".lockAnimation#speedScale", "Animation speed scale", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".lockAnimation#unlockSpeedScale", "Animation speed scale while trees are unlocked", "negative #speedScale")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".treeDetection#node", "Tree detection node")
    schema:register(XMLValueType.FLOAT, basePath .. ".treeDetection#sizeY", "Tree detection node size y", 2)
    schema:register(XMLValueType.FLOAT, basePath .. ".treeDetection#sizeZ", "Tree detection node size z", 2)

    schema:register(XMLValueType.INT, basePath .. ".componentJointLimit(?)#jointIndex", "Index of component joint to change", 1)
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".componentJointLimit(?)#limitActive", "Limit when tree is mounted")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".componentJointLimit(?)#limitInactive", "Limit when no tree is mounted")

    schema:register(XMLValueType.INT, basePath .. ".componentJointMassSetting(?)#jointIndex", "Index of component joint to change", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".componentJointMassSetting(?)#minMass", "Mass of mounted trees to use min defined value (t)", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".componentJointMassSetting(?)#maxMass", "Mass of mounted trees to use max defined value (t)", 1)
    schema:register(XMLValueType.VECTOR_3, basePath .. ".componentJointMassSetting(?)#minMaxRotDriveForce", "Max. rot drive force applied when the trees weight #minMass")
    schema:register(XMLValueType.VECTOR_3, basePath .. ".componentJointMassSetting(?)#maxMaxRotDriveForce", "Max. rot drive force applied when the trees weight #maxMass")

end


---Register custom events from this specialization
-- @param table vehicleType vehicle type
function LogGrab.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onLogGrabMountedTreesChanged")
end


---Register all functions from the specialization that can be called on vehicle level
-- @param table vehicleType vehicle type
function LogGrab.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadLogGrabFromXML", LogGrab.loadLogGrabFromXML)
    SpecializationUtil.registerFunction(vehicleType, "updateLogGrabClawState", LogGrab.updateLogGrabClawState)
    SpecializationUtil.registerFunction(vehicleType, "getGrabCanMountSplitShape", LogGrab.getGrabCanMountSplitShape)
    SpecializationUtil.registerFunction(vehicleType, "mountSplitShape", LogGrab.mountSplitShape)
    SpecializationUtil.registerFunction(vehicleType, "unmountSplitShape", LogGrab.unmountSplitShape)

    SpecializationUtil.registerFunction(vehicleType, "getIsLogGrabClawStateChangeAllowed", LogGrab.getIsLogGrabClawStateChangeAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setLogGrabClawState", LogGrab.setLogGrabClawState)
end


---Register all function overwritings
-- @param table vehicleType vehicle type
function LogGrab.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setComponentJointFrame", LogGrab.setComponentJointFrame)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getMovingToolMoveValue", LogGrab.getMovingToolMoveValue)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "onDelimbTree", LogGrab.onDelimbTree)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function LogGrab.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onCutTree", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onLogGrabMountedTreesChanged", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", LogGrab)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", LogGrab)
end


---Called on load
-- @param table savegame savegame
function LogGrab:onLoad(savegame)
    local spec = self.spec_logGrab

    spec.grabs = {}

    if self.xmlFile:hasProperty("vehicle.logGrab") then
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.trigger#node", "vehicle.logGrab.grab.trigger#node") --FS22 to FS25
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab#jointNode", "vehicle.logGrab.grab#jointNode") --FS22 to FS25
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab#jointRoot", "vehicle.logGrab.grab#jointRoot") --FS22 to FS25
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab#lockAllAxis", "vehicle.logGrab.grab#lockAllAxis") --FS22 to FS25

        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#componentJoint", "vehicle.logGrab.grab.claw#componentJointIndex") --FS22 to FS25
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#dampingFactor", "vehicle.logGrab.grab.claw#dampingFactor") --FS22 to FS25
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#axis", "vehicle.logGrab.grab.claw#axis") --FS22 to FS25
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#rotationOffsetThreshold", "vehicle.logGrab.grab.claw#rotationOffsetThreshold") --FS22 to FS25
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.logGrab.grab#rotationOffsetTime", "vehicle.logGrab.grab.claw#rotationOffsetTime") --FS22 to FS25

        local configurationId = self.configurations["logGrab"] or 1
        local configKey = string.format("vehicle.logGrab.logGrabConfigurations.logGrabConfiguration(%d)", configurationId - 1)
        self.xmlFile:iterate(configKey .. ".grab", function(_, grabKey)
            local logGrab = {}
            if self:loadLogGrabFromXML(self.xmlFile, grabKey, logGrab) then
                table.insert(spec.grabs, logGrab)
            end
        end)

        self.xmlFile:iterate("vehicle.logGrab.grab", function(_, grabKey)
            local logGrab = {}
            if self:loadLogGrabFromXML(self.xmlFile, grabKey, logGrab) then
                table.insert(spec.grabs, logGrab)
            end
        end)
    end

    if #spec.grabs == 0 then
        SpecializationUtil.removeEventListener(self, "onPostLoad", LogGrab)
        SpecializationUtil.removeEventListener(self, "onDelete", LogGrab)
        SpecializationUtil.removeEventListener(self, "onReadStream", LogGrab)
        SpecializationUtil.removeEventListener(self, "onWriteStream", LogGrab)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", LogGrab)
        SpecializationUtil.removeEventListener(self, "onCutTree", LogGrab)
        SpecializationUtil.removeEventListener(self, "onTurnedOn", LogGrab)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", LogGrab)
        SpecializationUtil.removeEventListener(self, "onLogGrabMountedTreesChanged", LogGrab)
        SpecializationUtil.removeEventListener(self, "onFoldStateChanged", LogGrab)
        SpecializationUtil.removeEventListener(self, "onFoldTimeChanged", LogGrab)
    end
end


---Called after loading
-- @param table savegame savegame
function LogGrab:onPostLoad(savegame)
    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.clawAnimation.name ~= nil then
            local state = grab.clawAnimation.initialState

            if savegame ~= nil and not savegame.resetVehicles then
                local grabKey = string.format("%s.logGrab.grab(%d)", savegame.key, i - 1)
                state = savegame.xmlFile:getValue(grabKey .. "#state", state)
            end

            if state then
                grab.clawAnimation.state = true
                self:playAnimation(grab.clawAnimation.name, 1, 0, true)
                AnimatedVehicle.updateAnimationByName(self, grab.clawAnimation.name, 9999999, true)
            end
        end

        for j=1, #grab.claws do
            local clawData = grab.claws[j]
            for ti=#clawData.movingTools, 1, -1 do
                local movingToolData = clawData.movingTools[ti]
                movingToolData.movingTool = self:getMovingToolByNode(movingToolData.node)
                if movingToolData.movingTool == nil then
                    table.remove(clawData.movingTools, ti)
                end
            end
        end
    end
end


---Called on deleting
function LogGrab:onDelete()
    local spec = self.spec_logGrab
    if spec.grabs ~= nil then
        for i=1, #spec.grabs do
            local grab = spec.grabs[i]
            if grab.callbackId ~= nil then
                removeTrigger(grab.triggerNode, grab.callbackId)
            end
        end
    end
end


---
function LogGrab:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_logGrab

    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.clawAnimation.name ~= nil then
            local grabKey = key .. string.format(".grab(%d)", i-1)
            xmlFile:setValue(grabKey.."#state", grab.clawAnimation.state)
        end
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function LogGrab:onReadStream(streamId, connection)
    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.clawAnimation.name ~= nil then
            local state = streamReadBool(streamId)
            self:setLogGrabClawState(i, state, true)
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function LogGrab:onWriteStream(streamId, connection)
    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.clawAnimation.name ~= nil then
            streamWriteBool(streamId, grab.clawAnimation.state)
        end
    end
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function LogGrab:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isServer then
        local spec = self.spec_logGrab

        for i=1, #spec.grabs do
            local grab = spec.grabs[i]

            --#debug if grab.treeDetectionNode ~= nil then
            --#debug     DebugUtil.drawCutNodeArea(grab.treeDetectionNode, grab.treeDetectionNodeSizeY, grab.treeDetectionNodeSizeZ, 1, 0, 0)
            --#debug end

            local isGrabClosed = true
            if grab.clawAnimation.name == nil then
                local triggerEmpty = next(grab.dynamicMountedShapes) == nil and next(grab.pendingDynamicMountShapes) == nil

                for j=1, #grab.claws do
                    local claw = grab.claws[j]

                    local clawState = self:updateLogGrabClawState(claw, dt, nil, triggerEmpty)
                    if g_time - grab.lastGrabChangeTime > 2500 then
                        clawState = claw.lastClawState
                    end

                    if grab.unmountOnTreeCut then
                        if self.spec_woodHarvester ~= nil then
                            if self.spec_woodHarvester.attachedSplitShape ~= nil then
                                clawState = false
                            end
                        end
                    end

                    if not clawState then
                        isGrabClosed = false
                    end
                    claw.lastClawState = clawState
                end
            else
                if grab.clawAnimation.state then
                    -- stop the closing animation as soon as all claws are over the lock limit
                    -- after the animation stopped or we are above the lockTime we mount the trees
                    if self:getIsAnimationPlaying(grab.clawAnimation.name) then
                        local clawsClosed = true
                        for j=1, #grab.claws do
                            if not self:updateLogGrabClawState(grab.claws[j], dt, true) then
                                clawsClosed = false
                            end
                        end

                        if clawsClosed then
                            self:stopAnimation(grab.clawAnimation.name)
                        end
                    end

                    if self:getIsAnimationPlaying(grab.clawAnimation.name) and self:getAnimationTime(grab.clawAnimation.name) < grab.clawAnimation.lockTime then
                        isGrabClosed = false
                    end
                else
                    if self:getAnimationTime(grab.clawAnimation.name) < grab.clawAnimation.lockTime then
                        isGrabClosed = false
                    end
                end
            end

            for shape,_ in pairs(grab.pendingDynamicMountShapes) do
                if not entityExists(shape) then
                    grab.pendingDynamicMountShapes[shape] = nil
                end
            end

            if isGrabClosed then
                for shape,_ in pairs(grab.pendingDynamicMountShapes) do
                    if grab.dynamicMountedShapes[shape] == nil then
                        if self:getGrabCanMountSplitShape(grab, shape) then
                            local jointIndex, jointTransform = self:mountSplitShape(grab, shape)
                            if jointIndex ~= nil then
                                grab.dynamicMountedShapes[shape] = {jointIndex=jointIndex, jointTransform=jointTransform}
                                grab.pendingDynamicMountShapes[shape] = nil
                            end
                        end
                    end
                end

                if not grab.jointLimitsOpen and next(grab.dynamicMountedShapes) ~= nil then
                    grab.jointLimitsOpen = true

                    for j=1, #grab.claws do
                        local claw = grab.claws[j]
                        local componentJoint = self.componentJoints[claw.componentJoint]
                        if componentJoint ~= nil then
                            for axis=1, 3 do
                                setJointRotationLimitSpring(componentJoint.jointIndex, axis-1, componentJoint.rotLimitSpring[axis], componentJoint.rotLimitDamping[axis] * claw.dampingFactor)
                            end
                        end
                    end
                end
            else
                for shapeId, shapeData in pairs(grab.dynamicMountedShapes) do
                    self:unmountSplitShape(grab, shapeId, shapeData.jointIndex, shapeData.jointTransform, false)
                end

                if grab.jointLimitsOpen then
                    grab.jointLimitsOpen = false

                    for j=1, #grab.claws do
                        local claw = grab.claws[j]
                        local componentJoint = self.componentJoints[claw.componentJoint]
                        if componentJoint ~= nil then
                            for axis=1, 3 do
                                setJointRotationLimitSpring(componentJoint.jointIndex, axis-1, componentJoint.rotLimitSpring[axis], componentJoint.rotLimitDamping[axis])
                            end
                        end
                    end
                end
            end

            if grab.lockAnimation.name ~= nil then
                local state = isGrabClosed and next(grab.dynamicMountedShapes) ~= nil
                if state ~= grab.lockAnimation.state then
                    grab.lockAnimation.state = state

                    if state then
                        self:playAnimation(grab.lockAnimation.name, grab.lockAnimation.speedScale, self:getAnimationTime(grab.lockAnimation.name))
                    else
                        self:playAnimation(grab.lockAnimation.name, grab.lockAnimation.unlockSpeedScale, self:getAnimationTime(grab.lockAnimation.name))
                    end
                end
            end

            local clawAnimationRunning = grab.clawAnimation.name ~= nil and self:getIsAnimationPlaying(grab.clawAnimation.name)
            if grab.componentLimitsDirty or clawAnimationRunning then
                local isActive = next(grab.dynamicMountedShapes) ~= nil
                for j=1, #grab.componentJointLimits do
                    local componentJointLimit = grab.componentJointLimits[j]
                    if componentJointLimit.isActive ~= isActive or clawAnimationRunning then
                        componentJointLimit.isActive = isActive
                        local alpha = next(grab.dynamicMountedShapes) ~= nil and 0 or 1
                        if grab.clawAnimation.name ~= nil and (next(grab.dynamicMountedShapes) ~= nil or next(grab.pendingDynamicMountShapes)) then
                            alpha = 1 - self:getAnimationTime(grab.clawAnimation.name)
                        end
                        local x, y, z = MathUtil.vector3Lerp(componentJointLimit.limitActive[1], componentJointLimit.limitActive[2], componentJointLimit.limitActive[3],
                                                             componentJointLimit.limitInactive[1], componentJointLimit.limitInactive[2], componentJointLimit.limitInactive[3],
                                                             alpha)
                        self:setComponentJointRotLimit(componentJointLimit.joint, 0, -x, x)
                        self:setComponentJointRotLimit(componentJointLimit.joint, 1, -y, y)
                        self:setComponentJointRotLimit(componentJointLimit.joint, 2, -z, z)
                    end
                end

                grab.componentLimitsDirty = false
            end
        end
    end
end


---
function LogGrab:loadLogGrabFromXML(xmlFile, key, logGrab)
    logGrab.claws = {}
    xmlFile:iterate(key .. ".claw", function(_, clawKey)
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, clawKey .. "#componentJoint", clawKey .. "#componentJointIndex") --FS22 to FS25

        local clawData = {}
        clawData.componentJoint = xmlFile:getValue(clawKey .. "#componentJointIndex")
        if clawData.componentJoint == nil then
            Logging.xmlWarning(xmlFile, "Missing claw componentJoint in xml. '%s'", clawKey)
            return
        end

        clawData.dampingFactor = xmlFile:getValue(clawKey .. "#dampingFactor", 20)
        clawData.axis = xmlFile:getValue(clawKey .. "#axis", 1)
        clawData.direction = {0, 0, 0}
        clawData.direction[clawData.axis] = 1

        local componentJoint = self.componentJoints[clawData.componentJoint]
        if componentJoint ~= nil then
            clawData.jointActor0 = componentJoint.jointNode
            clawData.jointActor1 = componentJoint.jointNodeActor1
            if componentJoint.jointNodeActor1 == componentJoint.jointNode then
                local actor1Reference = createTransformGroup("jointNodeActor1Reference")
                local component2 = self.components[componentJoint.componentIndices[2]]
                link(component2.node, actor1Reference)
                setWorldTranslation(actor1Reference, getWorldTranslation(componentJoint.jointNode))
                setWorldRotation(actor1Reference, getWorldRotation(componentJoint.jointNode))
                clawData.jointActor1 = actor1Reference
            end
        else
            Logging.xmlWarning(xmlFile, "Unable to load claw componentJoint from xml. '%s'", clawKey)
            return false
        end

        clawData.rotationOffsetThreshold = xmlFile:getValue(clawKey .. "#rotationOffsetThreshold", 10)
        clawData.rotationOffsetInverted = xmlFile:getValue(clawKey .. "#rotationOffsetInverted", false)
        clawData.rotationOffsetTime = xmlFile:getValue(clawKey .. "#rotationOffsetTime", 1000)
        clawData.rotationOffsetTimer = 0
        clawData.rotationChangedTimer = 0
        clawData.currentOffset = 0
        clawData.lastClawState = false

        clawData.movingTools = {}
        xmlFile:iterate(clawKey .. ".movingTool", function(_, movingToolKey)
            local movingToolData = {}
            movingToolData.node = xmlFile:getValue(movingToolKey .. "#node", nil, self.components, self.i3dMappings)
            if movingToolData.node ~= nil then
                movingToolData.direction = xmlFile:getValue(movingToolKey .. "#direction", 1)
                movingToolData.closeDirection = xmlFile:getValue(movingToolKey .. "#closeDirection")
                table.insert(clawData.movingTools, movingToolData)
            else
                Logging.xmlWarning(xmlFile, "Unable to load movingTool from xml. '%s'", movingToolKey)
            end
        end)

        table.insert(logGrab.claws, clawData)
    end)

    logGrab.clawAnimation = {}
    logGrab.clawAnimation.state = false
    logGrab.clawAnimation.name = xmlFile:getValue(key .. ".clawAnimation#name")
    logGrab.clawAnimation.speedScale = xmlFile:getValue(key .. ".clawAnimation#speedScale", 1)
    logGrab.clawAnimation.initialState = xmlFile:getValue(key .. ".clawAnimation#initialState", true)
    logGrab.clawAnimation.lockTime = xmlFile:getValue(key .. ".clawAnimation#lockTime", 1)
    logGrab.clawAnimation.inputAction = InputAction[xmlFile:getValue(key .. ".clawAnimation#inputAction", "IMPLEMENT_EXTRA2")] or InputAction.IMPLEMENT_EXTRA2
    logGrab.clawAnimation.controlGroupIndex = xmlFile:getValue(key .. ".clawAnimation#controlGroupIndex")
    logGrab.clawAnimation.textPos = xmlFile:getValue(key .. ".clawAnimation#textPos", "action_foldBenchPos", self.customEnvironment, false)
    logGrab.clawAnimation.textNeg = xmlFile:getValue(key .. ".clawAnimation#textNeg", "action_foldBenchNeg", self.customEnvironment, false)
    logGrab.clawAnimation.foldMinLimit = xmlFile:getValue(key .. ".clawAnimation#foldMinLimit", 0)
    logGrab.clawAnimation.foldMaxLimit = xmlFile:getValue(key .. ".clawAnimation#foldMaxLimit", 0)
    logGrab.clawAnimation.openDuringFolding = xmlFile:getValue(key .. ".clawAnimation#openDuringFolding", false)
    logGrab.clawAnimation.closeDuringFolding = xmlFile:getValue(key .. ".clawAnimation#closeDuringFolding", false)

    logGrab.lockAnimation = {}
    logGrab.lockAnimation.state = false
    logGrab.lockAnimation.name = xmlFile:getValue(key .. ".lockAnimation#name")
    logGrab.lockAnimation.speedScale = xmlFile:getValue(key .. ".lockAnimation#speedScale", 1)
    logGrab.lockAnimation.unlockSpeedScale = xmlFile:getValue(key .. ".lockAnimation#unlockSpeedScale", -logGrab.lockAnimation.speedScale)

    logGrab.jointNode = xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings)
    logGrab.jointRoot = xmlFile:getValue(key .. "#jointRoot", nil, self.components, self.i3dMappings)

    logGrab.lockAllAxis = xmlFile:getValue(key .. "#lockAllAxis", false)
    logGrab.limitYAxis = xmlFile:getValue(key .. "#limitYAxis", false)
    logGrab.rotLimit = xmlFile:getValue(key .. "#rotLimit", 10)

    logGrab.unmountOnTreeCut = xmlFile:getValue(key .. "#unmountOnTreeCut", false)

    logGrab.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
    logGrab.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

    logGrab.triggerNode = xmlFile:getValue(key .. ".trigger#node", nil, self.components, self.i3dMappings)
    if logGrab.triggerNode ~= nil then
        local collisionMask = getCollisionFilterMask(logGrab.triggerNode)
        if collisionMask ~= CollisionFlag.TREE then
            Logging.xmlWarning(xmlFile, "LogGrab trigger '%s' has wrong collision mask, only the Tree bit is allowed!", getName(logGrab.triggerNode))
            return
        end

        logGrab.callbackId = addTrigger(logGrab.triggerNode, "logGrabTriggerCallback", self, false, LogGrab.logGrabTriggerCallback)
    else
        Logging.xmlWarning(xmlFile, "Missing grab trigger in '%s'", key)
        return false
    end

    logGrab.pendingDynamicMountShapes = {}
    logGrab.dynamicMountedShapes = {}

    logGrab.jointLimitsOpen = false

    logGrab.treeDetectionNode = xmlFile:getValue(key .. ".treeDetection#node", nil, self.components, self.i3dMappings)
    if logGrab.treeDetectionNode == nil then
        Logging.xmlWarning(xmlFile, "Missing tree detection node in '%s'", key)
        return false
    end

    logGrab.treeDetectionNodeSizeY = xmlFile:getValue(key .. ".treeDetection#sizeY", 2)
    logGrab.treeDetectionNodeSizeZ = xmlFile:getValue(key .. ".treeDetection#sizeZ", 2)

    logGrab.componentJointLimits = {}
    xmlFile:iterate(key .. ".componentJointLimit", function(_, limitKey)
        local componentJointLimit = {}
        componentJointLimit.jointIndex = xmlFile:getValue(limitKey .. "#jointIndex")
        if componentJointLimit.jointIndex ~= nil then
            componentJointLimit.joint = self.componentJoints[componentJointLimit.jointIndex]
            componentJointLimit.limitActive = xmlFile:getValue(limitKey .. "#limitActive", nil, true)
            componentJointLimit.limitInactive = xmlFile:getValue(limitKey .. "#limitInactive", nil, true)
            if componentJointLimit.joint ~= nil and componentJointLimit.limitActive ~= nil and componentJointLimit.limitInactive ~= nil then
                componentJointLimit.isActive = false
                table.insert(logGrab.componentJointLimits, componentJointLimit)
            end
        end
    end)

    logGrab.componentJointMassSettings = {}
    xmlFile:iterate(key .. ".componentJointMassSetting", function(_, limitKey)
        local componentJointMassSetting = {}
        componentJointMassSetting.jointIndex = xmlFile:getValue(limitKey .. "#jointIndex")
        if componentJointMassSetting.jointIndex ~= nil then
            componentJointMassSetting.joint = self.componentJoints[componentJointMassSetting.jointIndex]
            componentJointMassSetting.minMass = xmlFile:getValue(limitKey .. "#minMass", 0)
            componentJointMassSetting.maxMass = xmlFile:getValue(limitKey .. "#maxMass", 1)

            componentJointMassSetting.minMaxRotDriveForce = xmlFile:getValue(limitKey .. "#minMaxRotDriveForce", nil, true)
            componentJointMassSetting.maxMaxRotDriveForce = xmlFile:getValue(limitKey .. "#maxMaxRotDriveForce", nil, true)
            componentJointMassSetting.maxRotDriveForce = {0, 0, 0}

            if componentJointMassSetting.joint ~= nil and componentJointMassSetting.minMaxRotDriveForce ~= nil and componentJointMassSetting.maxMaxRotDriveForce ~= nil then
                table.insert(logGrab.componentJointMassSettings, componentJointMassSetting)
            end
        end
    end)

    logGrab.componentLimitsDirty = false
    logGrab.lastGrabChangeTime = -math.huge

    return true
end


---
function LogGrab:updateLogGrabClawState(claw, dt, ignoreTiming, forceDirty)
    local componentJoint = self.componentJoints[claw.componentJoint]
    if componentJoint ~= nil then
        local xOff, yOff, zOff = localRotationToLocal(claw.jointActor1, claw.jointActor0, 0, 0, 0)

        local currentOffset = 0
        if claw.axis == 1 then
            currentOffset = xOff
        elseif claw.axis == 2 then
            currentOffset = yOff
        elseif claw.axis == 3 then
            currentOffset = zOff
        end

        if claw.rotationOffsetInverted then
            currentOffset = -currentOffset
        end

        local fullyClosed = true
        local hasCloseDirectionDefined = false
        for ti=1, #claw.movingTools do
            local movingToolData = claw.movingTools[ti]
            if movingToolData.closeDirection then
                local state = Cylindered.getMovingToolState(self, movingToolData.movingTool)
                if movingToolData.closeDirection > 0 then
                    fullyClosed = fullyClosed and state > 0.99
                else
                    fullyClosed = fullyClosed and state < 0.01
                end
                hasCloseDirectionDefined = true
            end
        end

        local grabClosed = currentOffset > claw.rotationOffsetThreshold
        grabClosed = grabClosed or (hasCloseDirectionDefined and fullyClosed)

        local x, y, z = getRotation(componentJoint.jointNode)
        local rotSum = x + y + z

        if grabClosed then
            claw.lastRotation = rotSum

            if claw.rotationOffsetTimer > claw.rotationOffsetTime or ignoreTiming then
                return true
            else
                claw.rotationOffsetTimer = claw.rotationOffsetTimer + dt
            end
        elseif claw.rotationOffsetTimer > 0 and not ignoreTiming then
            -- only unmount if the rotation of the componentJoint has changed -> if user opens the claw
            if (claw.lastRotation ~= nil and rotSum ~= claw.lastRotation) or forceDirty then
                claw.rotationOffsetTimer = 0
                claw.rotationChangedTimer = 750
                claw.lastRotation = nil
            else
                claw.rotationChangedTimer = math.max(claw.rotationChangedTimer - dt, 0)
                if claw.rotationChangedTimer <= 0 then
                    claw.lastRotation = rotSum
                    return true
                end
            end
        end

        claw.currentOffset = currentOffset
    end

    return false
end


---
function LogGrab:onCutTree(radius, isNewTree)
    if self.isServer then
        if radius > 0 and isNewTree then
            local spec = self.spec_logGrab
            for i=1, #spec.grabs do
                if self:getIsLogGrabClawStateChangeAllowed(i) then
                    self:setLogGrabClawState(i, true)
                end
            end
        end
    end
end


---
function LogGrab:onTurnedOn()
    if self.isServer then
        local spec = self.spec_logGrab
        for i=1, #spec.grabs do
            if self:getIsLogGrabClawStateChangeAllowed(i) then
                self:setLogGrabClawState(i, false)
            end
        end
    end
end


---
function LogGrab:onTurnedOff()
    if self.isServer then
        local spec = self.spec_logGrab
        for i=1, #spec.grabs do
            if self:getIsLogGrabClawStateChangeAllowed(i) then
                self:setLogGrabClawState(i, true)
            end
        end
    end
end


---
function LogGrab:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_logGrab
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            for i=1, #spec.grabs do
                local grab = spec.grabs[i]
                if grab.clawAnimation.name ~= nil then
                    if grab.clawAnimation.controlGroupIndex == nil or self.spec_cylindered == nil or self.spec_cylindered.currentControlGroupIndex == grab.clawAnimation.controlGroupIndex then
                        local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, grab.clawAnimation.inputAction, self, LogGrab.actionEventClawAnimation, false, true, false, true, i)
                        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                        LogGrab.updateActionEvents(self)
                    end
                end
            end
        end
    end
end


---
function LogGrab.actionEventClawAnimation(self, actionName, inputValue, callbackState, isAnalog)
    if self:getIsLogGrabClawStateChangeAllowed(callbackState) then
        self:setLogGrabClawState(callbackState, nil)
    end
end


---
function LogGrab.updateActionEvents(self)
    local spec = self.spec_logGrab

    for i=1, #spec.grabs do
        local grab = spec.grabs[i]

        local actionEvent = spec.actionEvents[grab.clawAnimation.inputAction]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, grab.clawAnimation.state and grab.clawAnimation.textNeg or grab.clawAnimation.textPos)
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsLogGrabClawStateChangeAllowed(i))
        end
    end
end


---
function LogGrab:setComponentJointFrame(superFunc, jointDesc, anchorActor)
    superFunc(self, jointDesc, anchorActor)

    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        for j=1, #grab.claws do
            local claw = grab.claws[j]
            local componentJoint = self.componentJoints[claw.componentJoint]
            if jointDesc == componentJoint then
                grab.lastGrabChangeTime = g_time
            end
        end
    end
end


---
function LogGrab:getMovingToolMoveValue(superFunc, movingTool)
    local move = superFunc(self, movingTool)

    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        for j=1, #grab.claws do
            local claw = grab.claws[j]
            for ti=1, #claw.movingTools do
                local movingToolData = claw.movingTools[ti]
                if movingToolData.movingTool == movingTool then
                    movingToolData.lastMoveValue = move
                    if claw.currentOffset > claw.rotationOffsetThreshold then
                        if math.sign(move) == movingToolData.direction then
                            move = 0
                        end
                    end
                end
            end
        end
    end

    return move
end


---
function LogGrab:onDelimbTree(superFunc, state, ...)
    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        if spec.grabs[i].clawAnimation.state then
            self:setLogGrabClawState(i, false, true)
        end
    end

    return superFunc(self, state, ...)
end


---
function LogGrab:getGrabCanMountSplitShape(grab, shapeId)
    if self.getFoldAnimTime ~= nil then
        local t = self:getFoldAnimTime()
        if t < grab.foldMinLimit or t > grab.foldMaxLimit then
            return false
        end
    end

    return true
end


---
function LogGrab:mountSplitShape(grab, shapeId)
    local constr = JointConstructor.new()
    constr:setActors(grab.jointRoot, shapeId)

    local jointTransform = createTransformGroup("dynamicMountJoint")

    local cx, cy, cz = getWorldTranslation(grab.treeDetectionNode)
    local nx, ny, nz = localDirectionToWorld(grab.treeDetectionNode, 1, 0, 0)
    local yx, yy, yz = localDirectionToWorld(grab.treeDetectionNode, 0, 1, 0)
    local minY, maxY, minZ, maxZ = testSplitShape(shapeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, grab.treeDetectionNodeSizeY, grab.treeDetectionNodeSizeZ)
    if minY ~= nil then
        link(grab.jointNode, jointTransform)
        local x, y, z = localToWorld(grab.treeDetectionNode, 0, (minY+maxY) * 0.5, (minZ+maxZ) * 0.5)
        setWorldTranslation(jointTransform, x, y, z)

        constr:setRotationLimit(0, -grab.rotLimit, grab.rotLimit)
        constr:setRotationLimit(1, -grab.rotLimit, grab.rotLimit)
        constr:setRotationLimit(2, -grab.rotLimit, grab.rotLimit)
    else
        link(grab.jointNode, jointTransform)
        setTranslation(jointTransform, 0, 0, 0)

        constr:setRotationLimit(0, 0, 0)
        constr:setRotationLimit(1, 0, 0)
        constr:setRotationLimit(2, 0, 0)
    end

    constr:setJointTransforms(jointTransform, jointTransform)

    if not grab.lockAllAxis then
        if grab.limitYAxis then
            constr:setTranslationLimit(1, true, -0.1, 2)
            constr:setTranslationLimit(2, false, 0, 0)
        else
            constr:setTranslationLimit(1, false, 0, 0)
            constr:setTranslationLimit(2, false, 0, 0)
        end
        constr:setEnableCollision(true)
    end
    local springForce = 7500
    local springDamping = 1500
    constr:setRotationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)
    constr:setTranslationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)

    grab.componentLimitsDirty = true

    g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, shapeId, self)
    SpecializationUtil.raiseEvent(self, "onLogGrabMountedTreesChanged", grab)

    return constr:finalize(), jointTransform
end


---
function LogGrab:unmountSplitShape(grab, shapeId, jointIndex, jointTransform, isDeleting)
    removeJoint(jointIndex)
    delete(jointTransform)

    grab.dynamicMountedShapes[shapeId] = nil
    if isDeleting ~= nil and isDeleting then
        grab.pendingDynamicMountShapes[shapeId] = nil
    else
        grab.pendingDynamicMountShapes[shapeId] = true
    end

    grab.componentLimitsDirty = true

    SpecializationUtil.raiseEvent(self, "onLogGrabMountedTreesChanged", grab)
end


---
function LogGrab:onLogGrabMountedTreesChanged(grab)
    if self.isServer then
        local mass = 0
        for shapeId, _ in pairs(grab.dynamicMountedShapes) do
            -- tree could be delected already by cutting it
            if entityExists(shapeId) then
                mass = mass + getMass(shapeId)
            end
        end

        for i=1, #grab.componentJointMassSettings do
            local setting = grab.componentJointMassSettings[i]
            local alpha = MathUtil.inverseLerp(setting.minMass, setting.maxMass, mass)
            setting.maxRotDriveForce[1], setting.maxRotDriveForce[1], setting.maxRotDriveForce[3] = MathUtil.vector3ArrayLerp(setting.minMaxRotDriveForce, setting.maxMaxRotDriveForce, alpha)

            local jointDesc = setting.joint
            for axis=1, 3 do
                local pos = jointDesc.rotDriveRotation[axis] or 0
                local vel = jointDesc.rotDriveVelocity[axis] or 0
                setJointAngularDrive(jointDesc.jointIndex, axis - 1, jointDesc.rotDriveRotation[axis] ~= nil, jointDesc.rotDriveVelocity[axis] ~= nil, jointDesc.rotDriveSpring[axis], jointDesc.rotDriveDamping[axis], setting.maxRotDriveForce[axis], pos, vel)
            end
        end
    end
end


---
function LogGrab:onFoldStateChanged(direction, moveToMiddle)
    local spec = self.spec_logGrab

    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.clawAnimation.openDuringFolding then
            if direction ~= self.spec_foldable.turnOnFoldDirection then
                self:setLogGrabClawState(i, false, true)
            end
        elseif grab.clawAnimation.closeDuringFolding then
            if direction ~= self.spec_foldable.turnOnFoldDirection then
                self:setLogGrabClawState(i, true, true)
            end
        end
    end
end


---
function LogGrab:onFoldTimeChanged(time)
    LogGrab.updateActionEvents(self)
end


---
function LogGrab:getIsLogGrabClawStateChangeAllowed(grabIndex)
    local spec = self.spec_logGrab
    local grab = spec.grabs[grabIndex]
    if grab ~= nil then
        if self.getFoldAnimTime ~= nil then
            local t = self:getFoldAnimTime()
            if t < grab.clawAnimation.foldMinLimit or t > grab.clawAnimation.foldMaxLimit then
                return false
            end
        end
    end

    return true
end


---
function LogGrab:setLogGrabClawState(grabIndex, state, noEventSend)
    local spec = self.spec_logGrab
    local grab = spec.grabs[grabIndex]
    if grab ~= nil then
        if state == nil then
            state = not grab.clawAnimation.state
        end
        grab.clawAnimation.state = state

        self:playAnimation(grab.clawAnimation.name, grab.clawAnimation.state and grab.clawAnimation.speedScale or -grab.clawAnimation.speedScale, self:getAnimationTime(grab.clawAnimation.name), true)
    end

    LogGrab.updateActionEvents(self)
    LogGrabClawStateEvent.sendEvent(self, state, grabIndex, noEventSend)
end


---
function LogGrab:logGrabTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.triggerNode == triggerId then
            if onEnter then
                if getSplitType(otherActorId) ~= 0 then
                    local rigidBodyType = getRigidBodyType(otherActorId)
                    if (rigidBodyType == RigidBodyType.DYNAMIC or rigidBodyType == RigidBodyType.KINEMATIC) and grab.pendingDynamicMountShapes[otherActorId] == nil then
                        grab.pendingDynamicMountShapes[otherActorId] = true
                    end
                end
            elseif onLeave then
                if getSplitType(otherActorId) ~= 0 then
                    if grab.pendingDynamicMountShapes[otherActorId] ~= nil then
                        grab.pendingDynamicMountShapes[otherActorId] = nil
                    elseif grab.dynamicMountedShapes[otherActorId] ~= nil then
                        self:unmountSplitShape(grab, otherActorId, grab.dynamicMountedShapes[otherActorId].jointIndex, grab.dynamicMountedShapes[otherActorId].jointTransform, true)
                    end
                end
            end
        end
    end
end


---
function LogGrab:addNodeObjectMapping(superFunc, list)
    superFunc(self, list)

    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.triggerNode ~= nil then
            list[grab.triggerNode] = self
        end
    end
end


---
function LogGrab:removeNodeObjectMapping(superFunc, list)
    superFunc(self, list)

    local spec = self.spec_logGrab
    for i=1, #spec.grabs do
        local grab = spec.grabs[i]
        if grab.triggerNode ~= nil then
            list[grab.triggerNode] = nil
        end
    end
end


---
function LogGrab:updateDebugValues(values)
    if self.isServer then
        local spec = self.spec_logGrab
        for i=1, #spec.grabs do
            local grab = spec.grabs[i]
            for j, claw in ipairs(grab.claws) do
                local lastMove, direction
                for ti=1, #claw.movingTools do
                    lastMove = claw.movingTools[ti].lastMoveValue
                    direction = claw.movingTools[ti].direction
                end

                local movingToolStr = ""
                if lastMove ~= nil and direction ~= nil then
                    local closing = math.sign(lastMove) == direction
                    movingToolStr = string.format(" | isClosing: %s (%.2f/%d)", closing, lastMove, direction)
                end

                table.insert(values, {name=string.format("grab (%d) claw (%d):", i, j), value=string.format("current: %.2fdeg / threshold: %.2fdeg  (timer: %d)%s", math.deg(claw.currentOffset), math.deg(claw.rotationOffsetThreshold), claw.rotationOffsetTimer, movingToolStr)})
            end

            for shapeId, _ in pairs(grab.dynamicMountedShapes) do
                if entityExists(shapeId) then
                    table.insert(values, {name=string.format("grab (%d) mounted:", i), value=string.format("%s - %d", getName(shapeId), shapeId)})
                end
            end

            for shapeId, _ in pairs(grab.pendingDynamicMountShapes) do
                if entityExists(shapeId) then
                    table.insert(values, {name=string.format("grab (%d) pending:", i), value=string.format("%s - %d", getName(shapeId), shapeId)})
                end
            end
        end
    end
end
