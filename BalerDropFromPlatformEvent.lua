




---Event for baler is unloading state
local BalerDropFromPlatformEvent_mt = Class(BalerDropFromPlatformEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BalerDropFromPlatformEvent.emptyNew()
    local self = Event.new(BalerDropFromPlatformEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean waitForNextBale is unloading bale
function BalerDropFromPlatformEvent.new(object, waitForNextBale)
    local self = BalerDropFromPlatformEvent.emptyNew()
    self.object = object
    self.waitForNextBale = waitForNextBale
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerDropFromPlatformEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.waitForNextBale = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerDropFromPlatformEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.waitForNextBale)
end


---Run action on receiving side
-- @param integer connection connection
function BalerDropFromPlatformEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:dropBaleFromPlatform(self.waitForNextBale, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean waitForNextBale waitForNextBale
-- @param boolean noEventSend no event send
function BalerDropFromPlatformEvent.sendEvent(object, waitForNextBale, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BalerDropFromPlatformEvent.new(object, waitForNextBale), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(BalerDropFromPlatformEvent.new(object, waitForNextBale))
        end
    end
end
