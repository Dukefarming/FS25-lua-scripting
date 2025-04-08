



















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function FoldableSteps.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end


---Called while initializing the specialization
function FoldableSteps.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FoldableSteps")

    schema:register(XMLValueType.STRING, "vehicle.foldableSteps#animationName", "Folding Animation Name")
    schema:register(XMLValueType.FLOAT, "vehicle.foldableSteps#animationSpeed", "Folding Animation Speed", 1)
    schema:register(XMLValueType.INT, "vehicle.foldableSteps#fillUnitIndex", "Fill unit that is allowed to be filled / blocked to fill")

    schema:register(XMLValueType.STRING, "vehicle.foldableSteps.controls#action", "Input action to toggle to full movement from state 1 to max state", "IMPLEMENT_EXTRA2")
    schema:registerAutoCompletionDataSource("vehicle.foldableSteps.controls#action", "$dataS/inputActions.xml", "actions.action#name")
    schema:register(XMLValueType.STRING, "vehicle.foldableSteps.controls#actionPos", "Input action to toggle the next fold state")
    schema:registerAutoCompletionDataSource("vehicle.foldableSteps.controls#actionPos", "$dataS/inputActions.xml", "actions.action#name")
    schema:register(XMLValueType.STRING, "vehicle.foldableSteps.controls#actionNeg", "Input action to toggle the last fold state")
    schema:registerAutoCompletionDataSource("vehicle.foldableSteps.controls#actionNeg", "$dataS/inputActions.xml", "actions.action#name")
    schema:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.controls#posText", "Text to display for full folding in positive direction")
    schema:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.controls#negText", "Text to display for full folding in negative direction")

    schema:register(XMLValueType.FLOAT, "vehicle.foldableSteps.state(?)#time", "State time of folding animation (Abs. folding time)")
    schema:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.state(?)#posText", "State text for toggle in positive direction")
    schema:register(XMLValueType.STRING, "vehicle.foldableSteps.state(?)#posContext", "Active context to be allowed to toggle in positive direction (PLAYER or VEHICLE)", "VEHICLE")
    schema:register(XMLValueType.L10N_STRING, "vehicle.foldableSteps.state(?)#negText", "State text for toggle in negative direction")
    schema:register(XMLValueType.STRING, "vehicle.foldableSteps.state(?)#negContext", "Active context to be allowed to toggle in negative direction (PLAYER or VEHICLE)", "VEHICLE")

    schema:register(XMLValueType.BOOL, "vehicle.foldableSteps.state(?)#allowTurnOn", "Turn on is allowed while in this state", false)
    schema:register(XMLValueType.BOOL, "vehicle.foldableSteps.state(?)#allowInfoHud", "Info hud is allowed while in this state", false)
    schema:register(XMLValueType.BOOL, "vehicle.foldableSteps.state(?)#allowFilling", "Allow filling while in this state", false)

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).foldableSteps#animTime", "Fold animation time")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).foldableSteps#state", "Current fold state index")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).foldableSteps#targetState", "Current target fold state index")
end


---Register all functions from the specialization that can be called on vehicle level
-- @param table vehicleType vehicle type
function FoldableSteps.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setFoldableStepsFoldState", FoldableSteps.setFoldableStepsFoldState)
end


---Register all function overwritings
-- @param table vehicleType vehicle type
function FoldableSteps.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", FoldableSteps.getCanBeTurnedOn)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", FoldableSteps.getTurnedOnNotAllowedWarning)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRequiresPower", FoldableSteps.getRequiresPower)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowHudInfoTrigger", FoldableSteps.getAllowHudInfoTrigger)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", FoldableSteps.getFillUnitSupportsToolType)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function FoldableSteps.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FoldableSteps)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FoldableSteps)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FoldableSteps)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FoldableSteps)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", FoldableSteps)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", FoldableSteps)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", FoldableSteps)
end


