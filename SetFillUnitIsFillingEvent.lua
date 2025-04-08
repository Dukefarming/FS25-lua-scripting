




---Event for toggle filling
local SetFillUnitIsFillingEvent_mt = Class(SetFillUnitIsFillingEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetFillUnitIsFillingEvent.emptyNew()
    local self = Event.new(SetFillUnitIsFillingEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean isFilling is filling state
function SetFillUnitIsFillingEvent.new(vehicle, isFilling)
    local self = SetFillUnitIsFillingEvent.emptyNew()
    self.vehicle = vehicle
    self.isFilling = isFilling
    return self
end


---Called on client side
-- @param integer streamId streamId
-- @param integer connection connection
function SetFillUnitIsFillingEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isFilling = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side
-- @param integer streamId streamId
-- @param integer connection connection
function SetFillUnitIsFillingEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isFilling)
end


---Run action on receiving side
-- @param integer connection connection
function SetFillUnitIsFillingEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setFillUnitIsFilling(self.isFilling, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SetFillUnitIsFillingEvent.new(self.vehicle, self.isFilling), nil, connection, self.vehicle)
    end
end
