

---
local HandsThrowObjectEvent_mt = Class(HandsThrowObjectEvent, Event)






---Create an empty instance
-- @return table instance Instance of object
function HandsThrowObjectEvent.emptyNew()
    local self = Event.new(HandsThrowObjectEvent_mt)
    return self
end



















---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function HandsThrowObjectEvent:readStream(streamId, connection)

    -- Read the hands.
    self.hands = NetworkUtil.readNodeObject(streamId)

    self.dirX = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
    self.dirY = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)
    self.dirZ = NetworkUtil.readCompressedRange(streamId, -1, 1, 12)

    self.forceScalar = NetworkUtil.readCompressedRange(streamId, 0, 1, HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS)

    self:run(connection)
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function HandsThrowObjectEvent:writeStream(streamId, connection)

    -- Write the hands.
    NetworkUtil.writeNodeObject(streamId, self.hands)

    -- Write the throw direction.
    NetworkUtil.writeCompressedRange(streamId, self.dirX, -1, 1, 12)
    NetworkUtil.writeCompressedRange(streamId, self.dirY, -1, 1, 12)
    NetworkUtil.writeCompressedRange(streamId, self.dirZ, -1, 1, 12)

    NetworkUtil.writeCompressedRange(streamId, self.forceScalar, 0, 1, HandsThrowObjectEvent.THROW_FORCE_SCALAR_NUM_BITS)
end


---Run event
-- @param table connection connection information
function HandsThrowObjectEvent:run(connection)
    if self.hands ~= nil then
        if not connection:getIsServer() then
            g_server:broadcastEvent(self, false, connection, self.player)
        end

        if self.dirX == 0 and self.dirY == 0 and self.dirZ == 0 then
            self.hands:dropHeldItem(true)
        else
            self.hands:throwHeldItemWithForceVector(self.dirX, self.dirY, self.dirZ, self.forceScalar, true)
        end
    end
end