---Called on load
-- @param table savegame savegame
function FoldableSteps:onLoad(savegame)
    local spec = self.spec_foldableSteps

    local animationName = self.xmlFile:getValue("vehicle.foldableSteps#animationName")
    if animationName ~= nil then
        spec.animationName = self.xmlFile:getValue("vehicle.foldableSteps#animationName")
        spec.animationSpeed = self.xmlFile:getValue("vehicle.foldableSteps#animationSpeed", 1)

        spec.action = InputAction[self.xmlFile:getValue("vehicle.foldableSteps.controls#action", "IMPLEMENT_EXTRA2")] or InputAction.IMPLEMENT_EXTRA2
        spec.actionPos = InputAction[self.xmlFile:getValue("vehicle.foldableSteps.controls#actionPos")]
        spec.posText = self.xmlFile:getValue("vehicle.foldableSteps.controls#posText", nil, self.customEnvironment, false)
        spec.actionNeg = InputAction[self.xmlFile:getValue("vehicle.foldableSteps.controls#actionNeg")]
        spec.negText = self.xmlFile:getValue("vehicle.foldableSteps.controls#negText", nil, self.customEnvironment, false)

        spec.fillUnitIndex = self.xmlFile:getValue("vehicle.foldableSteps#fillUnitIndex")

        spec.stateIndex = 1
        spec.stateTargetIndex = 1

        spec.states = {}
        for _, key in self.xmlFile:iterator("vehicle.foldableSteps.state") do
            local state = {}
            state.time = self.xmlFile:getValue(key .. "#time")
            if state.time ~= nil then
                state.time = (state.time * 1000) / self:getAnimationDuration(spec.animationName)
                state.posText = self.xmlFile:getValue(key .. "#posText", nil, self.customEnvironment, false)
                state.posContext = self.xmlFile:getValue(key .. "#posContext", "VEHICLE")
                state.negText = self.xmlFile:getValue(key .. "#negText", nil, self.customEnvironment, false)
                state.negContext = self.xmlFile:getValue(key .. "#negContext", "VEHICLE")

                state.allowTurnOn = self.xmlFile:getValue(key .. "#allowTurnOn", false)
                state.allowInfoHud = self.xmlFile:getValue(key .. "#allowInfoHud", false)
                state.allowFilling = self.xmlFile:getValue(key .. "#allowFilling", false)

                if state.posText ~= nil or state.negText ~= nil then
                    table.insert(spec.states, state)
                else
                    Logging.xmlWarning(self.xmlFile, "Missing texts for state in '%s'", key)
                end
            else
                Logging.xmlWarning(self.xmlFile, "Invalid state in '%s'", key)
            end
        end
        spec.maxState = #spec.states

        spec.texts = {}
        spec.texts.stateTextPos = g_i18n:getText("action_foldableSteps_unfold")
        spec.texts.stateTextNeg = g_i18n:getText("action_foldableSteps_fold")
        spec.texts.warningNotAllowedPlayer = g_i18n:getText("warning_actionNotAllowedPlayer")
        spec.texts.warningNotAllowedVehicle = g_i18n:getText("warning_actionNotAllowedVehicle")
        spec.texts.warningUnfoldFirst = string.format(g_i18n:getText("warning_firstUnfoldTheTool"), self.typeDesc)

        if #spec.states == 0 then
            Logging.xmlWarning(self.xmlFile, "No states found in 'vehicle.foldableSteps'")
        else
            if savegame ~= nil and not savegame.resetVehicles then
                spec.loadedAnimTime = savegame.xmlFile:getValue(savegame.key .. ".foldableSteps#animTime", 0)
                spec.stateIndex = savegame.xmlFile:getValue(savegame.key .. ".foldableSteps#state", spec.stateIndex)
                spec.stateTargetIndex = savegame.xmlFile:getValue(savegame.key .. ".foldableSteps#targetState", spec.stateTargetIndex)
            end
        end
    else
        SpecializationUtil.removeEventListener(self, "onPostLoad", FoldableSteps)
        SpecializationUtil.removeEventListener(self, "onReadStream", FoldableSteps)
        SpecializationUtil.removeEventListener(self, "onWriteStream", FoldableSteps)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", FoldableSteps)
        SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", FoldableSteps)
    end
end


---Called after loading
-- @param table savegame savegame
function FoldableSteps:onPostLoad(savegame)
    local spec = self.spec_foldableSteps
    if spec.loadedAnimTime ~= nil then
        self:setAnimationTime(spec.animationName, spec.loadedAnimTime, true, false)
    end
end


