




---Event for current automatic steering state
local AIAutomaticSteeringStateEvent_mt = Class(AIAutomaticSteeringStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIAutomaticSteeringStateEvent.emptyNew()
    local self = Event.new(AIAutomaticSteeringStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer currentAngle current angle
function AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft)
    local self = AIAutomaticSteeringStateEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    self.segmentIndex = segmentIndex
    self.segmentIsLeft = segmentIsLeft

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)

    if streamReadBool(streamId) then
        self.segmentIndex = streamReadUInt16(streamId)
        self.segmentIsLeft = streamReadBool(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.state)

    if streamWriteBool(streamId, self.segmentIndex ~= nil and self.segmentIndex > 0) then
        streamWriteUInt16(streamId, self.segmentIndex)
        streamWriteBool(streamId, Utils.getNoNil(self.segmentIsLeft, false))
    end
end


---Run action on receiving side
-- @param integer connection connection
function AIAutomaticSteeringStateEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.segmentIndex, self.segmentIsLeft = self.vehicle:setAIAutomaticSteeringEnabled(self.state, self.segmentIndex, self.segmentIsLeft, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(AIAutomaticSteeringStateEvent.new(self.vehicle, self.state, self.segmentIndex, self.segmentIsLeft), nil, nil, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer aiMode aiMode
-- @param boolean noEventSend no event send
function AIAutomaticSteeringStateEvent.sendEvent(vehicle, state, segmentIndex, segmentIsLeft, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft))
        end
    end
end
