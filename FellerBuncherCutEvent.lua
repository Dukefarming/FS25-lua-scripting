









---
local FellerBuncherCutEvent_mt = Class(FellerBuncherCutEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FellerBuncherCutEvent.emptyNew()
    local self = Event.new(FellerBuncherCutEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function FellerBuncherCutEvent.new(object)
    local self = FellerBuncherCutEvent.emptyNew()
    self.object = object

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FellerBuncherCutEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FellerBuncherCutEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function FellerBuncherCutEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:cutTree(true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function FellerBuncherCutEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FellerBuncherCutEvent.new(vehicle), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(FellerBuncherCutEvent.new(vehicle))
        end
    end
end
