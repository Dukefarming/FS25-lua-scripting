












---
function VehicleConfigurationDataObjectChange.registerXMLPaths(schema, rootPath, configPath)
    schema:register(XMLValueType.BOOL, rootPath .. "#postLoadObjectChange", "Defines if the object changes are applied before or after post load (can be helpful if you manipulate wheel nodes, which is only possible before postLoad)", false)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, configPath)
end


---
function VehicleConfigurationDataObjectChange.loadConfigItem(configItem, xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
    configItem.postLoadObjectChange = xmlFile:getValue(baseKey .. "#postLoadObjectChange", false)
end


---
function VehicleConfigurationDataObjectChange.onLoad(vehicle, configItem, configId)
    if not configItem.postLoadObjectChange then
        local configurationDesc = g_vehicleConfigurationManager:getConfigurationDescByName(configItem.configName)
        ObjectChangeUtil.updateObjectChanges(vehicle.xmlFile, configurationDesc.configurationKey, configId, vehicle.components, vehicle)
    end
end


---
function VehicleConfigurationDataObjectChange.onPostLoad(vehicle, configItem, configId)
    if configItem.postLoadObjectChange then
        local configurationDesc = g_vehicleConfigurationManager:getConfigurationDescByName(configItem.configName)
        ObjectChangeUtil.updateObjectChanges(vehicle.xmlFile, configurationDesc.configurationKey, configId, vehicle.components, vehicle)
    end
end
