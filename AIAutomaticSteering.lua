






































---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AIAutomaticSteering.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations)
end


---
function AIAutomaticSteering.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AIAutomaticSteering")

    SoundManager.registerSampleXMLPaths(schema, "vehicle.ai.automaticSteering.sounds", "engage")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.ai.automaticSteering.sounds", "disengage")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.ai.automaticSteering.sounds", "lineEnd")

    Dashboard.registerDashboardXMLPaths(schema, "vehicle.ai.automaticSteering.dashboards", {"steeringEngaged", "steeringState", "heading", "headingLetter"})

    schema:register(XMLValueType.FLOAT, "vehicle.ai.automaticSteering#lookAheadDistance", "Distance for aiming onto the wayline", "half of the vehicle length")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    SteeringFieldCourse.registerXMLPaths(schemaSavegame, "vehicles.vehicle(?).aiAutomaticSteering.steeringFieldCourse")
    SteeringFieldCourse.registerXMLPaths(schemaSavegame, "vehicles.vehicle(?).aiAutomaticSteering.lastActiveSteeringFieldCourse")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiAutomaticSteering#isOnField", "Is on field")
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiAutomaticSteering#courseWasActive", "Current course was also the last active one")
end


---
function AIAutomaticSteering.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIAutomaticSteeringLineEnd")
end



---Register all functions from the specialization that can be called on vehicle level
-- @param table vehicleType vehicle type
function AIAutomaticSteering.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getAttacherToolWorkingWidth", AIAutomaticSteering.getAttacherToolWorkingWidth)
    SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticSteeringAllowed", AIAutomaticSteering.getIsAutomaticSteeringAllowed)
    SpecializationUtil.registerFunction(vehicleType, "setAIAutomaticSteeringEnabled", AIAutomaticSteering.setAIAutomaticSteeringEnabled)
    SpecializationUtil.registerFunction(vehicleType, "setAIAutomaticSteeringCourse", AIAutomaticSteering.setAIAutomaticSteeringCourse)
    SpecializationUtil.registerFunction(vehicleType, "generateSteeringFieldCourse", AIAutomaticSteering.generateSteeringFieldCourse)
    SpecializationUtil.registerFunction(vehicleType, "getIsAIAutomaticSteeringAllowed", AIAutomaticSteering.getIsAIAutomaticSteeringAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getAIAutomaticSteeringState", AIAutomaticSteering.getAIAutomaticSteeringState)
    SpecializationUtil.registerFunction(vehicleType, "getAIAutomaticSteeringLookAheadDistance", AIAutomaticSteering.getAIAutomaticSteeringLookAheadDistance)
    SpecializationUtil.registerFunction(vehicleType, "getIsSideOffsetReversed", AIAutomaticSteering.getIsSideOffsetReversed)
end


---Register all function overwritings
-- @param table vehicleType vehicle type
function AIAutomaticSteering.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSteeringInput", AIAutomaticSteering.setSteeringInput)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehiclePhysics", AIAutomaticSteering.updateVehiclePhysics)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function AIAutomaticSteering.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onAIModeChanged", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onAIModeSettingsChanged", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onAIAutomaticSteeringLineEnd", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onActivate", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AIAutomaticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIAutomaticSteering)
end


---Called on loading
-- @param table savegame savegame
function AIAutomaticSteering:onLoad(savegame)
    local spec = self.spec_aiAutomaticSteering

    spec.lastIsOnField = false
    spec.forceFieldCourseUpdate = false
    spec.resetCourseTimer = 0

    spec.steeringFieldCourse = nil
    spec.lastActiveSteeringFieldCourse = nil

    spec.fieldCourseDetectionInProgress = false
    spec.fieldCourseDetectionPendingData = nil

    spec.lastDistanceToEnd = 0

    spec.steeringEnabled = false
    spec.steeringLastEnableTime = -math.huge
    spec.steeringValue = 0

    spec.lookAheadDistance = self.xmlFile:getValue("vehicle.ai.automaticSteering#lookAheadDistance")

    spec.lastSteeringInputValue = 0

    if self.isClient then
        spec.samples = {}
        spec.samples.engage = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "engage", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.disengage = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "disengage", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.lineEnd = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "lineEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    spec.dirtyFlag = self:getNextDirtyFlag()
