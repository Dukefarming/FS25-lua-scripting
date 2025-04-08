




---Event for animation stop
local AnimatedVehicleStopEvent_mt = Class(AnimatedVehicleStopEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AnimatedVehicleStopEvent.emptyNew()
    local self = Event.new(AnimatedVehicleStopEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param string name name
function AnimatedVehicleStopEvent.new(object, name)
    local self = AnimatedVehicleStopEvent.emptyNew()
    self.name = name
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AnimatedVehicleStopEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.name = streamReadString(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AnimatedVehicleStopEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteString(streamId, self.name)
end


---Run action on receiving side
-- @param integer connection connection
function AnimatedVehicleStopEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:stopAnimation(self.name, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(AnimatedVehicleStopEvent.new(self.object, self.name), nil, connection, self.object)
    end
end
