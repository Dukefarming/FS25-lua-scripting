









---Class to store and sync the data that is required to buy a new handtool
local BuyHandToolData_mt = Class(BuyHandToolData)


---Creates a new instance of BuyHandToolData
-- @return table BuyHandToolData BuyHandToolData instance
function BuyHandToolData.new(customMt)
    local self = setmetatable({}, customMt or BuyHandToolData_mt)

    self.storeItem = nil
    self.isFreeOfCharge = false
    self.ownerFarmId = AccessHandler.EVERYONE
    self.price = 0
    self.holder = nil

    return self
end


---Returns if all required data is set and the handtool can be bought
-- @return boolean isValid is valid
function BuyHandToolData:isValid()
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
function BuyHandToolData:setStoreItem(storeItem)
    self.storeItem = storeItem
end


---Sets if the handtool is free of charge (e.g. achievement)
-- @param boolean isFreeOfCharge isFreeOfCharge
function BuyHandToolData:setIsFreeOfCharge(isFreeOfCharge)
    self.isFreeOfCharge = isFreeOfCharge
end


---Sets the owner of the handtool
-- @param integer ownerFarmId ownerFarmId
function BuyHandToolData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end


---Sets a custom price for the purchase
-- @param integer price price
function BuyHandToolData:setPrice(price)
    self.price = price
end


---Updates to price depending on the store item + configurations
function BuyHandToolData:updatePrice()
    self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem)
end


---Read data from stream
-- @param integer streamId streamId
-- @param table connection connection
function BuyHandToolData:readStream(streamId, connection)
    local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    self.storeItem = g_storeManager:getItemByXMLFilename(string.lower(xmlFilename))
    self.isFreeOfCharge = streamReadBool(streamId)
    self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
end


---Write data to stream
-- @param integer streamId streamId
-- @param table connection connection
function BuyHandToolData:writeStream(streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))
    streamWriteBool(streamId, self.isFreeOfCharge)
    streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end


---Execute the purchase and load the handtool
-- @param function? callback callback that is called after all vehicles have been loaded (optional)
-- @param table? callbackTarget optional callback target
-- @param table? callbackArguments optional callback arguments
function BuyHandToolData:buy(callback, callbackTarget, callbackArguments)
    local data = HandToolLoadingData.new()
    data:setStoreItem(self.storeItem)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setHolder(self.holder)
    data:load(self.onBought, self, {callback=callback, callbackTarget=callbackTarget, callbackArguments=callbackArguments})
end
