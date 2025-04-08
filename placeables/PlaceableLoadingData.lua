









---Stores all data that is required to load a Placeable
local PlaceableLoadingData_mt = Class(PlaceableLoadingData)


---Creates a new instance of PlaceableLoadingData
-- @return table PlaceableLoadingData PlaceableLoadingData instance
function PlaceableLoadingData.new(customMt)
    local self = setmetatable({}, customMt or PlaceableLoadingData_mt)

    self.storeItem = nil
    self.validLocation = true

    self.placeable = nil
    self.isValid = false
    self.propertyState = PlaceablePropertyState.OWNED
    self.ownerFarmId = AccessHandler.EVERYONE

    self.forceServer = false
    self.isSaved = true

    self.uniqueId = nil
    self.loadingState = nil
    self.savegameData = nil
    self.configurations = {}
    self.boughtConfigurations = {}
    self.configurationData = {}

    self.isRegistered = true

    self.preplacedIndex = nil

    self.price = nil

    self.position = {0, 0, 0}
    self.rotation = {0, 0, 0}

    self.customParameters = {}

    return self
end


---Sets the store data by given xml filename
-- @param string filename filename
function PlaceableLoadingData:setFilename(filename)
    local storeItem = g_storeManager:getItemByXMLFilename(filename)
    if storeItem ~= nil then
        self:setStoreItem(storeItem)
    else
        Logging.error("Unable to find placeable storeitem for '%s'", filename)
        printCallstack()
    end
end


---Sets the store item
-- @param table storeItem storeItem
function PlaceableLoadingData:setStoreItem(storeItem)
    if storeItem ~= nil then
        self.storeItem = storeItem

        self.rotation[2] = storeItem.rotation

        self.placeable = { xmlFilename=storeItem.xmlFilename }
    end

    self.isValid = self.placeable ~= nil
end



---Sets the property state of the placeable
-- @param integer propertyState propertyState
function PlaceableLoadingData:setPropertyState(propertyState)
    self.propertyState = propertyState
end


---Sets the owner of the placeable
-- @param integer ownerFarmId ownerFarmId
function PlaceableLoadingData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end


---Sets the savegame data for a placeable if it's loaded from a savegame
-- @param table savegameData savegameData (table with the following attributes: xmlFile, key, ignoreFarmId)
function PlaceableLoadingData:setSavegameData(savegameData)
    self.savegameData = savegameData

    if self.storeItem ~= nil then
        -- load savegame configurations
        if savegameData ~= nil and savegameData.xmlFile ~= nil then
            self.configurations, self.boughtConfigurations, self.configurationData = ConfigurationUtil.loadConfigurationsFromXMLFile(self.storeItem.xmlFilename, savegameData.xmlFile, savegameData.key .. ".configuration")

            -- savegame backward compatibility
            for _, key in savegameData.xmlFile:iterator(savegameData.key .. ".boughtConfiguration") do
                local name = savegameData.xmlFile:getValue(key.."#name")
                local id = savegameData.xmlFile:getValue(key.."#id")
                if name ~= nil and id ~= nil then
                    if self.boughtConfigurations[name] == nil then
                        self.boughtConfigurations[name] = {}
                    end

                    local configIndex = ConfigurationUtil.getConfigIdBySaveId(self.storeItem.xmlFilename, name, id)
                    if configIndex ~= nil then
                        self.boughtConfigurations[name][configIndex] = true
                    end
                else
                    Logging.xmlWarning(savegameData.xmlFile, "Invalid bought configuration in '%s'!", savegameData.key)
                end
            end
        end
    end
end


















---Sets the configurations for the placeable
-- @param table configurations configurations
function PlaceableLoadingData:setConfigurations(configurations)
    if configurations ~= nil then
        self.configurations = configurations
    else
        self.configurations = {}
    end
end


---Sets the bought configurations for the placeable
-- @param table boughtConfigurations boughtConfigurations
function PlaceableLoadingData:setBoughtConfigurations(boughtConfigurations)
    if boughtConfigurations ~= nil then
        self.boughtConfigurations = boughtConfigurations
    else
        self.boughtConfigurations = {}
    end
end


---Sets the configuration data
-- @param table boughtConfigurations boughtConfigurations
function PlaceableLoadingData:setConfigurationData(configurationData)
    if configurationData ~= nil then
        self.configurationData = configurationData
    else
        self.configurationData = {}
    end
end


