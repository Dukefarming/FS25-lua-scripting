


















---Called on specialization initializing
function RidgeMarker.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("ridgeMarker", g_i18n:getText("configuration_ridgeMarker"), "ridgeMarker", VehicleConfigurationItem)

    g_workAreaTypeManager:addWorkAreaType("ridgemarker", false, false, false)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("RidgeMarker")

    RidgeMarker.registerRidgeMarkerXMLPaths(schema, "vehicle.ridgeMarker")

    RidgeMarker.registerRidgeMarkerXMLPaths(schema, "vehicle.ridgeMarker.ridgeMarkerConfigurations.ridgeMarkerConfiguration(?)")

    RidgeMarker.registerRidgeMarkerAreaXMLPaths(schema, WorkArea.WORK_AREA_XML_KEY)
    RidgeMarker.registerRidgeMarkerAreaXMLPaths(schema, WorkArea.WORK_AREA_XML_CONFIG_KEY)

    schema:register(XMLValueType.STRING, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#ridgeMarkerAnim", "Ridge marker animation")
    schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#ridgeMarkerAnimTimeMax", "Animation max. time for activation", 0.99)

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).ridgeMarker#state", "Ridge marker state")
end


---
function RidgeMarker.registerRidgeMarkerXMLPaths(schema, baseKey)
    schema:register(XMLValueType.STRING, baseKey .. "#inputButton", "Input action name", "IMPLEMENT_EXTRA4")

    schema:register(XMLValueType.STRING, baseKey .. ".marker(?)#animName", "Animation name")
    schema:register(XMLValueType.FLOAT, baseKey .. ".marker(?)#minWorkLimit", "Min. work limit", 0.99)
    schema:register(XMLValueType.FLOAT, baseKey .. ".marker(?)#maxWorkLimit", "Max. work limit", 1)
    schema:register(XMLValueType.FLOAT, baseKey .. ".marker(?)#liftedAnimTime", "Lifted animation time")
    schema:register(XMLValueType.INT, baseKey .. ".marker(?)#workAreaIndex", "Work area index")

    schema:register(XMLValueType.FLOAT, baseKey .. "#foldMinLimit", "Fold min. limit", 0)
    schema:register(XMLValueType.FLOAT, baseKey .. "#foldMaxLimit", "Fold max. limit", 1)
    schema:register(XMLValueType.INT, baseKey .. "#foldDisableDirection", "Fold disable direction")
    schema:register(XMLValueType.BOOL, baseKey .. "#onlyActiveWhenLowered", "Only active while lowered", true)
    schema:register(XMLValueType.NODE_INDEX, baseKey .. "#directionNode", "Direction node")
end


---
function RidgeMarker.registerRidgeMarkerAreaXMLPaths(schema, baseKey)
    schema:register(XMLValueType.NODE_INDEX, baseKey .. ".ridgeMarkerArea#node", "Around this node the ridge marker areas are generated")
    schema:register(XMLValueType.FLOAT,      baseKey .. ".ridgeMarkerArea#size", "Width and length of area and test area", 0.25)
    schema:register(XMLValueType.FLOAT,      baseKey .. ".ridgeMarkerArea#testAreaOffset", "Offset of test area in positive z direction", 0.2)
end


---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function RidgeMarker.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations)
end


---
function RidgeMarker.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadRidgeMarker",        RidgeMarker.loadRidgeMarker)
    SpecializationUtil.registerFunction(vehicleType, "setRidgeMarkerState",    RidgeMarker.setRidgeMarkerState)
    SpecializationUtil.registerFunction(vehicleType, "canFoldRidgeMarker",     RidgeMarker.canFoldRidgeMarker)
    SpecializationUtil.registerFunction(vehicleType, "processRidgeMarkerArea", RidgeMarker.processRidgeMarkerArea)
end


---
function RidgeMarker.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML",          RidgeMarker.loadWorkAreaFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive",          RidgeMarker.getIsWorkAreaActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", RidgeMarker.loadSpeedRotatingPartFromXML)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", RidgeMarker.getIsSpeedRotatingPartActive)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected",             RidgeMarker.getCanBeSelected)
end


