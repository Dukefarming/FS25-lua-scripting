













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function FruitExtraObjects.prerequisitesPresent(specializations)
    return true
end


---Called while initializing the specialization
function FruitExtraObjects.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FruitExtraObjects")

    FruitExtraObjects.registerXMLPaths(schema, "vehicle.cutter.fruitExtraObjects")
    FruitExtraObjects.registerXMLPaths(schema, "vehicle.mower.fruitExtraObjects")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).fruitExtraObjects#lastFruitType", "Name of last fruit type")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).fruitExtraObjects#lastFillType", "Name of last fill type")
end


---
function FruitExtraObjects.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".fruitExtraObject(?)#node", "Name of fruit type converter")
    schema:register(XMLValueType.STRING, basePath .. ".fruitExtraObject(?)#animationName", "Change animation name")
    schema:register(XMLValueType.FLOAT, basePath .. ".fruitExtraObject(?)#animationSpeed", "Speed of the animation", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".fruitExtraObject(?)#isDefault", "Is default active", false)
    schema:register(XMLValueType.STRING, basePath .. ".fruitExtraObject(?)#fruitType", "Name of fruit type")
    schema:register(XMLValueType.STRING, basePath .. ".fruitExtraObject(?)#fillType", "Name of fill type")
    schema:register(XMLValueType.BOOL, basePath .. "#hideOnDetach", "Hide extra objects on detach", false)
    schema:register(XMLValueType.BOOL, basePath .. "#hideOnMount", "Hide extra objects when mounted to a header trailer", false)
end


---Register all functions from the specialization that can be called on vehicle level
-- @param table vehicleType vehicle type
function FruitExtraObjects.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadFruitExtraObjectFromXML", FruitExtraObjects.loadFruitExtraObjectFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getFruitExtraObjectTypeData", FruitExtraObjects.getFruitExtraObjectTypeData)
    SpecializationUtil.registerFunction(vehicleType, "updateFruitExtraObjects", FruitExtraObjects.updateFruitExtraObjects)
end


---Register all function overwritings
-- @param table vehicleType vehicle type
function FruitExtraObjects.registerOverwrittenFunctions(vehicleType)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function FruitExtraObjects.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FruitExtraObjects)
    SpecializationUtil.registerEventListener(vehicleType, "onDynamicMountTypeChanged", FruitExtraObjects)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", FruitExtraObjects)
    SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", FruitExtraObjects)
end


