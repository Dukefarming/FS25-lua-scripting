

















---
local TreeAttachResponseEvent_mt = Class(TreeAttachResponseEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TreeAttachResponseEvent.emptyNew()
    local self = Event.new(TreeAttachResponseEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function TreeAttachResponseEvent.new(object, failedReason, ropeIndex)
    local self = TreeAttachResponseEvent.emptyNew()
    self.object = object
    self.failedReason = failedReason
    self.ropeIndex = ropeIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeAttachResponseEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.failedReason = streamReadUIntN(streamId, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_NUM_BITS)

    if streamReadBool(streamId) then
        self.ropeIndex = streamReadUIntN(streamId, 3)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreeAttachResponseEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.failedReason, TreeAttachResponseEvent.TREE_ATTACH_FAIL_REASON_NUM_BITS)

    if streamWriteBool(streamId, self.ropeIndex ~= nil) then
        streamWriteUIntN(streamId, self.ropeIndex, 3)
    end
end


---Run action on receiving side
-- @param integer connection connection
function TreeAttachResponseEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.object.showCarriageTreeMountFailedWarning ~= nil then
            self.object:showCarriageTreeMountFailedWarning(self.ropeIndex, self.failedReason)
        elseif self.object.showWinchTreeMountFailedWarning ~= nil then
            self.object:showWinchTreeMountFailedWarning(self.ropeIndex, self.failedReason)
        end
    end
end
