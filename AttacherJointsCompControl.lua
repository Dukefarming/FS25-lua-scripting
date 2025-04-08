














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AttacherJointsCompControl.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end


---
function AttacherJointsCompControl.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AttacherJointsCompControl")

    schema:addDelayedRegistrationFunc("AttacherJoint", function(cSchema, cKey)
        cSchema:register(XMLValueType.INT, cKey .. ".dependentComponentJoint#index", "Index of component joint that will be adjusted while something is attached")
        cSchema:register(XMLValueType.FLOAT, cKey .. ".dependentComponentJoint#transSpringFactor", "Factor that will be applied to the spring values on attach", 1)
        cSchema:register(XMLValueType.FLOAT, cKey .. ".dependentComponentJoint#transDampingFactor", "Factor that will be applied to the damping values on attach", "#transSpringFactor")
        cSchema:register(XMLValueType.FLOAT, cKey .. ".dependentComponentJoint#referenceMass", "Reference mass for spring and damping adjustments. At the mass attached to the front, the full factor will be applied to the spring/damping. (to)", 1)
        cSchema:register(XMLValueType.TIME, cKey .. ".dependentComponentJoint#attachInterpolationTime", "Time for the interpolation between the damping values after attach", 1)
        cSchema:register(XMLValueType.TIME, cKey .. ".dependentComponentJoint#detachInterpolationTime", "Time for the interpolation between the damping values after detach", 0.5)
    end)

    schema:setXMLSpecializationType()
end


---
function AttacherJointsCompControl.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setDependentComponentJointBaseFactors", AttacherJointsCompControl.setDependentComponentJointBaseFactors)
    SpecializationUtil.registerFunction(vehicleType, "addDependentComponentJointData", AttacherJointsCompControl.addDependentComponentJointData)
    SpecializationUtil.registerFunction(vehicleType, "updateDependentComponentJointValues", AttacherJointsCompControl.updateDependentComponentJointValues)
end


---
function AttacherJointsCompControl.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AttacherJointsCompControl.addToPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointFromXML", AttacherJointsCompControl.loadAttacherJointFromXML)
end


---
function AttacherJointsCompControl.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AttacherJointsCompControl)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJointsCompControl)
end


---Called on loading
-- @param table savegame savegame
function AttacherJointsCompControl:onPreLoad(savegame)
    local spec = self.spec_attacherJointsCompControl

    spec.dependentComponentJointData = {}

    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onStateChange", AttacherJointsCompControl)
    end
end


---
function AttacherJointsCompControl:onStateChange(state, data)
    if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
        self:updateDependentComponentJointValues()
    end
end


---
function AttacherJointsCompControl:setDependentComponentJointBaseFactors(componentJointIndex, transSpringFactor, transDampingFactor)
    if self.isServer then
        local data = self:addDependentComponentJointData(componentJointIndex)
        if data ~= nil then
            data.baseTransSpringFactor = data.baseTransSpringFactor * transSpringFactor or 1
            data.baseTransDampingFactor = data.baseTransDampingFactor * transDampingFactor or 1
        end
    end
end


---
function AttacherJointsCompControl:addDependentComponentJointData(componentJointIndex)
    if componentJointIndex == nil then
        return nil
    end

    local componentJoint = self.componentJoints[componentJointIndex]
    if componentJoint ~= nil then
        local spec = self.spec_attacherJointsCompControl

        local key = "dependentComponentJoint_" .. getName(componentJoint.jointNode)
        if spec.dependentComponentJointData[key] == nil then
            local data = {}

            data.interpolatorKey = key

            data.baseTransSpringFactor = 1
            data.baseTransDampingFactor = 1

            data.curTransSpringFactor = 1
            data.curTransDampingFactor = 1

            data.targetTransSpringFactor = 1
            data.targetTransDampingFactor = 1

            data.attachInterpolationTime = 1
            data.detachInterpolationTime = 0.5

            data.interpolatorGet = function()
                return data.curTransSpringFactor, data.curTransDampingFactor
            end
            data.interpolatorSet = function(springFactor, dampingFactor)
                data.curTransSpringFactor = springFactor
                data.curTransDampingFactor = dampingFactor

                for axis=1, 3 do
                    setJointTranslationLimitSpring(componentJoint.jointIndex, axis-1, componentJoint.transLimitSpring[axis] * springFactor, componentJoint.transLimitDamping[axis] * dampingFactor)
                end
            end

            spec.dependentComponentJointData[key] = data
        end

        return spec.dependentComponentJointData[key]
    else
        Logging.xmlWarning(self.xmlFile, "Unknown component joint index '%s' in dependentComponentJoint", componentJointIndex)

        return nil
    end
end


