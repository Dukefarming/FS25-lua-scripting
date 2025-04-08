









---Converts inputs into actual player movement, calculating and storing things like velocity.
local PlayerMover_mt = Class(PlayerMover)






































---Creates a new instance of the player mover class.
-- @param Player player The player who owns this mover and is moved.
-- @return PlayerMover instance The created instance.
function PlayerMover.new(player)

    -- TODO: Set up the dirty flag for the mover.

    -- Create the instance.
    local self = setmetatable({}, PlayerMover_mt)

    -- The player.
    self.player = player

    -- If this is true, update functions will run as normal and the player will be able to move and be affected by gravity.
    self.isPhysicsEnabled = true

    -- The movement to make this frame.
    self.currentForceX = 0.0
    self.currentForceY = 0.0
    self.currentForceZ = 0.0

    -- The rotation on the Y axis in world space in which the player is currently moving.
    self.movementDirectionYaw = 0.0

    -- The node used to show the direction of movement.
    self.movementDirectionNode = nil

    -- The velocity of the player.
    self.currentSpeed = 0.0
    self.currentVelocityX = 0.0
    self.currentVelocityY = 0.0
    self.currentVelocityZ = 0.0

    self.positionDeltaX = 0.0
    self.positionDeltaY = 0.0
    self.positionDeltaZ = 0.0

    self.currentRotationVelocity = 0.0

    -- The water level under the player's feet, and the distance from the player to the water level.
    self.waterUnderfootY = 0.0
    self.currentWaterSubmergeDistance = 0.0

    -- The floor level under the player's feet, and the distance from the player to the floor level.
    self.groundUnderfootY = 0.0
    self.currentGroundDistance = 0.0

    -- Is true if the player is currently grounded (not falling or jumping); otherwise false.
    self.isGrounded = true

    -- Is true if the player is currently close to the ground; otherwise false.
    self.isCloseToGround = true

    self.isInWater = false

    -- Is true if the player is submerged in water enough to start swimming; otherwise false.
    self.isSwimming = false
    self.needSwimming = false

    self.isCrouching = false

    -- How many seconds the player has been in the air.
    self.currentAirTime = 0.0

    -- How many seconds the player has been falling.
    self.currentFallTime = 0.0

    -- How many seconds the player has been on the ground.
    self.currentGroundTime = 0.0

    self.isFlightActive = false

    -- The dirty flag.
    self.dirtyFlag = self.player:getNextDirtyFlag()

    -- The event for when the position is changed via PlayerMover.teleportXXX.
    self.onPositionTeleport = ListenerList.new()

    -- Return the created instance.
    return self
end


---Is called when the player first loads into the world, used to create and set up the movement node into the scene.
function PlayerMover:initialise()

    -- Create the node used to show the direction of movement relative to the player.
    self.movementDirectionNode = createTransformGroup("movementDirectionNode")
    link(getRootNode(), self.movementDirectionNode)
end































---Uses the given parameters to calculate a smooth speed, interpolated between various values depending on the state of the mover.
-- @param float moveScalar The value from 0 to 1 of how much the player is moving, this is usually the input. e.g. if the player is holding the movement analogue stick 50% of the way, this will be 0.5.
-- @param boolean doWading If this is true then the current water submerge distance is used, interpolating the speed between PlayerStateSwim.MAXIMUM_MOVE_SPEED and the maximumSpeed parameter.
-- @param float minimumSpeed The slowest speed of the player, this will only be used if doWading is false or the player is not submerged in water.
-- @param float maximumSpeed The fastest speed that the player can move.
-- @return float smoothSpeed The interpolated speed.
function PlayerMover:calculateSmoothSpeed(moveScalar, doWading, minimumSpeed, maximumSpeed)

    -- If water is to be taken into account, adjust the minimum speed and move scalar.
    if doWading then

        -- Adjust the minimum movement speed possible if the player is in the water, so they smoothly go from running/walking to swimming.
        if self.currentWaterSubmergeDistance > PlayerMover.SLOW_SUBMERGE_THRESHOLD then
            minimumSpeed = PlayerStateSwim.MAXIMUM_MOVE_SPEED
        end

        -- Apply the wade scalar to the movement so they become slower the more submerged they are.
        moveScalar = moveScalar * PlayerMover.calculateWadeScalar(self.currentWaterSubmergeDistance)
    end

    -- Smoothly interpolate the speed between the minimum and maximum.
    return MathUtil.lerp(minimumSpeed, maximumSpeed, moveScalar)