end


---
function AIAutomaticSteering:onPostLoad(savegame)
    if savegame ~= nil and not savegame.resetVehicles then
        local spec = self.spec_aiAutomaticSteering
        local courseWasActive = savegame.xmlFile:getValue(savegame.key .. ".aiAutomaticSteering#courseWasActive", false)

        spec.lastIsOnField = savegame.xmlFile:getValue(savegame.key .. ".aiAutomaticSteering#isOnField", spec.lastIsOnField)

        SteeringFieldCourse.loadFromXML(savegame.xmlFile, savegame.key .. ".aiAutomaticSteering.lastActiveSteeringFieldCourse", function(steeringFieldCourse)
            if steeringFieldCourse ~= nil then
                spec.lastActiveSteeringFieldCourse = steeringFieldCourse
            end
        end)

        SteeringFieldCourse.loadFromXML(savegame.xmlFile, savegame.key .. ".aiAutomaticSteering.steeringFieldCourse", function(steeringFieldCourse)
            if steeringFieldCourse ~= nil then
                self:setAIAutomaticSteeringCourse(steeringFieldCourse, true)
                spec.forceFieldCourseUpdate = false

                if courseWasActive then
                    spec.lastActiveSteeringFieldCourse = steeringFieldCourse
                end
            end
        end)
    end
end


---Called on post load to register dashboard value types
function AIAutomaticSteering:onRegisterDashboardValueTypes()
    local spec = self.spec_aiAutomaticSteering

    local steeringEngaged = DashboardValueType.new("ai.automaticSteering", "steeringEngaged")
    steeringEngaged:setValue(spec, "steeringEnabled")
    self:registerDashboardValueType(steeringEngaged)

    local steeringState = DashboardValueType.new("ai.automaticSteering", "steeringState")
    steeringState:setValue(spec, function()
        return self:getAIAutomaticSteeringState() - 1
    end)
    self:registerDashboardValueType(steeringState)

    local heading = DashboardValueType.new("ai.automaticSteering", "heading")
    heading:setValue(spec, function()
        local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, 1)
        local yRot = MathUtil.getYRotationFromDirection(dx, dz)
        if yRot < 0 then
            yRot = yRot + math.pi * 2
        end

        return 360 - math.deg(yRot)
    end)
    self:registerDashboardValueType(heading)

    local headingLetter = DashboardValueType.new("ai.automaticSteering", "headingLetter")
    headingLetter:setValue(spec, function()
        local dx, _, dz = localDirectionToWorld(self.rootNode, 0, 0, -1)
        local yRot = MathUtil.getYRotationFromDirection(dx, dz)
        if yRot < 0 then
            yRot = yRot + math.pi * 2
        end

        yRot = 360 - math.deg(yRot)
        if yRot >= 337.5 or yRot < 22.5 then
            return AIAutomaticSteering.HEADING_LETTERS[1]
        elseif yRot >= 22.5 and yRot < 67.5 then
            return AIAutomaticSteering.HEADING_LETTERS[2]
        elseif yRot >= 67.5 and yRot < 112.5 then
            return AIAutomaticSteering.HEADING_LETTERS[3]
        elseif yRot >= 112.5 and yRot < 157.5 then
            return AIAutomaticSteering.HEADING_LETTERS[4]
        elseif yRot >= 157.5 and yRot < 202.5 then
            return AIAutomaticSteering.HEADING_LETTERS[5]
        elseif yRot >= 202.5 and yRot < 247.5 then
            return AIAutomaticSteering.HEADING_LETTERS[6]
        elseif yRot >= 247.5 and yRot < 292.5 then
            return AIAutomaticSteering.HEADING_LETTERS[7]
        elseif yRot >= 292.5 and yRot < 337.5 then
            return AIAutomaticSteering.HEADING_LETTERS[8]
        end
    end)
    self:registerDashboardValueType(headingLetter)
end


---Called on deleting
function AIAutomaticSteering:onDelete()
    local spec = self.spec_aiAutomaticSteering
    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples)
    end
end


