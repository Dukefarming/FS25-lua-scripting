




---Event for repairing
local WearableRepairEvent_mt = Class(WearableRepairEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WearableRepairEvent.emptyNew()
    return Event.new(WearableRepairEvent_mt)
end


---Create new instance of event
-- @param table vehicle vehicle
function WearableRepairEvent.new(vehicle, atSellingPoint)
    local self = WearableRepairEvent.emptyNew()
    self.vehicle = vehicle
    self.atSellingPoint = atSellingPoint
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WearableRepairEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.atSellingPoint = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WearableRepairEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.atSellingPoint)
end


---Run action on receiving side
-- @param integer connection connection
function WearableRepairEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        if self.vehicle.repairVehicle ~= nil then
            self.vehicle:repairVehicle(self.atSellingPoint)

            if not connection:getIsServer() then
                g_server:broadcastEvent(self) -- broadcast for UI updates
            end

            g_messageCenter:publish(MessageType.VEHICLE_REPAIRED, self.vehicle, self.atSellingPoint)
        end
    end
end
