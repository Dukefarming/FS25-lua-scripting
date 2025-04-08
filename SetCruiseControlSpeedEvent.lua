




---Event for cruise control speed
local SetCruiseControlSpeedEvent_mt = Class(SetCruiseControlSpeedEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetCruiseControlSpeedEvent.emptyNew()
    local self = Event.new(SetCruiseControlSpeedEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param float speed speed
-- @param float speedReverse speedReverse
function SetCruiseControlSpeedEvent.new(vehicle, speed, speedReverse)
    local self = SetCruiseControlSpeedEvent.emptyNew()
    self.speed = speed
    self.speedReverse = speedReverse
    self.vehicle = vehicle
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCruiseControlSpeedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.speed = streamReadUInt8(streamId)
    self.speedReverse = streamReadUInt8(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetCruiseControlSpeedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUInt8(streamId, self.speed)
    streamWriteUInt8(streamId, self.speedReverse)
end


---Run action on receiving side
-- @param integer connection connection
function SetCruiseControlSpeedEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setCruiseControlMaxSpeed(self.speed, self.speedReverse)
    end
end
