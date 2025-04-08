











---Configuration item to store tree sapling data and generate the configs dynamically based on the tree types on the map
local VehicleConfigurationItemTreeSapling_mt = Class(VehicleConfigurationItemTreeSapling, VehicleConfigurationItem)


---
function VehicleConfigurationItemTreeSapling.new(configName, customMt)
    local self = VehicleConfigurationItemTreeSapling:superClass().new(configName, VehicleConfigurationItemTreeSapling_mt)

    return self
end


---
function VehicleConfigurationItemTreeSapling:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
    if not VehicleConfigurationItemTreeSapling:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
        return false
    end

    self.useMapTreeTypes = xmlFile:getValue(configKey .. "#useMapTreeTypes", false)
    if self.useMapTreeTypes then
        self.numSaplings = xmlFile:getInt("vehicle.storeData.specs.capacity", 0)
    end

    self.fillUnitIndex = xmlFile:getValue(configKey .. "#fillUnitIndex", 1)
    self.treeTypeName = xmlFile:getValue(configKey .. "#treeType", "spruce")
    self.variationName = xmlFile:getValue(configKey .. "#variationName")
    self.filename = xmlFile:getValue(configKey .. "#filename", nil, baseDirectory)

    return true
end


---
function VehicleConfigurationItemTreeSapling.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
    VehicleConfigurationItemTreeSapling:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)

    for i, baseConfigItem in ipairs(configurationItems) do
        if baseConfigItem.useMapTreeTypes then
            VehicleConfigurationItemTreeSapling.generateConfigurations(configurationItems, xmlFile, configName, baseConfigItem)
            return
        end
    end
end


---
function VehicleConfigurationItemTreeSapling.generateConfigurations(configurationItems, xmlFile, configName, baseConfigItem)
    for i=#configurationItems, 1, -1 do
        configurationItems[i] = nil
    end

    for _, treeTypeDesc in ipairs(g_treePlantManager.treeTypes) do
        if #treeTypeDesc.stages > 1 then
            local configItem = VehicleConfigurationItemTreeSapling.new(configName)

            configItem.name = treeTypeDesc.title
            configItem.price = treeTypeDesc.saplingPrice * baseConfigItem.numSaplings
            configItem.saveId = treeTypeDesc.name

            configItem.fillUnitIndex = baseConfigItem.fillUnitIndex
            configItem.treeTypeName = treeTypeDesc.name
            configItem.variationName = baseConfigItem.variationName
            configItem.filename = nil

            table.insert(configurationItems, configItem)

            local index = #configurationItems
            configItem:setIndex(index)
            configItem.configKey = baseConfigItem.configKey
        end
    end
end


---
function VehicleConfigurationItemTreeSapling.registerXMLPaths(schema, rootPath, configPath)
    VehicleConfigurationItemTreeSapling:superClass().registerXMLPaths(schema, rootPath, configPath)

    schema:register(XMLValueType.BOOL, configPath .. "#useMapTreeTypes", "Create configuration for each tree type on the map", false)

    schema:register(XMLValueType.INT, configPath .. "#fillUnitIndex", "Index of the saplings fill unit", 1)
    schema:register(XMLValueType.STRING, configPath .. "#treeType", "Tree Type Name", "spruce")
    schema:register(XMLValueType.STRING, configPath .. "#variationName", "Stage variation name to use", "DEFAULT")
    schema:register(XMLValueType.FILENAME, configPath .. "#filename", "Custom tree sapling i3d file")
end
