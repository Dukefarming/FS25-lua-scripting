




---Event for dicharge state
local SetDischargeStateEvent_mt = Class(SetDischargeStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetDischargeStateEvent.emptyNew()
    local self = Event.new(SetDischargeStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer state discharge state
function SetDischargeStateEvent.new(vehicle, state)
    local self = SetDischargeStateEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetDischargeStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, 2)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetDischargeStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, 2)
end


---Run action on receiving side
-- @param integer connection connection
function SetDischargeStateEvent:run(connection)
    if self.vehicle ~= nil then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            self.vehicle:setDischargeState(self.state, true)
        end
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SetDischargeStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state discharge state
-- @param boolean noEventSend no event send
function SetDischargeStateEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetDischargeStateEvent.new(vehicle, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(SetDischargeStateEvent.new(vehicle, state))
        end
    end
end
