

















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function ReceivingHopper.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(Dischargeable, specializations)
end


---
function ReceivingHopper.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ReceivingHopper")

    schema:register(XMLValueType.INT, "vehicle.receivingHopper#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.receivingHopper.boxes#spawnPlaceNode", "Spawn place node")
    schema:register(XMLValueType.STRING, "vehicle.receivingHopper.boxes.box(?)#fillType", "Fill type name")
    schema:register(XMLValueType.STRING, "vehicle.receivingHopper.boxes.box(?)#filename", "Box filename")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).receivingHopper#createBoxes", "Create boxes")
end


---
function ReceivingHopper.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setCreateBoxes",        ReceivingHopper.setCreateBoxes)
    SpecializationUtil.registerFunction(vehicleType, "getCanSpawnNextBox",    ReceivingHopper.getCanSpawnNextBox)
    SpecializationUtil.registerFunction(vehicleType, "collisionTestCallback", ReceivingHopper.collisionTestCallback)
    SpecializationUtil.registerFunction(vehicleType, "createBox",             ReceivingHopper.createBox)
    SpecializationUtil.registerFunction(vehicleType, "onCreateBoxFinished",   ReceivingHopper.onCreateBoxFinished)
end


---
function ReceivingHopper.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeRaycast", ReceivingHopper.handleDischargeRaycast)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected",       ReceivingHopper.getCanBeSelected)
end


---
function ReceivingHopper.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ReceivingHopper)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ReceivingHopper)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ReceivingHopper)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ReceivingHopper)
end


---Called on loading
-- @param table savegame savegame
function ReceivingHopper:onLoad(savegame)
    local spec = self.spec_receivingHopper

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper#unloadingDelay", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper#unloadInfoIndex", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper#dischargeInfoIndex", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.tipTrigger#index", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger#index", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.fillScrollerNodes.fillScrollerNode", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.fillEffect", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.fillEffect", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger#litersPerMinute", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.raycastNode#index", "Dischargeable functionalities") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.raycastNode#raycastLength", "Dischargeable functionalities") -- FS17 to FS19

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger#boxSpawnPlaceIndex", "vehicle.receivingHopper.boxes#spawnPlaceNode") -- FS17 to FS19
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.receivingHopper.boxTrigger.box(0)", "vehicle.receivingHopper.boxes.box(0)") -- FS17 to FS19

    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.receivingHopper#fillUnitIndex", 1)
    spec.spawnPlace = self.xmlFile:getValue("vehicle.receivingHopper.boxes#spawnPlaceNode", nil, self.components, self.i3dMappings)

    spec.boxes = {}
    local i = 0
    while true do
        local baseName = string.format("vehicle.receivingHopper.boxes.box(%d)", i)
        if not self.xmlFile:hasProperty(baseName) then
            break
        end

        local fillTypeStr = self.xmlFile:getValue(baseName.."#fillType")
        local filename = self.xmlFile:getValue(baseName.."#filename")
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
        if fillTypeIndex ~= nil then
            spec.boxes[fillTypeIndex] = filename
        else
            Logging.xmlWarning(self.xmlFile, "Invalid fillType '%s'", fillTypeStr)
        end

        i = i + 1
    end

    spec.createBoxes = false
    spec.lastBox = nil
    spec.creatingBox = false

    if savegame ~= nil then
        spec.createBoxes = savegame.xmlFile:getValue(savegame.key..".receivingHopper#createBoxes", spec.createBoxes)
    end

    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", ReceivingHopper)
    end
end


---
function ReceivingHopper:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_receivingHopper

    xmlFile:setValue(key.."#createBoxes", spec.createBoxes)
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function ReceivingHopper:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_receivingHopper
    if spec.createBoxes then
        if self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OFF then
            if self:getCanSpawnNextBox() then
                self:createBox()
            end
        end
    end
end


---Toggle box creating
-- @param boolean state new state
-- @param boolean noEventSend no event send
function ReceivingHopper:setCreateBoxes(state, noEventSend)
    local spec = self.spec_receivingHopper
    if state ~= spec.createBoxes then
        ReceivingHopperSetCreateBoxesEvent.sendEvent(self, state, noEventSend)

        spec.createBoxes = state
        ReceivingHopper.updateActionEvents(self)

        spec.lastBox = nil
    end
end


