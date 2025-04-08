




---Event for enter request
local VehiclePlayerStyleChangedEvent_mt = Class(VehiclePlayerStyleChangedEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehiclePlayerStyleChangedEvent.emptyNew()
    local self = Event.new(VehiclePlayerStyleChangedEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param table playerStyle info
-- @return table instance instance of event
function VehiclePlayerStyleChangedEvent.new(vehicle, playerStyle)
    local self = VehiclePlayerStyleChangedEvent.emptyNew()

    self.vehicle = vehicle
    self.playerStyle = playerStyle

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehiclePlayerStyleChangedEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    self.playerStyle = PlayerStyle.new()
    self.playerStyle:readStream(streamId, connection)

    -- only do on client
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setVehicleCharacter(self.playerStyle)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehiclePlayerStyleChangedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    self.playerStyle:writeStream(streamId, connection)
end


---Run action on receiving side
-- @param integer connection connection
function VehiclePlayerStyleChangedEvent:run(connection)
end
