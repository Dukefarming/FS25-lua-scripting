


















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function BaleCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Baler, specializations)
end


---
function BaleCounter.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("BaleCounter")

    Dashboard.registerDashboardXMLPaths(schema, "vehicle.baleCounter.dashboards", {"sessionCounter", "lifetimeCounter"})

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleCounter#sessionCounter", "Session counter")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleCounter#lifetimeCounter", "Lifetime counter")
end


---
function BaleCounter.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "doBaleCounterReset", BaleCounter.doBaleCounterReset)
end


---
function BaleCounter.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "dropBale", BaleCounter.dropBale)
end


---
function BaleCounter.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", BaleCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleCounter)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", BaleCounter)
end


---
function BaleCounter:onLoad(savegame)
    local spec = self.spec_baleCounter

    spec.sessionCounter = 0
    spec.lifetimeCounter = 0

    if savegame ~= nil and not savegame.resetVehicles then
        spec.sessionCounter = savegame.xmlFile:getValue(savegame.key .. ".baleCounter#sessionCounter", spec.sessionCounter)
        spec.lifetimeCounter = savegame.xmlFile:getValue(savegame.key .. ".baleCounter#lifetimeCounter", spec.lifetimeCounter)
    end

    spec.hudExtension = BaleCounterHUDExtension.new(self)
end

















---Called on post load to register dashboard value types
function BaleCounter:onRegisterDashboardValueTypes()
    local spec = self.spec_baleCounter

    local sessionCounter = DashboardValueType.new("baleCounter", "sessionCounter")
    sessionCounter:setValue(spec, "sessionCounter")
    self:registerDashboardValueType(sessionCounter)

    local lifetimeCounter = DashboardValueType.new("baleCounter", "lifetimeCounter")
    lifetimeCounter:setValue(spec, "lifetimeCounter")
    self:registerDashboardValueType(lifetimeCounter)
end


---
function BaleCounter:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_baleCounter
    xmlFile:setValue(key.."#sessionCounter", spec.sessionCounter)
    xmlFile:setValue(key.."#lifetimeCounter", spec.lifetimeCounter)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleCounter:onReadStream(streamId, connection)
    local spec = self.spec_baleCounter
    spec.sessionCounter = streamReadUIntN(streamId, BaleCounter.SEND_NUM_BITS)
    spec.lifetimeCounter = streamReadUIntN(streamId, BaleCounter.SEND_NUM_BITS)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleCounter:onWriteStream(streamId, connection)
    local spec = self.spec_baleCounter
    streamWriteUIntN(streamId, spec.sessionCounter, BaleCounter.SEND_NUM_BITS)
    streamWriteUIntN(streamId, spec.lifetimeCounter, BaleCounter.SEND_NUM_BITS)
end


---
function BaleCounter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_baleCounter
        self:clearActionEventsTable(spec.actionEvents)

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.BALE_COUNTER_RESET, self, BaleCounter.actionEventResetCounter, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
        end
    end
end


---Called on load to register external action events
function BaleCounter:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
    if name == "baleCounterReset" then
        self:registerExternalActionEvent(trigger, name, BaleCounter.externalActionEventRegister, BaleCounter.externalActionEventUpdate)
    end
end


---
function BaleCounter.actionEventResetCounter(self, actionName, inputValue, callbackState, isAnalog)
    self:doBaleCounterReset()
end


---
function BaleCounter.externalActionEventRegister(data, vehicle)
    local function actionEvent(_, actionName, inputValue, callbackState, isAnalog)
        vehicle:doBaleCounterReset()
    end

    local _
    _, data.actionEventId = g_inputBinding:registerActionEvent(InputAction.BALE_COUNTER_RESET, data, actionEvent, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
end


---
function BaleCounter.externalActionEventUpdate(data, vehicle)
end


---
function BaleCounter:doBaleCounterReset(noEventSend)
    local spec = self.spec_baleCounter

    spec.sessionCounter = 0

    BaleCounterResetEvent.sendEvent(self, noEventSend)
end


---
function BaleCounter:dropBale(superFunc, baleIndex)
    superFunc(self, baleIndex)

    local spec = self.spec_baleCounter
    spec.sessionCounter = spec.sessionCounter + 1
    spec.lifetimeCounter = spec.lifetimeCounter + 1
end
