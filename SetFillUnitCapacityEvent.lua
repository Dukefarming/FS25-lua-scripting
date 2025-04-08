




---Event for fill unit capacity sync
local SetFillUnitCapacityEvent_mt = Class(SetFillUnitCapacityEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetFillUnitCapacityEvent.emptyNew()
    local self = Event.new(SetFillUnitCapacityEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean capacity is filling state
function SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity)
    local self = SetFillUnitCapacityEvent.emptyNew()
    self.vehicle = vehicle
    self.fillUnitIndex = fillUnitIndex
    self.capacity = capacity
    return self
end


---Called on client side
-- @param integer streamId streamId
-- @param integer connection connection
function SetFillUnitCapacityEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.fillUnitIndex = streamReadUIntN(streamId, 8)
    self.capacity = streamReadFloat32(streamId)
    self:run(connection)
end


---Called on server side
-- @param integer streamId streamId
-- @param integer connection connection
function SetFillUnitCapacityEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.fillUnitIndex, 8)
    streamWriteFloat32(streamId, self.capacity)
end


---Run action on receiving side
-- @param integer connection connection
function SetFillUnitCapacityEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setFillUnitCapacity(self.fillUnitIndex, self.capacity, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SetFillUnitCapacityEvent.new(self.vehicle, self.fillUnitIndex, self.capacity), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean isActive is active
-- @param boolean noEventSend no event send
function SetFillUnitCapacityEvent.sendEvent(vehicle, fillUnitIndex, capacity, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity))
        end
    end
end