---
function ReceivingHopper:getCanSpawnNextBox()
    local spec = self.spec_receivingHopper

    if spec.creatingBox then
        return false
    end

    local fillType = self:getFillUnitFillType(spec.fillUnitIndex)
    if spec.boxes[fillType] ~= nil then
        if spec.lastBox ~= nil then
            if spec.lastBox:getFillUnitFreeCapacity(1) > 0 then
                return false
            end
        end

        local xmlFilename = Utils.getFilename(spec.boxes[fillType], self.baseDirectory)
        local size = StoreItemUtil.getSizeValues(xmlFilename, "vehicle", 0)

        local x,y,z = getWorldTranslation(spec.spawnPlace)
        local rx,ry,rz = getWorldRotation(spec.spawnPlace)

        spec.foundObjectAtSpawnPlace = false
        overlapBox(x, y, z, rx, ry, rz, size.width*0.5, 2, size.length*0.5, "collisionTestCallback", self, ReceivingHopper.BOX_SPAWN_OVERLAP_MASK)

        return not spec.foundObjectAtSpawnPlace
    end

    return false
end


---
function ReceivingHopper:collisionTestCallback(transformId)
    if g_currentMission.nodeToObject[transformId] ~= nil or g_currentMission.players[transformId] ~= nil then
        if g_currentMission.nodeToObject[transformId] ~= self then
            local spec = self.spec_receivingHopper
            spec.foundObjectAtSpawnPlace = true
        end
    end
end


---Create box
function ReceivingHopper:createBox()
    local spec = self.spec_receivingHopper
    if self.isServer then
        if spec.createBoxes then
            local fillType = self:getFillUnitFillType(spec.fillUnitIndex)
            if spec.boxes[fillType] ~= nil then
                local x, y, z = getWorldTranslation(spec.spawnPlace)
                local rx, ry, rz = getWorldRotation(spec.spawnPlace)
                local xmlFilename = Utils.getFilename(spec.boxes[fillType], self.baseDirectory)

                spec.creatingBox = true

                local data = VehicleLoadingData.new()
                data:setFilename(xmlFilename)
                data:setPosition(x, y, z)
                data:setRotation(rx, ry, rz)
                data:setPropertyState(VehiclePropertyState.OWNED)
                data:setOwnerFarmId(self:getOwnerFarmId())

                data:load(self.onCreateBoxFinished, self, nil)
            end
        end
    end
end


---
function ReceivingHopper:onCreateBoxFinished(vehicles, vehicleLoadState, arguments)
    local spec = self.spec_receivingHopper
    spec.creatingBox = false

    if vehicleLoadState == VehicleLoadingState.OK then
        spec.lastBox = vehicles[1]
    end
end


---
function ReceivingHopper:handleDischargeRaycast(superFunc, dischargeNode, hitObject, hitShape, hitDistance, hitFillUnitIndex, hitTerrain)
    local stopDischarge = false
    if hitObject ~= nil then
        local fillType = self:getDischargeFillType(dischargeNode)
        local allowFillType = hitObject:getFillUnitAllowsFillType(hitFillUnitIndex, fillType)
        if allowFillType and hitObject:getFillUnitFreeCapacity(hitFillUnitIndex) > 0 then
            self:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT, true)
        else
            stopDischarge = true
        end
    else
        stopDischarge = true
    end

    if stopDischarge and self:getDischargeState() == Dischargeable.DISCHARGE_STATE_OBJECT then
        self:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF, true)
    end
end


---
function ReceivingHopper:getCanBeSelected(superFunc)
    return true
end


---
function ReceivingHopper:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_receivingHopper
        self:clearActionEventsTable(spec.actionEvents)
        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, ReceivingHopper.actionEventToggleBoxCreation, false, true, false, true, nil)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
            ReceivingHopper.updateActionEvents(self)
        end
    end
end


---
function ReceivingHopper:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
    if self:getFillUnitFillLevel(fillUnitIndex) > 0 then
        self:raiseActive()
    end
end


---
function ReceivingHopper.actionEventToggleBoxCreation(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_receivingHopper
    self:setCreateBoxes(not spec.createBoxes)
end


---
function ReceivingHopper.updateActionEvents(self)
    local spec = self.spec_receivingHopper
    local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]
    if actionEvent ~= nil then
        if spec.createBoxes then
            g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_disablePalletSpawning"))
        else
            g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("action_enablePalletSpawning"))
        end
    end
end
