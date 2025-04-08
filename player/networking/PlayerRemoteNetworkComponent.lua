









---The class which handles interpolating player actions for non-controlled players on other clients.
local PlayerRemoteNetworkComponent_mt = Class(PlayerRemoteNetworkComponent, PlayerNetworkComponent)


---Creates a new network component for the given player.
-- @param Player player The player whose position and state is being managed by this component.
-- @return PlayerRemoteNetworkComponent instance The created instance.
function PlayerRemoteNetworkComponent.new(player)
    local self = PlayerNetworkComponent.new(player, PlayerRemoteNetworkComponent_mt)

    -- The player.
    self.player = player

    return self
end


---Reads the data from the incoming network stream and handles the state.
-- @param integer streamId The id of the stream from which to read.
-- @param Connection connection The connection between the server and the target client.
-- @param integer timestamp The current timestamp for synchronisation purposes.
function PlayerRemoteNetworkComponent:readUpdateStream(streamId, connection, timestamp)

    PlayerRemoteNetworkComponent:superClass().readUpdateStream(self, streamId, connection, timestamp)

    local isControlled = streamReadBool(streamId)
    local skipModel = streamReadBool(streamId)
    local skipMover = streamReadBool(streamId)
    self.player:updateControlledState(isControlled, skipModel, skipMover)

    local receivedPositionX = streamReadFloat32(streamId)
    local receivedPositionY = streamReadFloat32(streamId)
    local receivedPositionZ = streamReadFloat32(streamId)
    local receivedYaw = NetworkUtil.readCompressedAngle(streamId)
    local isGrounded = streamReadBool(streamId)
    local isFirstPerson = streamReadBool(streamId)
    local isCrouching = streamReadBool(streamId)

    local isVisible = streamReadBool(streamId)
    self.player.graphicsComponent:setGraphicsRootNodeVisibility(isVisible)

    local interpolator = self.player.positionalInterpolator
    interpolator:setTargetPosition(receivedPositionX, receivedPositionY, receivedPositionZ)
    interpolator:setTargetYaw(receivedYaw)
    interpolator:startNetworkNewPhase()

    self.player.mover.isGrounded = isGrounded
    self.player.mover:setIsCrouching(isCrouching)

    self.player.isFirstPerson = isFirstPerson
end
