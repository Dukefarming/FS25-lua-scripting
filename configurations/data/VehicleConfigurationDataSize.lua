












---
function VehicleConfigurationDataSize.registerXMLPaths(schema, rootPath, configPath)
    schema:setXMLSharedRegistration("VehicleConfigurationDataSize", configPath)

    local sizeKey = configPath .. ".size"
    schema:register(XMLValueType.FLOAT, sizeKey .. "#width", "occupied width of the vehicle when loaded in this configuration")
    schema:register(XMLValueType.FLOAT, sizeKey .. "#length", "occupied length of the vehicle when loaded in this configuration")
    schema:register(XMLValueType.FLOAT, sizeKey .. "#height", "occupied height of the vehicle when loaded in this configuration")
    schema:register(XMLValueType.FLOAT, sizeKey .. "#widthOffset", "width offset")
    schema:register(XMLValueType.FLOAT, sizeKey .. "#lengthOffset", "length offset")
    schema:register(XMLValueType.FLOAT, sizeKey .. "#heightOffset", "height offset")

    schema:resetXMLSharedRegistration("VehicleConfigurationDataSize", configPath)
end


---
function VehicleConfigurationDataSize.onSizeLoad(configItem, xmlFile, sizeData)
    if configItem.configKey == "" then
        return
    end

    local key = configItem.configKey .. ".size"

    -- configuration values will completely overwrite the size values
    sizeData.width = xmlFile:getValue(key .. "#width", sizeData.width)
    sizeData.length = xmlFile:getValue(key .. "#length", sizeData.length)
    sizeData.height = xmlFile:getValue(key .. "#height", sizeData.height)
    sizeData.widthOffset = xmlFile:getValue(key .. "#widthOffset", sizeData.widthOffset)
    sizeData.lengthOffset = xmlFile:getValue(key .. "#lengthOffset", sizeData.lengthOffset)
    sizeData.heightOffset = xmlFile:getValue(key .. "#heightOffset", sizeData.heightOffset)
end
