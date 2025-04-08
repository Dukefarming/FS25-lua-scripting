













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AdditionalToolConnections.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AttacherJoints, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)
end


---
function AdditionalToolConnections.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("AdditionalToolConnections")

    schema:register(XMLValueType.STRING, "vehicle.additionalToolConnections.connection(?)#id", "Identifier of the tool connection")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.additionalToolConnections.connection(?)#movingPartNode", "Node of movingPart to set the reference node to the connection node")
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.additionalToolConnections.connection(?)")

    schema:addDelayedRegistrationFunc("AttacherJoint", function(cSchema, cKey)
        cSchema:register(XMLValueType.STRING, cKey .. ".additionalToolConnection(?)#id", "Identifier of the tool connection")
        cSchema:register(XMLValueType.NODE_INDEX, cKey .. ".additionalToolConnection(?)#node", "Node to connect to")
    end)

    schema:setXMLSpecializationType()
end


---
function AdditionalToolConnections.registerFunctions(vehicleType)
end


---
function AdditionalToolConnections.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointFromXML", AdditionalToolConnections.loadAttacherJointFromXML)
end


---
function AdditionalToolConnections.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AdditionalToolConnections)
    SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", AdditionalToolConnections)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", AdditionalToolConnections)
end


---
function AdditionalToolConnections:onPostLoad(savegame)
    local spec = self.spec_additionalToolConnections

    spec.additionalToolConnections = {}
    self.xmlFile:iterate("vehicle.additionalToolConnections.connection", function(_, connectionKey)
        local id = self.xmlFile:getValue(connectionKey .. "#id")
        local movingPartNode = self.xmlFile:getValue(connectionKey .. "#movingPartNode", nil, self.components, self.i3dMappings)
        if id ~= nil and movingPartNode ~= nil then
            local movingPart = self:getMovingPartByNode(movingPartNode)
            if movingPart ~= nil then
                local entry = {}
                entry.id = id
                entry.movingPartNode = movingPartNode

                entry.objectChanges = {}
                ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, connectionKey, entry.objectChanges, self.components, self)
                ObjectChangeUtil.setObjectChanges(entry.objectChanges, false, self, self.setMovingToolDirty)

                table.insert(spec.additionalToolConnections, entry)
            else
                Logging.xmlWarning(self.xmlFile, "Failed to find moving part for '%s' in '%s'", getName(movingPartNode), connectionKey)
            end
        else
            Logging.xmlWarning(self.xmlFile, "Failed to load additionalToolConnection '%s'", connectionKey)
        end
    end)
end


---Load attacher joint from xml
-- @param table attacherJoint attacherJoint
-- @param integer fileId xml file id
-- @param string baseName baseName
-- @param integer index index of attacher joint
function AdditionalToolConnections:loadAttacherJointFromXML(superFunc, attacherJoint, xmlFile, baseName, index, ...)
    if not superFunc(self, attacherJoint, xmlFile, baseName, index, ...) then
        return false
    end

    attacherJoint.additionalToolConnections = attacherJoint.additionalToolConnections or {}
    xmlFile:iterate(baseName .. ".additionalToolConnection", function(_, connectionKey)
        local id = xmlFile:getValue(connectionKey .. "#id")
        local node = xmlFile:getValue(connectionKey .. "#node", nil, self.components, self.i3dMappings)
        if id ~= nil and node ~= nil then
            attacherJoint.additionalToolConnections[id] = node
        else
            Logging.xmlWarning(xmlFile, "Failed to load additionalToolConnection '%s'", connectionKey)
        end
    end)

    return true
end


---Called if vehicle gets attached
-- @param table attacherVehicle attacher vehicle
-- @param integer inputJointDescIndex index of input attacher joint
-- @param integer jointDescIndex index of attacher joint it gets attached to
-- @param boolean loadFromSavegame attachment is loaded from savegame
function AdditionalToolConnections:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
    local spec = self.spec_additionalToolConnections

    local jointDesc = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)
    if jointDesc.additionalToolConnections ~= nil then
        for i=1, #spec.additionalToolConnections do
            local connection = spec.additionalToolConnections[i]
            local node = jointDesc.additionalToolConnections[connection.id]
            if node ~= nil then
                self:setMovingPartReferenceNode(connection.movingPartNode, node, true)

                ObjectChangeUtil.setObjectChanges(connection.objectChanges, true, self, self.setMovingToolDirty)
            end
        end
    end
end


---Called if vehicle gets attached
-- @param table attacherVehicle attacher vehicle
-- @param table implement implement
function AdditionalToolConnections:onPreDetach(attacherVehicle, implement)
    local spec = self.spec_additionalToolConnections

    for i=1, #spec.additionalToolConnections do
        local connection = spec.additionalToolConnections[i]
        self:setMovingPartReferenceNode(connection.movingPartNode, nil, false)
        ObjectChangeUtil.setObjectChanges(connection.objectChanges, false, self, self.setMovingToolDirty)
    end
end
