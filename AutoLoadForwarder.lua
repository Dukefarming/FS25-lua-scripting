














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AutoLoadForwarder.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AutomaticArmControlForwarder, specializations)
end


---
function AutoLoadForwarder.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AutoLoadForwarder")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder#idlePositionNode", "Crane will move to this position after the tree has been loaded")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder#dropPositionNode", "Crane will move to this position before the tree is dropped on the loading bay")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder#craneTreeJointNode", "Tree will be mounted to this node while mounted to the crane")
    schema:register(XMLValueType.INT, "vehicle.autoLoadForwarder.loadPlaces#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoadForwarder.loadPlaces#dropOffset", "Y offset of crane to the load place before dropping the tree", 0)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.autoLoadForwarder.loadPlaces.loadPlace(?)#node", "Load place node")

    schema:register(XMLValueType.STRING, "vehicle.autoLoadForwarder.grabAnimation#name", "Grab animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoadForwarder.grabAnimation#speedScale", "Animation speed scale")
    schema:register(XMLValueType.FLOAT, "vehicle.autoLoadForwarder.grabAnimation#filledTime", "Target animation time when a tree is grabbed")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).autoLoadForwarder#treeI3DFilename", "Path to i3d file of the tree")
end


---
function AutoLoadForwarder.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onAutoLoadForwaderMountedTree")
end


---
function AutoLoadForwarder.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "mountTreeToCrane", AutoLoadForwarder.mountTreeToCrane)
    SpecializationUtil.registerFunction(vehicleType, "addTreeToLoadPlaces", AutoLoadForwarder.addTreeToLoadPlaces)
    SpecializationUtil.registerFunction(vehicleType, "removeMountedObject", AutoLoadForwarder.removeMountedObject)
    SpecializationUtil.registerFunction(vehicleType, "sortLoadedTreeObjects", AutoLoadForwarder.sortLoadedTreeObjects)
end


---
function AutoLoadForwarder.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", AutoLoadForwarder.getAreControlledActionsAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AutoLoadForwarder.addToPhysics)
end


---
function AutoLoadForwarder.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoadForwarder)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AutoLoadForwarder)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AutoLoadForwarder)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AutoLoadForwarder)
    SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", AutoLoadForwarder)
end


---
function AutoLoadForwarder:onLoad(savegame)
    local spec = self.spec_autoLoadForwarder

    spec.idlePositionNode = self.xmlFile:getValue("vehicle.autoLoadForwarder#idlePositionNode", nil, self.components, self.i3dMappings)
    spec.dropPositionNode = self.xmlFile:getValue("vehicle.autoLoadForwarder#dropPositionNode", nil, self.components, self.i3dMappings)
    spec.craneTreeJointNode = self.xmlFile:getValue("vehicle.autoLoadForwarder#craneTreeJointNode", nil, self.components, self.i3dMappings)

    spec.loadPlaces = {}
    spec.loadPlaceFillUnitIndex = self.xmlFile:getValue("vehicle.autoLoadForwarder.loadPlaces#fillUnitIndex", 1)
    spec.loadPlaceDropOffset = self.xmlFile:getValue("vehicle.autoLoadForwarder.loadPlaces#dropOffset", 0)
    self.xmlFile:iterate("vehicle.autoLoadForwarder.loadPlaces.loadPlace", function(index, key)
        local entry = {}
        entry.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
        if entry.node ~= nil then
            entry.treeObject = nil

            table.insert(spec.loadPlaces, entry)
        end
    end)

    spec.grabAnimation = {}
    spec.grabAnimation.name = self.xmlFile:getValue("vehicle.autoLoadForwarder.grabAnimation#name")
    spec.grabAnimation.speedScale = self.xmlFile:getValue("vehicle.autoLoadForwarder.grabAnimation#speedScale", 1)
    spec.grabAnimation.filledTime = self.xmlFile:getValue("vehicle.autoLoadForwarder.grabAnimation#filledTime", 0.5)

    spec.grappleTreeId = nil
    spec.pendingIdleReturn = false

    spec.texts = {}
    spec.texts.warning_forwarderNoTreeInRange = g_i18n:getText("warning_forwarderNoTreeInRange")
