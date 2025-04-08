













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function HookLiftContainer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(Attachable, specializations)
end


---Called on specialization initializing
function HookLiftContainer.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HookLiftContainer")

    schema:register(XMLValueType.BOOL, "vehicle.hookLiftContainer#tiltContainerOnDischarge", "Tilt container on discharge", true)

    schema:setXMLSpecializationType()
end


---
function HookLiftContainer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", HookLiftContainer.getCanDischargeToObject)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", HookLiftContainer.getCanDischargeToGround)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed",         HookLiftContainer.isDetachAllowed)
end


---
function HookLiftContainer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HookLiftContainer)
    SpecializationUtil.registerEventListener(vehicleType, "onStartTipping", HookLiftContainer)
    SpecializationUtil.registerEventListener(vehicleType, "onStopTipping", HookLiftContainer)
end


---Called on loading
-- @param table savegame savegame
function HookLiftContainer:onLoad(savegame)
    local spec = self.spec_hookLiftContainer

    spec.tiltContainerOnDischarge = self.xmlFile:getValue("vehicle.hookLiftContainer#tiltContainerOnDischarge", true)
end


---
function HookLiftContainer:getCanDischargeToObject(superFunc, dischargeNode)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and attacherVehicle.getIsTippingAllowed ~= nil then
        if not attacherVehicle:getIsTippingAllowed() then
            return false
        end
    end

    return superFunc(self, dischargeNode)
end


---
function HookLiftContainer:getCanDischargeToGround(superFunc, dischargeNode)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and attacherVehicle.getIsTippingAllowed ~= nil then
        if not attacherVehicle:getIsTippingAllowed() then
            return false
        end
    end

    return superFunc(self, dischargeNode)
end


---
function HookLiftContainer:isDetachAllowed(superFunc)
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and attacherVehicle.getCanDetachContainer ~= nil then
        if not attacherVehicle:getCanDetachContainer() then
            return false, nil
        end
    end

    return superFunc(self)
end


---
function HookLiftContainer:onStartTipping(tipSideIndex)
    local spec = self.spec_hookLiftContainer
    local attacherVehicle = self:getAttacherVehicle()
    if attacherVehicle ~= nil and attacherVehicle.startTipping ~= nil and spec.tiltContainerOnDischarge then
        attacherVehicle:startTipping()
    end
end


---
function HookLiftContainer:onStopTipping()
    local spec = self.spec_hookLiftContainer
    local attacherVehicle = self:getAttacherVehicle()

    if attacherVehicle ~= nil and attacherVehicle.stopTipping ~= nil and spec.tiltContainerOnDischarge then
        attacherVehicle:stopTipping()
    end
end
