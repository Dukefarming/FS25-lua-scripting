













---Returns if a store item is a vehicle
-- @param table storeItem a storeitem object
-- @return boolean true if storeitem is a vehicle, else false
function StoreItemUtil.getIsVehicle(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.VEHICLE
end


---Returns if a store item is an animal
-- @param table storeItem a storeitem object
-- @return boolean true if storeitem is an animal, else false
function StoreItemUtil.getIsAnimal(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.ANIMAL
end


---Returns if a store item is a placeable
-- @param table storeItem a storeitem object
-- @return boolean true if storeitem is a placeable, else false
function StoreItemUtil.getIsPlaceable(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.PLACEABLE
end


---Returns if a store item is an object
-- @param table storeItem a storeitem object
-- @return boolean true if storeitem is an object, else false
function StoreItemUtil.getIsObject(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.OBJECT
end


---Returns if a store item is a handtool
-- @param table storeItem a storeitem object
-- @return boolean true if storeitem is a handtool, else false
function StoreItemUtil.getIsHandTool(storeItem)
    return storeItem ~= nil and storeItem.species == StoreSpecies.HANDTOOL
end


---Returns if a store item is configurable.
-- Checks if there are any configurations and also if any of the configurations has more than just one option.
-- @param table storeItem a storeitem object
-- @return boolean true if storeitem is configurable, else false
function StoreItemUtil.getIsConfigurable(storeItem)
    local hasConfigurations = storeItem ~= nil and storeItem.configurations ~= nil
    local hasMoreThanOneOption = false
    if hasConfigurations then
        for _, configItems in pairs(storeItem.configurations) do
            local selectableItems = 0
            for i=1, #configItems do
                if configItems[i].isSelectable ~= false then
                    selectableItems = selectableItems + 1

                    if selectableItems > 1 then
                        hasMoreThanOneOption = true
                        break
                    end
                end
            end

            if hasMoreThanOneOption then
                break
            end
        end
    end

    return hasConfigurations and hasMoreThanOneOption
end


---Returns if a store item can be bought directly or if buying it first leads to the shop config screen.
-- Checks if the store item is a handtool, in which case the shop config screen is not opened, for all other items it is.
-- @param table storeItem a storeitem object
-- @return boolean true if the item can be shown in config screen, false if the item is bought immediately
function StoreItemUtil.getCanBeShownInConfigScreen(storeItem)
    local isHandTool = StoreItemUtil.getIsHandTool(storeItem)
    return not isHandTool
end


---Returns if a store item is leaseable
-- @param table storeItem a storeitem object
-- @return boolean true if storeitem is leaseable, else false
function StoreItemUtil.getIsLeasable(storeItem)
    return storeItem ~= nil and storeItem.allowLeasing and storeItem.runningLeasingFactor ~= nil and not StoreItemUtil.getIsPlaceable(storeItem)
end


---Get the default config id
-- @param table storeItem a storeitem object
-- @param string configurationName name of the configuration
-- @return integer configId the default config id
function StoreItemUtil.getDefaultConfigId(storeItem, configurationName)
    return ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[configurationName])
end


---Get the default price
-- @param table storeItem a storeitem object
-- @param table? configurations list of configurations
-- @return integer the default price
function StoreItemUtil.getDefaultPrice(storeItem, configurations)
    return StoreItemUtil.getCosts(storeItem, configurations, "price")
end


---Get the daily upkeep
-- @param table storeItem a storeitem object
-- @param table? configurations list of configurations
-- @return integer the daily upkeep
function StoreItemUtil.getDailyUpkeep(storeItem, configurations)
    return StoreItemUtil.getCosts(storeItem, configurations, "dailyUpkeep")
end


---Get the costs of storeitem
-- @param table storeItem a storeitem object
-- @param table? configurations list of configurations
-- @param string costType the cost type
-- @return integer cost of the storeitem
function StoreItemUtil.getCosts(storeItem, configurations, costType)
    if storeItem ~= nil then
        local costs = storeItem[costType]
        if costs == nil then
            costs = 0
        end
        if storeItem.configurations ~= nil then
            for name, value in pairs(configurations) do
                local nameConfig = storeItem.configurations[name]
                if nameConfig ~= nil then
                    local valueConfig = nameConfig[value]
                    if valueConfig ~= nil then
                        local costTypeConfig = valueConfig[costType]
                        if costTypeConfig ~= nil then
                            costs = costs + tonumber(costTypeConfig)
                        end
                    end
                end
            end
        end
        return costs
    end
    return 0
end



































---Gets the storeitem functions from xml as a list, nil if none are present
-- @param integer xmlFile the xml handle
-- @param string storeDataXMLName name of the parent xml element
-- @param string customEnvironment a custom environment
-- @return table? functions list of storeitem functions
function StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLName, customEnvironment)
    local functions
    for functionIndex, functionKey in xmlFile:iterator(storeDataXMLName..".functions.function") do
        local functionName = xmlFile:getValue(functionKey, nil, customEnvironment, true)
        if functionName ~= nil then
            functions = functions or {}
            table.insert(functions, functionName)
        end
    end

    return functions
end


---Loads the storeitem specs values from xml into the item
-- is only run if specs were not loaded before already
function StoreItemUtil.loadSpecsFromXML(item)
    if item.specs == nil then
        local storeItemXmlFile = XMLFile.load("storeItemXML", item.xmlFilename, item.xmlSchema)
        item.specs = StoreItemUtil.getSpecsFromXML(g_storeManager:getSpecTypes(), item.species, storeItemXmlFile, item.customEnvironment, item.baseDir)
        storeItemXmlFile:delete()
    end

    if item.bundleInfo ~= nil then
        local bundleItems = item.bundleInfo.bundleItems
        for i=1, #bundleItems do
            StoreItemUtil.loadSpecsFromXML(bundleItems[i].item)
        end
    end
end


---Gets the storeitem specs from xml
-- @param table specTypes list of spec types
-- @param integer xmlFile the xml handle
-- @param string customEnvironment a custom environment
-- @return table specs list of storeitem specs
function StoreItemUtil.getSpecsFromXML(specTypes, species, xmlFile, customEnvironment, baseDirectory)
--#profile    RemoteProfiler.zoneBeginN("getSpecsFromXML_" .. xmlFile.filename)

    local specs = {}
    for _, specType in pairs(specTypes) do
        if specType.species == species then
            if specType.loadFunc ~= nil then
--#profile                RemoteProfiler.zoneBeginN("type_"..specType.name)
                specs[specType.name] = specType.loadFunc(xmlFile, customEnvironment, baseDirectory)
--#profile                RemoteProfiler.zoneEnd()
            end
        end
    end

--#profile    RemoteProfiler.zoneEnd()

    return specs
end


---Gets the storeitem brand index from xml
-- @param integer xmlFile the xml handle
-- @param string storeDataXMLKey path of the parent xml element
-- @return integer brandIndex the brandindex
function StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLKey)
    local brandName = xmlFile:getValue(storeDataXMLKey..".brand", "")
    return g_brandManager:getBrandIndexByName(brandName)
end


---Gets the storeitem vram usage from xml
-- @param integer xmlFile the xml handle
-- @param string storeDataXMLName name of the parent xml element
-- @return integer sharedVramUsage the shared vram usage
-- @return integer perInstanceVramUsage the per instance vram usage
-- @return boolean ignoreVramUsage true if vram usage should be ignored else false
function StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLName)
    local vertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName..".vertexBufferMemoryUsage", 0)
    local indexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName..".indexBufferMemoryUsage", 0)
    local textureMemoryUsage = xmlFile:getValue(storeDataXMLName..".textureMemoryUsage", 0)
    local instanceVertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName..".instanceVertexBufferMemoryUsage", 0)
    local instanceIndexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName..".instanceIndexBufferMemoryUsage", 0)
    local ignoreVramUsage = xmlFile:getValue(storeDataXMLName..".ignoreVramUsage", false)

    local perInstanceVramUsage = instanceVertexBufferMemoryUsage + instanceIndexBufferMemoryUsage
    local sharedVramUsage = vertexBufferMemoryUsage + indexBufferMemoryUsage + textureMemoryUsage

    return sharedVramUsage, perInstanceVramUsage, ignoreVramUsage