end


---Toggles the flight active mode on/off. Does nothing if the player's flight mode is not toggled on.
function PlayerMover:toggleFlightActive()
    self:setFlightActive(not self.isFlightActive)
end


---Sets the flight active mode to the given value. Does nothing if the player's flight mode is not toggled on.
-- @param boolean isFlightActive True if flight mode should be activated; otherwise false.
-- @param boolean? isForced If this is true, the check for the command is skipped.
function PlayerMover:setFlightActive(isFlightActive, isForced)

    -- Disallow flight if the command is not toggled on.
    if not isForced and (self.player.toggleFlightModeCommand == nil or self.player.toggleFlightModeCommand.value == false) then
        return
    end

    -- Set the flight toggle.
    self.isFlightActive = isFlightActive == true
end






























---Gets the yaw (y rotation) of the player's movement direction. This is more or less the actual yaw that the player has, and the graphical node's yaw smoothly follows it.
-- @return float currentForceYaw The movement yaw of the player.
function PlayerMover:getMovementYaw()
    return self.movementDirectionYaw
end















































---Moves the player to the given position.
-- @param float x The x position.
-- @param float y The y position.
-- @param float z The z position.
-- @param boolean? setNodeTranslation If this is true, the player's root node will also be moved to the given position. Defaults to false.
function PlayerMover:setPosition(x, y, z, setNodeTranslation)

    -- Move the player via their CCT.
    self.player.capsuleController:setPosition(x, y, z, setNodeTranslation)

    -- Raise the dirty flag, as a change has been made.
    self.player:raiseDefaultDirtyFlag()
end










---Returns the player's current horizontal speed in metres per second.
-- @return float currentSpeed The player's current speed in metres per second.
function PlayerMover:getSpeed()
    return self.currentSpeed
end




















































---Teleports the player to the given position, sending a network event.
-- @param float x The x position.
-- @param float y The y position.
-- @param float z The z position.
-- @param boolean? setNodeTranslation If this is true, the player's root node will also be moved to the given position. Defaults to false.
-- @param boolean? noEventSend If this is true, no event will be sent to the server/client.
function PlayerMover:teleportTo(x, y, z, setNodeTranslation, noEventSend)

    -- If the player is not the server and is the controlling player, then fire the teleport event so that the teleport is reflected on the server.
    if not noEventSend and not self.player.isServer and self.player.isOwner then
        g_client:getServerConnection():sendEvent(PlayerTeleportEvent.new(x, y, z, true, false))
    end

    -- Set the last position.
    self.lastPositionX, self.lastPositionY, self.lastPositionZ = self:getPosition()

    -- Call the base move function.
    self:setPosition(x, y, z, setNodeTranslation)

    self.onPositionTeleport:invoke(x, y, z)

    --#debug self.player:debugLog(Player.DEBUG_DISPLAY_FLAG.MOVEMENT, "Teleported to %.4f, %.4f, %.4f", x, y, z)
end























































---Adds the given movement to the player's movement this frame. Does not immediately change the player's position.
-- @param float currentForceX The movement to make on the x axis in world space.
-- @param float currentForceZ The movement to make on the z axis in world space.
function PlayerMover:moveHorizontally(currentForceX, currentForceZ)

    -- Add the movement to the movement this frame.
    self.currentForceX = self.currentForceX + currentForceX
    self.currentForceZ = self.currentForceZ + currentForceZ

    -- Raise the dirty flag, as a change has been made.
    self.player:raiseDefaultDirtyFlag()
end


---Adds the given movement to the player's movement this frame. Does not immediately change the player's position.
-- @param float currentForceY The movement to make on the y axis in world space.
function PlayerMover:moveVertically(currentForceY)

    -- Add the movement to the movement this frame.
    self.currentForceY = self.currentForceY + currentForceY

    -- Raise the dirty flag, as a change has been made.
    self.player:raiseDefaultDirtyFlag()
end


