

---
local PlayerRequestStyleEvent_mt = Class(PlayerRequestStyleEvent, Event)




---Create an empty instance
-- @return table instance Instance of object
function PlayerRequestStyleEvent.emptyNew()
    local self = Event.new(PlayerRequestStyleEvent_mt)
    return self
end


---Create an instance
function PlayerRequestStyleEvent.new(playerObjectId)
    local self = PlayerRequestStyleEvent.emptyNew()

    self.playerObjectId = playerObjectId

    return self
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerRequestStyleEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObjectId(streamId, self.playerObjectId)
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerRequestStyleEvent:readStream(streamId, connection)
    self.playerObjectId = NetworkUtil.readNodeObjectId(streamId)
    self.player = NetworkUtil.getObject(self.playerObjectId)

    self:run(connection)
end


---Run event
-- @param table connection connection information
function PlayerRequestStyleEvent:run(connection)
    if not connection:getIsServer() then --server side
        if self.player ~= nil then
            local style = self.player.graphicsComponent:getStyle()
            connection:sendEvent(PlayerSetStyleEvent.new(self.player, style))
        else
            Logging.info("PlayerRequestStyleEvent - Player not found or already left the game")
        end
    end
end
