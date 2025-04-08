










---
local LoadingStation_mt = Class(LoadingStation, Object)


















































































---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function LoadingStation:readStream(streamId, connection)
    LoadingStation:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        for _, loadTrigger in ipairs(self.loadTriggers) do
            local loadTriggerId = NetworkUtil.readNodeObjectId(streamId)
            loadTrigger:readStream(streamId, connection)
            g_client:finishRegisterObject(loadTrigger, loadTriggerId)
        end
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function LoadingStation:writeStream(streamId, connection)
    LoadingStation:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        for _, loadTrigger in ipairs(self.loadTriggers) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(loadTrigger))
            loadTrigger:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, loadTrigger)
        end
    end
end













---
function LoadingStation:raiseActive()
    LoadingStation:superClass().raiseActive(self)

    if self.owningPlaceable ~= nil then
        self.owningPlaceable:raiseActive()
    end
end














































































































































---removeFillLevel
-- @param integer fillTypeIndex
-- @param float fillDelta
-- @param integer farmId
-- @return float remainingDelta
function LoadingStation:removeFillLevel(fillTypeIndex, fillDelta, farmId)

--#debug     assertWithCallstack(fillDelta >= 0, "fillDelta needs to be positive")

    local remainingDelta = fillDelta
    for _, sourceStorage in pairs(self.sourceStorages) do
        if self:hasFarmAccessToStorage(farmId, sourceStorage) then
            local oldFillLevel = sourceStorage:getFillLevel(fillTypeIndex)
            if oldFillLevel > 0 then
                sourceStorage:setFillLevel(oldFillLevel - fillDelta, fillTypeIndex)
            end
            local newFillLevel = sourceStorage:getFillLevel(fillTypeIndex)
            remainingDelta = remainingDelta - (oldFillLevel - newFillLevel)

            if remainingDelta < 0.0001 then
                remainingDelta = 0
                break
            end
        end
    end

    return remainingDelta
end





















































---
function LoadingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX,  basePath .. "#node",          "Loading station node")
    schema:register(XMLValueType.STRING,      basePath .. "#stationName",   "Station name", "LoadingStation")
    schema:register(XMLValueType.FLOAT,       basePath .. "#storageRadius", "Inside of this radius storages can be placed", 50)
    schema:register(XMLValueType.BOOL,        basePath .. "#supportsExtension", "Supports extensions", false)
    schema:register(XMLValueType.STRING,      basePath .. "#fillTypes",   "Basic supported filltypes")
    schema:register(XMLValueType.STRING,      basePath .. "#fillTypeCategories",   "Basic supported filltype categories")

    LoadTrigger.registerXMLPaths(schema, basePath .. ".loadTrigger(?)")
    schema:register(XMLValueType.STRING, basePath .. ".loadTrigger(?)#class", "Name of load trigger class")
end