end


---
function AutoLoadForwarder:onPostLoad(savegame)
    local spec = self.spec_autoLoadForwarder
    if spec.grabAnimation.name ~= nil then
        self:setAnimationTime(spec.grabAnimation.name, 1, true)
    end

    local fillLevel = MathUtil.round(self:getFillUnitFillLevel(spec.loadPlaceFillUnitIndex))
    if fillLevel > 0 then
        if not savegame.resetVehicles then
            self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.loadPlaceFillUnitIndex, -math.huge, self:getFillUnitFillType(spec.loadPlaceFillUnitIndex), ToolType.UNDEFINED, nil)

            local i3dFilename = savegame.xmlFile:getValue(savegame.key..".autoLoadForwarder#treeI3DFilename")
            if i3dFilename ~= nil then
                i3dFilename = NetworkUtil.convertFromNetworkFilename(i3dFilename)

                local onTreeLoaded = function(target, treeObject, state, args)
                    if state then
                        self:addTreeToLoadPlaces(treeObject)
                    end
                end

                for _=1, fillLevel do
                    local forestryLog = ForestryLog.new(self.isServer, self.isClient)
                    forestryLog:loadFromFilename(i3dFilename, 0, 0, 0, 0, 0, 0, onTreeLoaded, self, forestryLog)
                end
            end
        end
    end
end


---
function AutoLoadForwarder:onDelete()
    local spec = self.spec_autoLoadForwarder
    for i=#spec.loadPlaces, 1, -1 do
        local loadPlace = spec.loadPlaces[i]
        if loadPlace.treeObject ~= nil then
            loadPlace.treeObject:delete()
            loadPlace.treeObject = nil
        end
    end
end


---
function AutoLoadForwarder:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_autoLoadForwarder

    if MathUtil.round(self:getFillUnitFillLevel(spec.loadPlaceFillUnitIndex)) > 0 then
        for i=1, #spec.loadPlaces do
            local loadPlace = spec.loadPlaces[i]
            if loadPlace.treeObject ~= nil then
                xmlFile:setValue(key.."#treeI3DFilename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(loadPlace.treeObject.i3dFilename)))
                break
            end
        end
    end
end


---
function AutoLoadForwarder:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_autoLoadForwarder

    if Platform.gameplay.automaticVehicleControl then
        if self:getActionControllerDirection() == -1 then
            if spec.grappleTreeId == nil then
                local x, y, z, dx, dy, dz = self:getAutomaticAlignmentCurrentTarget()
                if x ~= nil then
                    if not self:getIsAutomaticAlignmentFinished() then
                        self:doTreeArmAlignment(x, y, z, dx, dy, dz, 1)

                        if spec.grabAnimation.name ~= nil then
                            if not self:getIsAnimationPlaying(spec.grabAnimation.name) and self:getAnimationTime(spec.grabAnimation.name) > 0 then
                                self:playAnimation(spec.grabAnimation.name, -spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name))
                            end
                        end

                        spec.craneTargetTreeId = self:getAutomaticAlignmentTargetTree()
                    else
                        local treeId = spec.craneTargetTreeId
                        if treeId ~= nil and entityExists(treeId) and self:mountTreeToCrane(treeId) then
                            spec.grappleTreeId = treeId
                            self:resetAutomaticAlignment()

                            if spec.grabAnimation.name ~= nil then
                                self:setAnimationTime(spec.grabAnimation.name, spec.grabAnimation.filledTime, true)
                            end
                        else
                            -- grabbing failed - return to idle position
                            spec.grappleTreeId = nil
                            self:playControlledActions()

                            if spec.grabAnimation.name ~= nil then
                                self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name))
                            end
                        end

                        spec.craneTargetTreeId = nil
                    end
                else
                    -- turn off when the tree gets out of range
                    self:playControlledActions()
                end
            else
                local nextLoadPlace
                for i=1, #spec.loadPlaces do
                    local loadPlace = spec.loadPlaces[i]
                    if loadPlace.treeObject == nil then
                        nextLoadPlace = loadPlace
                        break
                    end
                end

                if nextLoadPlace ~= nil then
                    local x, y, z = getWorldTranslation(nextLoadPlace.node)
                    local dx, dy, dz = localDirectionToWorld(nextLoadPlace.node, 0, 0, 1)
                    self:doTreeArmAlignment(x, y + spec.loadPlaceDropOffset, z, dx, dy, dz, -1)
                    if self:getIsAutomaticAlignmentFinished() then
                        -- drop the tree to the loading places
                        if spec.grappleTreeId ~= nil and entityExists(spec.grappleTreeId) then
                            local treeObject = g_currentMission:getNodeObject(spec.grappleTreeId)
                            if treeObject ~= nil then
                                self:addTreeToLoadPlaces(treeObject)
                            end
                        end

                        spec.grappleTreeId = nil
                        self:resetAutomaticAlignment()

                        -- return to idle if we dont have the next tree in range
                        local treeId = self:getAutomaticAlignmentAvailableTargetTree()
                        if treeId == nil or self:getFillUnitFreeCapacity(spec.loadPlaceFillUnitIndex) < 1 then
                            self:playControlledActions()

                            if spec.grabAnimation.name ~= nil then
                                self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name))
                            end
                        end
                    end
                end
            end
        elseif spec.pendingIdleReturn then
            if spec.idlePositionNode ~= nil then
                self:setEasyControlForcedTransMove(-1)

                local tx, ty, tz = getWorldTranslation(spec.idlePositionNode)
                local dx, dy, dz = localDirectionToWorld(spec.idlePositionNode, 0, 0, 1)
                self:doTreeArmAlignment(tx, ty, tz, dx, dy, dz, -1, true)
                if self:getIsAutomaticAlignmentFinished() then
                    spec.pendingIdleReturn = false
                end
            else
                spec.pendingIdleReturn = false
            end
        end
    end
