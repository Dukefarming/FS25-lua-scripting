









---The interface representing the camera of a player in either third or first person mode.
local PlayerCamera_mt = Class(PlayerCamera)











































---Creates a new camera for the given player.
-- @param Player player The player who owns this camera.
-- @return PlayerCamera instance The created instance.
function PlayerCamera.new(player)

    -- Create the instance.
    local self = setmetatable({}, PlayerCamera_mt)

    -- The player who owns this camera.
    self.player = player

    -- The current mode of the camera.
    self.isFirstPerson = true

    -- Is true if the player cannot switch between third and first, and can only use the current perspective.
    self.isSwitchingLocked = false

    -- The collision enabled flag, determining if the camera should be able to clip through objects.
    self.isCollisionEnabled = true

    -- The collision mask used when the player is in no-clip mode.
    self.noClipCollisionMask = PlayerCamera.COLLISION_MASK

    -- The distance between the camera and the object behind it, from the raycast. Nil if no object is behind the camera in range.
    self.lastCollisionDistance = nil

    -- The distance from the collided object that the camera should be.
    self.lastDistanceOffset = nil

    -- The nodes used for yaw and pitch for the camera.
    self.yawNode = nil
    self.pitchNode = nil

    -- The actual camera object.
    self.cameraRootNode = nil

    -- The y offset.
    self.offsetY = 0.0

    -- The transform of the camera when a target override transition is started.
    self.startPositionX, self.startPositionY, self.startPositionZ = nil, nil, nil
    self.startRotationX, self.startRotationY, self.startRotationZ, self.startRotationW = nil, nil, nil, nil

    -- The target transform of the override transition.
    self.targetPositionX, self.targetPositionY, self.targetPositionZ = nil, nil, nil
    self.targetRotationX, self.targetRotationY, self.targetRotationZ, self.targetRotationW = nil, nil, nil, nil

    -- The start time and duration of the override transition.
    self.overrideTransitionStartTime = nil
    self.overrideTransitionDuration = nil

    -- The last bob offsets.
    self.lastBobOffsetX = 0.0
    self.lastBobOffsetY = 0.0

    -- The maximum zoom distance that the player would like to have.
    self.desiredZoomDistance = PlayerCamera.DEFAULT_ZOOM

    -- The zoom distance of the camera currently.
    self.currentZoomDistance = self.desiredZoomDistance

    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON], self.onFovySettingChanged, self)
    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON], self.onFovySettingChanged, self)

    -- Create and return the instance.
    return self
end


---Fired when the player loads for the first time. Creates and sets up the required nodes in the scene.
function PlayerCamera:initialise()

    -- Create the camera nodes.
    self:initialiseCameraNodes()
end






































































---Sets this camera as the scene's main camera.
function PlayerCamera:makeCurrent()
    if self.isFirstPerson then
        g_cameraManager:setActiveCamera(self.firstPersonCamera)
    elseif self.isInConversation then
        g_cameraManager:setActiveCamera(self.thirdPersonConversationCamera)
    else
        g_cameraManager:setActiveCamera(self.thirdPersonCamera)
    end
end


---Handles toggling between first person and third person modes, including setting the camera position.
function PlayerCamera:toggleThirdPersonMode()
    self:switchToPerspective(not self.isFirstPerson)
end

















































































































---Gets if collision is enabled for this camera. This will be false if the player is in first person mode, even if the variable itself is true.
-- @return boolean isCollisionEnabled True if the camera is in third person and collision is enabled; otherwise false.
function PlayerCamera:getIsCollisionEnabled()
    return self.isCollisionEnabled
end


---Sets the collision enabled value to the given value.
-- @param boolean isCollisionEnabled The new value to use.
function PlayerCamera:setIsCollisionEnabled(isCollisionEnabled)
    self.isCollisionEnabled = isCollisionEnabled
end
























---Returns the current y offset of the camera. This is applied alongside the offset from the ground, to fine-adjust for things like swimming.
-- @return float offsetY The current y offset of the camera.
function PlayerCamera:getOffsetY()
    return self.offsetY
end


---Sets the current y offset to the given value. Defaults to 0.
-- @param float offsetY The new y offset to use. If this is nil, uses 0 instead.
function PlayerCamera:setOffsetY(offsetY)
    self.offsetY = offsetY or 0
end


---Gets the current zoom distance of the camera.
-- @return float zoomDistance The current zoom distance of the camera.
function PlayerCamera:getCurrentZoomDistance()
    return self.currentZoomDistance
end


---Sets the current zoom distance, ensuring it does not go further than the desired distance and positioning the camera.
-- @param float zoomDistance The new zoomDistance to use.
-- @param boolean? isForced If true, will not clamp the given value.
function PlayerCamera:setCurrentZoomDistance(zoomDistance, isForced)
    self.currentZoomDistance = zoomDistance
    setTranslation(self.cameraRootNode, 0, 0, -self.currentZoomDistance)
