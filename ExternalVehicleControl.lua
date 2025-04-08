















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function ExternalVehicleControl.prerequisitesPresent(specializations)
    return true
end


---Called while initializing the specialization
function ExternalVehicleControl.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ExternalVehicleControl")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.externalVehicleControl.trigger(?)#node", "Player trigger node")
    schema:register(XMLValueType.STRING, ExternalVehicleControl.FUNCTION_XML_PATH .. "#name", "Name of the function to be available")

    schema:setXMLSpecializationType()
end


---Register all custom events from this specialization
-- @param table vehicleType vehicle type
function ExternalVehicleControl.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onRegisterExternalActionEvents")
end


---Register all functions from the specialization that can be called on vehicle level
-- @param table vehicleType vehicle type
function ExternalVehicleControl.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "registerExternalActionEvent", ExternalVehicleControl.registerExternalActionEvent)
end


---Register all function overwritings
-- @param table vehicleType vehicle type
function ExternalVehicleControl.registerOverwrittenFunctions(vehicleType)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function ExternalVehicleControl.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ExternalVehicleControl)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ExternalVehicleControl)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ExternalVehicleControl)
end


---Called on load
-- @param table savegame savegame
function ExternalVehicleControl:onLoadFinished(savegame)
    local spec = self.spec_externalVehicleControl

    spec.triggers = {}

    for _, key in self.xmlFile:iterator("vehicle.externalVehicleControl.trigger") do
        local trigger = {}
        trigger.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if trigger.node ~= nil then
            if not CollisionFlag.getHasMaskFlagSet(trigger.node, CollisionFlag.PLAYER) then
                Logging.xmlWarning(self.xmlFile, "Invalid collision mask flags set in '%s'. Player bit missing!", key)
            end

            trigger.vehicle = self
            trigger.isPlayerInRange = false
            trigger.controlFunctions = {}

            trigger.callbackId = addTrigger(trigger.node, "onExternalVehicleControlTriggerCallback", trigger, false, ExternalVehicleControl.onExternalVehicleControlTriggerCallback)

            for _, funcKey in self.xmlFile:iterator(key .. ".function") do
                local name = self.xmlFile:getValue(funcKey .. "#name")
                if name ~= nil then
                    SpecializationUtil.raiseEvent(self, "onRegisterExternalActionEvents", trigger, name, self.xmlFile, funcKey)
                end
            end

            trigger.activatable = ExternalVehicleControlActivatable.new(self, trigger)

            table.insert(spec.triggers, trigger)
        end
    end

    if #spec.triggers == 0 then
        SpecializationUtil.removeEventListener(self, "onDelete", ExternalVehicleControl)
        SpecializationUtil.removeEventListener(self, "onUpdateTick", ExternalVehicleControl)
    end
end


---Called on deleting
function ExternalVehicleControl:onDelete()
    local spec = self.spec_externalVehicleControl
    if spec.triggers ~= nil then
        for _, trigger in ipairs(spec.triggers) do
            if trigger.node ~= nil then
                removeTrigger(trigger.node, trigger.callbackId)
            end

            g_currentMission.activatableObjectsSystem:removeActivatable(trigger.activatable)
        end
    end
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function ExternalVehicleControl:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_externalVehicleControl
    for _, trigger in ipairs(spec.triggers) do
        if trigger.isPlayerInRange then
            trigger.activatable:updateText()
            self:raiseActive()
        end
    end
end


---
function ExternalVehicleControl:registerExternalActionEvent(trigger, name, registerFunc, updateFunc)
    local controlFunction = {}
    controlFunction.registerFunc = registerFunc
    controlFunction.updateFunc = updateFunc

    table.insert(trigger.controlFunctions, controlFunction)
end


---Callback when trigger changes state
-- @param integer triggerId
-- @param integer otherId
-- @param boolean onEnter
-- @param boolean onLeave
-- @param boolean onStay
function ExternalVehicleControl.onExternalVehicleControlTriggerCallback(trigger, triggerId, otherId, onEnter, onLeave, onStay)
    if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
        if onEnter then
            trigger.isPlayerInRange = true
            trigger.vehicle:raiseActive()

            trigger.activatable:updateText()
            g_currentMission.activatableObjectsSystem:addActivatable(trigger.activatable)
        else
            trigger.isPlayerInRange = false
            g_currentMission.activatableObjectsSystem:removeActivatable(trigger.activatable)
        end
    end
end


---Callback when trigger changes state
local ExternalVehicleControlActivatable_mt = Class(ExternalVehicleControlActivatable)


---
function ExternalVehicleControlActivatable.new(vehicle, trigger)
    local self = setmetatable({}, ExternalVehicleControlActivatable_mt)

    self.vehicle = vehicle
    self.trigger = trigger
    self.activateText = ""
    self:updateText()

    return self
end


---
function ExternalVehicleControlActivatable:registerCustomInput(inputContext)
    -- only allow controls while in player context
    -- otherwise they can be registered on vehicle onEnter before the player has left the trigger (tabbing from trigger to the vehicle)
    -- this can cause a failed registration of the inputs in the vehicle
    -- issue #51640 might be related
    if inputContext ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
        return
    end

    for i, controlFunction in ipairs(self.trigger.controlFunctions) do
        if controlFunction.registerFunc ~= nil then
            controlFunction:registerFunc(self.vehicle)
        end
    end
end


---
function ExternalVehicleControlActivatable:removeCustomInput(inputContext)
    for i, controlFunction in ipairs(self.trigger.controlFunctions) do
        g_inputBinding:removeActionEventsByTarget(controlFunction)
    end
end


---
function ExternalVehicleControlActivatable:getIsActivatable()
    if not g_currentMission.accessHandler:canPlayerAccess(self.vehicle) then
        return false
    end

    return self.trigger.isPlayerInRange
end


---Called on activate object
function ExternalVehicleControlActivatable:run()
end


---
function ExternalVehicleControlActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.trigger.node)
    return MathUtil.vector3Length(x-tx, y-ty, z-tz)
end


---
function ExternalVehicleControlActivatable:updateText()
    for i, controlFunction in ipairs(self.trigger.controlFunctions) do
        if controlFunction.updateFunc ~= nil then
            controlFunction:updateFunc(self.vehicle)
        end
    end
end
