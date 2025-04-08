








---The state used for the player moving on foot.
local PlayerStateWalk_mt = Class(PlayerStateWalk, BaseStateMachineState)








---Creates a state with the given player and managing state machine.
-- @param Player player The player who owns this state.
-- @param StateMachine stateMachine The state machine managing this state.
-- @return BaseStateMachineState instance The created instance.
function PlayerStateWalk.new(player, stateMachine)

    -- Create the instance, set the player, then return the instance.
    local self = BaseStateMachineState.new(stateMachine, PlayerStateWalk_mt)

    self.player = player

    self.walkAxis = 0
    self.runAxis = 0

    return self
end


---Called just after the creation of all states, so that other states can be used to create transitions.
function PlayerStateWalk:createTransitions()

    self:addTransition(self.stateMachine.states.idle.calculateIfIdle, self.stateMachine.states.idle)
    self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
    self:addTransition(self.stateMachine.states.crouching.calculateIfCrouching, self.stateMachine.states.crouching)
end


---Calculates if this state is a valid state to enter back in on after a forced state.
-- @return boolean isValid True if calculateIfWalking is true, the player is grounded, and stateMachine.states.swimming:calculateIfSubmerged() is true; otherwise false.
function PlayerStateWalk:calculateIfValidEntryState()
    return self:calculateIfMoving() and self.player.mover.isGrounded and not self.stateMachine.states.swimming:calculateIfSubmerged()
end










---Calculates if the player's inputs allow them to walk.
-- @return boolean isRunning True if the player has movement inputs, is not holding the run button, and is not holding the crouch button; otherwise false.
function PlayerStateWalk:calculateIfWalking()
    return self:calculateIfMoving() and self.runAxis == 0.0
end


---Calculates if the player's inputs allow them to run.
-- @return boolean isRunning True if the player has movement inputs, is holding the run button, and is not holding the crouch button; otherwise false.
function PlayerStateWalk:calculateIfRunning()
    local runMultiplier = self.player:getRunMultiplier()
    return self:calculateIfMoving() and self.runAxis > 0.0 and runMultiplier > 0
end























































---Calculates the desired horizontal velocity in metres per second.
-- @param float directionX The direction on the x axis to use.
-- @param float directionZ The direction on the z axis to use.
-- @return float x The desired x.
-- @return float z The desired z.
function PlayerStateWalk:calculateDesiredHorizontalVelocity(directionX, directionZ)

    -- Calculate the speed to use then return it as a velocity vector.
    local speed = self:calculateDesiredSpeed()
    return directionX * speed, directionZ * speed
end
