











---
local TreeAttachRequestEvent_mt = Class(TreeAttachRequestEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TreeAttachRequestEvent.emptyNew()
    local self = Event.new(TreeAttachRequestEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function TreeAttachRequestEvent.new(object, splitShapeId, x, y, z, ropeIndex, setupRope)
    local self = TreeAttachRequestEvent.emptyNew()
    self.object = object
    self.splitShapeId = splitShapeId
    self.x = x
    self.y = y
    self.z = z
    self.ropeIndex = ropeIndex
    self.setupRope = setupRope

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeAttachRequestEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.splitShapeId = readSplitShapeIdFromStream(streamId)
    self.x = streamReadFloat32(streamId)
    self.y = streamReadFloat32(streamId)
    self.z = streamReadFloat32(streamId)

    if streamReadBool(streamId) then
        self.ropeIndex = streamReadUIntN(streamId, 3)
    end

    if streamReadBool(streamId) then
        self.setupRopeData = ForestryPhysicsRope.readStream(streamId, true)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeAttachRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    writeSplitShapeIdToStream(streamId, self.splitShapeId)
    streamWriteFloat32(streamId, self.x)
    streamWriteFloat32(streamId, self.y)
    streamWriteFloat32(streamId, self.z)

    if streamWriteBool(streamId, self.ropeIndex ~= nil) then
        streamWriteUIntN(streamId, self.ropeIndex, 3)
    end

    if streamWriteBool(streamId, self.setupRope ~= nil) then
        self.setupRope:writeStream(streamId)
    end
end


---Run action on receiving side
-- @param integer connection connection
function TreeAttachRequestEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.object.getIsCarriageTreeAttachAllowed ~= nil then
            local isAllowed, reason = self.object:getIsCarriageTreeAttachAllowed(self.splitShapeId)
            if isAllowed then
                self.object:attachTreeToCarriage(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex)
            else
                g_server:broadcastEvent(TreeAttachResponseEvent.new(self.object, reason, self.ropeIndex), nil, nil, self.object, nil, {connection})
            end
        elseif self.object.getIsWinchTreeAttachAllowed ~= nil then
            local isAllowed, reason = self.object:getIsWinchTreeAttachAllowed(self.ropeIndex, self.splitShapeId)
            if isAllowed then
                self.object:attachTreeToWinch(self.splitShapeId, self.x, self.y, self.z, self.ropeIndex, self.setupRopeData)
            else
                g_server:broadcastEvent(TreeAttachResponseEvent.new(self.object, reason, self.ropeIndex), nil, nil, self.object, nil, {connection})
            end
        end
    end
end
