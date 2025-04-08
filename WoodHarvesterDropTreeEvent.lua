




---Event for cut tree
local WoodHarvesterDropTreeEvent_mt = Class(WoodHarvesterDropTreeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WoodHarvesterDropTreeEvent.emptyNew()
    local self = Event.new(WoodHarvesterDropTreeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param float length length
function WoodHarvesterDropTreeEvent.new(object)
    local self = WoodHarvesterDropTreeEvent.emptyNew()
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterDropTreeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterDropTreeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function WoodHarvesterDropTreeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(WoodHarvesterDropTreeEvent.new(self.object), nil, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:dropWoodHarvesterTree(true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param float length length
-- @param boolean noEventSend no event send
function WoodHarvesterDropTreeEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(WoodHarvesterDropTreeEvent.new(object), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(WoodHarvesterDropTreeEvent.new(object))
        end
    end
end
