




---Event for locomotive state
local LocomotiveStateEvent_mt = Class(LocomotiveStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function LocomotiveStateEvent.emptyNew()
    local self = Event.new(LocomotiveStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean state state
function LocomotiveStateEvent.new(object, state)
    local self = LocomotiveStateEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function LocomotiveStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, Locomotive.NUM_BITS_STATE)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function LocomotiveStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.state, Locomotive.NUM_BITS_STATE)
end


---Run action on receiving side
-- @param integer connection connection
function LocomotiveStateEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setLocomotiveState(self.state, true)
    end
end
