




---Event for water trailer filling
local WaterTrailerSetIsFillingEvent_mt = Class(WaterTrailerSetIsFillingEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WaterTrailerSetIsFillingEvent.emptyNew()
    local self = Event.new(WaterTrailerSetIsFillingEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean isFilling is filling
function WaterTrailerSetIsFillingEvent.new(vehicle, isFilling)
    local self = WaterTrailerSetIsFillingEvent.emptyNew()
    self.vehicle = vehicle
    self.isFilling = isFilling
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WaterTrailerSetIsFillingEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isFilling = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WaterTrailerSetIsFillingEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isFilling)
end


---Run action on receiving side
-- @param integer connection connection
function WaterTrailerSetIsFillingEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setIsWaterTrailerFilling(self.isFilling, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isFilling is filling
-- @param boolean noEventSend no event send
function WaterTrailerSetIsFillingEvent.sendEvent(vehicle, isFilling, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(WaterTrailerSetIsFillingEvent.new(vehicle, isFilling), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(WaterTrailerSetIsFillingEvent.new(vehicle, isFilling))
        end
    end
end
