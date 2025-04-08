




---Event for steering mode
local SetCrabSteeringEvent_mt = Class(SetCrabSteeringEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetCrabSteeringEvent.emptyNew()
    local self = Event.new(SetCrabSteeringEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer state state
function SetCrabSteeringEvent.new(vehicle, state)
    local self = SetCrabSteeringEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCrabSteeringEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, CrabSteering.STEERING_SEND_NUM_BITS)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCrabSteeringEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, CrabSteering.STEERING_SEND_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function SetCrabSteeringEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setCrabSteering(self.state, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SetCrabSteeringEvent.new(self.vehicle, self.state), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function SetCrabSteeringEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetCrabSteeringEvent.new(vehicle, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(SetCrabSteeringEvent.new(vehicle, state))
        end
    end
end
