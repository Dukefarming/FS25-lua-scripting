









---The state used for the player being in the air after jumping, not long enough to be considered falling.
local PlayerStateJump_mt = Class(PlayerStateJump, BaseStateMachineState)




















---Creates a state with the given player and managing state machine.
-- @param Player player The player who owns this state.
-- @param StateMachine stateMachine The state machine managing this state.
-- @return BaseStateMachineState instance The created instance.
function PlayerStateJump.new(player, stateMachine)

    -- Create the instance and set the player.
    local self = BaseStateMachineState.new(stateMachine, PlayerStateJump_mt)
    self.player = player

    -- The timer for how long the player has been falling after reaching the top of their jump.
    self.timeSpentFallingDown = 0.0

    -- The timer for how long the player has been jumping
    self.timeSpentJumping = 0.0

    -- Return the created instance.
    return self
end


---Called just after the creation of all states, so that other states can be used to create transitions.
function PlayerStateJump:createTransitions()

    self:addTransition(self.calculateIfFalling, self.stateMachine.states.falling, self)
end


---Calculates if the player has been falling for long enough to transition into the falling state. This is different than the regular time to start falling, to prevent the player from entering the falling state during a jump.
-- @return boolean isFalling True if timeSpentFallingDown is greater than or equal to FALL_TIME_THRESHOLD; otherwise false.
function PlayerStateJump:calculateIfFalling()
    return self.timeSpentFallingDown >= self.FALL_TIME_THRESHOLD
end


---Calculates if the player is pressing the jump button.
-- @return boolean isJumping True if player.inputComponent.jumpPower is over 0.0; otherwise false.
function PlayerStateJump:calculateIfJumping()
    if self.player.isOwner then
        return self.player.inputComponent.jumpPower > 0.0 and self.player.mover.currentGroundTime >= PlayerStateJump.MINIMUM_GROUND_TIME_THRESHOLD
    else
        return self.player.mover.currentVelocityY > 0.0 and self.player.mover.currentGroundTime >= PlayerStateJump.MINIMUM_GROUND_TIME_THRESHOLD
    end
end


---Calculates if the player is still in the early part of the jump.
-- @return boolean isTakingOff True if timeSpentJumping is less than or equal to JUMP_TIME_THRESHOLD and player.mover.currentLocalVelocity is less than or equal to 0; otherwise false.
function PlayerStateJump:calculateIfTakingOff()
    return self.timeSpentJumping <= self.JUMP_TIME_THRESHOLD and self.player.mover.currentVelocityY > 0.0
end


---Calculates if the player is about to land on the ground after a jump.
-- @return boolean isLanding True if player.mover.currentGroundDistance is less than or equal to GROUND_LANDING_DISTANCE and calculateIfTakingOff() is false; otherwise false.
function PlayerStateJump:calculateIfLanding()
    return self.player.mover.currentGroundDistance <= self.GROUND_LANDING_DISTANCE and not self:calculateIfTakingOff()
end


---Fired when this state is entered.
-- @param PlayerStateBase previousState The previous state the machine was in before entering this one.
function PlayerStateJump:onStateEntered(previousState)

    -- Set the up force and velocity.
    self.player.mover.currentVelocityY = PlayerStateJump.JUMP_UPFORCE

    -- Reset the timers.
    self:resetTimers()
end


---Fired when this state is exited.
-- @param BaseStateMachineState previousState The state the machine will be in after exiting this one.
function PlayerStateJump:onStateExited(previousState)

    -- Reset the up force.
    self.player.mover.currentUpForce = 0.0

    -- Reset the timers.
    self:resetTimers()
end


---Resets all jumping related timers.
function PlayerStateJump:resetTimers()

    -- Reset the timers.
    self.timeSpentFallingDown = 0.0
    self.timeSpentJumping = 0.0
end


---Updates this state when it is currently the state machine's current state.
-- @param float dt Delta time in ms.
function PlayerStateJump:updateAsCurrent(dt)

    -- If the player is falling downwards, increment the downwards falling counter. This means that the jump upwards does not count as falling.
    if self.player.mover.currentVelocityY < 0 then
        self.timeSpentFallingDown = self.timeSpentFallingDown + (dt * 0.001)
    end

    -- Update the jump timer.
    self.timeSpentJumping = self.timeSpentJumping + (dt * 0.001)

    -- If the player is grounded again, determine the new state.
    if self.player.mover.isGrounded and not self:calculateIfTakingOff() then
        self.stateMachine:determineState()
        return
    end

    -- Go through the transitions and see if any are valid.
    self:trySwitchToValidTransition()
end


---Calculates the desired horizontal velocity in metres per second.
-- @param float directionX The direction on the x axis to use.
-- @param float directionZ The direction on the z axis to use.
-- @return float x The desired x.
-- @return float z The desired z.
function PlayerStateJump:calculateDesiredHorizontalVelocity(directionX, directionZ)

    -- Calculate the direction, then the desired speed.
    local maximumMovepeed = self.player.toggleSuperSpeedCommand.value and PlayerStateJump.MAXIMUM_MOVE_SPEED * 8 or PlayerStateJump.MAXIMUM_MOVE_SPEED
    local speed = self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, false, 0, maximumMovepeed)
    return directionX * speed, directionZ * speed
end