---
function RidgeMarker.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", RidgeMarker)
    SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", RidgeMarker)
end


---Called on loading
-- @param table savegame savegame
function RidgeMarker:onLoad(savegame)
    local spec = self.spec_ridgeMarker

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ridgeMarkers", "vehicle.ridgeMarker") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ridgeMarkers.ridgeMarker", "vehicle.ridgeMarker.marker") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ridgeMarker.ridgeMarker", "vehicle.ridgeMarker.marker") -- FS17 to FS19

    local configurationId = Utils.getNoNil(self.configurations["ridgeMarker"], 1)
    local configKey = string.format("vehicle.ridgeMarker.ridgeMarkerConfigurations.ridgeMarkerConfiguration(%d)", configurationId - 1)

    if not self.xmlFile:hasProperty(configKey) then
        configKey = "vehicle.ridgeMarker"
    end

    local inputButtonStr = self.xmlFile:getValue(configKey .. "#inputButton")
    if inputButtonStr ~= nil then
        spec.ridgeMarkerInputButton = InputAction[inputButtonStr]
    end
    spec.ridgeMarkerInputButton = Utils.getNoNil(spec.ridgeMarkerInputButton, InputAction.IMPLEMENT_EXTRA4)

    spec.ridgeMarkers = {}
    spec.workAreaToRidgeMarker = {}
    local i = 0
    while true do
        local key = string.format("%s.marker(%d)", configKey, i)
        if not self.xmlFile:hasProperty(key) then
            break
        end

        if #spec.ridgeMarkers >= RidgeMarker.MAX_NUM_RIDGEMARKERS-1 then
            Logging.xmlError(self.xmlFile, "Too many ridgeMarker states. Only %d states are supported!", RidgeMarker.MAX_NUM_RIDGEMARKERS-1)
            break
        end

        local ridgeMarker = {}
        if self:loadRidgeMarker(self.xmlFile, key, ridgeMarker) then
            table.insert(spec.ridgeMarkers, ridgeMarker)
            spec.workAreaToRidgeMarker[ridgeMarker.workAreaIndex] = ridgeMarker
        end

        i = i + 1
    end
    spec.numRigdeMarkers = #spec.ridgeMarkers

    spec.ridgeMarkerMinFoldTime = self.xmlFile:getValue(configKey .. "#foldMinLimit", 0)
    spec.ridgeMarkerMaxFoldTime = self.xmlFile:getValue(configKey .. "#foldMaxLimit", 1)
    spec.foldDisableDirection = self.xmlFile:getValue(configKey .. "#foldDisableDirection")
    spec.onlyActiveWhenLowered = self.xmlFile:getValue(configKey .. "#onlyActiveWhenLowered", true)
    spec.ridgeMarkerState = 0
    spec.directionNode = self.xmlFile:getValue(configKey .. "#directionNode", nil, self.components, self.i3dMappings)

    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", RidgeMarker)
    end
end


---
function RidgeMarker:onPostLoad(savegame)
    local spec = self.spec_ridgeMarker
    if spec.numRigdeMarkers > 0 and savegame ~= nil then
        local state = savegame.xmlFile:getValue(savegame.key..".ridgeMarker#state")
        if state ~= nil then
            self:setRidgeMarkerState(state, true)
            if state ~= 0 then
                AnimatedVehicle.updateAnimationByName(self, spec.ridgeMarkers[state].animName, 9999999, true)
            end
        end
    end
end


---
function RidgeMarker:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_ridgeMarker
    if spec.numRigdeMarkers > 0 then
        xmlFile:setValue(key.."#state", spec.ridgeMarkerState)
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RidgeMarker:onReadStream(streamId, connection)
    local spec = self.spec_ridgeMarker
    if spec.numRigdeMarkers > 0 then
        local state = streamReadUIntN(streamId, RidgeMarker.SEND_NUM_BITS)
        self:setRidgeMarkerState(state, true)
        if state ~= 0 then
            AnimatedVehicle.updateAnimationByName(self, spec.ridgeMarkers[state].animName, 9999999, true)
        end
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RidgeMarker:onWriteStream(streamId, connection)
    local spec = self.spec_ridgeMarker
    if spec.numRigdeMarkers > 0 then
        streamWriteUIntN(streamId, spec.ridgeMarkerState, RidgeMarker.SEND_NUM_BITS)
    end
