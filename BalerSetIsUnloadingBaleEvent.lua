




---Event for baler is unloading state
local BalerSetIsUnloadingBaleEvent_mt = Class(BalerSetIsUnloadingBaleEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BalerSetIsUnloadingBaleEvent.emptyNew()
    local self = Event.new(BalerSetIsUnloadingBaleEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isUnloadingBale is unloading bale
function BalerSetIsUnloadingBaleEvent.new(object, isUnloadingBale)
    local self = BalerSetIsUnloadingBaleEvent.emptyNew()
    self.object = object
    self.isUnloadingBale = isUnloadingBale
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerSetIsUnloadingBaleEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isUnloadingBale = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerSetIsUnloadingBaleEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isUnloadingBale)
end


---Run action on receiving side
-- @param integer connection connection
function BalerSetIsUnloadingBaleEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setIsUnloadingBale(self.isUnloadingBale, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean isUnloadingBale isUnloadingBale
-- @param boolean noEventSend no event send
function BalerSetIsUnloadingBaleEvent.sendEvent(object, isUnloadingBale, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BalerSetIsUnloadingBaleEvent.new(object, isUnloadingBale), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(BalerSetIsUnloadingBaleEvent.new(object, isUnloadingBale))
        end
    end
end
