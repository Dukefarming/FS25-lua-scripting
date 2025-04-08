













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function FillTriggerVehicle.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end


---
function FillTriggerVehicle.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("FillTriggerVehicle")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.fillTriggerVehicle#triggerNode", "Fill trigger node")
    schema:register(XMLValueType.INT, "vehicle.fillTriggerVehicle#fillUnitIndex", "Fill unit index", 1)
    schema:register(XMLValueType.FLOAT, "vehicle.fillTriggerVehicle#litersPerSecond", "Liter per second", 200)

    schema:setXMLSpecializationType()
end


---
function FillTriggerVehicle.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", FillTriggerVehicle.getDrawFirstFillText)
end


---
function FillTriggerVehicle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FillTriggerVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", FillTriggerVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", FillTriggerVehicle)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", FillTriggerVehicle)
end


---Called on loading
-- @param table savegame savegame
function FillTriggerVehicle:onLoad(savegame)
    local spec = self.spec_fillTriggerVehicle

    local triggerNode = self.xmlFile:getValue("vehicle.fillTriggerVehicle#triggerNode", nil, self.components, self.i3dMappings)
    if triggerNode ~= nil then
        spec.fillUnitIndex = self.xmlFile:getValue("vehicle.fillTriggerVehicle#fillUnitIndex", 1)
        spec.litersPerSecond = self.xmlFile:getValue("vehicle.fillTriggerVehicle#litersPerSecond", 200)
        spec.fillTrigger = FillTrigger.new(triggerNode, self, spec.fillUnitIndex, spec.litersPerSecond)

        if self:getPropertyState() ~= VehiclePropertyState.SHOP_CONFIG then
            if self.isServer then
                local moneyChangeType = MoneyType.register("other", "finance_purchaseFuel")
                spec.fillTrigger:setMoneyChangeType(moneyChangeType)
            end
        end
    end
end


---Called on deleting
function FillTriggerVehicle:onDelete()
    local spec = self.spec_fillTriggerVehicle

    if spec.fillTrigger ~= nil then
        spec.fillTrigger:delete()
        spec.fillTrigger = nil
    end
end














---
function FillTriggerVehicle:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_fillTriggerVehicle
        if spec.fillTrigger ~= nil then
            streamWriteUInt16(streamId, spec.fillTrigger.moneyChangeType.id)
        end
    end
end


---
function FillTriggerVehicle:getDrawFirstFillText(superFunc)
    local spec = self.spec_fillTriggerVehicle
    if self.isClient then
        if spec.fillUnitIndex ~= nil and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
            return true
        end
    end

    return superFunc(self)
end