---
function AIAutomaticSteering:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_aiAutomaticSteering
    xmlFile:setValue(key .. "#courseWasActive", spec.lastActiveSteeringFieldCourse == spec.steeringFieldCourse)

    if spec.lastActiveSteeringFieldCourse ~= nil and spec.lastActiveSteeringFieldCourse ~= spec.steeringFieldCourse then
        spec.lastActiveSteeringFieldCourse:saveToXML(xmlFile, key .. ".lastActiveSteeringFieldCourse")
    end

    if spec.steeringFieldCourse ~= nil then
        spec.steeringFieldCourse:saveToXML(xmlFile, key .. ".steeringFieldCourse")
    end

    xmlFile:setValue(key .. "#isOnField", spec.lastIsOnField)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteering:onReadStream(streamId, connection)
    if streamReadBool(streamId) then
        SteeringFieldCourse.readStream(streamId, connection, function(steeringFieldCourse)
            self:setAIAutomaticSteeringCourse(steeringFieldCourse, true)
            self.spec_aiAutomaticSteering.lastIsOnField = true
            self.spec_aiAutomaticSteering.forceFieldCourseUpdate = false
        end)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteering:onWriteStream(streamId, connection)
    local spec = self.spec_aiAutomaticSteering
    if streamWriteBool(streamId, spec.steeringFieldCourse ~= nil) then
        spec.steeringFieldCourse:writeStream(streamId, connection)
    end
end


---
function AIAutomaticSteering:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            SteeringFieldCourse.readSegmentStatesFromStream(self.spec_aiAutomaticSteering.steeringFieldCourse, streamId, connection)
        end
    end
end


---
function AIAutomaticSteering:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_aiAutomaticSteering
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            spec.steeringFieldCourse:writeSegmentStatesToStream(streamId, connection)
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function AIAutomaticSteering:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_aiAutomaticSteering
    if self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST then
        if spec.steeringFieldCourse ~= nil then
            if isActiveForInputIgnoreSelection and VehicleDebug.state == VehicleDebug.DEBUG_AI then
                spec.steeringFieldCourse:draw()
            end

            local aiRootNode = self:getAIRootNode()
            local reverserDirection = self:getReverserDirection()
            local sideOffsetReversed = self:getIsSideOffsetReversed()

            local lookAheadDistance = self:getAIAutomaticSteeringLookAheadDistance()
            lookAheadDistance = math.max(lookAheadDistance, 4)
            lookAheadDistance = lookAheadDistance + math.sign(lookAheadDistance) * math.pow(math.min(self:getLastSpeed() / 30, 1), 2) * 5

            local x, _, z = localToWorld(aiRootNode, 0, 0, lookAheadDistance)
            local dirX, _, dirZ = localDirectionToWorld(aiRootNode, 0, 0, 1)
            dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
            if spec.steeringFieldCourse:updateVehicleData(dt, spec.steeringEnabled, x, z, dirX, dirZ, sideOffsetReversed) then
                AIAutomaticSteering.updateActionEvents(self)
            end

            if self.isServer then
                if spec.steeringFieldCourse.currentSegment ~= nil then
                    if spec.steeringEnabled then
                        local tX, tZ, distanceToEnd = spec.steeringFieldCourse:getSteeringTarget(aiRootNode, lookAheadDistance, sideOffsetReversed)
                        if tX ~= 0 and tZ ~= 0 then
