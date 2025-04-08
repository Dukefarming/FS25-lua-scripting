











---
local TreeDetachEvent_mt = Class(TreeDetachEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TreeDetachEvent.emptyNew()
    local self = Event.new(TreeDetachEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function TreeDetachEvent.new(object, ropeIndex)
    local self = TreeDetachEvent.emptyNew()
    self.object = object
    self.ropeIndex = ropeIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeDetachEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    if streamReadBool(streamId) then
        self.ropeIndex = streamReadUIntN(streamId, 4)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeDetachEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)

    if streamWriteBool(streamId, self.ropeIndex ~= nil) then
        streamWriteUIntN(streamId, self.ropeIndex, 4)
    end
end


---Run action on receiving side
-- @param integer connection connection
function TreeDetachEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.object.detachTreeFromCarriage ~= nil then
            self.object:detachTreeFromCarriage(self.ropeIndex, true)
        elseif self.object.detachTreeFromWinch ~= nil then
            self.object:detachTreeFromWinch(self.ropeIndex, true)
        end
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean noEventSend no event send
function TreeDetachEvent.sendEvent(vehicle, ropeIndex, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreeDetachEvent.new(vehicle, ropeIndex), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(TreeDetachEvent.new(vehicle, ropeIndex))
        end
    end
end