end


---Gets the current zoom level of the camera. This is 0 if the player is in first person mode.
-- @return float desiredZoomDistance The current zoom distance of the camera.
function PlayerCamera:getDesiredZoomDistance()
    return self.isFirstPerson and 0 or self.desiredZoomDistance
end














---Gets the current position of the camera's yaw node, which is the position the camera is looking at.
-- @return float x The x position.
-- @return float y The y position.
-- @return float z The z position.
function PlayerCamera:getFocusPosition()
    return getWorldTranslation(self.yawNode)
end


---Sets the position of the yaw node to the given position.
-- @param float x The x position.
-- @param float y The y position.
-- @param float z The z position.
function PlayerCamera:setFocusPosition(x, y, z)
    setWorldTranslation(self.yawNode, x, y, z)
end



















































---Gets the position of the camera node itself (not the yaw node).
-- @return float x The x position.
-- @return float y The y position.
-- @return float z The z position.
function PlayerCamera:getCameraPosition()
    return getWorldTranslation(self.cameraRootNode)
end


---Gets the rotation of the camera. This function avoids the flipping issue of the engine.
-- @return float pitch The pitch of the camera.
-- @return float yaw The yaw of the camera.
-- @return float roll The roll of the camera.
function PlayerCamera:getRotation()

    -- Calculate and return the pitch, yaw, and roll from the camera.
    local cameraLookX, cameraLookY, cameraLookZ = localDirectionToWorld(self.cameraRootNode, 0, 0, -1)
    local pitch, yaw = MathUtil.directionToPitchYaw(cameraLookX, cameraLookY, cameraLookZ)
    local _, _, roll = getRotation(self.cameraRootNode)
    return pitch, yaw, roll
end


---Sets the rotation of the camera to the given rotation.
-- @param float pitch The pitch of the camera.
-- @param float yaw The yaw of the camera.
-- @param float roll The roll of the camera.
function PlayerCamera:setRotation(pitch, yaw, roll)
    setRotation(self.pitchNode, pitch or 0, 0, 0)
    setRotation(self.yawNode, 0, yaw or 0, 0)
    setRotation(self.cameraRootNode, 0, math.pi, roll or 0)
end


---Takes the given local x and z direction and transforms it into world-space around the yaw node.
-- @param float directionX The x direction.
-- @param float directionZ The z direction.
-- @return float worldDirectionX The transformed x direction.
-- @return float worldDirectionZ The transformed z direction.
function PlayerCamera:calculateWorldDirection(directionX, directionZ)
    local worldDirectionX, _, worldDirectionZ = localDirectionToWorld(self.yawNode, directionX, 0, directionZ)
    return worldDirectionX, worldDirectionZ
end


---Takes the given world x and z direction and transforms it into local-space around the yaw node.
-- @param float directionX The x direction.
-- @param float directionZ The z direction.
-- @return float localDirectionX The transformed x direction.
-- @return float localDirectionZ The transformed z direction.
function PlayerCamera:calculateLocalDirection(directionX, directionZ)
    local localDirectionX, _, localDirectionZ = worldDirectionToLocal(self.yawNode, directionX, 0, directionZ)
    return localDirectionX, localDirectionZ
end















---Updates the rotation of the camera based on player input.
-- @param float dt Delta time in ms.
function PlayerCamera:updateRotation(dt)

    -- If there's a target override, update for that and do nothing else.
    if self:getHasOverriddenTarget() then
        self:updateRotationFromTarget()
        return
    end

    -- Calculate how much of a rotation to make this frame based on the player's input and the camera sensitivity.
    local cameraSensitivity = g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
    local rotationDeltaX = self.player.inputComponent.cameraRotationX * cameraSensitivity
    local rotationDeltaY = -self.player.inputComponent.cameraRotationY * cameraSensitivity

    -- Get the current rotation of the camera.
    local cameraPitch, cameraYaw, cameraRoll = self:getRotation()

    -- Add the deltas, ensuring the pitch is limited.
    cameraPitch = math.clamp(cameraPitch + rotationDeltaX, PlayerCamera.LOWEST_PITCH, PlayerCamera.HIGHEST_PITCH)
    cameraYaw = MathUtil.getValidLimit(cameraYaw + rotationDeltaY)

    -- Set the rotation of the camera.
    self:setRotation(cameraPitch, cameraYaw, cameraRoll)
end


---Updates the camera's position so that it follows the player, also applying view bobbing if needed.
-- @param float dt Delta time in ms.
function PlayerCamera:updatePosition(dt)

    -- If there's a target override, update for that and do nothing else.
    if self:getHasOverriddenTarget() then
        self:updatePositionFromTarget()
        return
    end

    -- Move the camera to the player's position.
    self:focusOnPlayer()

    -- Try apply the view bobbing.
    self:tryApplyViewBobbing(dt)

    -- Try apply the zoom logic, which includes raycasting to find the best distance.
    self:applyZoom(dt)
