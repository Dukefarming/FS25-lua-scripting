









---
local FellerBuncherReleaseEvent_mt = Class(FellerBuncherReleaseEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FellerBuncherReleaseEvent.emptyNew()
    local self = Event.new(FellerBuncherReleaseEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function FellerBuncherReleaseEvent.new(object)
    local self = FellerBuncherReleaseEvent.emptyNew()
    self.object = object

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FellerBuncherReleaseEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FellerBuncherReleaseEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function FellerBuncherReleaseEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:releaseMountedTrees(true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function FellerBuncherReleaseEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FellerBuncherReleaseEvent.new(vehicle), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(FellerBuncherReleaseEvent.new(vehicle))
        end
    end
end
