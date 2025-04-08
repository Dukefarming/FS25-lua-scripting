









---The state used for the player standing still and doing nothing.
local PlayerStateIdle_mt = Class(PlayerStateIdle, BaseStateMachineState)


---Creates a state with the given player and managing state machine.
-- @param Player player The player who owns this state.
-- @param StateMachine stateMachine The state machine managing this state.
-- @return BaseStateMachineState instance The created instance.
function PlayerStateIdle.new(player, stateMachine)

    -- Create the instance, set the player, then return the instance.
    local self = BaseStateMachineState.new(stateMachine, PlayerStateIdle_mt)
    self.player = player
    return self
end


---Called just after the creation of all states, so that other states can be used to create transitions.
function PlayerStateIdle:createTransitions()

    self:addTransition(self.stateMachine.states.walking.calculateIfMoving, self.stateMachine.states.walking)
    self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
    self:addTransition(self.stateMachine.states.crouching.calculateIfCrouching, self.stateMachine.states.crouching)
end


---Calculates if this state is a valid state to enter back in on after a forced state.
-- @return boolean isValid True if calculateIfIdle() and player.mover.isGrounded are true; otherwise false.
function PlayerStateIdle:calculateIfValidEntryState()
    return self:calculateIfIdle() and self.player.mover.isGrounded
end


---Calculates if the player has no movement inputs and is not crouching.
-- @return boolean isIdle True if player.inputComponent.hasMovementInputs and stateMachine.states.crouching:calculateIfCrouching() are false; otherwise false.
function PlayerStateIdle:calculateIfIdle()
    if self.player.isOwner then
        return self.player.mover:getSpeed() <= 0.01 and not self.player.inputComponent.hasMovementInputs and not self.stateMachine.states.crouching:calculateIfCrouching()
    else
        return self.player.mover:getSpeed() <= 0.01 and not self.stateMachine.states.crouching:calculateIfCrouching()
    end
end
