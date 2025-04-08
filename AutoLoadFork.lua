















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AutoLoadFork.prerequisitesPresent(specializations)
    return true
end


---
function AutoLoadFork.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AutoLoadFork")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadFork#triggerNode", "Trigger to detect the pallets")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadFork#jointNode", "Node to join the pallets to")

    schema:register(XMLValueType.STRING, "vehicle.autoLoadFork.liftAnimation#name", "Lift animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoadFork.liftAnimation#speedScale", "Animation speed scale")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).autoLoadFork#liftAnimationTime", "Current state of lift animation")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).autoLoadFork.mountedObject(?)#vehicleUniqueId", "Vehicle unique id")
    Bale.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).autoLoadFork.mountedObject(?).bale")
end


---
function AutoLoadFork.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onAutoLoadForkTriggerCallback", AutoLoadFork.onAutoLoadForkTriggerCallback)
    SpecializationUtil.registerFunction(vehicleType, "getCanUnloadFork", AutoLoadFork.getCanUnloadFork)
    SpecializationUtil.registerFunction(vehicleType, "getIsForkUnloadingAllowed", AutoLoadFork.getIsForkUnloadingAllowed)
    SpecializationUtil.registerFunction(vehicleType, "doUnloadFork", AutoLoadFork.doUnloadFork)
    SpecializationUtil.registerFunction(vehicleType, "onUnmountObject", AutoLoadFork.onUnmountObject)
    SpecializationUtil.registerFunction(vehicleType, "mountObjectToFork", AutoLoadFork.mountObjectToFork)
end


---
function AutoLoadFork.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AutoLoadFork.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AutoLoadFork.removeFromPhysics)
end


---
function AutoLoadFork.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoadFork)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutoLoadFork)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoadFork)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoadFork)
    SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AutoLoadFork)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutoLoadFork)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AutoLoadFork)
end


---
function AutoLoadFork:onLoad(savegame)
    local spec = self.spec_autoLoadFork

    if self.isServer then
        spec.triggerNode = self.xmlFile:getValue("vehicle.autoLoadFork#triggerNode", nil, self.components, self.i3dMappings)
        if spec.triggerNode ~= nil then
            addTrigger(spec.triggerNode, "onAutoLoadForkTriggerCallback", self)
        end
    end

    spec.jointNode = self.xmlFile:getValue("vehicle.autoLoadFork#jointNode", nil, self.components, self.i3dMappings)

    spec.remountDistance = 0

    spec.mountedObjects = {}
    spec.unmountedObjects = {}

    spec.liftAnimation = {}
    spec.liftAnimation.name = self.xmlFile:getValue("vehicle.autoLoadFork.liftAnimation#name")
    spec.liftAnimation.speedScale = self.xmlFile:getValue("vehicle.autoLoadFork.liftAnimation#speedScale", 1)
end


---
function AutoLoadFork:onPostLoad(savegame)
    local spec = self.spec_autoLoadFork

    if savegame ~= nil and not savegame.resetVehicles then
        local xmlFile = savegame.xmlFile
        if spec.liftAnimation.name ~= nil then
            local liftAnimationTime = xmlFile:getValue(savegame.key..".autoLoadFork#liftAnimationTime")
            if liftAnimationTime ~= nil then
                self:setAnimationTime(spec.liftAnimation.name, liftAnimationTime, true, false)
            end
        end

        local key = string.format("%s.autoLoadFork.mountedObject", savegame.key)
        spec.pendingVehicles = {}
        xmlFile:iterate(key, function(_, objectKey)
            local vehicleUniqueId = xmlFile:getValue(objectKey .. "#vehicleUniqueId")

            if vehicleUniqueId ~= nil then
                local pendingVehicle = {
                    vehicleUniqueId = vehicleUniqueId
                }
                table.insert(spec.pendingVehicles, pendingVehicle)
            elseif xmlFile:hasProperty(objectKey .. ".bale") then
                local bale = Bale.new(self.isServer, self.isClient)
                if bale:loadFromXMLFile(xmlFile, objectKey .. ".bale", false) then
                    bale:register()
                    self:mountObjectToFork(bale)
                else
                    Logging.xmlWarning(xmlFile, "Could not load autoLoadFork bale for '%s'", objectKey)
                    bale:delete()
                end
            end
        end)
    end
end


---
function AutoLoadFork:onDelete()
    local spec = self.spec_autoLoadFork

    if self.isServer then
        for _, mountedObjectId in pairs(spec.mountedObjects) do
            local object = NetworkUtil.getObject(mountedObjectId)
            if object ~= nil then
                object:unmountKinematic()
            end
        end
    end

    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end
end






























