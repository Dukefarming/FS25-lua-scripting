




---Event for bale wrapper state
local BaleWrapperStateEvent_mt = Class(BaleWrapperStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BaleWrapperStateEvent.emptyNew()
    local self = Event.new(BaleWrapperStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer stateId state id
-- @param integer? nearestBaleServerId server id of nearest bale, required for state BaleWrapper.CHANGE_GRAB_BALE
-- @return BaleWrapperStateEvent self
function BaleWrapperStateEvent.new(object, stateId, nearestBaleServerId)
    local self = BaleWrapperStateEvent.emptyNew()
    self.object = object
    self.stateId = stateId
    assert(nearestBaleServerId ~= nil or self.stateId ~= BaleWrapper.CHANGE_GRAB_BALE)
    self.nearestBaleServerId = nearestBaleServerId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapperStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.stateId = streamReadInt8(streamId)
    if self.stateId == BaleWrapper.CHANGE_GRAB_BALE then
        self.nearestBaleServerId = NetworkUtil.readNodeObjectId(streamId)
    end
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleWrapperStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteInt8(streamId, self.stateId)
    if self.stateId == BaleWrapper.CHANGE_GRAB_BALE then
        NetworkUtil.writeNodeObjectId(streamId, self.nearestBaleServerId)
    end
end


---Run action on receiving side
-- @param integer connection connection
function BaleWrapperStateEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:doStateChange(self.stateId, self.nearestBaleServerId)
    end
end
