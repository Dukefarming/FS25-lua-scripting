




---Event for baleWrappers to sync automatic drop state
local BaleWrapperAutomaticDropEvent_mt = Class(BaleWrapperAutomaticDropEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BaleWrapperAutomaticDropEvent.emptyNew()
    return Event.new(BaleWrapperAutomaticDropEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param boolean automaticDrop automaticDrop
function BaleWrapperAutomaticDropEvent.new(object, automaticDrop)
    local self = BaleWrapperAutomaticDropEvent.emptyNew()
    self.object = object
    self.automaticDrop = automaticDrop
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapperAutomaticDropEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.automaticDrop = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapperAutomaticDropEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.automaticDrop)
end


---Run action on receiving side
-- @param integer connection connection
function BaleWrapperAutomaticDropEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBaleWrapperAutomaticDrop(self.automaticDrop, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean automaticDrop automaticDrop
-- @param boolean noEventSend no event send
function BaleWrapperAutomaticDropEvent.sendEvent(object, automaticDrop, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BaleWrapperAutomaticDropEvent.new(object, automaticDrop), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(BaleWrapperAutomaticDropEvent.new(object, automaticDrop))
        end
    end
end
