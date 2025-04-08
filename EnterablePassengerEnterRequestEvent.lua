










---
local EnterablePassengerEnterRequestEvent_mt = Class(EnterablePassengerEnterRequestEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function EnterablePassengerEnterRequestEvent.emptyNew()
    local self = Event.new(EnterablePassengerEnterRequestEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function EnterablePassengerEnterRequestEvent.new(object, seatIndex)
    local self = EnterablePassengerEnterRequestEvent.emptyNew()
    self.object = object
    self.objectId = NetworkUtil.getObjectId(self.object)
    self.seatIndex = seatIndex
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassengerEnterRequestEvent:readStream(streamId, connection)
    self.objectId = NetworkUtil.readNodeObjectId(streamId)
    self.seatIndex = streamReadUIntN(streamId, EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS) + 1

    self.object = NetworkUtil.getObject(self.objectId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassengerEnterRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.objectId)
    streamWriteUIntN(streamId, math.clamp(self.seatIndex - 1, 0, 2 ^ EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS - 1), EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function EnterablePassengerEnterRequestEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.object:getIsPassengerSeatIndexAvailable(self.seatIndex) then
            local userId = g_currentMission.userManager:getUserIdByConnection(connection)
            g_server:broadcastEvent(EnterablePassengerEnterResponseEvent.new(self.objectId, false, self.seatIndex, userId), true, connection)
            connection:sendEvent(EnterablePassengerEnterResponseEvent.new(self.objectId, true, self.seatIndex, userId))
        end
    end
end
