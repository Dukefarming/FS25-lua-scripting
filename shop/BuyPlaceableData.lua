









---Class to store and sync the data that is required to buy a new placeable (set by the ConstructionScreen and use in BuyPlacdeableEvent)
-- The 'buy' function is able to load the placeable at the given place
local BuyPlaceableData_mt = Class(BuyPlaceableData)


---Creates a new instance of BuyPlaceableData
-- @param table? customMt
-- @return BuyPlaceableData self BuyPlaceableData instance
function BuyPlaceableData.new(customMt)
    local self = setmetatable({}, customMt or BuyPlaceableData_mt)

    self.storeItem = nil
    self.isFreeOfCharge = false
    self.configurations = {}
    self.boughtConfigurations = {}
    self.configurationData = {}
    self.ownerFarmId = AccessHandler.EVERYONE
    self.price = 0
    self.displacementCosts = 0
    self.modifyTerrain = false
    self.position = {0, 0, 0}
    self.rotation = {0, 0, 0}

    return self
end


---Returns if all required data is set and the vehicle can be bought
-- @return boolean isValid is valid
function BuyPlaceableData:isValid()
    if self.storeItem == nil then
        return false
    end

    if GS_IS_CONSOLE_VERSION and not fileExists(self.storeItem.xmlFilename) then
        return false
    end

    return true
end


---Sets the store item
-- @param table storeItem storeItem
function BuyPlaceableData:setStoreItem(storeItem)
    self.storeItem = storeItem
end










---Sets if the palceable is free of charge (e.g. achievement)
-- @param boolean isFreeOfCharge isFreeOfCharge
function BuyPlaceableData:setIsFreeOfCharge(isFreeOfCharge)
    self.isFreeOfCharge = isFreeOfCharge
end


---Sets the configurations
-- @param table configurations configurations
-- @param table boughtConfigurations boughtConfigurations
function BuyPlaceableData:setConfigurations(configurations, boughtConfigurations)
    self.configurations = configurations or self.configurations
    self.boughtConfigurations = boughtConfigurations or self.boughtConfigurations

    for configName, index in pairs(self.configurations) do
        if self.boughtConfigurations[configName] == nil then
            self.boughtConfigurations[configName] = {}
        end

        self.boughtConfigurations[configName][index] = true
    end
end


---Sets the configuration data
-- @param table configurationData configurationData
function BuyPlaceableData:setConfigurationData(configurationData)
    self.configurationData = configurationData or self.configurationData
end


---Sets the owner of the placeable
-- @param integer ownerFarmId ownerFarmId
function BuyPlaceableData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end


---Sets a custom price for the purchase
-- @param integer price price
function BuyPlaceableData:setPrice(price)
    self.price = price
end


---Updates to price depending on the store item + configurations
function BuyPlaceableData:updatePrice()
    self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem, self.configurations, nil)
end


---Sets the displacement costs
-- @param integer displacementCosts
function BuyPlaceableData:setDisplacementCosts(displacementCosts)
    self.displacementCosts = displacementCosts
end


---Sets if terrain is modified
-- @param boolean modifyTerrain modifyTerrain
function BuyPlaceableData:setModifyTerrain(modifyTerrain)
    self.modifyTerrain = modifyTerrain
end


---Read data from stream
-- @param integer streamId streamId
-- @param table connection connection
function BuyPlaceableData:readStream(streamId, connection)
    local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    self.storeItem = g_storeManager:getItemByXMLFilename(xmlFilename:lower())

    self.position[1] = streamReadFloat32(streamId)
    self.position[2] = streamReadFloat32(streamId)
    self.position[3] = streamReadFloat32(streamId)
    self.rotation[1] = streamReadFloat32(streamId)
    self.rotation[2] = streamReadFloat32(streamId)
    self.rotation[3] = streamReadFloat32(streamId)

    self.configurations, self.boughtConfigurations, self.configurationData = ConfigurationUtil.readConfigurationsFromStream(g_placeableConfigurationManager, streamId, connection, xmlFilename)

    self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.isFreeOfCharge = streamReadBool(streamId)
    self.displacementCosts = streamReadInt32(streamId)
    self.modifyTerrain = streamReadBool(streamId)
end


---Write data to stream
-- @param integer streamId streamId
-- @param table connection connection
function BuyPlaceableData:writeStream(streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))

    streamWriteFloat32(streamId, self.position[1])
    streamWriteFloat32(streamId, self.position[2])
    streamWriteFloat32(streamId, self.position[3])
    streamWriteFloat32(streamId, self.rotation[1])
    streamWriteFloat32(streamId, self.rotation[2])
    streamWriteFloat32(streamId, self.rotation[3])

    ConfigurationUtil.writeConfigurationsToStream(g_placeableConfigurationManager, streamId, connection, self.storeItem.xmlFilename, self.configurations, self.boughtConfigurations, self.configurationData)

    streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteBool(streamId, self.isFreeOfCharge)
    streamWriteInt32(streamId, self.displacementCosts)
    streamWriteBool(streamId, self.modifyTerrain)
end


---Execute the purchase and load the placeable at the given places
-- @param function? callback callback that is called after all vehicles have been loaded (optional)
-- @param table? callbackTarget optional callback target
-- @param table? callbackArguments optional callback arguments
function BuyPlaceableData:buy(callback, callbackTarget, callbackArguments)
    local data = PlaceableLoadingData.new()
    data:setStoreItem(self.storeItem)
    data:setConfigurations(self.configurations, self.boughtConfigurations)
    data:setConfigurationData(self.configurationData)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setPosition(self.position[1], self.position[2], self.position[3])
    data:setRotation(self.rotation[1], self.rotation[2], self.rotation[3])
    data:load(self.onLoaded, self, {callback=callback, callbackTarget=callbackTarget, callbackArguments=callbackArguments})
end
