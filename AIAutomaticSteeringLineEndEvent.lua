




---Event when hitting the end of the line (server to client)
local AIAutomaticSteeringLineEndEvent_mt = Class(AIAutomaticSteeringLineEndEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIAutomaticSteeringLineEndEvent.emptyNew()
    local self = Event.new(AIAutomaticSteeringLineEndEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer currentAngle current angle
function AIAutomaticSteeringLineEndEvent.new(vehicle, state, segmentIndex, segmentIsLeft)
    local self = AIAutomaticSteeringLineEndEvent.emptyNew()
    self.vehicle = vehicle

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringLineEndEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringLineEndEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end


---Run action on receiving side
-- @param integer connection connection
function AIAutomaticSteeringLineEndEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        SpecializationUtil.raiseEvent(self.vehicle, "onAIAutomaticSteeringLineEnd")
    end
end
