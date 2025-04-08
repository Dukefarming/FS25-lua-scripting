




---Event for ridge marker state
local RidgeMarkerSetStateEvent_mt = Class(RidgeMarkerSetStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function RidgeMarkerSetStateEvent.emptyNew()
    local self = Event.new(RidgeMarkerSetStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean state state
function RidgeMarkerSetStateEvent.new(vehicle, state)
    local self = RidgeMarkerSetStateEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    assert(state >= 0 and state < RidgeMarker.MAX_NUM_RIDGEMARKERS)
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RidgeMarkerSetStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, RidgeMarker.SEND_NUM_BITS)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RidgeMarkerSetStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, RidgeMarker.SEND_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function RidgeMarkerSetStateEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setRidgeMarkerState(self.state, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(RidgeMarkerSetStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state discharge state
-- @param boolean noEventSend no event send
function RidgeMarkerSetStateEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(RidgeMarkerSetStateEvent.new(vehicle, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(RidgeMarkerSetStateEvent.new(vehicle, state))
        end
    end
end
