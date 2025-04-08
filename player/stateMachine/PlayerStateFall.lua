









---The state used for the player being in the air after a set amount of time.
local PlayerStateFall_mt = Class(PlayerStateFall, BaseStateMachineState)














---Creates a state with the given player and managing state machine.
-- @param Player player The player who owns this state.
-- @param StateMachine stateMachine The state machine managing this state.
-- @return BaseStateMachineState instance The created instance.
function PlayerStateFall.new(player, stateMachine)

    -- Create the instance, set the player, then return the instance.
    local self = BaseStateMachineState.new(stateMachine, PlayerStateFall_mt)
    self.player = player
    return self
end








---Calculates if the player has been falling for long enough to count as falling and is not submerged in water.
-- @return boolean isFalling True if stateMachine.states.swimming:calculateIfSubmerged() is false and player.mover.currentFallTime is greater than or equal to FALL_TIME_THRESHOLD; otherwise false.
function PlayerStateFall:calculateIfFalling()
    return not self.stateMachine.states.swimming:calculateIfSubmerged()
    and self.player.mover.currentFallTime >= PlayerStateFall.FALL_TIME_THRESHOLD
end


---Calculates if the player is close enough to the ground to count as landing.
-- @return boolean isLanding True if player.mover.currentGroundDistance is less than or equal to GROUND_LANDING_DISTANCE; otherwise false.
function PlayerStateFall:calculateIfLanding()
    return self.player.mover.currentGroundDistance <= PlayerStateFall.GROUND_LANDING_DISTANCE
end


---Updates this state when it is currently the state machine's current state. Calls stateMachine:determineState() when calculateIfShouldBeForced() returns false.
-- @param float dt Delta time in ms.
function PlayerStateFall:updateAsCurrent(dt)
    if not self:calculateIfShouldBeForced() then
        self.stateMachine:determineState()
    end
end






---Calculates the desired horizontal velocity in metres per second.
-- @param float directionX The direction on the x axis to use.
-- @param float directionZ The direction on the z axis to use.
-- @return float x The desired x.
-- @return float z The desired z.
function PlayerStateFall:calculateDesiredHorizontalVelocity(directionX, directionZ)

    -- Calculate the direction, then the desired speed.
    local maximumMoveSpeed = self.player.toggleSuperSpeedCommand.value and PlayerStateFall.MAXIMUM_MOVE_SPEED * 8 or PlayerStateFall.MAXIMUM_MOVE_SPEED
    return directionX * maximumMoveSpeed, directionZ * maximumMoveSpeed
end
