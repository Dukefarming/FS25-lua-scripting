




---Event for light state
local VehicleSetLightEvent_mt = Class(VehicleSetLightEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleSetLightEvent.emptyNew()
    local self = Event.new(VehicleSetLightEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer lightsTypesMask light types mask
function VehicleSetLightEvent.new(object, lightsTypesMask, numBits)
    local self = VehicleSetLightEvent.emptyNew()
    self.object = object
    self.lightsTypesMask = lightsTypesMask
    self.numBits = numBits
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleSetLightEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.numBits = streamReadUIntN(streamId, 5)
    self.lightsTypesMask = streamReadUIntN(streamId, self.numBits)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleSetLightEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.numBits, 5)
    streamWriteUIntN(streamId, self.lightsTypesMask, self.numBits)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleSetLightEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setLightsTypesMask(self.lightsTypesMask, true, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(VehicleSetLightEvent.new(self.object, self.lightsTypesMask, self.numBits), nil, connection, self.object)
    end
end
