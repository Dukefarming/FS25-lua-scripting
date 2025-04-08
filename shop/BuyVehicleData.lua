









---Class to store and sync the data that is required to buy a new vehicle or reconfigure a existing vehicle (set by the ShopConfigScreen and use in BuyVehicleEvent and ChangeVehicleConfigEvent)
-- The 'buy' function is able to load the vehicle(s) at the given store place
local BuyVehicleData_mt = Class(BuyVehicleData)


---Creates a new instance of BuyVehicleData
-- @param table? customMt
-- @return BuyVehicleData self
function BuyVehicleData.new(customMt)
    local self = setmetatable({}, customMt or BuyVehicleData_mt)

    self.storeItem = nil
    self.isFreeOfCharge = false
    self.configurations = {}
    self.boughtConfigurations = {}
    self.configurationData = {}
    self.leaseVehicle = false
    self.ownerFarmId = AccessHandler.EVERYONE
    self.licensePlateData = nil
    self.saleItem = nil
    self.price = 0

    return self
end


---Returns if all required data is set and the vehicle can be bought
-- @return boolean isValid is valid
function BuyVehicleData:isValid()
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
function BuyVehicleData:setStoreItem(storeItem)
    self.storeItem = storeItem
end


---Sets if the vehicle is free of charge (e.g. achievement)
-- @param boolean isFreeOfCharge isFreeOfCharge
function BuyVehicleData:setIsFreeOfCharge(isFreeOfCharge)
    self.isFreeOfCharge = isFreeOfCharge
end


---Sets the configurations
-- @param table configurations configurations
-- @param table boughtConfigurations boughtConfigurations
function BuyVehicleData:setConfigurations(configurations, boughtConfigurations)
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
function BuyVehicleData:setConfigurationData(configurationData)
    self.configurationData = configurationData or self.configurationData
end


---Sets if the vehicle is leased or bough
-- @param boolean leaseVehicle leaseVehicle
function BuyVehicleData:setLeaseVehicle(leaseVehicle)
    self.leaseVehicle = leaseVehicle
end


---Sets the owner of the vehicle
-- @param integer ownerFarmId ownerFarmId
function BuyVehicleData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end


---Sets the license plate data
-- @param table licensePlateData licensePlateData
function BuyVehicleData:setLicensePlateData(licensePlateData)
    self.licensePlateData = licensePlateData
end


---Sets the corresponding saleItem if the vehicle is bought from the sales
-- @param table saleItem saleItem
function BuyVehicleData:setSaleItem(saleItem)
    self.saleItem = saleItem
end


---Sets a custom price for the purchase
-- @param integer price price
function BuyVehicleData:setPrice(price)
    self.price = price
end


---Updates to price depending on the store item + configurations
function BuyVehicleData:updatePrice()
    self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem, self.configurations, self.saleItem)

    if self.leaseVehicle then
        self.price = g_currentMission.economyManager:getInitialLeasingPrice(self.price)
    end
end


---Returns if the purchase is for limited objects (pallets or bales)
-- @return boolean isBalePurchase is a bale purchase
-- @return boolean isPalletPurchase is a pallet purchase
function BuyVehicleData:getIsLimitedObjectPurchase()
    -- check if buying bales and pallets
    local xmlFile = XMLFile.load("BuyVehicleDataVehicleXML", self.storeItem.xmlFilename, nil)
    local isBalePurchase = xmlFile:hasProperty("vehicle.multipleItemPurchase") and xmlFile:getBool("vehicle.multipleItemPurchase#isVehicle") == false
    local isPalletPurchase = xmlFile:hasProperty("vehicle.multipleItemPurchase") and xmlFile:getBool("vehicle.multipleItemPurchase#isVehicle")
    xmlFile:delete()

    return isBalePurchase, isPalletPurchase
end


---Read data from stream
-- @param integer streamId streamId
-- @param table connection connection
function BuyVehicleData:readStream(streamId, connection)
    local xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    self.storeItem = g_storeManager:getItemByXMLFilename(xmlFilename:lower())

    self.isFreeOfCharge = streamReadBool(streamId)

    self.configurations, self.boughtConfigurations, self.configurationData = ConfigurationUtil.readConfigurationsFromStream(g_vehicleConfigurationManager, streamId, connection, xmlFilename)

    self.leaseVehicle = streamReadBool(streamId)
    self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

    self.licensePlateData = LicensePlateManager.readLicensePlateData(streamId, connection)

    local saleId = streamReadUInt8(streamId)
    if saleId ~= 0 then
        self.saleItem = g_currentMission.vehicleSaleSystem:getSaleById(saleId)
    end
end


---Write data to stream
-- @param integer streamId streamId
-- @param table connection connection
function BuyVehicleData:writeStream(streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))

    streamWriteBool(streamId, self.isFreeOfCharge)

    ConfigurationUtil.writeConfigurationsToStream(g_vehicleConfigurationManager, streamId, connection, self.storeItem.xmlFilename, self.configurations, self.boughtConfigurations, self.configurationData)

    streamWriteBool(streamId, self.leaseVehicle)
    streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)

    LicensePlateManager.writeLicensePlateData(streamId, connection, self.licensePlateData)

    if self.saleItem ~= nil then
        streamWriteUInt8(streamId, self.saleItem.id)
    else
        streamWriteUInt8(streamId, 0)
    end
end


---Execute the purchase and load the vehicle(s) at the given store places
-- @param table storePlaces storePlaces
-- @param table usedStorePlaces usedStorePlaces
-- @param function? callback callback that is called after all vehicles have been loaded (optional)
-- @param table? callbackTarget optional callback target
-- @param table? callbackArguments optional callback arguments
function BuyVehicleData:buy(storePlaces, usedStorePlaces, callback, callbackTarget, callbackArguments)
    local data = VehicleLoadingData.new()
    data:setStoreItem(self.storeItem)
    data:setConfigurations(self.configurations, self.boughtConfigurations)
    data:setConfigurationData(self.configurationData)
    data:setLoadingPlace(storePlaces, usedStorePlaces)
    data:setPropertyState(self.leaseVehicle and VehiclePropertyState.LEASED or VehiclePropertyState.OWNED)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setSaleItem(self.saleItem)

    data:load(self.onBought, self, {callback=callback, callbackTarget=callbackTarget, callbackArguments=callbackArguments})
end
