












---
function PlaceableConfigurationDataObjectChange.registerXMLPaths(schema, rootPath, configPath)
    schema:register(XMLValueType.BOOL, rootPath .. "#postLoadObjectChange", "Defines if the object changes are applied before or after post load", false)
    ObjectChangeUtil.registerObjectChangeXMLPaths(schema, configPath)
end


---
function PlaceableConfigurationDataObjectChange.loadConfigItem(configItem, xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
    configItem.postLoadObjectChange = xmlFile:getValue(baseKey .. "#postLoadObjectChange", false)
end


---
function PlaceableConfigurationDataObjectChange.onLoad(placeable, configItem, configId)
    if not configItem.postLoadObjectChange then
        local configurationDesc = g_placeableConfigurationManager:getConfigurationDescByName(configItem.configName)
        ObjectChangeUtil.updateObjectChanges(placeable.xmlFile, configurationDesc.configurationKey, configId, placeable.components, placeable)
    end
end


---
function PlaceableConfigurationDataObjectChange.onPostLoad(placeable, configItem, configId)
    if configItem.postLoadObjectChange then
        local configurationDesc = g_placeableConfigurationManager:getConfigurationDescByName(configItem.configName)
        ObjectChangeUtil.updateObjectChanges(placeable.xmlFile, configurationDesc.configurationKey, configId, placeable.components, placeable)
    end
end