end


---
function StoreItemUtil.getSubConfigurationIndex(storeItem, configName, configIndex)
    local subConfigurations = storeItem.subConfigurations[configName]
    local subConfigValues = subConfigurations.subConfigValues

    for k, identifier in ipairs(subConfigValues) do
        local items = subConfigurations.subConfigItemMapping[identifier]
        for _, item in ipairs(items) do
            if item.index == configIndex then
                return k
            end
        end
    end

    return nil
end


---
function StoreItemUtil.getSubConfigurationItems(storeItem, configName, state)
    local subConfigurations = storeItem.subConfigurations[configName]
    local subConfigValues = subConfigurations.subConfigValues
    local identifier = subConfigValues[state]
    return subConfigurations.subConfigItemMapping[identifier]
end


---
function StoreItemUtil.getSizeValues(xmlFilename, baseName, rotationOffset, configurations)
    local xmlFile = XMLFile.load("storeItemGetSizeXml", xmlFilename, Vehicle.xmlSchema)
    local size = {
        width = Vehicle.defaultWidth,
        length = Vehicle.defaultLength,
        height = Vehicle.defaultHeight,
        widthOffset = 0,
        lengthOffset = 0,
        heightOffset = 0
    }
    if xmlFile ~= nil then
        size = StoreItemUtil.getSizeValuesFromXML(xmlFilename, xmlFile, baseName, rotationOffset, configurations)
        xmlFile:delete()
    end

    return size
