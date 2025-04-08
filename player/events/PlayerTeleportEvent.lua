

---
local PlayerTeleportEvent_mt = Class(PlayerTeleportEvent, Event)




---Create an empty instance
-- @return table instance Instance of object
function PlayerTeleportEvent.emptyNew()
    local self = Event.new(PlayerTeleportEvent_mt, NetworkNode.CHANNEL_MAIN)
    return self
end


---Create an instance
-- @param float x world x position
-- @param float y world y position
-- @param float z world z position
-- @param boolean isAbsolute if not true, y is a delta from the terrain
-- @param boolean isRootNode if true, y is the root node location, otherwise y is the feet location
-- @return table instance Instance of object
function PlayerTeleportEvent.new(x, y, z, isAbsolute, isRootNode)
    local self = PlayerTeleportEvent.emptyNew()
    self.x = x
    self.y = y
    self.z = z
    self.isAbsolute = isAbsolute
    self.isRootNode = isRootNode
    return self
end


---Create an instance when player exits vehicle
-- @param table exitVehicle instance of the vehicle that the player exits
-- @return table instance Instance of object
function PlayerTeleportEvent.newExitVehicle(exitVehicle)
    local self = PlayerTeleportEvent.emptyNew()
    self.exitVehicle = exitVehicle
    return self
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerTeleportEvent:readStream(streamId, connection)
    if streamReadBool(streamId) then
        self.exitVehicle = NetworkUtil.readNodeObject(streamId)
    else
        self.x = streamReadFloat32(streamId)
        self.y = streamReadFloat32(streamId)
        self.z = streamReadFloat32(streamId)
        self.isAbsolute = streamReadBool(streamId)
        self.isRootNode = streamReadBool(streamId)
    end
    self:run(connection)
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerTeleportEvent:writeStream(streamId, connection)
    if streamWriteBool(streamId, self.exitVehicle ~= nil) then
        NetworkUtil.writeNodeObject(streamId, self.exitVehicle)
    else
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
        streamWriteBool(streamId, self.isAbsolute)
        streamWriteBool(streamId, self.isRootNode)
    end
end


---Run event
-- @param table connection connection information
function PlayerTeleportEvent:run(connection)
    if connection:getIsServer() then
        return
    end

    local player = g_currentMission.connectionsToPlayer[connection]
    --#debug Player.debugLog(player, Player.DEBUG_DISPLAY_FLAG.NETWORK_MOVEMENT, "Player teleportation event to %.4f, %.4f, %.4f received", self.x, self.y, self.z)
    if player ~= nil then
        if self.exitVehicle ~= nil then
            player:teleportToExitPoint(self.exitVehicle, true)
        elseif self.x ~= nil then
            player:teleportTo(self.x, self.y, self.z, true, true)
        end
    end
end