end


---
function RidgeMarker:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    RidgeMarker.updateActionEvents(self)
end


---
function RidgeMarker:loadRidgeMarker(xmlFile, key, ridgeMarker)
    ridgeMarker.animName = xmlFile:getValue(key .. "#animName")
    ridgeMarker.minWorkLimit = xmlFile:getValue(key .. "#minWorkLimit", 0.99)
    ridgeMarker.maxWorkLimit = xmlFile:getValue(key .. "#maxWorkLimit", 1)

    ridgeMarker.liftedAnimTime = xmlFile:getValue(key .. "#liftedAnimTime")
    ridgeMarker.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")

    if ridgeMarker.workAreaIndex == nil then
        Logging.xmlWarning(self.xmlFile, "Missing 'workAreaIndex' for ridgeMarker '%s'!", key)
        return false
    end

    return true
end


---Toggle ridge marker state
-- @param integer state new state
-- @param boolean noEventSend no event send
function RidgeMarker:setRidgeMarkerState(state, noEventSend)
    local spec = self.spec_ridgeMarker

    if spec.ridgeMarkerState ~= state then
        RidgeMarkerSetStateEvent.sendEvent(self, state, noEventSend)

        -- fold last state
        if spec.ridgeMarkerState ~= 0 then
            local animTime = self:getAnimationTime(spec.ridgeMarkers[spec.ridgeMarkerState].animName)
            self:playAnimation(spec.ridgeMarkers[spec.ridgeMarkerState].animName, -1, animTime, true)
        end
        spec.ridgeMarkerState = state

        -- unfold new state
        if spec.ridgeMarkerState ~= 0 then
            if spec.ridgeMarkers[spec.ridgeMarkerState].liftedAnimTime ~= nil and not self:getIsLowered(true) then
                self:setAnimationStopTime(spec.ridgeMarkers[spec.ridgeMarkerState].animName, spec.ridgeMarkers[spec.ridgeMarkerState].liftedAnimTime)
            end

            local animTime = self:getAnimationTime(spec.ridgeMarkers[spec.ridgeMarkerState].animName)
            self:playAnimation(spec.ridgeMarkers[spec.ridgeMarkerState].animName, 1, animTime, true)
        end
    end
end



---Return if ridge markers can be folden
-- @param integer state state
-- @return boolean canFold ridge markers can be folden
function RidgeMarker:canFoldRidgeMarker(state)
    local spec = self.spec_ridgeMarker

    if self.getFoldAnimTime ~= nil then
        local foldAnimTime = self:getFoldAnimTime()
        if foldAnimTime < spec.ridgeMarkerMinFoldTime or foldAnimTime > spec.ridgeMarkerMaxFoldTime then
            return false
        end
    end

    local foldableSpec = self.spec_foldable
    if state ~= 0 and not foldableSpec.moveToMiddle and spec.foldDisableDirection ~= nil and (spec.foldDisableDirection == foldableSpec.foldMoveDirection or foldableSpec.foldMoveDirection == 0) then
        return false
    end

    return true
end