---Returns a cloned table of the configurations for the given configFileName
-- @param string configFileName path to xml file
-- @return table configurations configurations
-- @return table boughtConfigurations boughtConfigurations
function PlaceableLoadingData:getConfigurations(configFileName)
    local configurations = table.clone(self.configurations, math.huge)
    local boughtConfigurations = table.clone(self.boughtConfigurations, math.huge)
    local configurationData = table.clone(self.configurationData, math.huge)

    local storeItem = g_storeManager:getItemByXMLFilename(configFileName)
    if storeItem ~= nil and storeItem.configurations ~= nil then
        for configName, configId in pairs(configurations) do
            if storeItem.configurations[configName] == nil then
                configurations[configName] = nil
                boughtConfigurations[configName] = nil
            end
        end
    end

    if self.storeItem.configurations ~= nil then
        for configName, configItems in pairs(self.storeItem.configurations) do
            local configIndex = configurations[configName]
            if configIndex == nil then
                configurations[configName] = ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
            end
        end
    end

    return configurations, boughtConfigurations, configurationData
end


---Sets if the placeable is registered after loading
-- @param boolean isRegistered isRegistered
function PlaceableLoadingData:setIsRegistered(isRegistered)
    self.isRegistered = isRegistered
end


---Sets if the placeable is created as server placeable also on client side (With dynamic physics etc.)
-- @param boolean forceServer forceServer
function PlaceableLoadingData:setForceServer(forceServer)
    self.forceServer = forceServer
end


---Sets if the placeable is saved
-- @param boolean isSaved isSaved
function PlaceableLoadingData:setIsSaved(isSaved)
    self.isSaved = isSaved
end


---Set custom parameter which is available inside the placeable
-- @param string name name of parameter
-- @param any value parameter value
function PlaceableLoadingData:setCustomParameter(name, value)
    self.customParameters[name] = value
end


---Returns custom parameter value by given name
-- @param string name name of parameter
-- @return any value parameter value
function PlaceableLoadingData:getCustomParameter(name)
    return self.customParameters[name]
end


---Set spawn translation (World space)
-- @param float x x translation
-- @param float y y translation (if nil, the terrain height will be used)
-- @param float z z translation
function PlaceableLoadingData:setPosition(x, y, z)
    if y == nil then
        y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
    end

    self.position[1], self.position[2], self.position[3] = x, y, z
end


---Set spawn rotation (World space)
-- @param float rx x rotation
-- @param float ry y rotation
-- @param float rz z rotation
function PlaceableLoadingData:setRotation(rx, ry, rz)
    self.rotation[1], self.rotation[2], self.rotation[3] = rx, ry, rz
end


---Set the spawn translation and rotation based on the given node's position
-- @param entityId node node id
function PlaceableLoadingData:setSpawnNode(node)
    self.position[1], self.position[2], self.position[3] = getWorldTranslation(node)
    self.rotation[1], self.rotation[2], self.rotation[3] = getWorldRotation(node)
end



---Apply the position data to a given placeable
-- @param table placeable placeable
-- @return boolean success position data was successfully applied (otherwise the placeable was not correctly spawned and should be removed)
function PlaceableLoadingData:applyPositionData(placeable)
    if not self.validLocation then
        return false
    end

    if self.preplacedIndex ~= nil then
        return true
    end

    if self.savegameData ~= nil then
        local savegame = self.savegameData
        local x, y, z = savegame.xmlFile:getValue(savegame.key .. "#position")
        local xRot, yRot, zRot = savegame.xmlFile:getValue(savegame.key .. "#rotation")

        if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
            Logging.xmlWarning(savegame.xmlFile, "Invalid position in '%s' (%s)!", savegame.key, placeable.configFileName)
            return false
        end

        placeable:setPose(x, y, z, xRot, yRot, zRot)

        return true
    end

    placeable:setPose(self.position[1], self.position[2], self.position[3], self.rotation[1], self.rotation[2], self.rotation[3])

    return true
end


---Loads placeable from the set storeItem and calls the optional callback
-- @param function? callback callback to be called when all vehicles have been loaded
-- @param table? callbackTarget callback target
-- @param table? callbackArguments callback arguments
function PlaceableLoadingData:load(callback, callbackTarget, callbackArguments)
    g_currentMission.placeableSystem:addPendingPlaceableLoad(self)

    self.callback, self.callbackTarget, self.callbackArguments = callback, callbackTarget, callbackArguments

    self.loadingState = PlaceableLoadingState.OK
    self:loadPlaceable(self.placeable)
end
