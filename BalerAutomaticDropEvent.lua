




---Event for balers to sync automatic drop state
local BalerAutomaticDropEvent_mt = Class(BalerAutomaticDropEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BalerAutomaticDropEvent.emptyNew()
    return Event.new(BalerAutomaticDropEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param boolean automaticDrop automaticDrop
function BalerAutomaticDropEvent.new(object, automaticDrop)
    local self = BalerAutomaticDropEvent.emptyNew()
    self.object = object
    self.automaticDrop = automaticDrop
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerAutomaticDropEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.automaticDrop = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerAutomaticDropEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.automaticDrop)
end


---Run action on receiving side
-- @param integer connection connection
function BalerAutomaticDropEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBalerAutomaticDrop(self.automaticDrop, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean automaticDrop automaticDrop
-- @param boolean noEventSend no event send
function BalerAutomaticDropEvent.sendEvent(object, automaticDrop, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BalerAutomaticDropEvent.new(object, automaticDrop), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(BalerAutomaticDropEvent.new(object, automaticDrop))
        end
    end
end