end



---Called if root vehicle changes
-- @param table rootVehicle root vehicle
function AutoLoadForwarder:onRootVehicleChanged(rootVehicle)
    local spec = self.spec_autoLoadForwarder
    local actionController = rootVehicle.actionController
    if actionController ~= nil then
        if spec.controlledAction ~= nil then
            spec.controlledAction:updateParent(actionController)
            return
        end

        spec.controlledAction = actionController:registerAction("forwarderLoading", nil, 4)
        spec.controlledAction:setCallback(self, AutoLoadForwarder.actionControllerEvent)
        spec.controlledAction:setIsAvailableFunction(function()
            return spec.grappleTreeId == nil and self:getFillUnitFreeCapacity(spec.loadPlaceFillUnitIndex) > 0
        end)
        spec.controlledAction:setActionIcons("LOAD_LOG", "LOAD_LOG", true)
    else
        if spec.controlledAction ~= nil then
            spec.controlledAction:remove()
            spec.controlledAction = nil
        end
    end
end


---
function AutoLoadForwarder.actionControllerEvent(self, direction)
    local spec = self.spec_autoLoadForwarder
    if direction < 0 then
        spec.pendingIdleReturn = true
        self:resetAutomaticAlignment()

        if spec.grabAnimation.name ~= nil then
            self:playAnimation(spec.grabAnimation.name, spec.grabAnimation.speedScale, self:getAnimationTime(spec.grabAnimation.name))
        end
    else
        spec.pendingIdleReturn = false
        self:resetAutomaticAlignment()
    end

    return true
end


---Returns if controlled actions are allowed
-- @return boolean allow allow controlled actions
-- @return string warning not allowed warning
function AutoLoadForwarder:getAreControlledActionsAllowed(superFunc)
    if self:getActionControllerDirection() == 1 then -- always allow turn off
        local treeId = self:getAutomaticAlignmentTargetTree()
        if treeId == nil then
            return false, self.spec_autoLoadForwarder.texts.warning_forwarderNoTreeInRange
        end
    end

    return superFunc(self)
end


