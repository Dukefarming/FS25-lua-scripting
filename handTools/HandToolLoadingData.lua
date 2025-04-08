









---Stores all data that is required to load a HandTool
local HandToolLoadingData_mt = Class(HandToolLoadingData)


---Creates a new instance of HandToolLoadingData
-- @return table handToolLoadingData HandToolLoadingData instance
function HandToolLoadingData.new(customMt)
    local self = setmetatable({}, customMt or HandToolLoadingData_mt)

    self.isValid = false
    self.storeItem = nil
    self.handToolData = nil
    self.ownerFarmId = AccessHandler.EVERYONE
    self.savegameData = nil
    self.isSaved = true
    self.canBeDropped = true

    self.isRegistered = true
    self.forceServer = false
    self.loadingHandTool = nil
    self.loadingState = nil

    return self
end


---Sets the store data by given xml filename
-- @param string filename filename
function HandToolLoadingData:setFilename(filename)
    if fileExists(filename) then
        self.handToolData = { xmlFilename = filename }
    else
        Logging.error("Unable to find handtool config for '%s'", filename)
        printCallstack()
    end
end


---Sets the store item
-- @param table storeItem storeItem
function HandToolLoadingData:setStoreItem(storeItem)
    if storeItem ~= nil then
        self.storeItem = storeItem
        self.handToolData = { xmlFilename = storeItem.xmlFilename }
    else
        Logging.error("No store item defined")
        printCallstack()
    end

    self.isValid = storeItem ~= nil
end


---Sets the owner of the handtool
-- @param integer ownerFarmId ownerFarmId
function HandToolLoadingData:setOwnerFarmId(ownerFarmId)
    self.ownerFarmId = ownerFarmId
end


---Sets if the handtool is registered after loading
-- @param boolean isRegistered isRegistered
function HandToolLoadingData:setIsRegistered(isRegistered)
    self.isRegistered = isRegistered
end

















---Sets the savegame data for a handtool if it's loaded from a savegame
-- @param table savegameData savegameData (table with the following attributes: xmlFile, key)
function HandToolLoadingData:setSavegameData(savegameData)
    self.savegameData = savegameData
end


---Load handtool and calls the optional callback
-- @param function? callback callback to be called when handtool has been loaded
-- @param table? callbackTarget callback target
-- @param table? callbackArguments callback arguments
function HandToolLoadingData:load(callback, callbackTarget, callbackArguments)
    self.callback, self.callbackTarget, self.callbackArguments = callback, callbackTarget, callbackArguments

    local handToolData = self.handToolData
    handToolData.handToolType, handToolData.handToolClass = g_handToolTypeManager:getObjectTypeFromXML(handToolData.xmlFilename)

    self.loadingState = HandToolLoadingState.OK

    if handToolData.handToolType == nil or handToolData.handToolClass == nil then
        self.loadingState = HandToolLoadingState.ERROR
        if self.callback ~= nil then
            self.callback(self.callbackTarget, nil, self.loadingState, self.callbackArguments)
        end
        return
    end

    self:loadHandTool(handToolData)
end
