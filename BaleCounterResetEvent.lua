









---
local BaleCounterResetEvent_mt = Class(BaleCounterResetEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BaleCounterResetEvent.emptyNew()
    local self = Event.new(BaleCounterResetEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function BaleCounterResetEvent.new(object)
    local self = BaleCounterResetEvent.emptyNew()
    self.object = object

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleCounterResetEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleCounterResetEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function BaleCounterResetEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:doBaleCounterReset(true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function BaleCounterResetEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BaleCounterResetEvent.new(vehicle), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(BaleCounterResetEvent.new(vehicle))
        end
    end
end
