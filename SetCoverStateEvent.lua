




---Event for cover state
local SetCoverStateEvent_mt = Class(SetCoverStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetCoverStateEvent.emptyNew()
    return Event.new(SetCoverStateEvent_mt)
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer state cover state
function SetCoverStateEvent.new(vehicle, state)
    local self = SetCoverStateEvent.emptyNew()

    self.vehicle = vehicle
    self.state = state

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCoverStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, Cover.SEND_NUM_BITS)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCoverStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, Cover.SEND_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function SetCoverStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            self.vehicle:setCoverState(self.state, true)
        end
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state cover state
-- @param boolean noEventSend no event send
function SetCoverStateEvent.sendEvent(vehicle, state, noEventSend)
    if vehicle.spec_cover.state ~= state then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(SetCoverStateEvent.new(vehicle, state), nil, nil, vehicle)
            else
                g_client:getServerConnection():sendEvent(SetCoverStateEvent.new(vehicle, state))
            end
        end
    end
end
