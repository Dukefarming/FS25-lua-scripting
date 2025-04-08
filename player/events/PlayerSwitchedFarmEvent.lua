



---
local PlayerSwitchedFarmEvent_mt = Class(PlayerSwitchedFarmEvent, Event)






---Create an empty instance
-- @return table instance Instance of object
function PlayerSwitchedFarmEvent.emptyNew()
    local self = Event.new(PlayerSwitchedFarmEvent_mt)
    return self
end












---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSwitchedFarmEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.oldFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSwitchedFarmEvent:readStream(streamId, connection)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.oldFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.userId = User.streamReadUserId(streamId)

    self:run(connection)
end


---Run event
-- @param table connection connection information
function PlayerSwitchedFarmEvent:run(connection)
    if connection:getIsServer() then -- on client
        if self.oldFarmId ~= FarmManager.INVALID_FARM_ID then
            local oldFarm = g_farmManager:getFarmById(self.oldFarmId)
            if oldFarm ~= nil then
                oldFarm:removeUser(self.userId)
            end
        end

        if self.farmId ~= FarmManager.INVALID_FARM_ID then
            local newFarm = g_farmManager:getFarmById(self.farmId)
            if newFarm ~= nil then
                newFarm:addUser(self.userId)
            end
        end

        local player = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
        g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, player)
    else -- on server, notify all clients (incl. self) of player farm switch
        g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(self.oldFarmId, self.farmId, self.userId), true)
    end
end