---Updates the distance from the player to the ground level to determine how far in the air they are.
-- @param float dt The current delta time, used to update the self.currentFallTime timer.
function PlayerMover:updateFloorDistance(dt, isGrounded, currentX, currentY, currentZ)

    -- If a grounded value was given, use it.
    if isGrounded ~= nil then
        self.isGrounded = isGrounded
    end

    -- If the bottom of the player's collider is touching the ground, set the ground distance to 0 and the ground level to the given y. This avoids raycasting.
    if self.isGrounded then
        self.currentGroundDistance = 0.0
        self.groundUnderfootY = currentY
    -- Otherwise; calculate the distance from the ground using a raycast.
    else

        -- Reset the ground level distance and fire a ray downwards.
        self.groundUnderfootY = nil
        raycastClosest(currentX, currentY + 10, currentZ, 0, -1, 0, 200, "onGroundRaycastCallback", self, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD)

        -- If the ray hit the ground, then calculate the distance.
        if self.groundUnderfootY ~= nil then
            self.currentGroundDistance = math.max(0, currentY - self.groundUnderfootY)
        -- Otherwise; treat y0 as the floor.
        else
            self.groundUnderfootY = 0.0
            self.currentGroundDistance = currentY
        end
    end

    -- The player is close to ground if they are either grounded or they're close enough to the ground.
    self.isCloseToGround = self.isGrounded or self.currentGroundDistance <= self.CLOSE_TO_GROUND_THRESHOLD

    -- Increment the fall timer. If the player is grounded or swimming then set it to 0.
    self.currentGroundTime = self.isGrounded and self.currentGroundTime + dt * 0.001 or 0
    self.currentAirTime = (self.isGrounded or self.isInWater) and 0 or self.currentAirTime + dt * 0.001
    self.currentFallTime = (self.currentAirTime == 0 or self.currentVelocityY >= 0) and 0 or self.currentFallTime + dt * 0.001
end


---Raycast callback for the ground checking ray. Simply sets self.groundUnderfootY to the y parameter if the hitObjectId exists.
-- @param float hitObjectId The id of the object hit by the ray.
-- @param float x The x position of the ray hit.
-- @param float y The y position of the ray hit.
-- @param float z The z position of the ray hit.
function PlayerMover:onGroundRaycastCallback(hitObjectId, x, y, z)
    if hitObjectId ~= 0 then
        self.groundUnderfootY = y
    end
end


---Updates the distance from the player to the water level to determine how submerged they are.
function PlayerMover:updateWaterSubmergeDistance(currentX, currentY, currentZ)

    -- Reset the water level distance and fire a ray downwards.
    self.waterUnderfootY = nil
    self.updateWaterSubmergeDistanceCurrentY = currentY
    raycastClosestAsync(currentX, currentY + 3, currentZ, 0, -1, 0, 6, "onWaterRaycastCallback", self, CollisionFlag.WATER)
end


---Raycast callback for the water checking ray
-- Sets self.waterUnderfootY to the y parameter if the hitObjectId exists and updates isInWater, needSwimming and isSwimming variables
-- @param float hitObjectId The id of the object hit by the ray.
-- @param float x The x position of the ray hit.
-- @param float y The y position of the ray hit.
-- @param float z The z position of the ray hit.
function PlayerMover:onWaterRaycastCallback(hitObjectId, x, y, z)
    if hitObjectId ~= 0 then
        self.waterUnderfootY = y
    end

    -- Start with a distance of 0
    self.currentWaterSubmergeDistance = 0.0

    -- If the ray hit water save the result.
    if self.waterUnderfootY ~= nil then
        self.currentWaterSubmergeDistance = math.max(0, self.waterUnderfootY - self.updateWaterSubmergeDistanceCurrentY)
    end

    self.isInWater = self.currentWaterSubmergeDistance > 0

    self.needSwimming = self.currentWaterSubmergeDistance >= PlayerMover.SWIM_SUBMERGE_THRESHOLD

    self.isSwimming = self.currentWaterSubmergeDistance >= PlayerMover.SWIM_SUBMERGE_THRESHOLD - 0.2
end


