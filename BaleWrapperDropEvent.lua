




---Event for bale wrapper drop
local BaleWrapperDropEvent_mt = Class(BaleWrapperDropEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BaleWrapperDropEvent.emptyNew()
    local self = Event.new(BaleWrapperDropEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer dropAnimationIndex state id
-- @return BaleWrapperDropEvent self
function BaleWrapperDropEvent.new(object, dropAnimationIndex)
    local self = BaleWrapperDropEvent.emptyNew()
    self.object = object
    self.dropAnimationIndex = dropAnimationIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapperDropEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.dropAnimationIndex = streamReadUIntN(streamId, 4)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapperDropEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.dropAnimationIndex, 4)
end


---Run action on receiving side
-- @param integer connection connection
function BaleWrapperDropEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, nil, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBaleWrapperDropAnimation(self.dropAnimationIndex)
        self.object:doStateChange(BaleWrapper.CHANGE_WRAPPER_START_DROP_BALE, nil)
    end
end
