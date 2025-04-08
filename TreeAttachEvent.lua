











---
local TreeAttachEvent_mt = Class(TreeAttachEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TreeAttachEvent.emptyNew()
    local self = Event.new(TreeAttachEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function TreeAttachEvent.new(object, splitShapeId, x, y, z, ropeIndex)
    local self = TreeAttachEvent.emptyNew()
    self.object = object
    self.splitShapeId = splitShapeId
    self.x = x
    self.y = y
    self.z = z
    self.ropeIndex = ropeIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeAttachEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.splitShapeId = readSplitShapeIdFromStream(streamId)
    self.x = streamReadFloat32(streamId)
    self.y = streamReadFloat32(streamId)
    self.z = streamReadFloat32(streamId)

    if streamReadBool(streamId) then
        self.ropeIndex = streamReadUIntN(streamId, 4)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeAttachEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    writeSplitShapeIdToStream(streamId, self.splitShapeId)
    streamWriteFloat32(streamId, self.x)
    streamWriteFloat32(streamId, self.y)
    streamWriteFloat32(streamId, self.z)

    if streamWriteBool(streamId, self.ropeIndex ~= nil) then
        streamWriteUIntN(streamId, self.ropeIndex, 4)
    end
end


---Run action on receiving side
-- @param integer connection connection
function TreeAttachEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.object.attachTreeToCarriage ~= nil then
            self.object:attachTreeToCarriage(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex, true)
        elseif self.object.attachTreeToWinch ~= nil then
            self.object:attachTreeToWinch(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex, nil, true)
        end
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean noEventSend no event send
function TreeAttachEvent.sendEvent(vehicle, splitShapeId, x, y, z, ropeIndex, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreeAttachEvent.new(vehicle, splitShapeId, x, y, z, ropeIndex), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(TreeAttachEvent.new(vehicle, splitShapeId, x, y, z, ropeIndex))
        end
    end
end
