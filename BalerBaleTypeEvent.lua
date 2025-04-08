







---Event for balers to sync selected bale type
local BalerBaleTypeEvent_mt = Class(BalerBaleTypeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BalerBaleTypeEvent.emptyNew()
    return Event.new(BalerBaleTypeEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param integer baleTypeIndex baleTypeIndex
-- @param boolean force force
function BalerBaleTypeEvent.new(object, baleTypeIndex, force)
    local self = BalerBaleTypeEvent.emptyNew()
    self.object = object
    self.baleTypeIndex = baleTypeIndex
    self.force = force
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerBaleTypeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.baleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
    self.force = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerBaleTypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.baleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
    streamWriteBool(streamId, Utils.getNoNil(self.force, false))
end


---Run action on receiving side
-- @param integer connection connection
function BalerBaleTypeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBaleTypeIndex(self.baleTypeIndex, self.force, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param integer baleTypeIndex baleTypeIndex
-- @param boolean force force
-- @param boolean noEventSend no event send
function BalerBaleTypeEvent.sendEvent(object, baleTypeIndex, force, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(BalerBaleTypeEvent.new(object, baleTypeIndex, force), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(BalerBaleTypeEvent.new(object, baleTypeIndex, force))
        end
    end
end
