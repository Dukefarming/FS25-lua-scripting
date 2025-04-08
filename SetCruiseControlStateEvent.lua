




---Event for cruise control state event
local SetCruiseControlStateEvent_mt = Class(SetCruiseControlStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetCruiseControlStateEvent.emptyNew()
    local self = Event.new(SetCruiseControlStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer state state
function SetCruiseControlStateEvent.new(vehicle, state)
    local self = SetCruiseControlStateEvent.emptyNew()
    self.state = state
    self.vehicle = vehicle
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCruiseControlStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, 2)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCruiseControlStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.state, 2)
end


---Run action on receiving side
-- @param integer connection connection
function SetCruiseControlStateEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setCruiseControlState(self.state, true)
    end
end
