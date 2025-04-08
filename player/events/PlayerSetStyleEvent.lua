

---
local PlayerSetStyleEvent_mt = Class(PlayerSetStyleEvent, Event)




---Create an empty instance
-- @return table instance Instance of object
function PlayerSetStyleEvent.emptyNew()
    local self = Event.new(PlayerSetStyleEvent_mt)
    return self
end


---Create an instance
function PlayerSetStyleEvent.new(player, style, playerObjectId)
    local self = PlayerSetStyleEvent.emptyNew()

    self.player = player
    self.style = style
    self.playerObjectId = playerObjectId

    return self
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetStyleEvent:writeStream(streamId, connection)
    --#debug Assert.isNotNil(self.player, "Player could not be written to the stream!")

    if self.playerObjectId ~= nil then
        NetworkUtil.writeNodeObjectId(streamId, self.playerObjectId)
    else
        NetworkUtil.writeNodeObject(streamId, self.player)
    end

    self.style:writeStream(streamId, connection)
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetStyleEvent:readStream(streamId, connection)

    -- Read the player's id, then get the player object from it.
   self.playerObjectId = NetworkUtil.readNodeObjectId(streamId)
   self.player = NetworkUtil.getObject(self.playerObjectId)

    --#debug Assert.isNotNil(self.player, "Player with object id %q could not be read from the stream!", self.playerObjectId)

    self.style = PlayerStyle.new()
    self.style:readStream(streamId, connection)

    self:run(connection)
end


---Run event
-- @param table connection connection information
function PlayerSetStyleEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.player)
    end

    -- Set the player's style.
    self.player:setStyleAsync(self.style, false, nil, true)
end


---Create an instance
-- @param Player player player instance.
-- @param PlayerStyle The player's style.
-- @param integer? playerObjectId The object id to use for the player. If this is nil, the player will be used to get the id.
-- @param boolean? noEventSend if false will send the event
function PlayerSetStyleEvent.sendEvent(player, style, playerObjectId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlayerSetStyleEvent.new(player, style, playerObjectId), nil, nil, player)
        else
            g_client:getServerConnection():sendEvent(PlayerSetStyleEvent.new(player, style, playerObjectId))
        end
    end
end