--#debug                            local wx, wy, wz = localToWorld(aiRootNode, tX, 0, tZ)
--#debug                            DebugGizmo.renderAtPosition(wx, wy, wz, 0, 1, 0, 0, 0, 1, "t")

                            local tX_2 = tX * 0.5
                            local tZ_2 = tZ * 0.5

                            local d1X, d1Z = tZ_2, -tX_2
                            if tX > 0 then
                                d1X, d1Z = -tZ_2, tX_2
                            end

                            local hit, _, f2 = MathUtil.getLineLineIntersection2D(tX_2, tZ_2, d1X, d1Z, 0,0, tX, 0)

                            local rotTime = 0
                            if hit and math.abs(f2) < 100000 then
                                local radius = tX * f2
                                rotTime = self:getSteeringRotTimeByCurvature(1 / radius)

                                if reverserDirection < 0 then
                                    rotTime = -rotTime
                                end
                            end

                            local targetRotTime
                            if rotTime >= 0 then
                                targetRotTime = math.min(rotTime, self.maxRotTime)
                            else
                                targetRotTime = math.max(rotTime, self.minRotTime)
                            end

                            if targetRotTime > spec.steeringValue then
                                spec.steeringValue = math.min(spec.steeringValue + dt*self:getAISteeringSpeed(), targetRotTime)
                            else
                                spec.steeringValue = math.max(spec.steeringValue - dt*self:getAISteeringSpeed(), targetRotTime)
                            end

                            if distanceToEnd ~= spec.lastDistanceToEnd then
                                if spec.lastDistanceToEnd > AIAutomaticSteering.LINE_END_SOUND_DISTANCE and distanceToEnd <= AIAutomaticSteering.LINE_END_SOUND_DISTANCE then
                                    SpecializationUtil.raiseEvent(self, "onAIAutomaticSteeringLineEnd")

                                    g_server:broadcastEvent(AIAutomaticSteeringLineEndEvent.new(self), nil, nil, self)
                                end
                                spec.lastDistanceToEnd = distanceToEnd
                            end
                        end

                        if self:getLastSpeed() > 1 and self.movingDirection * reverserDirection < 0 then
                            self:setAIAutomaticSteeringEnabled(false)
                        end
                    end
                end

                if spec.steeringFieldCourse.segmentStatesDirty then
                    self:raiseDirtyFlags(spec.dirtyFlag)
                    spec.steeringFieldCourse.segmentStatesDirty = false
                end
            end
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function AIAutomaticSteering:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_aiAutomaticSteering

    if isActiveForInputIgnoreSelection then
        if self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST then
            local x, _, z = localToWorld(self.rootNode, 0, 0, self.size.length * 0.5 + self.size.lengthOffset)
            x, z = g_fieldCourseManager:roundToTerrainDetailPixel(x, z)

            local isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z) ~= 0
            if not isOnField then
                x, _, z = localToWorld(self.rootNode, 0, 0, -self.size.length * 0.5 + self.size.lengthOffset + 1) -- add one meter offset to not get into the work area of the tool
                x, z = g_fieldCourseManager:roundToTerrainDetailPixel(x, z)

                isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z) ~= 0
            end

            local farmId = self:getActiveFarm()
            local hasAccess = g_currentMission.accessHandler:canFarmAccessLand(farmId, x, z) or g_missionManager:getIsMissionWorkAllowed(farmId, x, z, nil, self)
            if not hasAccess then
                isOnField = false
            end

            if isOnField ~= spec.lastIsOnField or spec.forceFieldCourseUpdate then
                spec.lastIsOnField = isOnField

                if isOnField then
                    spec.resetCourseTimer = 0
                    local workingWidth = self:getAttacherToolWorkingWidth()

                    local generateCourse = true
                    if spec.steeringFieldCourse ~= nil and not spec.forceFieldCourseUpdate then
                        if spec.steeringFieldCourse:getIsPointInsideBoundary(x, z) then
                            -- working width can be 0 for tools without work areas (e.g. vine harvesters)
                            if workingWidth == 0 or math.abs(workingWidth - spec.steeringFieldCourse.fieldCourseSettings.implementWidth) < 0.05 then
                                generateCourse = false
                            end
                        end
                    end

                    if generateCourse then
                        self:initializeLoadedAIModeUserSettings()
                        local fieldCourseSettings = self:getAIModeFieldCourseSettings()
                        if fieldCourseSettings == nil then
                            fieldCourseSettings, _ = FieldCourseSettings.generate(self.rootVehicle)
                        end

                        if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                            fieldCourseSettings:print()
                        end

                        g_client:getServerConnection():sendEvent(AIAutomaticSteeringRequestEvent.new(self, x, z, fieldCourseSettings))
                    end
                else
                    spec.resetCourseTimer = AIAutomaticSteering.RESET_COURSE_TIME
                end

                spec.forceFieldCourseUpdate = false
            end

            if not isOnField and not spec.steeringEnabled then
                if spec.resetCourseTimer > 0 then
                    spec.resetCourseTimer = spec.resetCourseTimer - dt
                    if spec.resetCourseTimer <= 0 then
                        self:setAIAutomaticSteeringCourse(nil)
                    end
                end
            end
        end
    end

    if self.isServer then
        if self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST then
            -- disable steering while reversing
            if spec.steeringFieldCourse ~= nil then
                if spec.steeringEnabled then
                    if self:getLastSpeed() > 1 then
                        if self.movingDirection * self:getReverserDirection() < 0 then
                            self:setAIAutomaticSteeringEnabled(false)
                        end
                    end
                end
            end
        end
    end
