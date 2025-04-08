































---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AIModeSelection.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AIDrivable, specializations)
    and SpecializationUtil.hasSpecialization(AIAutomaticSteering, specializations)
end


---
function AIModeSelection.initSpecialization()
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).aiModeSelection#currentMode", "Currently selected AI mode")
    AIUserSettings.registerXMLPaths(schemaSavegame, "vehicles.vehicle(?).aiModeSelection.settings")
end


---
function AIModeSelection.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAIModeChanged")
    SpecializationUtil.registerEvent(vehicleType, "onAIModeSettingsChanged")
end


---
function AIModeSelection.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setAIModeSelection", AIModeSelection.setAIModeSelection)
    SpecializationUtil.registerFunction(vehicleType, "getAIModeSelection", AIModeSelection.getAIModeSelection)
    SpecializationUtil.registerFunction(vehicleType, "aiModeSettingsChanged", AIModeSelection.aiModeSettingsChanged)
    SpecializationUtil.registerFunction(vehicleType, "initializeLoadedAIModeUserSettings", AIModeSelection.initializeLoadedAIModeUserSettings)
    SpecializationUtil.registerFunction(vehicleType, "getAIModeFieldCourseSettings", AIModeSelection.getAIModeFieldCourseSettings)
    SpecializationUtil.registerFunction(vehicleType, "setAIModeFieldCourseSettings", AIModeSelection.setAIModeFieldCourseSettings)
    SpecializationUtil.registerFunction(vehicleType, "applyReadAIModeSettingsFromStream", AIModeSelection.applyReadAIModeSettingsFromStream)
    SpecializationUtil.registerFunction(vehicleType, "writeAIModeSettingsToStream", AIModeSelection.writeAIModeSettingsToStream)
end


---
function AIModeSelection.registerOverwrittenFunctions(vehicleType)
end


---
function AIModeSelection.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIModeSelection)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIModeSelection)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIModeSelection)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIModeSelection)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIModeSelection)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", AIModeSelection)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIModeSelection)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIModeSelection)
end


---Called on loading
-- @param table savegame savegame
function AIModeSelection:onLoad(savegame)
    local spec = self.spec_aiModeSelection
    spec.currentMode = AIModeSelection.MODE.WORKER
    spec.modeChangeStartTime = 0
    spec.lastModeChangeTime = -math.huge

    spec.hudExtension = AIModeHUDExtension.new(self)

    spec.texts = {}
    spec.texts.modeSelect = g_i18n:getText("ai_modeSelect")

    if savegame ~= nil and not savegame.resetVehicles then
        local currentModeName = savegame.xmlFile:getValue(savegame.key .. ".aiModeSelection#currentMode")
        if currentModeName ~= nil then
            spec.currentMode = AIModeSelection.MODE[string.upper(currentModeName)] or spec.currentMode
        end

        if savegame.xmlFile:hasProperty(savegame.key .. ".aiModeSelection.settings") then
            spec.loadedUserSettings = AIUserSettings.new()
            spec.loadedUserSettings:loadFromXML(savegame.xmlFile, savegame.key .. ".aiModeSelection.settings")
        end
    end
end









---
function AIModeSelection:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_aiModeSelection
    xmlFile:setValue(key.."#currentMode", AIModeSelection.MODE.getName(spec.currentMode))

    if spec.userSettings ~= nil then
        spec.userSettings:saveToXML(xmlFile, key .. ".settings")
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIModeSelection:onReadStream(streamId, connection)
    local spec = self.spec_aiModeSelection
    spec.currentMode = streamReadUIntN(streamId, AIModeSelection.NUM_BITS) + 1

    if streamReadBool(streamId) then
        spec.receivedFieldCourseAttributes = FieldCourseSettings.readStream(streamId, connection)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIModeSelection:onWriteStream(streamId, connection)
    local spec = self.spec_aiModeSelection
    streamWriteUIntN(streamId, spec.currentMode - 1, AIModeSelection.NUM_BITS)

    if streamWriteBool(streamId, spec.fieldCourseSettings ~= nil) then
        spec.fieldCourseSettings:writeStream(streamId, connection)
    end
end


---
function AIModeSelection:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- update actionEvents
    if self.isClient then
        AIModeSelection.updateActionEvents(self)
    end

    if not g_currentMission.vehicleSystem.isReloadRunning then
        local spec = self.spec_aiModeSelection
        if spec.loadedUserSettings ~= nil then
            self:initializeLoadedAIModeUserSettings()
        end

        if spec.receivedFieldCourseAttributes ~= nil then
            spec.fieldCourseSettings = FieldCourseSettings.generate(self)
            spec.userSettings = AIUserSettings.new(spec.fieldCourseSettings)

            spec.fieldCourseSettings:applyAttributes(spec.receivedFieldCourseAttributes)
            spec.receivedFieldCourseAttributes = nil

            spec.userSettings:reinitialize(spec.fieldCourseSettings, false)
            spec.userSettings:apply(spec.fieldCourseSettings, spec.currentMode)
        end
    end
end


---
function AIModeSelection:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if isActiveForInputIgnoreSelection then
        local spec = self.spec_aiModeSelection
        if spec.hudExtension ~= nil then
            local hud = g_currentMission.hud
            hud:addHelpExtension(spec.hudExtension)
        end
    end
end


---
function AIModeSelection:onStateChange(state, data)
    if (state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH) and not g_currentMission.vehicleSystem.isReloadRunning then
        local spec = self.spec_aiModeSelection
        spec.fieldCourseSettings = nil
        spec.userSettings = nil
    end
end


