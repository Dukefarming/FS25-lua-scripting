




---Event for horse jumping
local JumpEvent_mt = Class(JumpEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function JumpEvent.emptyNew()
    local self = Event.new(JumpEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isPlaying honk is playing
function JumpEvent.new(object)
    local self = JumpEvent.emptyNew()
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function JumpEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.object = NetworkUtil.readNodeObject(streamId)
        self:run(connection)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function JumpEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.object)
    end
end


---Run action on receiving side
-- @param integer connection connection
function JumpEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:jump(true)
    end
end