---
function FoldableSteps:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_foldableSteps
    if spec.animationName ~= nil then
        xmlFile:setValue(key.."#animTime", self:getAnimationTime(spec.animationName))
        xmlFile:setValue(key.."#state", spec.stateIndex)
        xmlFile:setValue(key.."#targetState", spec.stateTargetIndex)
    end
end


---
function FoldableSteps:onReadStream(streamId, connection)
    local spec = self.spec_foldableSteps

    local animTime = streamReadFloat32(streamId)
    self:setAnimationTime(spec.animationName, animTime, true, false)

    spec.stateIndex = streamReadUIntN(streamId, FoldableSteps.STATE_NUM_BITS)
    local targetState = streamReadUIntN(streamId, FoldableSteps.STATE_NUM_BITS)
    self:setFoldableStepsFoldState(targetState, true)
end


---
function FoldableSteps:onWriteStream(streamId, connection)
    local spec = self.spec_foldableSteps
    streamWriteFloat32(streamId, self:getAnimationTime(spec.animationName))

    streamWriteUIntN(streamId, spec.stateIndex, FoldableSteps.STATE_NUM_BITS)
    streamWriteUIntN(streamId, spec.stateTargetIndex, FoldableSteps.STATE_NUM_BITS)
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function FoldableSteps:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_foldableSteps
    if spec.stateIndex ~= spec.stateTargetIndex then
        if not self:getIsAnimationPlaying(spec.animationName) then
            spec.stateIndex = spec.stateTargetIndex
            FoldableSteps.updateActionEvents(self, spec.actionEvents)
        end

        self:raiseActive()
    end
end


---Register action events
-- @param boolean isActiveForInput vehicle is currently active for input
-- @param boolean isActiveForInputIgnoreSelection vehicle is currently active for input regardless of the current vehicle selection
function FoldableSteps:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_foldableSteps
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.action, self, FoldableSteps.actionEventFold, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)

            if spec.actionPos ~= nil then
                _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.actionPos, self, FoldableSteps.actionEventFoldPos, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            end

            if spec.actionNeg ~= nil then
                _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.actionNeg, self, FoldableSteps.actionEventFoldNeg, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
            end

            FoldableSteps.updateActionEvents(self, spec.actionEvents)
        end
    end
end


---Called on load to register external action events
function FoldableSteps:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
    if name == "foldableStepsFull" then
        self:registerExternalActionEvent(trigger, name, FoldableSteps.externalActionEventFoldRegister, FoldableSteps.externalActionEventFoldUpdate)
    elseif name == "foldableStepsNextPos" then
        if self.spec_foldableSteps.actionPos ~= nil then
            self:registerExternalActionEvent(trigger, name, FoldableSteps.externalActionEventFoldPosRegister, FoldableSteps.externalActionEventFoldPosUpdate)
        end
    elseif name == "foldableStepsNextNeg" then
        if self.spec_foldableSteps.actionNeg ~= nil then
            self:registerExternalActionEvent(trigger, name, FoldableSteps.externalActionEventFoldNegRegister, FoldableSteps.externalActionEventFoldNegUpdate)
        end
    end
end


---
function FoldableSteps:setFoldableStepsFoldState(stateTargetIndex, noEventSend)
    local spec = self.spec_foldableSteps

    spec.stateTargetIndex = math.clamp(stateTargetIndex, 1, spec.maxState)
    local targetState = spec.states[spec.stateTargetIndex]

    local animationTime = self:getAnimationTime(spec.animationName)
    local difference = animationTime-targetState.time
    if math.abs(difference) > 0.0001 then
        self:setAnimationStopTime(spec.animationName, targetState.time)
        self:playAnimation(spec.animationName, spec.animationSpeed * -math.sign(difference), animationTime, true)
        self:raiseActive()
    end

    FoldableSteps.updateActionEvents(self, spec.actionEvents)
    FoldableStepsChangeStateEvent.sendEvent(self, spec.stateTargetIndex, noEventSend)
end