---Add vehicle to physics
-- @return boolean success success
function AutoLoadForwarder:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end

    local spec = self.spec_autoLoadForwarder
    for i=1, #spec.loadPlaces do
        local loadPlace = spec.loadPlaces[i]
        if loadPlace.treeObject ~= nil then
            -- remount trees again to make sure they are kinematic and not having a collision with the vehicle components
            local rx, ry, rz = getRotation(loadPlace.treeObject.nodeId)
            loadPlace.treeObject:mountKinematic(self, loadPlace.node, 0, 0, 0, rx, ry, rz)

            SpecializationUtil.raiseEvent(self, "onAutoLoadForwaderMountedTree", loadPlace.treeObject.nodeId)
        end
    end

    return true
end


---
function AutoLoadForwarder:mountTreeToCrane(treeId)
    local treeObject = g_currentMission:getNodeObject(treeId)
    if treeObject ~= nil then
        local spec = self.spec_autoLoadForwarder
        local radius = getUserAttribute(treeId, "logRadius") or 0.5
        local rx, _, rz = localRotationToLocal(treeId, spec.craneTreeJointNode, 0, 0, 0)
        if math.abs(rx) < math.pi * 0.5 then
            rx = 0
        end

        treeObject:mountKinematic(self, spec.craneTreeJointNode, 0, -radius, 0, rx, 0, rz)

        SpecializationUtil.raiseEvent(self, "onAutoLoadForwaderMountedTree", treeObject.nodeId)

        return true
    end

    return false
end


---
function AutoLoadForwarder:addTreeToLoadPlaces(treeObject)
    local spec = self.spec_autoLoadForwarder
    self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.loadPlaceFillUnitIndex, 1, self:getFillUnitFirstSupportedFillType(spec.loadPlaceFillUnitIndex), ToolType.UNDEFINED, nil)

    for i=1, #spec.loadPlaces do
        local loadPlace = spec.loadPlaces[i]
        if loadPlace.treeObject == nil then
            local rx, _, rz = localRotationToLocal(treeObject.nodeId, loadPlace.node, 0, 0, 0)
            if math.abs(rx) < math.pi * 0.5 then
                rx = 0
            else
                rx = math.pi
            end

            treeObject:mountKinematic(self, loadPlace.node, 0, 0, 0, rx, 0, rz)
            loadPlace.treeObject = treeObject

            SpecializationUtil.raiseEvent(self, "onAutoLoadForwaderMountedTree", treeObject.nodeId)

            return
        end
    end

    -- delete tree in the grab if not place could be found
    treeObject:delete()
end


---Remove mounted object
-- @param integer object object to remove
-- @param boolean isDeleting called on delete
function AutoLoadForwarder:removeMountedObject(object, isDeleting)
    local spec = self.spec_autoLoadForwarder

    for i=1, #spec.loadPlaces do
        local loadPlace = spec.loadPlaces[i]
        if loadPlace.treeObject == object then
            loadPlace.treeObject = nil
            self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.loadPlaceFillUnitIndex, -1, self:getFillUnitFirstSupportedFillType(spec.loadPlaceFillUnitIndex), ToolType.UNDEFINED, nil)
        end
    end

    self:sortLoadedTreeObjects()
end


---Sort loaded tree objects, so we don't have a free load place in between
function AutoLoadForwarder:sortLoadedTreeObjects()
    local spec = self.spec_autoLoadForwarder
    for i=1, #spec.loadPlaces do
        local loadPlace = spec.loadPlaces[i]
        if loadPlace.treeObject == nil then
            local foundTree = false
            for j=i + 1, #spec.loadPlaces do
                local loadPlace2 = spec.loadPlaces[j]
                if loadPlace2.treeObject ~= nil then
                    local rx, ry, rz = getRotation(loadPlace2.treeObject.nodeId)
                    loadPlace2.treeObject:mountKinematic(self, loadPlace.node, 0, 0, 0, rx, ry, rz)
                    loadPlace.treeObject = loadPlace2.treeObject
                    loadPlace2.treeObject = nil
                    foundTree = true
                    break
                end
            end

            if not foundTree then
                break
            end
        end
    end
end