end


---
function StoreItemUtil.getSizeValuesFromXML(xmlFilename, xmlFile, baseName, rotationOffset, configurations)
    return StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, "base", "size", "size", rotationOffset, configurations, Vehicle.DEFAULT_SIZE)
end


---
function StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, baseKey, elementKey, configKey, rotationOffset, configurations, defaults)
    local baseSizeKey = string.format("%s.%s.%s", baseName, baseKey, elementKey)

    local size = {
        width = xmlFile:getValue(baseSizeKey .. "#width", defaults.width),
        length = xmlFile:getValue(baseSizeKey .. "#length", defaults.length),
        height = xmlFile:getValue(baseSizeKey .. "#height", defaults.height),
        widthOffset = xmlFile:getValue(baseSizeKey .. "#widthOffset", defaults.widthOffset),
        lengthOffset = xmlFile:getValue(baseSizeKey .. "#lengthOffset", defaults.lengthOffset),
        heightOffset = xmlFile:getValue(baseSizeKey .. "#heightOffset", defaults.heightOffset)
    }

    -- check configurations for changed size values
    if configurations ~= nil then
        for name, id in pairs(configurations) do
            local configItem = ConfigurationUtil.getConfigItemByConfigId(xmlFilename, name, id)
            if configItem ~= nil and configItem.onSizeLoad ~= nil then
                configItem.onSizeLoad(configItem, xmlFile, size)
            end
        end
    end

    -- limit rotation to 90 deg steps
    rotationOffset = math.floor(rotationOffset / math.rad(90) + 0.5) * math.rad(90)
    rotationOffset = rotationOffset % (2*math.pi)
    if rotationOffset < 0 then
        rotationOffset = rotationOffset + 2*math.pi
    end
    -- switch/invert width/length if rotated
    local rotationIndex = math.floor(rotationOffset / math.rad(90) + 0.5)
    if rotationIndex == 1 then -- 90 deg
        size.width, size.length = size.length, size.width
        size.widthOffset,size.lengthOffset = size.lengthOffset, -size.widthOffset
    elseif rotationIndex == 2 then
        size.widthOffset, size.lengthOffset = -size.widthOffset, -size.lengthOffset
    elseif rotationIndex == 3 then -- 270 def
        size.width, size.length = size.length, size.width
        size.widthOffset, size.lengthOffset = -size.lengthOffset, size.widthOffset
    end

    return size
end



---Register configuration set paths
function StoreItemUtil.registerConfigurationSetXMLPaths(schema, baseKey)
    baseKey = baseKey .. ".configurationSets"
    schema:register(XMLValueType.L10N_STRING, baseKey .. "#title", "Title to display in config screen")
    schema:register(XMLValueType.BOOL , baseKey .. "#isYesNoOption", "Defines if the configuration set is a yes/no option", false)

    local setKey = baseKey .. ".configurationSet(?)"
    schema:register(XMLValueType.L10N_STRING, setKey .. "#name", "Set name")
    schema:register(XMLValueType.STRING, setKey .. "#params", "Parameters to insert into name")
    schema:register(XMLValueType.BOOL, setKey .. "#isDefault", "Is default set")
    schema:register(XMLValueType.STRING, setKey .. ".configuration(?)#name", "Configuration name")
    schema:register(XMLValueType.INT, setKey .. ".configuration(?)#index", "Selected index")
end
