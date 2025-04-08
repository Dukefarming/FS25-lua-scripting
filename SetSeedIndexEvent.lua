




---Set seed index event
local SetSeedIndexEvent_mt = Class(SetSeedIndexEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetSeedIndexEvent.emptyNew()
    local self = Event.new(SetSeedIndexEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer seedIndex index of seed
function SetSeedIndexEvent.new(object, seedIndex)
    local self = SetSeedIndexEvent.emptyNew()
    self.object = object
    self.seedIndex = seedIndex
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetSeedIndexEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.seedIndex = streamReadUInt8(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetSeedIndexEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUInt8(streamId, self.seedIndex)
end


---Run action on receiving side
-- @param integer connection connection
function SetSeedIndexEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setSeedIndex(self.seedIndex, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param integer seedIndex index of seed
-- @param boolean noEventSend no event send
function SetSeedIndexEvent.sendEvent(object, seedIndex, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetSeedIndexEvent.new(object, seedIndex), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(SetSeedIndexEvent.new(object, seedIndex))
        end
    end
end