end


---Focuses the camera on the player, handling the positioning based on if the player is in first person mode or not.
function PlayerCamera:focusOnPlayer()

    -- Get the player's current position.
    local currentX, currentY, currentZ = self.player:getGraphicalPosition()
    self:focusOnPosition(currentX, currentY, currentZ)
end
























































---Positions the camera's yaw node to the given position, using the current offsetY.
-- @param float x The x position.
-- @param float y The y position.
-- @param float z The z position.
function PlayerCamera:focusOnPosition(x, y, z)
    local baseOffsetY = self:getBaseOffsetY()
    self:setFocusPosition(x, y + self.offsetY + baseOffsetY, z)
end


---Applies the view bobbing to the camera position, as long as the player is in first person and their CAMERA_BOBBING setting is on.
-- @param float dt Delta time in ms.
function PlayerCamera:tryApplyViewBobbing(dt)

    -- If the player is in third person or their setting for view bobbing is off, reset the camera position.
    if not self.isFirstPerson then
        setTranslation(self.cameraRootNode, 0.0, 0.0, -self.currentZoomDistance)
        return
    end

    local doCameraBobbing = g_gameSettings:getValue(GameSettings.SETTING.CAMERA_BOBBING)
    if not doCameraBobbing then
        setTranslation(self.cameraRootNode, 0.0, 0.0, 0.0)
        return
    end

    -- Avoid view bobbing when the player can move very fast.
    if self.player.mover.currentSpeed > 10 then
        return
    end

    -- Set the target bob offset, defaulting to 0.
    local targetBobOffsetX = 0.0
    local targetBobOffsetY = 0.0

    -- Set the roll, defaulting to 0.
    local bobRoll = 0

    -- If the player is moving and is on the ground, calculate the oscillating bob offset.
    local isMoving = math.abs(self.player.mover.currentSpeed) >= PlayerMover.SMALL_SPEED_THRESHOLD
    if isMoving and self.player.mover.isGrounded then

        -- Round the speed so it does not cause jitter.
        local roundedSpeed = MathUtil.round(self.player.mover.currentSpeed)

        -- Create a random number to shift the x oscillation by when calculating the y oscillation. This makes the up/down bobbing a bit more bumpy and natural.
        local randomOffsetX = math.random(-self.BOBBING_OSCILLATION_RANDOMNESS, self.BOBBING_OSCILLATION_RANDOMNESS)

        -- The x oscillation is simply the sine of the time (in seconds) multiplied by the random speed.
        local oscillationX = math.sin((g_time * 0.001) * roundedSpeed)

        -- The y oscillation is calculated from the x oscillation, with a 90 degree lead so the bobbing makes an 'n' shape. A random offset is added to make it more natural.
        local oscillationY = math.sin((oscillationX + randomOffsetX + 0.5) * math.pi)

        -- Set the roll based on the x oscillation.
        bobRoll = oscillationX * PlayerCamera.ROLL_BOBBING

        -- Set the target bob offset.
        targetBobOffsetX = oscillationX * self.HORIZONTAL_BOBBING
        targetBobOffsetY = oscillationY * self.VERTICAL_BOBBING
    end

    -- Create the bob offset for each axis.
    local bobOffsetX, bobOffsetY

    -- Calculate the maximum possible movements on each axis.
    local maxBobMovementX = (self.HORIZONTAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION)
    local maxBobMovementY = (self.VERTICAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION)

    -- Calculate the most amount of bobbing the camera should make in this frame, on the x axis.
    if self.lastBobOffsetX < targetBobOffsetX then
        bobOffsetX = math.min(self.lastBobOffsetX + maxBobMovementX, targetBobOffsetX)
    else
        bobOffsetX = math.max(self.lastBobOffsetX - maxBobMovementX, targetBobOffsetX)
    end

    -- Do the same for the y axis.
    if self.lastBobOffsetY < targetBobOffsetY then
        bobOffsetY = math.min(self.lastBobOffsetY + maxBobMovementY, targetBobOffsetY)
    else
        bobOffsetY = math.max(self.lastBobOffsetY - maxBobMovementY, targetBobOffsetY)
    end

    -- Apply the view bobbing to the camera.
    setTranslation(self.cameraRootNode, bobOffsetX, bobOffsetY, 0.0)
    local currentPitch, currentYaw = self:getRotation()
    self:setRotation(currentPitch, currentYaw, bobRoll)

    -- Save the old bob offset.
    self.lastBobOffsetX = bobOffsetX
    self.lastBobOffsetY = bobOffsetY
end
