




---Event for repairing
local WearableRepaintEvent_mt = Class(WearableRepaintEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WearableRepaintEvent.emptyNew()
    return Event.new(WearableRepaintEvent_mt)
end


---Create new instance of event
-- @param table vehicle vehicle
function WearableRepaintEvent.new(vehicle)
    local self = WearableRepaintEvent.emptyNew()
    self.vehicle = vehicle
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WearableRepaintEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WearableRepaintEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end


---Run action on receiving side
-- @param integer connection connection
function WearableRepaintEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        if self.vehicle.repaintVehicle ~= nil then
            self.vehicle:repaintVehicle()

            if not connection:getIsServer() then
                g_server:broadcastEvent(self) -- broadcast for UI updates
            end

            g_messageCenter:publish(MessageType.VEHICLE_REPAINTED, self.vehicle)
        end
    end
end
