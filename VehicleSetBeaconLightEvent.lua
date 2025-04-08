




---Event for beacon light state
local VehicleSetBeaconLightEvent_mt = Class(VehicleSetBeaconLightEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleSetBeaconLightEvent.emptyNew()
    local self = Event.new(VehicleSetBeaconLightEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean active active
function VehicleSetBeaconLightEvent.new(object, active)
    local self = VehicleSetBeaconLightEvent.emptyNew()
    self.active = active
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleSetBeaconLightEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.active = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleSetBeaconLightEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.active)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleSetBeaconLightEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBeaconLightsVisibility(self.active, true, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(VehicleSetBeaconLightEvent.new(self.object, self.active), nil, connection, self.object)
    end
end