---
function AttacherJointsCompControl:updateDependentComponentJointValues(forceUpdate, skipInterpolation)
    local spec = self.spec_attacherJointsCompControl
    for i, data in pairs(spec.dependentComponentJointData) do
        data.targetTransSpringFactor = data.baseTransSpringFactor
        data.targetTransDampingFactor = data.baseTransDampingFactor
    end

    for jointIndex, attacherJoint in ipairs(self:getAttacherJoints()) do
        local mass = 0

        local implement = self:getImplementByJointDescIndex(jointIndex)
        if implement ~= nil then
            mass = implement.object:getTotalMass()
        end

        if attacherJoint.dependentComponentJoint ~= nil then
            local data = attacherJoint.dependentComponentJoint.data

            local scale = math.min(mass / attacherJoint.dependentComponentJoint.referenceMass, 1)
            local springFactor = (attacherJoint.dependentComponentJoint.transSpringFactor - 1) * scale + 1
            local dampingFactor = (attacherJoint.dependentComponentJoint.transDampingFactor - 1) * scale + 1

            data.targetTransSpringFactor = data.targetTransSpringFactor + (springFactor - 1)
            data.targetTransDampingFactor = data.targetTransDampingFactor + (dampingFactor - 1)
        end
    end

    for key, data in pairs(spec.dependentComponentJointData) do
        if data.targetTransSpringFactor ~= data.curTransSpringFactor or data.targetTransDampingFactor ~= data.curTransDampingFactor or forceUpdate then
            local interpolationTime = data.attachInterpolationTime
            if data.targetTransSpringFactor <= data.baseTransSpringFactor + 0.001 and data.targetTransDampingFactor <= data.targetTransDampingFactor + 0.001 then
                interpolationTime = data.detachInterpolationTime
            end

            if skipInterpolation then
                data.interpolatorSet(data.targetTransSpringFactor, data.targetTransDampingFactor)
            else
                local interpolator = ValueInterpolator.new(key, data.interpolatorGet, data.interpolatorSet, {data.targetTransSpringFactor, data.targetTransDampingFactor}, interpolationTime)
                if interpolator ~= nil then
                    interpolator:setDeleteListenerObject(self)
                end
            end
        end
    end
end


---Add to physics
-- @return boolean success success
function AttacherJointsCompControl:addToPhysics(superFunc)
    if not superFunc(self) then
        return false
    end

    if self.isServer then
        self:updateDependentComponentJointValues(true, true)
    end

    return true
end


---Load attacher joint from xml
-- @param table attacherJoint attacherJoint
-- @param integer fileId xml file id
-- @param string baseName baseName
-- @param integer index index of attacher joint
function AttacherJointsCompControl:loadAttacherJointFromXML(superFunc, attacherJoint, xmlFile, baseName, index)
    if not superFunc(self, attacherJoint, xmlFile, baseName, index) then
        return false
    end

    if self.isServer then
        local componentJointIndex = xmlFile:getValue(baseName .. ".dependentComponentJoint#index")
        if componentJointIndex ~= nil then
            local data = self:addDependentComponentJointData(componentJointIndex)
            if data ~= nil then
                data.attachInterpolationTime = xmlFile:getValue(baseName .. ".dependentComponentJoint#attachInterpolationTime", data.attachInterpolationTime)
                data.detachInterpolationTime = xmlFile:getValue(baseName .. ".dependentComponentJoint#detachInterpolationTime", data.detachInterpolationTime)

                attacherJoint.dependentComponentJoint = {}
                attacherJoint.dependentComponentJoint.data = data

                attacherJoint.dependentComponentJoint.transSpringFactor = xmlFile:getValue(baseName .. ".dependentComponentJoint#transSpringFactor", 1)
                attacherJoint.dependentComponentJoint.transDampingFactor = xmlFile:getValue(baseName .. ".dependentComponentJoint#transDampingFactor", attacherJoint.dependentComponentJoint.transSpringFactor)
                attacherJoint.dependentComponentJoint.referenceMass = xmlFile:getValue(baseName .. ".dependentComponentJoint#referenceMass", 1)
            end
        end
    end

    return true
end


---
function AttacherJointsCompControl:updateDebugValues(values)
    local spec = self.spec_attacherJointsCompControl

    for jointIndex, attacherJoint in ipairs(self:getAttacherJoints()) do
        local mass = 0

        local implement = self:getImplementByJointDescIndex(jointIndex)
        if implement ~= nil then
            mass = implement.object:getTotalMass()
        end

        if attacherJoint.dependentComponentJoint ~= nil then
            table.insert(values, {name="Attacher Joint", value=tostring(jointIndex)})

            local scale = math.min(mass / attacherJoint.dependentComponentJoint.referenceMass, 1)
            local springFactor = (attacherJoint.dependentComponentJoint.transSpringFactor - 1) * scale + 1
            local dampingFactor = (attacherJoint.dependentComponentJoint.transDampingFactor - 1) * scale + 1

            table.insert(values, {name="Mass", value=string.format("%.2f / %.2f to", mass, attacherJoint.dependentComponentJoint.referenceMass)})
            table.insert(values, {name="Spring Factors", value=string.format("spring %.2f damping %.2f", springFactor, dampingFactor)})
        end
    end

    for key, data in pairs(spec.dependentComponentJointData) do
        table.insert(values, {name="Component Joint", value=key})
        table.insert(values, {name="Base Factors", value=string.format("spring %.2f damping %.2f", data.baseTransSpringFactor, data.baseTransDampingFactor)})
        table.insert(values, {name="Current Factors", value=string.format("spring %.2f damping %.2f", data.curTransSpringFactor, data.curTransDampingFactor)})
    end
end