---Applies gravity and movement every frame.
-- @param float dt Delta time in ms.
function PlayerMover:update(dt)

    local nextPositionX, nextPositionY, nextPositionZ
    if self:getIsPhysicsEnabled() then
        -- Update and calculate the deltas.
        self.positionDeltaX, self.positionDeltaY, self.positionDeltaZ = self:updateDeltas(dt)

        -- Calculate where the player should be after the move, if there are no collisions.
        local currentPositionX, currentPositionY, currentPositionZ = self:getPosition()
        nextPositionX, nextPositionY, nextPositionZ = currentPositionX + self.positionDeltaX, currentPositionY + self.positionDeltaY, currentPositionZ + self.positionDeltaZ

        setWorldTranslation(self.movementDirectionNode, nextPositionX, nextPositionY, nextPositionZ)

        -- Apply the velocity to the player CCT.
        self.player.capsuleController:move(self.positionDeltaX, self.positionDeltaY, self.positionDeltaZ)
    end

    -- If no next position was calculated, use the current position.
    if nextPositionX == nil then
        nextPositionX, nextPositionY, nextPositionZ = self:getPosition()
    end

    -- Get the collision of the player's collider, if the bottom is touching something then they are grounded. This can only be done on the server.
    local isGrounded = nil
    if self.player.isServer or self:getIsPhysicsEnabled() then
        isGrounded = self.player.capsuleController:calculateIfBottomTouchesGround()
    end

    -- Update the current distance from the water level and floor using the current position.
    self:updateWaterSubmergeDistance(nextPositionX, nextPositionY, nextPositionZ)
    self:updateFloorDistance(dt, isGrounded, nextPositionX, nextPositionY, nextPositionZ)

    -- If physics are disabled, don't bother updating anything else.
    if not self:getIsPhysicsEnabled() then
        return
    end

    local movementYaw
    if self.player.isStrafeWalkMode then
        local _, yaw = self.player.camera:getRotation()
        movementYaw = yaw
    else
        local currentSpeed = self:getSpeed()
        movementYaw = currentSpeed <= 0 and self.movementDirectionYaw or MathUtil.getYRotationFromDirection(self.currentVelocityX / currentSpeed, self.currentVelocityZ / currentSpeed)
    end

    -- Update the movement node's rotation.
    local oldDirectionYaw = self.movementDirectionYaw
    self:updateRotation(dt, movementYaw)
    self.currentRotationVelocity = MathUtil.getValidLimit(self.movementDirectionYaw - oldDirectionYaw) / (dt * 0.001)
end



























































































































































---Displays the debug information.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
-- @return float y The y position on the screen after the entire debug info was drawn.
function PlayerMover:debugDraw(x, y, textSize)

    -- Draw the movement direction node.
    DebugUtil.drawDebugNode(self.movementDirectionNode, "MDIR", false, 0)

    -- Render the header.
    y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Mover", nil, true)

    -- Render the values.
    y = DebugUtil.renderTextLine(x, y, textSize, "Movement", nil, true)
    local positionX, positionY, positionZ = self:getPosition()
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Position: %.2f, %.2f, %.2f", positionX, positionY, positionZ))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Velocity: %.2f, %.2f, %.2f", self.currentVelocityX, self.currentVelocityY , self.currentVelocityZ))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Movement yaw: %.4f", self:getMovementYaw()))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Rotation: %.4f", self.movementDirectionYaw))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Rotation velocity: %.4f", self.currentRotationVelocity))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Speed: %.4f", self.currentSpeed))
    y = DebugUtil.renderNewLine(y, textSize)
    y = DebugUtil.renderTextLine(x, y, textSize, "Ground/water", nil, true)
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Water level: %.4f", self.waterUnderfootY or 0.0))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Submerge distance: %.4f", self.currentWaterSubmergeDistance))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Swimming/in water: %s/%s", self.isSwimming, self.isInWater))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Ground level: %.4f", self.groundUnderfootY or 0.0))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Ground distance: %.4f", self.currentGroundDistance))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Grounded: %s", self.isGrounded))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Close to ground: %s", self.isCloseToGround))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Fall/air/ground time: %.4f/%.4f/%.4f", self.currentFallTime, self.currentAirTime, self.currentGroundTime))

    -- Return the final y value.
    return y
end
