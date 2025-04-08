












---
function VehicleConfigurationDataAttacherJoint.registerXMLPaths(schema, rootPath, configPath)
    AttacherJoints.registerAttacherJointXMLPaths(schema, configPath)
end


---
function VehicleConfigurationDataAttacherJoint.onPrePostLoad(vehicle, configItem, configId)
    if configItem.configKey == "" then
        return
    end

    if vehicle.spec_attacherJoints ~= nil then
        for _, key in vehicle.xmlFile:iterator(configItem.configKey .. ".attacherJoint") do
            local attacherJoint = {}
            if vehicle:loadAttacherJointFromXML(attacherJoint, vehicle.xmlFile, key, 0) then
                table.insert(vehicle.spec_attacherJoints.attacherJoints, attacherJoint)
            end
        end
    end
end
