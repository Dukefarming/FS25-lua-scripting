










---
local EnterablePassengerEnterResponseEvent_mt = Class(EnterablePassengerEnterResponseEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function EnterablePassengerEnterResponseEvent.emptyNew()
    local self = Event.new(EnterablePassengerEnterResponseEvent_mt)
    return self
end


---Create new instance of event
-- @param table id id
-- @param boolean isOwner is owner
-- @param table playerStyle
-- @return table instance instance of event
function EnterablePassengerEnterResponseEvent.new(id, isOwner, seatIndex, userId)
    local self = EnterablePassengerEnterResponseEvent.emptyNew()

    self.id = id
    self.isOwner = isOwner
    self.seatIndex = seatIndex
    self.userId = userId

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassengerEnterResponseEvent:readStream(streamId, connection)
    self.id = NetworkUtil.readNodeObjectId(streamId)
    self.isOwner = streamReadBool(streamId)

    self.seatIndex = streamReadUIntN(streamId, EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS) + 1
    self.userId = User.streamReadUserId(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function EnterablePassengerEnterResponseEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.id)
    streamWriteBool(streamId, self.isOwner)

    streamWriteUIntN(streamId, math.clamp(self.seatIndex - 1, 0, 2 ^ EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS - 1), EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)
end


---Run action on receiving side
-- @param integer connection connection
function EnterablePassengerEnterResponseEvent:run(connection)
    local object = NetworkUtil.getObject(self.id)

    if object ~= nil and object:getIsSynchronized() then
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByUserId(self.userId)
        local player
        for _, missionPlayer in pairs(g_currentMission.playerSystem.players) do
            if missionPlayer.uniqueUserId == uniqueUserId then
                player = missionPlayer
                break
            end
        end

        player:onEnterVehicleAsPassenger(object, self.seatIndex)
    end
end
