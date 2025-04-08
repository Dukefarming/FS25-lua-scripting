




---Event for work modes
local SetWorkModeEvent_mt = Class(SetWorkModeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetWorkModeEvent.emptyNew()
    local self = Event.new(SetWorkModeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer state state
function SetWorkModeEvent.new(vehicle, state)
    local self = SetWorkModeEvent.emptyNew()
    self.vehicle = vehicle
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetWorkModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, WorkMode.WORKMODE_SEND_NUM_BITS)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetWorkModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, WorkMode.WORKMODE_SEND_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function SetWorkModeEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setWorkMode(self.state, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SetWorkModeEvent.new(self.vehicle, self.state), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function SetWorkModeEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetWorkModeEvent.new(vehicle, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(SetWorkModeEvent.new(vehicle, state))
        end
    end
end