---
function FoldableSteps.updateActionEvents(self, actionEvents)
    local spec = self.spec_foldableSteps

    local isMoving = spec.stateIndex ~= spec.stateTargetIndex

    local actionEvent = actionEvents[spec.action]
    if actionEvent ~= nil then
        local text = spec.stateIndex < spec.maxState and spec.posText or spec.negText
        if text ~= nil then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(text, self.typeDesc))
        end
        g_inputBinding:setActionEventActive(actionEvent.actionEventId, text ~= nil)
    end

    actionEvent = actionEvents[spec.actionPos]
    if actionEvent ~= nil then
        if not isMoving then
            local state = spec.states[spec.stateIndex]
            if state.posText ~= nil then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(spec.texts.stateTextPos, string.format(state.posText, self.typeDesc)))
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
            else
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
            end
        else
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
        end
    end

    actionEvent = actionEvents[spec.actionNeg]
    if actionEvent ~= nil then
        if not isMoving then
            local state = spec.states[spec.stateIndex]
            if state.negText ~= nil then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(spec.texts.stateTextNeg, string.format(state.negText, self.typeDesc)))
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
            else
                g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
            end
        else
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
        end
    end
end


---
function FoldableSteps.actionEventFold(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_foldableSteps
    local stateTargetIndex
    if spec.stateIndex ~= spec.stateTargetIndex then
        if spec.stateIndex < spec.stateTargetIndex then
            stateTargetIndex = 1
        else
            stateTargetIndex = spec.maxState
        end
    else
        if spec.stateIndex < spec.maxState then
            stateTargetIndex = spec.maxState
        else
            stateTargetIndex = 1
        end
    end

    if stateTargetIndex ~= nil and FoldableSteps.updateFoldStateChangeAllowed(self, stateTargetIndex) then
        self:setFoldableStepsFoldState(stateTargetIndex)
    end
end


---
function FoldableSteps.actionEventFoldPos(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_foldableSteps
    local stateTargetIndex = spec.stateTargetIndex + 1
    if FoldableSteps.updateFoldStateChangeAllowed(self, stateTargetIndex, g_inputBinding:getContextName()) then
        self:setFoldableStepsFoldState(stateTargetIndex)
    end
end


---
function FoldableSteps.actionEventFoldNeg(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_foldableSteps
    local stateTargetIndex = spec.stateTargetIndex - 1
    if FoldableSteps.updateFoldStateChangeAllowed(self, stateTargetIndex, g_inputBinding:getContextName()) then
        self:setFoldableStepsFoldState(stateTargetIndex)
    end
end


---
function FoldableSteps.updateFoldStateChangeAllowed(self, stateTargetIndex, context)
    local spec = self.spec_foldableSteps
    local allowed, warning = self:getIsFoldAllowed(stateTargetIndex > spec.stateIndex and self.spec_foldable.turnOnFoldDirection or self.spec_foldable.turnOnFoldDirection, false)
    if not allowed then
        g_currentMission:showBlinkingWarning(warning, 2000)

        return false
    end

    local isPowered, powerWarning = self:getIsPowered()
    if not isPowered then
        g_currentMission:showBlinkingWarning(powerWarning, 2000)

        return false
    end

    if context ~= nil then
        local oldState = spec.states[spec.stateIndex]
        if (stateTargetIndex > spec.stateIndex and oldState.posContext ~= context)
        or (stateTargetIndex < spec.stateIndex and oldState.negContext ~= context) then
            if context == Vehicle.INPUT_CONTEXT_NAME then
                g_currentMission:showBlinkingWarning(string.format(spec.texts.warningNotAllowedPlayer, self.typeDesc), 2000)
            else
                g_currentMission:showBlinkingWarning(string.format(spec.texts.warningNotAllowedVehicle, self.typeDesc), 2000)
            end

            return false
        end
    end

    return true
end


---
function FoldableSteps.externalActionEventFoldRegister(data, vehicle)
    local spec = vehicle.spec_foldableSteps

    local function actionEvent(_, actionName, inputValue, callbackState, isAnalog)
        Motorized.tryStartMotor(vehicle)
        FoldableSteps.actionEventFold(vehicle, actionName, inputValue, callbackState, isAnalog)
    end

    local _
    _, data.actionEventId = g_inputBinding:registerActionEvent(spec.action, data, actionEvent, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end


---
function FoldableSteps.externalActionEventFoldUpdate(data, vehicle)
    local spec = vehicle.spec_foldableSteps
    local text = spec.stateIndex < spec.maxState and spec.posText or spec.negText
    if text ~= nil then
        g_inputBinding:setActionEventText(data.actionEventId, string.format(text, vehicle.typeDesc))
    end
    g_inputBinding:setActionEventActive(data.actionEventId, text ~= nil)
end


---
function FoldableSteps.externalActionEventFoldPosRegister(data, vehicle)
    local spec = vehicle.spec_foldableSteps

    local function actionEvent(_, actionName, inputValue, callbackState, isAnalog)
        Motorized.tryStartMotor(vehicle)
        FoldableSteps.actionEventFoldPos(vehicle, actionName, inputValue, callbackState, isAnalog)
    end

    local _
    _, data.actionEventId = g_inputBinding:registerActionEvent(spec.actionPos, data, actionEvent, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end


---
function FoldableSteps.externalActionEventFoldPosUpdate(data, vehicle)
    local spec = vehicle.spec_foldableSteps
    local isMoving = spec.stateIndex ~= spec.stateTargetIndex
    if not isMoving then
        local state = spec.states[spec.stateIndex]
        if state.posText ~= nil then
            g_inputBinding:setActionEventText(data.actionEventId, string.format(spec.texts.stateTextPos, string.format(state.posText, vehicle.typeDesc)))
            g_inputBinding:setActionEventActive(data.actionEventId, true)
        else
            g_inputBinding:setActionEventActive(data.actionEventId, false)
        end
    else
        g_inputBinding:setActionEventActive(data.actionEventId, false)
    end
end


---
function FoldableSteps.externalActionEventFoldNegRegister(data, vehicle)
    local spec = vehicle.spec_foldableSteps

    local function actionEvent(_, actionName, inputValue, callbackState, isAnalog)
        Motorized.tryStartMotor(vehicle)
        FoldableSteps.actionEventFoldNeg(vehicle, actionName, inputValue, callbackState, isAnalog)
    end

    local _
    _, data.actionEventId = g_inputBinding:registerActionEvent(spec.actionNeg, data, actionEvent, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end


---
function FoldableSteps.externalActionEventFoldNegUpdate(data, vehicle)
    local spec = vehicle.spec_foldableSteps
    local isMoving = spec.stateIndex ~= spec.stateTargetIndex
    if not isMoving then
        local state = spec.states[spec.stateIndex]
        if state.negText ~= nil then
            g_inputBinding:setActionEventText(data.actionEventId, string.format(spec.texts.stateTextNeg, string.format(state.negText, vehicle.typeDesc)))
            g_inputBinding:setActionEventActive(data.actionEventId, true)
        else
            g_inputBinding:setActionEventActive(data.actionEventId, false)
        end
    else
        g_inputBinding:setActionEventActive(data.actionEventId, false)
    end
end


---
function FoldableSteps:getCanBeTurnedOn(superFunc)
    local spec = self.spec_foldableSteps
    if spec.animationName ~= nil then
        local state = spec.states[spec.stateIndex]
        if spec.stateIndex ~= spec.stateTargetIndex or not state.allowTurnOn then
            return false
        end
    end

    return superFunc(self)
end


---
function FoldableSteps:getTurnedOnNotAllowedWarning(superFunc)
    local spec = self.spec_foldableSteps
    if spec.animationName ~= nil then
        local state = spec.states[spec.stateIndex]
        if spec.stateIndex ~= spec.stateTargetIndex or not state.allowTurnOn then
            return spec.texts.warningUnfoldFirst
        end
    end

    return superFunc(self)
end


---
function FoldableSteps:getRequiresPower(superFunc)
    local spec = self.spec_foldableSteps
    if spec.animationName ~= nil then
        if spec.stateIndex ~= spec.stateTargetIndex then
            return true
        end
    end

    return superFunc(self)
end


---
function FoldableSteps:getAllowHudInfoTrigger(superFunc)
    local spec = self.spec_foldableSteps
    if spec.animationName ~= nil then
        local state = spec.states[spec.stateIndex]
        if not state.allowInfoHud then
            return false
        end
    end

    return superFunc(self)
end


---
function FoldableSteps:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
    local spec = self.spec_foldableSteps
    if spec.animationName ~= nil then
        -- tool type undefined is always allowed
        if toolType ~= ToolType.UNDEFINED then
            if fillUnitIndex == spec.fillUnitIndex then
                local state = spec.states[spec.stateIndex]
                if not state.allowFilling then
                    return false
                end
            end
        end
    end

    return superFunc(self, fillUnitIndex, toolType)
end
