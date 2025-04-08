









---The general player state machine. Note that the player class is inactive when the player is not on foot, so the purpose of this class is to hold a reliable state of the player and to update the on-foot state when it is active.
local PlayerStateMachine_mt = Class(PlayerStateMachine, StateMachine)


---Creates the main player state machine.
-- @param Player player The player who owns this state machine.
-- @return PlayerStateMachine instance The created instance.
function PlayerStateMachine.new(player)

    -- Create the instance.
    local self = StateMachine.new(PlayerStateMachine_mt)

    -- The player.
    self.player = player

    -- Create the states.
    self.states =
    {
        onFoot = PlayerOnFootStateMachine.new(player),
        driving = PlayerStateDriving.new(player, self),
        passenger = PlayerStatePassenger.new(player, self),
        rollercoaster = PlayerStateRollercoaster.new(player, self)
    }

    -- Create the state transitions now that the list of states is ready.
    self:initialiseStateTransitions()

    -- Start on the onFoot state, and set it as the default.
    self.currentState = self.states.onFoot
    self.defaultState = self.states.onFoot

    -- The player's state machine is driven by player events rather than transitions, so should be passive.
    self:setIsPassive(true)

    -- Return the created instance.
    return self
end


---Updates the player while they are frozen or in a gui.
-- @param float dt Delta time in ms.
-- @param boolean isInGui True if the player is in a GUI, e.g. the shop.
-- @param boolean isFrozen True if the player is frozen, e.g. during the intro.
function PlayerStateMachine:updateWhilePaused(dt, isInGui, isFrozen)
    self:callStateFunction("updateWhilePaused", dt, isInGui, isFrozen)
end