---
function AIModeSelection:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_aiModeSelection
        self:clearActionEventsTable(spec.actionEvents)

        if self:getIsActiveForInput(true, true) then
            local _, eventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_AI, self, AIModeSelection.actionEventToggleAIState, true, true, true, true, nil)
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_HIGH)

            AIModeSelection.updateActionEvents(self)
        end
    end
end


---
function AIModeSelection.actionEventToggleAIState(self, actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding, isReset)
    local spec = self.spec_aiModeSelection
    if inputValue == 1 then
        if spec.modeChangeStartTime == 0 then
            spec.modeChangeStartTime = g_time
        end

        if spec.modeChangeStartTime + AIModeSelection.MODE_CHANGE_DURATION < g_time then
            if spec.fieldCourseSettings == nil then
                local _
                spec.fieldCourseSettings, _ = FieldCourseSettings.generate(self.rootVehicle)

                if spec.userSettings ~= nil then
                    spec.userSettings:reinitialize(spec.fieldCourseSettings, true)
                end
            end

            if spec.userSettings == nil then
                spec.userSettings = AIUserSettings.new(spec.fieldCourseSettings)
            end

            local fieldX, fieldZ, _ = FieldCourse.findClosestField(nil, nil, nil, nil, self.rootVehicle:getActiveFarm(), self.rootVehicle, nil, spec.fieldCourseSettings)

            AISettingsDialog.show(spec.userSettings, spec.fieldCourseSettings, self, spec.currentMode, fieldX, fieldZ, self.aiModeSettingsChanged, self)

            spec.modeChangeStartTime = 0
        end
    else
        if spec.modeChangeStartTime ~= 0 then
            spec.modeChangeStartTime = 0

            if not isReset then
                if spec.currentMode == AIModeSelection.MODE.WORKER then
                    if g_currentMission:getHasPlayerPermission("hireAssistant") then
                        self:toggleAIVehicle()
                    else
                        g_currentMission:showBlinkingWarning(g_i18n:getText("ai_startStateNoPermission"), 2000)
                    end
                elseif spec.currentMode == AIModeSelection.MODE.STEERING_ASSIST then
                    local isAllowed, warning = self:getIsAIAutomaticSteeringAllowed()
                    if isAllowed then
                        self:setAIAutomaticSteeringEnabled()
                    else
                        g_currentMission:showBlinkingWarning(warning, 2000)
                    end
                end
            end
        end
    end
end
















---
function AIModeSelection:setAIModeSelection(aiMode, noEventSend)
    local spec = self.spec_aiModeSelection

    if aiMode == nil then
        aiMode = spec.currentMode + 1
        if aiMode > AIModeSelection.NUM_MODES then
            aiMode = 1
        end
    end

    spec.lastModeChangeTime = g_time

    if aiMode ~= spec.currentMode then
        spec.currentMode = aiMode
        SpecializationUtil.raiseEvent(self, "onAIModeChanged", aiMode)

        AIModeSelection.updateActionEvents(self)

        AISetModeEvent.sendEvent(self, aiMode, noEventSend)
    end
end


---
function AIModeSelection:getAIModeSelection()
    return self.spec_aiModeSelection.currentMode
end


---
function AIModeSelection:aiModeSettingsChanged(aiMode)
    local spec = self.spec_aiModeSelection

    AIModeSelectionSettingsEvent.sendEvent(self, spec.fieldCourseSettings, false)

    self:setAIModeSelection(aiMode)
    SpecializationUtil.raiseEvent(self, "onAIModeSettingsChanged", aiMode)
end


---
function AIModeSelection:initializeLoadedAIModeUserSettings()
    local spec = self.spec_aiModeSelection
    if spec.loadedUserSettings ~= nil then
        if spec.fieldCourseSettings == nil then
            local _
            spec.fieldCourseSettings, _ = FieldCourseSettings.generate(self.rootVehicle)
        end

        spec.userSettings = spec.loadedUserSettings
        spec.loadedUserSettings = nil

        spec.userSettings:reinitialize(spec.fieldCourseSettings, true)
        spec.userSettings:apply(spec.fieldCourseSettings, spec.currentMode)
    end
end


---
function AIModeSelection:getAIModeFieldCourseSettings()
    return self.spec_aiModeSelection.fieldCourseSettings
end


---
function AIModeSelection:setAIModeFieldCourseSettings(fieldCourseSettings)
    local spec = self.spec_aiModeSelection

    spec.fieldCourseSettings = fieldCourseSettings

    if spec.userSettings == nil then
        local defaultFieldCourseSettings, _ = FieldCourseSettings.generate(self.rootVehicle)
        spec.userSettings = AIUserSettings.new(defaultFieldCourseSettings)
    end

    spec.userSettings:reinitialize(spec.fieldCourseSettings, false)
    spec.userSettings:apply(spec.fieldCourseSettings, spec.currentMode)

    SpecializationUtil.raiseEvent(self, "onAIModeSettingsChanged", spec.currentMode)
end


---
function AIModeSelection.readAIModeSettingsFromStream(streamId, connection)
    if streamReadBool(streamId) then
        local data = {}
        data.attributes = FieldCourseSettings.readStream(streamId, connection)

        return data
    end

    return nil
end

---
function AIModeSelection:applyReadAIModeSettingsFromStream(data)
    local spec = self.spec_aiModeSelection
    if data ~= nil then
        spec.fieldCourseSettings = FieldCourseSettings.generate(self)
        spec.fieldCourseSettings:applyAttributes(data.attributes)

        spec.loadedUserSettings = nil
    end
end


---
function AIModeSelection:writeAIModeSettingsToStream(streamId, connection)
    self:initializeLoadedAIModeUserSettings()

    local spec = self.spec_aiModeSelection
    if streamWriteBool(streamId, spec.fieldCourseSettings ~= nil) then
        spec.fieldCourseSettings:writeStream(streamId, connection)
    end
end
