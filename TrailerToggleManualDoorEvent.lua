




---Event for toggle manual trailer door opening
local TrailerToggleManualDoorEvent_mt = Class(TrailerToggleManualDoorEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TrailerToggleManualDoorEvent.emptyNew()
    local self = Event.new(TrailerToggleManualDoorEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean state state
function TrailerToggleManualDoorEvent.new(object, tipSideIndex, state)
    local self = TrailerToggleManualDoorEvent.emptyNew()
    self.object = object
    self.tipSideIndex = tipSideIndex
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TrailerToggleManualDoorEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self.tipSideIndex = streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TrailerToggleManualDoorEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
    streamWriteUIntN(streamId, self.tipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function TrailerToggleManualDoorEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setTrailerDoorState(self.tipSideIndex, self.state, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isActive belt is active
-- @param integer beltId id of belt
-- @param boolean noEventSend no event send
function TrailerToggleManualDoorEvent.sendEvent(vehicle, tipSideIndex, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TrailerToggleManualDoorEvent.new(vehicle, tipSideIndex, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(TrailerToggleManualDoorEvent.new(vehicle, tipSideIndex, state))
        end
    end
end