end


---
function AIAutomaticSteering:onStateChange(state, data)
    if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
        local spec = self.spec_aiAutomaticSteering
        spec.forceFieldCourseUpdate = true
        spec.lastActiveSteeringFieldCourse = nil

        if self.isServer and self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST then
            if not self:getIsAutomaticSteeringAllowed() then
                self:setAIModeSelection(AIModeSelection.MODE.WORKER)
            end
        end
    end
end


---
function AIAutomaticSteering:onAIModeChanged(aiMode)
    if aiMode ~= AIModeSelection.MODE.STEERING_ASSIST then
        self:setAIAutomaticSteeringCourse(nil, true)
    else
        if self.isActiveForInputIgnoreSelectionIgnoreAI then
            self.spec_aiAutomaticSteering.forceFieldCourseUpdate = true
        end
    end
end


---
function AIAutomaticSteering:onAIModeSettingsChanged(aiMode)
    if self.isActiveForInputIgnoreSelectionIgnoreAI then
        if aiMode == AIModeSelection.MODE.STEERING_ASSIST then
            self:setAIAutomaticSteeringCourse(nil)

            self.spec_aiAutomaticSteering.forceFieldCourseUpdate = true
        end
    end
end


---
function AIAutomaticSteering:onAIAutomaticSteeringLineEnd()
    local spec = self.spec_aiAutomaticSteering
    g_soundManager:playSample(spec.samples.lineEnd)
end


---
function AIAutomaticSteering:onActivate()
    if self:getIsActiveForInput(true, true) then
        local spec = self.spec_aiAutomaticSteering
        if spec.steeringFieldCourse ~= nil then
            g_fieldCourseManager:setActiveSteeringFieldCourse(spec.steeringFieldCourse, self)
        end
    end
end


---
function AIAutomaticSteering:onDeactivate()
    if not self.isDeleted and not self.isDeleting then
        if self.isActiveForInputIgnoreSelectionIgnoreAI then
            local spec = self.spec_aiAutomaticSteering
            if spec.steeringFieldCourse ~= nil then
                g_fieldCourseManager:setActiveSteeringFieldCourse(nil, self)
            end

            self:setAIAutomaticSteeringEnabled(false)
        end
    end
end


---
function AIAutomaticSteering:getAttacherToolWorkingWidth()
    local workingWidth = 0
    for _, vehicle in pairs(self.rootVehicle.childVehicles) do
        if vehicle.getAIMarkers ~= nil then
            vehicle:updateAIMarkerWidth()

            local _, _, _, _, aiMarkerWidth = vehicle:getAIMarkers()
            if aiMarkerWidth ~= nil then
                workingWidth = math.max(workingWidth, aiMarkerWidth)
            end
        end

        if vehicle.getAIWorkAreaWidth ~= nil then
            workingWidth = math.max(workingWidth, vehicle:getAIWorkAreaWidth())
        end
    end

    return workingWidth
end


---
function AIAutomaticSteering:getIsAutomaticSteeringAllowed()
    if self.rootVehicle.getImplementAllowAutomaticSteering ~= nil then
        if self.rootVehicle:getImplementAllowAutomaticSteering() then
            return true
        end
    end

    for _, vehicle in pairs(self.rootVehicle.childVehicles) do
        if vehicle.getImplementAllowAutomaticSteering ~= nil then
            if vehicle:getImplementAllowAutomaticSteering() then
                return true
            end
        end
    end

    return false
end


