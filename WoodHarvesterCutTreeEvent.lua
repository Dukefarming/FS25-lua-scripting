




---Event for cut tree
local WoodHarvesterCutTreeEvent_mt = Class(WoodHarvesterCutTreeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WoodHarvesterCutTreeEvent.emptyNew()
    local self = Event.new(WoodHarvesterCutTreeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param float length length
function WoodHarvesterCutTreeEvent.new(object, length)
    local self = WoodHarvesterCutTreeEvent.emptyNew()
    self.object = object
    self.length = length
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterCutTreeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.length = streamReadFloat32(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterCutTreeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteFloat32(streamId, self.length)
end


---Run action on receiving side
-- @param integer connection connection
function WoodHarvesterCutTreeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(WoodHarvesterCutTreeEvent.new(self.object, self.length), nil, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:cutTree(self.length, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param float length length
-- @param boolean noEventSend no event send
function WoodHarvesterCutTreeEvent.sendEvent(object, length, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(WoodHarvesterCutTreeEvent.new(object, length), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(WoodHarvesterCutTreeEvent.new(object, length))
        end
    end
end
