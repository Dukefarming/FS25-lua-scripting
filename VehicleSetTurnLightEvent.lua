




---Event for turn light state
local VehicleSetTurnLightEvent_mt = Class(VehicleSetTurnLightEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VehicleSetTurnLightEvent.emptyNew()
    local self = Event.new(VehicleSetTurnLightEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer state state
function VehicleSetTurnLightEvent.new(object, state)
    local self = VehicleSetTurnLightEvent.emptyNew()
    self.object = object
    self.state = state
    assert(state >= 0 and state <= Lights.TURNLIGHT_HAZARD)
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleSetTurnLightEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, Lights.turnLightSendNumBits)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VehicleSetTurnLightEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.state, Lights.turnLightSendNumBits)
end


---Run action on receiving side
-- @param integer connection connection
function VehicleSetTurnLightEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setTurnLightState(self.state, true, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(VehicleSetTurnLightEvent.new(self.object, self.state), nil, connection, self.object)
    end
end
