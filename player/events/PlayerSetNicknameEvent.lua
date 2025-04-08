

---
local PlayerSetNicknameEvent_mt = Class(PlayerSetNicknameEvent, Event)




---Create an empty instance
-- @return table instance Instance of object
function PlayerSetNicknameEvent.emptyNew()
    local self = Event.new(PlayerSetNicknameEvent_mt)
    return self
end


---Create an instance
function PlayerSetNicknameEvent.new(player, nickname, userId)
    local self = PlayerSetNicknameEvent.emptyNew()

    self.player = player
    self.nickname = nickname
    self.userId = userId

    return self
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetNicknameEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.player)
    streamWriteString(streamId, self.nickname)
    User.streamWriteUserId(streamId, self.userId)
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetNicknameEvent:readStream(streamId, connection)
    self.player = NetworkUtil.readNodeObject(streamId)
    self.nickname = streamReadString(streamId)
    self.userId = User.streamReadUserId(streamId)

    self:run(connection)
end


---Run event
-- @param table connection connection information
function PlayerSetNicknameEvent:run(connection)
    if not connection:getIsServer() then --server side
        g_currentMission:setPlayerNickname(self.player, self.nickname, self.userId)
    else -- client side
        g_currentMission:setPlayerNickname(self.player, self.nickname, self.userId, true)
    end
end
