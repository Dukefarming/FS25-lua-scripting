









---
local LogGrabClawStateEvent_mt = Class(LogGrabClawStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function LogGrabClawStateEvent.emptyNew()
    local self = Event.new(LogGrabClawStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function LogGrabClawStateEvent.new(object, state, grabIndex)
    local self = LogGrabClawStateEvent.emptyNew()
    self.object = object
    self.state = state
    self.grabIndex = grabIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function LogGrabClawStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self.grabIndex = streamReadUIntN(streamId, LogGrab.GRAB_INDEX_NUM_BITS)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function LogGrabClawStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
    streamWriteUIntN(streamId, self.grabIndex, LogGrab.GRAB_INDEX_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function LogGrabClawStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setLogGrabClawState(self.grabIndex, self.state, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function LogGrabClawStateEvent.sendEvent(vehicle, state, grabIndex, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(LogGrabClawStateEvent.new(vehicle, state, grabIndex), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(LogGrabClawStateEvent.new(vehicle, state, grabIndex))
        end
    end
end
