



---
local PlaceableFenceAddGateEvent_mt = Class(PlaceableFenceAddGateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableFenceAddGateEvent.emptyNew()
    return Event.new(PlaceableFenceAddGateEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param integer groupIndex index of group
-- @param boolean isActive is active
function PlaceableFenceAddGateEvent.new(fence, segmentIndex, animatedObject)
    local self = PlaceableFenceAddGateEvent.emptyNew()

    self.fence = fence
    self.segmentIndex = segmentIndex
    self.animatedObject = animatedObject

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableFenceAddGateEvent:readStream(streamId, connection)
    self.fence = NetworkUtil.readNodeObject(streamId)
    self.segmentIndex = streamReadInt32(streamId)

    self.animatedObject = self.fence:getSegment(self.segmentIndex).animatedObject

    local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
    self.animatedObject:readStream(streamId, connection)
    g_client:finishRegisterObject(self.animatedObject, animatedObjectId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableFenceAddGateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.fence)
    streamWriteInt32(streamId, self.segmentIndex)

    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.animatedObject))
    self.animatedObject:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, self.animatedObject)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableFenceAddGateEvent:run(connection)
end
