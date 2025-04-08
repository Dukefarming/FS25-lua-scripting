









---
local RollercoasterPassengerEnterResponseEvent_mt = Class(RollercoasterPassengerEnterResponseEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function RollercoasterPassengerEnterResponseEvent.emptyNew()
    local self = Event.new(RollercoasterPassengerEnterResponseEvent_mt)
    return self
end


---Create new instance of event
-- @param table rollercoaster rollercoaster object
-- @param integer userId user id
-- @param integer seatIndex index of the seat to be entered
-- @return table instance instance of event
function RollercoasterPassengerEnterResponseEvent.new(rollercoaster, userId, seatIndex)
    local self = RollercoasterPassengerEnterResponseEvent.emptyNew()

    self.rollercoaster = rollercoaster
    self.userId = userId
    self.seatIndex = seatIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RollercoasterPassengerEnterResponseEvent:readStream(streamId, connection)
    self.rollercoaster = NetworkUtil.readNodeObject(streamId)
    self.userId = User.streamReadUserId(streamId)
    self.seatIndex = streamReadUIntN(streamId, PlaceableRollercoaster.SEAT_INDEX_NUM_BITS) + 1

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RollercoasterPassengerEnterResponseEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.rollercoaster)
    User.streamWriteUserId(streamId, self.userId)
    streamWriteUIntN(streamId, self.seatIndex - 1, PlaceableRollercoaster.SEAT_INDEX_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function RollercoasterPassengerEnterResponseEvent:run(connection)
    if self.rollercoaster ~= nil and self.rollercoaster:getIsSynchronized() then
        local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByUserId(self.userId)
        local player
        for _, missionPlayer in pairs(g_currentMission.playerSystem.players) do
            if missionPlayer.uniqueUserId == uniqueUserId then
                player = missionPlayer
                break
            end
        end

        player:onEnterRollercoaster(self.rollercoaster, self.seatIndex)
    end
end
