









---The state used for the player moving on foot while holding the crouch button.
local PlayerStateCrouch_mt = Class(PlayerStateCrouch, BaseStateMachineState)














---Creates a state with the given player and managing state machine.
-- @param Player player The player who owns this state.
-- @param StateMachine stateMachine The state machine managing this state.
-- @return BaseStateMachineState instance The created instance.
function PlayerStateCrouch.new(player, stateMachine)

    -- Create the instance and set the player.
    local self = BaseStateMachineState.new(stateMachine, PlayerStateCrouch_mt)
    self.player = player

    -- The camera y offset.
    self.cameraOffsetY = 0.0

    -- The timer for how long the player has been crouched.
    self.crouchTime = 0.0

    -- The timer for the transition between standing and crouching (and vice versa).
    self.transitionTime = 0.0

    -- Return the created instance.
    return self
end


---Called just after the creation of all states, so that other states can be used to create transitions.
function PlayerStateCrouch:createTransitions()

    self:addTransition(self.stateMachine.states.idle.calculateIfIdle, self.stateMachine.states.idle)
    self:addTransition(self.stateMachine.states.walking.calculateIfMoving, self.stateMachine.states.walking)
    self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
end


---Determines if this state should be used after the player comes out of a forced state or vehicle.
-- @return Returns true if the player is holding the crouch button, is grounded, and is not so deep in water that they are swimming.
function PlayerStateCrouch:calculateIfValidEntryState()
    return self:calculateIfCrouching() and self.player.mover.isGrounded and not self.stateMachine.states.swimming:calculateIfSubmerged()
end


---Determines if this state is valid to transition to from another state. Does not excessively check things like grounded state and water level, as the transition can only happen from valid states.
-- @return Returns true if the player is holding the crouch button.
function PlayerStateCrouch:calculateIfCrouching()
    if self.player.isOwner then
        return self.player.inputComponent.crouchValue > 0.0
            and (not self.player:getIsHoldingHandTool() or self.player:getHeldHandTool().canCrouch)
            and self.player.mover.currentWaterSubmergeDistance < 1
    else
        -- TODO: Implement crouching over the network.
        return false
    end
end


---Fired when this state is entered.
-- @param PlayerStateBase previousState The previous state the machine was in before entering this one.
function PlayerStateCrouch:onStateEntered(previousState)
    self.player.mover:setIsCrouching(true)

    -- Reset the timers.
    self:resetTimers()
end


---Fired when this state is exited.
-- @param BaseStateMachineState nextState The state the machine will be in after exiting this one.
function PlayerStateCrouch:onStateExited(nextState)
    self.player.mover:setIsCrouching(false)

    -- Reset the timers.
    self:resetTimers()
end


---Resets all timers associated with crouching.
function PlayerStateCrouch:resetTimers()

    -- Reset the timers.
    self.transitionTime = 0.0
    self.crouchTime = 0.0

    -- Reset the camera offset.
    self.cameraOffsetY = 0.0
end


---Updates this state when it is currently the state machine's current state.
-- @param float dt Delta time in ms.
function PlayerStateCrouch:updateAsCurrent(dt)

    -- If the player is holding the crouch button, increment the crouch timer,
    if self:calculateIfCrouching() then

        -- Set the height to the crouching height.
        self.player.capsuleController:setHeight(PlayerCCT.DEFAULT_HEIGHT * 0.5)

        -- Increment the crouch timer and transition timer.
        self.crouchTime = self.crouchTime + (dt * 0.001)
        self.transitionTime = math.min(self.transitionTime + (dt * 0.001), PlayerStateCrouch.SMOOTHING_TIME)
    -- Otherwise; increment the uncrouch timer.
    else

        -- Set the height to the standing height.
        self.player.capsuleController:setHeight(PlayerCCT.DEFAULT_HEIGHT)

        if self.player.capsuleController:getHeight() == PlayerCCT.DEFAULT_HEIGHT then
            -- Reset the crouch timer and decrement the transition timer.
            self.crouchTime = 0.0
            self.transitionTime = math.max(0, self.transitionTime - (dt * 0.001))
        end
    end

    -- Calculate the crouch progress based on the transition time.
    local crouchProgress = math.clamp(self.transitionTime / PlayerStateCrouch.SMOOTHING_TIME, 0, 1)

    -- Set the y offset based on the crouch progress.
    self.cameraOffsetY = PlayerStateCrouch.CROUCHED_CAMERA_OFFSET * crouchProgress

    -- If the transition timer is 0 and the player is standing, go through the transitions and see if any are valid.
    if not self.stateMachine:getIsPassive() and self.transitionTime <= 0 and self.player.capsuleController:getHeight() == PlayerCCT.DEFAULT_HEIGHT then
        self:trySwitchToValidTransition()
    end
end






---Calculates the desired horizontal velocity in metres per second.
-- @param float directionX The direction on the x axis to use.
-- @param float directionZ The direction on the z axis to use.
-- @return float x The desired x.
-- @return float z The desired z.
function PlayerStateCrouch:calculateDesiredHorizontalVelocity(directionX, directionZ)

    -- Calculate the speed to use then return it as a velocity vector.
    local speed = self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, true, 0, PlayerStateCrouch.MAXIMUM_MOVE_SPEED)
    return directionX * speed, directionZ * speed
end
