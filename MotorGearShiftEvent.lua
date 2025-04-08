


















---
local MotorGearShiftEvent_mt = Class(MotorGearShiftEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function MotorGearShiftEvent.emptyNew()
    local self = Event.new(MotorGearShiftEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean turnedOn is turned on
function MotorGearShiftEvent.new(vehicle, shiftType, shiftValue)
    local self = MotorGearShiftEvent.emptyNew()
    self.vehicle = vehicle
    self.shiftType = shiftType
    self.shiftValue = shiftValue
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorGearShiftEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.shiftType = streamReadUIntN(streamId, 4)

    if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
        self.shiftValue = streamReadUIntN(streamId, 3)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MotorGearShiftEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.shiftType, 4)

    if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
        streamWriteUIntN(streamId, self.shiftValue, 3)
    end
end


---Run action on receiving side
-- @param integer connection connection
function MotorGearShiftEvent:run(connection)
    local vehicle = self.vehicle
    if vehicle ~= nil and vehicle:getIsSynchronized() then
        local spec = vehicle.spec_motorized
        if spec ~= nil then
            local motorState = vehicle:getMotorState()
            if motorState == MotorState.STARTING or motorState == MotorState.ON then
                if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_UP then
                    spec.motor:shiftGear(true)
                elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_DOWN then
                    spec.motor:shiftGear(false)
                elseif self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR then
                    spec.motor:selectGear(self.shiftValue, self.shiftValue ~= 0)
                elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP then
                    spec.motor:shiftGroup(true)
                elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN then
                    spec.motor:shiftGroup(false)
                elseif self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
                    spec.motor:selectGroup(self.shiftValue, self.shiftValue ~= 0)
                elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE then
                    spec.motor:changeDirection()
                elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS then
                    spec.motor:changeDirection(1)
                elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG then
                    spec.motor:changeDirection(-1)
                end
            end
        end
    end
end


---Send shifting event to server
-- @param table vehicle vehicle
-- @param integer shiftType type of shifting event
-- @param integer? shiftValue additional value for shifting event, required for types TYPE_SELECT_GEAR and TYPE_SELECT_GROUP
function MotorGearShiftEvent.sendToServer(vehicle, shiftType, shiftValue)
    if g_client ~= nil then
        g_client:getServerConnection():sendEvent(MotorGearShiftEvent.new(vehicle, shiftType, shiftValue))
    end
end
