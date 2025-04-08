



---
local PlayerSetFarmEvent_mt = Class(PlayerSetFarmEvent, Event)




---Create an empty instance
-- @return table instance Instance of object
function PlayerSetFarmEvent.emptyNew()
    local self = Event.new(PlayerSetFarmEvent_mt)
    return self
end


---Create an instance
-- @param table player player instance
-- @param integer toolId tool identification
-- @return table instance Instance of object
function PlayerSetFarmEvent.new(player, farmId, password)
    local self = PlayerSetFarmEvent.emptyNew()

    self.player = player
    self.farmId = farmId
    self.password = password

    return self
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetFarmEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.player)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

    if self.password ~= nil then
        streamWriteBool(streamId, true)
        streamWriteString(streamId, self.password)
    else
        streamWriteBool(streamId, false)
    end
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetFarmEvent:readStream(streamId, connection)
    self.player = NetworkUtil.readNodeObject(streamId)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

    if streamReadBool(streamId) then
        self.password = streamReadString(streamId)
    end

    self:run(connection)
end


---Run event
-- @param table connection connection information
function PlayerSetFarmEvent:run(connection)
    if not connection:getIsServer() then --server side
        local oldFarmId = self.player.farmId
        local oldFarm = g_farmManager:getFarmById(oldFarmId)

        local farm = g_farmManager:getFarmById(self.farmId)

        if farm ~= nil then
            local user = g_currentMission.userManager:getUserByUserId(self.player.userId)

            -- admins can always join any farm, otherwise the password must be empty or correctly given
            if user:getIsMasterUser() or farm.password == nil or farm.password == self.password then
                oldFarm:removeUser(user:getId())
                self.player:setFarmId(self.farmId)
                farm:addUser(user:getId(), user:getUniqueUserId(), user:getIsMasterUser())

--                 self.player:onFarmChange()  -- TODO: function does not exist anymore in player, was it needed?

                if self.player.playerHotspot ~= nil then
                    self.player.playerHotspot:setOwnerFarmId(self.farmId)
                end

                -- publish message about farm change
                g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, self.player)

                -- Force an update of the finance history
                user:setFinancesVersionCounter(0)

                -- Finish handshake, lets the client record the password for the farm
                connection:sendEvent(PlayerSetFarmAnswerEvent.new(PlayerSetFarmAnswerEvent.STATE.OK, self.farmId, self.password))

                -- Tell all players that a player has switched
                g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(oldFarmId, self.farmId, user:getId()))
            else
                -- let the client know that the correct password is required
                connection:sendEvent(PlayerSetFarmAnswerEvent.new(PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED, self.farmId))
            end
        end
    else -- client side
        self.player.farmId = self.farmId
--         self.player:onFarmChange()  -- TODO: function does not exist anymore in player, was it needed?

        if self.player.playerHotspot ~= nil then
            self.player.playerHotspot:setOwnerFarmId(self.farmId)
        end

        g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, self.player)
    end
end


---Create an instance
-- @param table player player instance
-- @param integer farmId farm identification
-- @param boolean? noEventSend if false will send the event
function PlayerSetFarmEvent.sendEvent(player, farmId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlayerSetFarmEvent.new(player, farmId), nil, nil, player)
        else
            g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(player, farmId))
        end
    end
end
