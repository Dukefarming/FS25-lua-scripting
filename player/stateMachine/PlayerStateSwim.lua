









---The state used for the player moving or being still on foot while deep enough in water.
local PlayerStateSwim_mt = Class(PlayerStateSwim, BaseStateMachineState)

















---Creates a state with the given player and managing state machine.
-- @param Player player The player who owns this state.
-- @param StateMachine stateMachine The state machine managing this state.
-- @return BaseStateMachineState instance The created instance.
function PlayerStateSwim.new(player, stateMachine)

    -- Create the instance, set the player, then return the instance.
    local self = BaseStateMachineState.new(stateMachine, PlayerStateSwim_mt)
    self.player = player
    return self
end
































---Updates this state when it is currently the state machine's current state. Calls stateMachine:determineState() when calculateIfShouldBeForced() returns false.
-- @param float dt Delta time in ms.
function PlayerStateSwim:updateAsCurrent(dt)
    if not self:calculateIfShouldBeForced() then
        self.stateMachine:determineState()
    end
end
























---Calculates the desired horizontal velocity in metres per second.
-- @param float directionX The direction on the x axis to use.
-- @param float directionZ The direction on the z axis to use.
-- @return float x The desired x.
-- @return float z The desired z.
function PlayerStateSwim:calculateDesiredHorizontalVelocity(directionX, directionZ)

    -- Calculate the speed to use then return it as a velocity vector.
    local speed = self:calculateDesiredSpeed()
    return directionX * speed, directionZ * speed
end