---
function AutoLoadFork:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_autoLoadFork
    if spec.liftAnimation.name ~= nil then
        xmlFile:setValue(key.."#liftAnimationTime", self:getAnimationTime(spec.liftAnimation.name))
    end

    local i = 0
    for _, mountedObjectId in pairs(spec.mountedObjects) do
        local object = NetworkUtil.getObject(mountedObjectId)
        if object ~= nil then
            local mountKey = string.format("%s.mountedObject(%d)", key, i)

            if object:isa(Vehicle) then
                xmlFile:setValue(mountKey .. "#vehicleUniqueId", object:getUniqueId())
            elseif object:isa(Bale) then
                object:saveToXMLFile(xmlFile, mountKey .. ".bale")
            end

            i = i + 1
        end
    end
end


---
function AutoLoadFork:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_autoLoadFork
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.UNLOAD_FORK, self, AutoLoadFork.actionEventUnloadFork, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
        end
    end
end


---Called if root vehicle changes
-- @param table rootVehicle root vehicle
function AutoLoadFork:onRootVehicleChanged(rootVehicle)
    local spec = self.spec_autoLoadFork
    local actionController = rootVehicle.actionController
    if actionController ~= nil then
        if spec.controlledAction ~= nil then
            spec.controlledAction:updateParent(actionController)
            return
        end

        spec.controlledAction = actionController:registerAction("forkLifting", nil, 4)
        spec.controlledAction:setCallback(self, AutoLoadFork.actionControllerEvent)
        spec.controlledAction:setActionIcons("LOADER_LOWER", "LOADER_LIFT", false)
    else
        if spec.controlledAction ~= nil then
            spec.controlledAction:remove()
            spec.controlledAction = nil
        end
    end
end


---
function AutoLoadFork.actionControllerEvent(self, direction)
    local spec = self.spec_autoLoadFork

    if spec.liftAnimation.name ~= nil then
        self:playAnimation(spec.liftAnimation.name, spec.liftAnimation.speedScale * direction, self:getAnimationTime(spec.liftAnimation.name))
    end

    return true
end


---
function AutoLoadFork.onDeleteMountedObject(self, object)
    local spec = self.spec_autoLoadFork
    for i=#spec.mountedObjects, 1, -1 do
        local mountedObjectId = spec.mountedObjects[i]
        if mountedObjectId == object.id then
            table.remove(spec.mountedObjects, i)
            table.insert(spec.unmountedObjects, {objectId=object.id, time=g_time})
            break
        end
    end
end


---
function AutoLoadFork:onAutoLoadForkTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    local object = g_currentMission:getNodeObject(otherId)
    if object ~= nil and (object.isPallet or object:isa(Bale)) then
        local spec = self.spec_autoLoadFork
        if onEnter then
            if #spec.mountedObjects == 0 and spec.remountDistance <= 0 then
                for i=1, #spec.mountedObjects do
                    if spec.mountedObjects[i] == object.id then
                        return
                    end
                end

                for i=#spec.unmountedObjects, 1, -1 do
                    local unmountedObject = spec.unmountedObjects[i]
                    if unmountedObject.objectId == object.id then
                        if unmountedObject.time + AutoLoadFork.BLOCK_REMOUNT_TIME > g_time then
                            return -- block mounting if it directly reenters the trigger
                        end
                    elseif unmountedObject.time + AutoLoadFork.BLOCK_REMOUNT_TIME < g_time then
                        table.remove(spec.unmountedObjects, i)
                    end
                end

                self:mountObjectToFork(object)
            end
        elseif onLeave then
            for i=#spec.mountedObjects, 1, -1 do
                local mountedObjectId = spec.mountedObjects[i]
                if mountedObjectId == object.id then
                    object:removeDeleteListener(self, AutoLoadFork.onDeleteMountedObject)

                    table.remove(spec.mountedObjects, i)
                    table.insert(spec.unmountedObjects, {objectId=object.id, time=g_time})
                    break
                end
            end
        end
    end
end
















































---
function AutoLoadFork.actionEventUnloadFork(self, actionName, inputValue, callbackState, isAnalog)
    self:doUnloadFork()
end





















---
function AutoLoadFork:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end

    if self.isServer then
        local spec = self.spec_autoLoadFork
        for i=#spec.mountedObjects, 1, -1 do
            local mountedObjectId = spec.mountedObjects[i]
            local object = NetworkUtil.getObject(mountedObjectId)
            if object ~= nil and object.addToPhysics ~= nil then
                object:addToPhysics()
            end
        end
    end

    return true
end


---
function AutoLoadFork:removeFromPhysics(superFunc)
    local ret = superFunc(self)

    if self.isServer then
        local spec = self.spec_autoLoadFork
        for i=#spec.mountedObjects, 1, -1 do
            local mountedObjectId = spec.mountedObjects[i]
            local object = NetworkUtil.getObject(mountedObjectId)
            if object ~= nil and object.removeFromPhysics ~= nil then
                object:removeFromPhysics()
            end
        end
    end

    return ret
end