---
function AIAutomaticSteering:setAIAutomaticSteeringEnabled(isEnabled, segmentIndex, segmentIsLeft, noEventSend)
    local spec = self.spec_aiAutomaticSteering

    if isEnabled == nil then
        isEnabled = not spec.steeringEnabled
    end

    -- function is called twice (from client user input and from server event to receive the server's segment index)
    if isEnabled ~= spec.steeringEnabled then
        spec.steeringEnabled = isEnabled

        if isEnabled then
            spec.steeringValue = self.rotatedTime
            spec.steeringLastEnableTime = g_time

            if self.isServer then
                spec.lastActiveSteeringFieldCourse = spec.steeringFieldCourse
            end
        end

        if self.isClient then
            if isEnabled then
                g_soundManager:playSample(spec.samples.engage)
            else
                g_soundManager:playSample(spec.samples.disengage)
            end

            AIAutomaticSteering.updateActionEvents(self)
        end
    end

    if spec.steeringFieldCourse ~= nil then
        if self.isServer then
            segmentIndex = spec.steeringFieldCourse.currentSegmentIndex
            segmentIsLeft = spec.steeringFieldCourse.currentSegmentIsLeft
        else
            if segmentIndex ~= nil then
                spec.steeringFieldCourse:setCurrentSegmentIndex(segmentIndex, segmentIsLeft)
            end
        end
    end

    AIAutomaticSteeringStateEvent.sendEvent(self, isEnabled, segmentIndex, segmentIsLeft, noEventSend)

    return segmentIndex, segmentIsLeft
end


---
function AIAutomaticSteering:setAIAutomaticSteeringCourse(steeringFieldCourse, noEventSend)
    local spec = self.spec_aiAutomaticSteering
    spec.steeringFieldCourse = steeringFieldCourse

    if steeringFieldCourse == nil then
        if spec.steeringEnabled then
            self:setAIAutomaticSteeringEnabled(false, nil, nil, true)
        end
    end

    if self.isActiveForInputIgnoreSelectionIgnoreAI then
        g_fieldCourseManager:setActiveSteeringFieldCourse(steeringFieldCourse, self)
    end

    if self.isClient then
        AIAutomaticSteering.updateActionEvents(self)
    end

    if noEventSend ~= true then
        if g_server ~= nil then
            g_server:broadcastEvent(AIAutomaticSteeringCourseEvent.new(self, steeringFieldCourse), nil, nil, self)
        else
            g_client:getServerConnection():sendEvent(AIAutomaticSteeringCourseEvent.new(self, steeringFieldCourse))
        end
    end
end


---
function AIAutomaticSteering:generateSteeringFieldCourse(x, z, fieldCourseSettings)
    local spec = self.spec_aiAutomaticSteering
    if spec.lastActiveSteeringFieldCourse ~= nil then
        if spec.lastActiveSteeringFieldCourse:getIsPointInsideBoundary(x, z) then
            if fieldCourseSettings:isIdentical(spec.lastActiveSteeringFieldCourse.fieldCourseSettings) then
                self:setAIAutomaticSteeringCourse(spec.lastActiveSteeringFieldCourse)
                return
            end
        end
    end

    if not spec.fieldCourseDetectionInProgress then
        spec.fieldCourseDetectionInProgress = true

        g_fieldCourseManager:generateFieldCourseAtWorldPos(x, z, fieldCourseSettings, function(_, course)
            spec.fieldCourseDetectionInProgress = false

            if course == nil then
                Logging.devInfo("Failed to generate field course for AISteering")
                self:setAIAutomaticSteeringCourse(nil)
            else
                local steeringFieldCourse = SteeringFieldCourse.new(course)
                self:setAIAutomaticSteeringCourse(steeringFieldCourse)
            end

            -- if we received different data in the meantime, we need to regenerate the course with this data
            -- but still send the already created course to the client
            if spec.fieldCourseDetectionPendingData ~= nil then
                local data = spec.fieldCourseDetectionPendingData
                spec.fieldCourseDetectionPendingData = nil

                self:generateSteeringFieldCourse(data.x, data.z, data.fieldCourseSettings)

                return
            end
        end)
    else
        spec.fieldCourseDetectionPendingData = {x=x, z=z, fieldCourseSettings=fieldCourseSettings}
    end
end


---
function AIAutomaticSteering:getIsAIAutomaticSteeringAllowed()
    local spec = self.spec_aiAutomaticSteering
    if spec.steeringFieldCourse == nil then
        return false, g_i18n:getText("ai_automaticSteeringWarningNoCourse")
    end

    if spec.steeringFieldCourse.currentSegment == nil then
        return false, g_i18n:getText("ai_automaticSteeringWarningNoSegment")
    end

    return true
end


---
function AIAutomaticSteering:getAIAutomaticSteeringState()
    local spec = self.spec_aiAutomaticSteering
    if spec.steeringFieldCourse ~= nil then
        if spec.steeringEnabled then
            return AIAutomaticSteering.STATE.ACTIVE
        else
            return AIAutomaticSteering.STATE.AVAILABLE
        end
    end

    return AIAutomaticSteering.STATE.DISABLED
end


---
function AIAutomaticSteering:getAIAutomaticSteeringLookAheadDistance()
    local spec = self.spec_aiAutomaticSteering
    if spec.lookAheadDistance == nil then
        return self:getAIRootNodeMaxZOffset()
    end

    return spec.lookAheadDistance
end


---
function AIAutomaticSteering:getIsSideOffsetReversed()
    for _, vehicle in pairs(self.rootVehicle.childVehicles) do
        if vehicle.spec_plow ~= nil then
            return vehicle.spec_plow.rotationMax
        end
    end

    return false
end


---
function AIAutomaticSteering:setSteeringInput(superFunc, inputValue, isAnalog, deviceCategory)
    local spec = self.spec_aiAutomaticSteering

    if spec.steeringEnabled then
        if deviceCategory ~= InputDevice.CATEGORY.KEYBOARD_MOUSE then
            -- the first 2.5 seconds after enabling the steering, we keep it turned on (let the wheel get back into the rest position)
            if g_time - spec.steeringLastEnableTime > 2500 then
                local diff = inputValue - spec.lastSteeringInputValue
                if math.abs(diff) > 0.1 then
                    self:setAIAutomaticSteeringEnabled(false)
                end
            else
                spec.lastSteeringInputValue = inputValue
            end
        else
            self:setAIAutomaticSteeringEnabled(false)
        end
    else
        spec.lastSteeringInputValue = inputValue
    end

    return superFunc(self, inputValue, isAnalog, deviceCategory)
end


---
function AIAutomaticSteering:updateVehiclePhysics(superFunc, axisForward, axisSide, doHandbrake, dt)
    local spec = self.spec_aiAutomaticSteering
    if spec.steeringEnabled then
        if spec.steeringValue < 0 then
            axisSide = -spec.steeringValue / self.maxRotTime
        else
            axisSide = spec.steeringValue / self.minRotTime
        end

        local acceleration = superFunc(self, axisForward, axisSide, doHandbrake, dt)
        self.rotatedTime = spec.steeringValue

        self.spec_drivable.axisSide = axisSide
        return acceleration
    end

    return superFunc(self, axisForward, axisSide, doHandbrake, dt)
end


---
function AIAutomaticSteering:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_aiAutomaticSteering
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_AI_STEERING, self, AIAutomaticSteering.actionEventSteering, false, true, false, true, nil)
            if actionEventId ~= nil then
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                g_inputBinding:setActionEventText(actionEventId, string.format(g_i18n:getText("ai_modeSelect"), g_i18n:getText("ai_modeSteeringAssist")))

                AIAutomaticSteering.updateActionEvents(self)
            end

            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_AI_STEERING_LINES, self, AIAutomaticSteering.actionEventSteeringLines, false, true, false, true, nil)
            if actionEventId ~= nil then
                g_inputBinding:setActionEventTextVisibility(actionEventId, false)
            end
        end
    end
end


---
function AIAutomaticSteering.actionEventSteering(self, actionName, inputValue, callbackState, isAnalog)
    self:setAIAutomaticSteeringEnabled()
end


---
function AIAutomaticSteering.updateActionEvents(self)
    local spec = self.spec_aiAutomaticSteering
    local actionEvent = spec.actionEvents[InputAction.TOGGLE_AI_STEERING]
    if actionEvent ~= nil then
        local isActive = spec.steeringFieldCourse ~= nil and spec.steeringFieldCourse.currentSegment ~= nil
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, isActive)
    end
end


---
function AIAutomaticSteering.actionEventSteeringLines(self)
    local value = g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_LINES)
    g_gameSettings:setValue(GameSettings.SETTING.STEERING_ASSIST_LINES, not value, true)
end
