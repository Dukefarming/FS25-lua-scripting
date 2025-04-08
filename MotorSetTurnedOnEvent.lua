








---
local MotorSetTurnedOnEvent_mt = Class(MotorSetTurnedOnEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function MotorSetTurnedOnEvent.emptyNew()
    local self = Event.new(MotorSetTurnedOnEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean turnedOn is turned on
function MotorSetTurnedOnEvent.new(vehicle, turnedOn)
    local self = MotorSetTurnedOnEvent.emptyNew()
    self.vehicle = vehicle
    self.turnedOn = turnedOn
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorSetTurnedOnEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.turnedOn = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorSetTurnedOnEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.turnedOn)
end


---Run action on receiving side
-- @param integer connection connection
function MotorSetTurnedOnEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        if self.turnedOn then
            self.vehicle:startMotor(true)
        else
            self.vehicle:stopMotor(true)
        end
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(MotorSetTurnedOnEvent.new(self.vehicle, self.turnedOn), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean turnedOn if the motor should be turned on
-- @param boolean noEventSend no event send
function MotorSetTurnedOnEvent.sendEvent(vehicle, turnedOn, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(MotorSetTurnedOnEvent.new(vehicle, turnedOn), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(MotorSetTurnedOnEvent.new(vehicle, turnedOn))
        end
    end
end
