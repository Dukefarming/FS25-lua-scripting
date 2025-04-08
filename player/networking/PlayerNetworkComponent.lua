













---Creates an instance of the abstract PlayerNetworkComponent class. Only use this when deriving another class from it.
-- @param Player player The player who owns this component.
-- @param table custom_mt The required metatable used to derive this class.
-- @return PlayerNetworkComponent instance The created instance.
function PlayerNetworkComponent.new(player, custom_mt)

    -- Create the instance with the given metatable.
    local self = setmetatable({}, custom_mt)

    -- The player who owns this component.
    self.player = player

    -- Return the created instance.
    return self
end








---Updates the player based on the network state every frame.
-- @param float dt delta time in ms
function PlayerNetworkComponent:update(dt)
end


---Runs every tick and handles preparing the state.
-- @param float dt Delta time in ms.
function PlayerNetworkComponent:updateTick(dt)
end


---Writes the state into the outgoing network stream.
-- @param integer streamId The id of the stream into which to write.
-- @param Connection connection The connection between the server and the target client.
-- @param integer dirtyMask The current dirty mask.
function PlayerNetworkComponent:writeUpdateStream(streamId, connection, dirtyMask)

end


---Reads the data from the incoming network stream and handles the state.
-- @param integer streamId The id of the stream from which to read.
-- @param Connection connection The connection between the server and the target client.
-- @param integer timestamp The current timestamp for synchronisation purposes.
function PlayerNetworkComponent:readUpdateStream(streamId, connection, timestamp)

end


---Displays the debug information.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
-- @return float y The y position on the screen after the entire debug info was drawn.
function PlayerNetworkComponent:debugDraw(x, y, textSize)
    return y
end
