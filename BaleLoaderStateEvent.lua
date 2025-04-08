




---Event for bale loader state
local BaleLoaderStateEvent_mt = Class(BaleLoaderStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BaleLoaderStateEvent.emptyNew()
    local self = Event.new(BaleLoaderStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer stateId stateId
-- @param integer? nearestBaleServerId nearestBaleServerId, required for state BaleLoader.CHANGE_GRAB_BALE
-- @return BaleLoaderStateEvent self
function BaleLoaderStateEvent.new(object, stateId, nearestBaleServerId)
    local self = BaleLoaderStateEvent.emptyNew()
    self.object = object
    self.stateId = stateId
    assert(nearestBaleServerId ~= nil or self.stateId ~= BaleLoader.CHANGE_GRAB_BALE)
    self.nearestBaleServerId = nearestBaleServerId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleLoaderStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)

    self.stateId = streamReadInt8(streamId)
    if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
        self.nearestBaleServerId = NetworkUtil.readNodeObjectId(streamId)
    end
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BaleLoaderStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteInt8(streamId, self.stateId)
    if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
        NetworkUtil.writeNodeObjectId(streamId, self.nearestBaleServerId)
    end
end


---Run action on receiving side
-- @param integer connection connection
function BaleLoaderStateEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:doStateChange(self.stateId, self.nearestBaleServerId)
    end
end