---Called on load
-- @param table savegame savegame
function FruitExtraObjects:onPostLoad(savegame)
    local spec = self.spec_fruitExtraObjects

    if self.isClient then
        spec.defaultExtraObject = nil

        spec.extraObjects = {}
        for _, key in self.xmlFile:iterator("vehicle.cutter.fruitExtraObjects.fruitExtraObject") do
            local extraObject = {}
            if self:loadFruitExtraObjectFromXML(self.xmlFile, key, extraObject) then
                if extraObject.isDefault then
                    spec.defaultExtraObject = extraObject
                    extraObject.index = 0
                else
                    table.insert(spec.extraObjects, extraObject)
                    extraObject.index = #spec.extraObjects
                end
            end
        end

        for _, key in self.xmlFile:iterator("vehicle.mower.fruitExtraObjects.fruitExtraObject") do
            local extraObject = {}
            if self:loadFruitExtraObjectFromXML(self.xmlFile, key, extraObject) then
                if extraObject.isDefault then
                    spec.defaultExtraObject = extraObject
                    extraObject.index = 0
                else
                    table.insert(spec.extraObjects, extraObject)
                    extraObject.index = #spec.extraObjects
                end
            end
        end

        spec.hideExtraObjectsOnDetach = self.xmlFile:getValue("vehicle.cutter.fruitExtraObjects#hideOnDetach", self.xmlFile:getValue("vehicle.mower.fruitExtraObjects#hideOnDetach", false))
        spec.hideExtraObjectsOnMount = self.xmlFile:getValue("vehicle.cutter.fruitExtraObjects#hideOnMount", self.xmlFile:getValue("vehicle.mower.fruitExtraObjects#hideOnMount", false))

        spec.currentExtraObject = nil

        spec.lastFruitType = nil
        spec.lastFillType = nil
        if savegame ~= nil and not savegame.resetVehicles then
            local lastFruitTypeName = savegame.xmlFile:getValue(savegame.key .. ".fruitExtraObjects#lastFruitType")
            if lastFruitTypeName ~= nil then
                spec.lastFruitType = g_fruitTypeManager:getFruitTypeIndexByName(lastFruitTypeName)
            end

            local lastFillTypeName = savegame.xmlFile:getValue(savegame.key .. ".fruitExtraObjects#lastFillType")
            if lastFillTypeName ~= nil then
                spec.lastFillType = g_fillTypeManager:getFillTypeIndexByName(lastFillTypeName)
            end
        end

        self:updateFruitExtraObjects()
    end

    if not self.isClient or (#spec.extraObjects == 0 and spec.defaultExtraObject == nil) then
        SpecializationUtil.removeEventListener(self, "onLoadFinished", FruitExtraObjects)
        SpecializationUtil.removeEventListener(self, "onDynamicMountTypeChanged", FruitExtraObjects)
        SpecializationUtil.removeEventListener(self, "onPreAttach", FruitExtraObjects)
        SpecializationUtil.removeEventListener(self, "onPostDetach", FruitExtraObjects)
    end
end


---
function FruitExtraObjects:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_fruitExtraObjects
    if spec.lastFruitType ~= nil then
        xmlFile:setValue(key.."#lastFruitType", g_fruitTypeManager:getFruitTypeNameByIndex(spec.lastFruitType))
    end

    if spec.lastFillType ~= nil then
        xmlFile:setValue(key.."#lastFillType", g_fillTypeManager:getFillTypeNameByIndex(spec.lastFillType))
    end
end


---
function FruitExtraObjects:onDynamicMountTypeChanged(dynamicMountType, mountObject)
    self:updateFruitExtraObjects()
end


---Called if vehicle gets attached
-- @param table attacherVehicle attacher vehicle
-- @param integer inputJointDescIndex index of input attacher
-- @param integer jointDescIndex index if attacher at the attacher vehicle
function FruitExtraObjects:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
    self:updateFruitExtraObjects()
end


---Called if vehicle gets detached
-- @param table attacherVehicle attacher vehicle
-- @param table implement implement
function FruitExtraObjects:onPostDetach(attacherVehicle, implement)
    self:updateFruitExtraObjects()
end


---Called on deleting
function FruitExtraObjects:loadFruitExtraObjectFromXML(xmlFile, key, extraObject)
    XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#anim", key .. "#animationName") --FS22 to FS25

    extraObject.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

    if extraObject.node ~= nil then
        setVisibility(extraObject.node, false)
    end

    extraObject.animationName = xmlFile:getValue(key .. "#animationName")

    if extraObject.node ~= nil or extraObject.animationName ~= nil then
        extraObject.isDefault = xmlFile:getValue(key.."#isDefault", false)
        extraObject.animationSpeed = xmlFile:getValue(key .. "#animationSpeed", 1)

        local fruitTypeName = self.xmlFile:getValue(key.."#fruitType")
        if fruitTypeName ~= nil then
            local fruitTypeIndex = g_fruitTypeManager:getFruitTypeIndexByName(string.upper(fruitTypeName))
            if fruitTypeIndex ~= nil then
                extraObject.fruitType = fruitTypeIndex
            end
        end

        local fillTypeName = self.xmlFile:getValue(key.."#fillType")
        if fillTypeName ~= nil then
            local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(string.upper(fillTypeName))
            if fillTypeIndex ~= nil then
                extraObject.fillType = fillTypeIndex
            end
        end

        if (extraObject.fruitType == nil and extraObject.fillType == nil) and not extraObject.isDefault then
            Logging.xmlWarning(xmlFile, "Missing fruitType/fillType or isDefault attribute for '%s'", key)
            return false
        elseif (extraObject.fruitType ~= nil or extraObject.fillType ~= nil) and extraObject.isDefault then
            Logging.xmlWarning(xmlFile, "FruitType/fillType and isDefault attribute are defined for '%s'. Only one is allowed!", key)
            return false
        end
    end

    return true
end


---
function FruitExtraObjects:getFruitExtraObjectTypeData()
    return nil, nil
end


---
function FruitExtraObjects:updateFruitExtraObjects()
    local spec = self.spec_fruitExtraObjects

    local extraObject
    extraObject = spec.currentExtraObject

    local fruitType, fillType = self:getFruitExtraObjectTypeData()
    if (fruitType == nil or fruitType == FruitType.UNKNOWN) and spec.lastFruitType ~= nil then
        fruitType = spec.lastFruitType
    end
    spec.lastFruitType = fruitType

    if (fillType == nil or fillType == FillType.UNKNOWN) and spec.lastFillType ~= nil then
        fillType = spec.lastFillType
    end
    spec.lastFillType = fillType

    extraObject = spec.defaultExtraObject
    for _, _extraObject in ipairs(spec.extraObjects) do
        if (fruitType ~= nil and _extraObject.fruitType == fruitType)
        or (fillType ~= nil and _extraObject.fillType == fillType) then
            extraObject = _extraObject
            break
        end
    end

    if spec.hideExtraObjectsOnDetach then
        if self.getAttacherVehicle == nil or self:getAttacherVehicle() == nil then
            extraObject = nil
        end
    end

    if spec.hideExtraObjectsOnMount and (self.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE) then
        extraObject = nil
    end

    if extraObject ~= spec.currentExtraObject then
        if spec.currentExtraObject ~= nil then
            if spec.currentExtraObject.node ~= nil then
                setVisibility(spec.currentExtraObject.node, false)
            end

            if spec.currentExtraObject.animationName ~= nil and self.playAnimation ~= nil then
                self:playAnimation(spec.currentExtraObject.animationName, -spec.currentExtraObject.animationSpeed, self:getAnimationTime(spec.currentExtraObject.animationName), true)
            end

            spec.currentExtraObject = nil
        end

        if extraObject ~= nil then
            if extraObject.node ~= nil then
                setVisibility(extraObject.node, true)
            end

            if extraObject.animationName ~= nil and self.playAnimation ~= nil then
                self:playAnimation(extraObject.animationName, extraObject.animationSpeed, self:getAnimationTime(extraObject.animationName), true)
                if not self.finishedLoading then
                    AnimatedVehicle.updateAnimationByName(self, extraObject.animationName, 9999999, true)
                end
            end

            spec.currentExtraObject = extraObject
        end
    end
end