---
function RidgeMarker:processRidgeMarkerArea(workArea, dt)
    local spec = self.spec_ridgeMarker

    local mission = g_currentMission
    local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)

    local densityBits = getDensityAtWorldPos(groundTypeMapId, getWorldTranslation(workArea.testNode))
    local densityType = bitAND(bitShiftRight(densityBits, groundTypeFirstChannel), 2^groundTypeNumChannels - 1)
    local groundType = FieldGroundType.getTypeByValue(densityType)

    -- ignore non-field areas
    if groundType ~= FieldGroundType.NONE then
        local x, _, z = getWorldTranslation(workArea.start)
        local x1, _, z1 = getWorldTranslation(workArea.width)
        local x2, _, z2 = getWorldTranslation(workArea.height)

        local wx, wz = x1-x, z1-z
        local hx, hz = x2-x, z2-z

        local worldToDensity = mission.terrainDetailMapSize / mission.terrainSize
        x = math.floor(x * worldToDensity + 0.5)/worldToDensity
        z = math.floor(z * worldToDensity + 0.5)/worldToDensity

        x1, z1 = x + wx, z + wz
        x2, z2 = x + hx, z + hz

        local dx, _, dz = localDirectionToWorld(spec.directionNode or self.rootNode, 0, 0, 1)
        local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), mission.fieldGroundSystem:getGroundAngleMaxValue())

        if groundType == FieldGroundType.PLOWED then
            FSDensityMapUtil.updateCultivatorArea(x, z, x1, z1, x2, z2, false, true, angle, nil, nil, true)
        else
            FSDensityMapUtil.updatePlowArea(x, z, x1, z1, x2, z2, false, true, angle, false, true)
        end

        FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
    end

    return 0, 0
end


---Loads work areas from xml
-- @param table workArea workArea
-- @param integer xmlFile id of xml object
-- @param string key key
-- @return boolean success success
function RidgeMarker:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
    local ridgeMarkerNode = xmlFile:getValue(key ..".ridgeMarkerArea#node", nil, self.components, self.i3dMappings)

    local ridgeMarkerSize = xmlFile:getValue(key ..".ridgeMarkerArea#size", 0.25) * 0.5
    local ridgeMarkerTestOffset = xmlFile:getValue(key ..".ridgeMarkerArea#testAreaOffset", 0.2)

    if ridgeMarkerNode ~= nil then
        workArea.start = createTransformGroup("ridgeMarkerAreaStart")
        link(ridgeMarkerNode, workArea.start)
        setTranslation(workArea.start, ridgeMarkerSize, 0, ridgeMarkerSize)

        workArea.width = createTransformGroup("ridgeMarkerAreaWidth")
        link(ridgeMarkerNode, workArea.width)
        setTranslation(workArea.width, -ridgeMarkerSize, 0, ridgeMarkerSize)

        workArea.height = createTransformGroup("ridgeMarkerAreaHeight")
        link(ridgeMarkerNode, workArea.height)
        setTranslation(workArea.height, ridgeMarkerSize, 0, -ridgeMarkerSize)

        local testOffset = (ridgeMarkerTestOffset + 2 * ridgeMarkerSize)
        workArea.testNode = createTransformGroup("ridgeMarkerTestNode")
        link(ridgeMarkerNode, workArea.testNode)
        setTranslation(workArea.testNode, 0, 0, ridgeMarkerSize + testOffset)
    end

    if not superFunc(self, workArea, xmlFile, key) then
        return false
    end

    if workArea.type == WorkAreaType.RIDGEMARKER then
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key ..".testArea#startNode", key ..".ridgeMarkerArea#node") -- FS19 to FS22
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key ..".testArea#widthNode", key ..".ridgeMarkerArea#node") -- FS19 to FS22
        XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key ..".testArea#heightNode", key ..".ridgeMarkerArea#node") -- FS19 to FS22
    end

    if ridgeMarkerNode ~= nil then
        if workArea.type == WorkAreaType.DEFAULT then
            workArea.type = WorkAreaType.RIDGEMARKER
        end
    elseif workArea.type == WorkAreaType.RIDGEMARKER then
        Logging.xmlWarning(self.xmlFile, "Missing ridge marker node for ridge marker area '%s'", key)
    end

    return true
end


---Loads speed rotating parts from xml
-- @param table speedRotatingPart speedRotatingPart
-- @param integer xmlFile id of xml object
-- @param string key key
-- @return boolean success success
function RidgeMarker:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
    if not superFunc(self, speedRotatingPart, xmlFile, key) then
        return false
    end

    speedRotatingPart.ridgeMarkerAnim = xmlFile:getValue(key .. "#ridgeMarkerAnim")
    speedRotatingPart.ridgeMarkerAnimTimeMax = xmlFile:getValue(key .. "#ridgeMarkerAnimTimeMax", 0.99)

    return true
