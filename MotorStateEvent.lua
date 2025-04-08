








---
local MotorStateEvent_mt = Class(MotorStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function MotorStateEvent.emptyNew()
    local self = Event.new(MotorStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer motorState the motor state
function MotorStateEvent.new(vehicle, motorState)
    local self = MotorStateEvent.emptyNew()
    self.vehicle = vehicle
    self.motorState = motorState

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.motorState = MotorState.readStream(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    MotorState.writeStream(streamId, self.motorState)
end


---Run action on receiving side
-- @param integer connection connection
function MotorStateEvent:run(connection)
    local vehicle = self.vehicle
    if vehicle ~= nil and vehicle:getIsSynchronized() then
        vehicle:setMotorState(self.motorState, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(MotorStateEvent.new(self.vehicle, self.motorState), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer motorState the motor state
-- @param boolean noEventSend no event send
function MotorStateEvent.sendEvent(vehicle, motorState, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(MotorStateEvent.new(vehicle, motorState), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(MotorStateEvent.new(vehicle, motorState))
        end
    end
end
