













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function HUDInfoTrigger.prerequisitesPresent(specializations)
    return true
end


---Called while initializing the specialization
function HUDInfoTrigger.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HUDInfoTrigger")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.hudInfoTrigger#triggerNode", "Player or vehicle trigger node")

    schema:setXMLSpecializationType()
end


---Register all functions from the specialization that can be called on vehicle level
-- @param table vehicleType vehicle type
function HUDInfoTrigger.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInHudInfoTrigger", HUDInfoTrigger.getIsPlayerInHudInfoTrigger)
    SpecializationUtil.registerFunction(vehicleType, "getAllowHudInfoTrigger", HUDInfoTrigger.getAllowHudInfoTrigger)
end


---Register all function overwritings
-- @param table vehicleType vehicle type
function HUDInfoTrigger.registerOverwrittenFunctions(vehicleType)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function HUDInfoTrigger.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HUDInfoTrigger)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", HUDInfoTrigger)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", HUDInfoTrigger)
end


---Called on load
-- @param table savegame savegame
function HUDInfoTrigger:onLoad(savegame)
    local spec = self.spec_hudInfoTrigger

    spec.triggerNode = self.xmlFile:getValue("vehicle.hudInfoTrigger#triggerNode", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil then
        spec.callbackId = addTrigger(spec.triggerNode, "onHudInfoTriggerCallback", self, false, HUDInfoTrigger.onHudInfoTriggerCallback)

        spec.enteredObjects = {}
    else
        SpecializationUtil.removeEventListener(self, "onDelete", HUDInfoTrigger)
        SpecializationUtil.removeEventListener(self, "onUpdate", HUDInfoTrigger)
    end
end


---Called on deleting
function HUDInfoTrigger:onDelete()
    local spec = self.spec_hudInfoTrigger
    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode, spec.callbackId)
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function HUDInfoTrigger:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if not isActiveForInputIgnoreSelection then
        if self:getIsPlayerInHudInfoTrigger() then
            self.rootVehicle:draw()
            self:raiseActive()
        end
    end
end


---Callback when trigger changes state
-- @param integer triggerId
-- @param integer otherId
-- @param boolean onEnter
-- @param boolean onLeave
-- @param boolean onStay
function HUDInfoTrigger.onHudInfoTriggerCallback(self, triggerId, otherId, onEnter, onLeave, onStay)
    local object = g_currentMission:getNodeObject(otherId)
    if object == nil then
        if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
            object = g_localPlayer
        end
    end

    if object ~= nil and object ~= self then
        local objectId = NetworkUtil.getObjectId(object)
        if objectId ~= nil then
            local spec = self.spec_hudInfoTrigger
            if onEnter then
                spec.enteredObjects[objectId] = (spec.enteredObjects[objectId] or 0) + 1
                self:raiseActive()
            elseif onLeave then
                spec.enteredObjects[objectId] = (spec.enteredObjects[objectId] or 0) - 1
                if spec.enteredObjects[objectId] <= 0 then
                    spec.enteredObjects[objectId] = nil
                end
            end
        end
    end
end


---Returns if the display of the hud extensions is allowed or not
function HUDInfoTrigger:getAllowHudInfoTrigger()
    return true
end


---Get if current player is in the HUD trigger as character or with a vehicle
function HUDInfoTrigger:getIsPlayerInHudInfoTrigger()
    if not self:getAllowHudInfoTrigger() then
        return false
    end

    local spec = self.spec_hudInfoTrigger

    local localPlayer = g_localPlayer
    if localPlayer == nil then
        return false
    end

    if not localPlayer:getIsInVehicle() then
        local objectId = NetworkUtil.getObjectId(g_localPlayer)
        return spec.enteredObjects[objectId] ~= nil
    end

    local playerVehicle = localPlayer:getCurrentVehicle()
    if playerVehicle == nil then
        return false
    end

    local childVehicles = playerVehicle.childVehicles
    for _, vehicle in ipairs(childVehicles) do
        local objectId = NetworkUtil.getObjectId(vehicle)
        if spec.enteredObjects[objectId] ~= nil then
            return true
        end
    end

    return false
end
