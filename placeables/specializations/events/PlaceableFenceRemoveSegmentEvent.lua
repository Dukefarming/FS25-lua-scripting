



---
local PlaceableFenceRemoveSegmentEvent_mt = Class(PlaceableFenceRemoveSegmentEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableFenceRemoveSegmentEvent.emptyNew()
    return Event.new(PlaceableFenceRemoveSegmentEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param integer groupIndex index of group
-- @param boolean isActive is active
function PlaceableFenceRemoveSegmentEvent.new(fence, segmentIndex, poleIndex)
    local self = PlaceableFenceRemoveSegmentEvent.emptyNew()

    self.fence = fence
    self.segmentIndex = segmentIndex
    self.poleIndex = poleIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableFenceRemoveSegmentEvent:readStream(streamId, connection)
    self.fence = NetworkUtil.readNodeObject(streamId)
    self.segmentIndex = streamReadInt32(streamId)
    self.poleIndex = streamReadInt32(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableFenceRemoveSegmentEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.fence)
    streamWriteInt32(streamId, self.segmentIndex)
    streamWriteInt32(streamId, self.poleIndex)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableFenceRemoveSegmentEvent:run(connection)
    if self.fence ~= nil and self.fence:getIsSynchronized() then
        local spec = self.fence.spec_fence
        self.fence:doDeletePanel(spec.segments[self.segmentIndex], self.segmentIndex, self.poleIndex)

        g_messageCenter:publish(PlaceableFenceRemoveSegmentEvent, self.fence, self.segmentIndex, self.poleIndex)

        -- Server broadcasts to all clients
        if not connection:getIsServer() then
            g_server:broadcastEvent(self)
        end
    end
end
