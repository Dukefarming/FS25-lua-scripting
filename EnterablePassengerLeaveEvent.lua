










---
local EnterablePassengerLeaveEvent_mt = Class(EnterablePassengerLeaveEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function EnterablePassengerLeaveEvent.emptyNew()
    local self = Event.new(EnterablePassengerLeaveEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @return table instance instance of event
function EnterablePassengerLeaveEvent.new(vehicle, userId)
    local self = EnterablePassengerLeaveEvent.emptyNew()
    self.vehicle = vehicle
    self.userId = userId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassengerLeaveEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassengerLeaveEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    User.streamWriteUserId(streamId, self.userId)
end


---Run action on receiving side
-- @param integer connection connection
function EnterablePassengerLeaveEvent:run(connection)
    -- If the vehicle is not yet ready, do nothing.
    if self.vehicle == nil or not self.vehicle:getIsSynchronized() then
        Logging.devInfo("EnterablePassengerLeaveEvent.run: Vehicle not found or not synchronized yet")
        return
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(EnterablePassengerLeaveEvent.new(self.vehicle, self.userId), nil, connection, self.vehicle)
    end

    local player = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
    if player ~= nil then
        player:leaveVehicle(self.vehicle, true)
    end
end


---
function EnterablePassengerLeaveEvent.sendEvent(vehicle, userId, noEventSend)
    if noEventSend ~= true then
        if g_server ~= nil then
            g_server:broadcastEvent(EnterablePassengerLeaveEvent.new(vehicle, userId), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(EnterablePassengerLeaveEvent.new(vehicle, userId))
        end
    end
end