end


---Returns true if speed rotating part is active
-- @param table speedRotatingPart speedRotatingPart
-- @return boolean isActive speed rotating part is active
function RidgeMarker:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    if speedRotatingPart.ridgeMarkerAnim ~= nil and self:getAnimationTime(speedRotatingPart.ridgeMarkerAnim) < speedRotatingPart.ridgeMarkerAnimTimeMax then
        return false
    end

    return superFunc(self, speedRotatingPart)
end


---
function RidgeMarker:getCanBeSelected(superFunc)
    return true
end


---Returns true if work area is active
-- @param table workArea workArea
-- @return boolean isActive work area is active
function RidgeMarker:getIsWorkAreaActive(superFunc, workArea)

    if workArea.type == WorkAreaType.RIDGEMARKER then
        local spec = self.spec_ridgeMarker
        if spec.numRigdeMarkers == 0 then
            return false
        end

        local ridgeMarker = spec.workAreaToRidgeMarker[workArea.index]

        if ridgeMarker ~= nil then
            local animTime = self:getAnimationTime(ridgeMarker.animName)
            if animTime > ridgeMarker.maxWorkLimit or animTime < ridgeMarker.minWorkLimit then
                return false
            end

            if spec.onlyActiveWhenLowered and not self:getIsLowered(false) then
                return false
            end
        end
    end

    return superFunc(self, workArea)
end


---
function RidgeMarker:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_ridgeMarker
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection and spec.numRigdeMarkers > 0 then
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.ridgeMarkerInputButton, self, RidgeMarker.actionEventToggleRidgeMarkers, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_toggleRidgeMarker"))
        end
    end
end


---Called on lowered state change
-- @param boolean lowered is lowered
function RidgeMarker:onSetLowered(lowered)
    local spec = self.spec_ridgeMarker
    if lowered then
        for _, ridgeMarker in pairs(spec.ridgeMarkers) do
            if ridgeMarker.liftedAnimTime ~= nil then
                local animTime = self:getAnimationTime(ridgeMarker.animName)
                if animTime == ridgeMarker.liftedAnimTime then
                    self:playAnimation(ridgeMarker.animName, 1, animTime, true)
                end
            end
        end
    else
        for _, ridgeMarker in pairs(spec.ridgeMarkers) do
            if ridgeMarker.liftedAnimTime ~= nil then
                local animTime = self:getAnimationTime(ridgeMarker.animName)
                if animTime > ridgeMarker.liftedAnimTime then
                    self:setAnimationStopTime(ridgeMarker.animName, ridgeMarker.liftedAnimTime)
                    self:playAnimation(ridgeMarker.animName, -1, animTime, true)
                end
            end
        end
    end
end


---Called on folding state change
-- @param integer direction direction
-- @param boolean moveToMiddle move to middle position
function RidgeMarker:onFoldStateChanged(direction, moveToMiddle)
    if not moveToMiddle and direction > 0 then
        self:setRidgeMarkerState(0, true)
    end
end


---
function RidgeMarker:onAIImplementStart()
    self:setRidgeMarkerState(0, true)
end


---
function RidgeMarker.actionEventToggleRidgeMarkers(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_ridgeMarker

    local newState = (spec.ridgeMarkerState + 1) % (spec.numRigdeMarkers+1)
    if self:canFoldRidgeMarker(newState) then
        self:setRidgeMarkerState(newState)
    end
end


---
function RidgeMarker.updateActionEvents(self)
    local spec = self.spec_ridgeMarker

    local actionEvent = spec.actionEvents[spec.ridgeMarkerInputButton]
    if actionEvent ~= nil then
        local isVisible = false
        if spec.numRigdeMarkers > 0 then
            local newState = (spec.ridgeMarkerState + 1) % (spec.numRigdeMarkers+1)
            if self:canFoldRidgeMarker(newState) then
                isVisible = true
            end
        end

        g_inputBinding:setActionEventActive(actionEvent.actionEventId, isVisible)
    end
end
