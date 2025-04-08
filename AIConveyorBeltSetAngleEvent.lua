




---Event for conveyor belt angle
local AIConveyorBeltSetAngleEvent_mt = Class(AIConveyorBeltSetAngleEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIConveyorBeltSetAngleEvent.emptyNew()
    local self = Event.new(AIConveyorBeltSetAngleEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer currentAngle current angle
function AIConveyorBeltSetAngleEvent.new(vehicle, currentAngle)
    local self = AIConveyorBeltSetAngleEvent.emptyNew()
    self.currentAngle = currentAngle
    self.vehicle = vehicle
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIConveyorBeltSetAngleEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.currentAngle = streamReadInt8(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIConveyorBeltSetAngleEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteInt8(streamId, self.currentAngle)
end


---Run action on receiving side
-- @param integer connection connection
function AIConveyorBeltSetAngleEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setAIConveyorBeltAngle(self.currentAngle, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(AIConveyorBeltSetAngleEvent.new(self.vehicle, self.currentAngle), nil, connection, self.vehicle)
    end
end
