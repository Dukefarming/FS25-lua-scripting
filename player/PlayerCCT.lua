









---A capsule controller for a player. Simply managing the CCT.
local PlayerCCT_mt = Class(PlayerCCT)

























---Creates a new player CCT instance
-- @return PlayerCCT playerCCT The created instance.
function PlayerCCT.new()
    local self = setmetatable({}, PlayerCCT_mt)

    -- The id of the CCT itself.
    self.capsuleId = nil

    -- The height of the capsule.
    self.height = PlayerCCT.DEFAULT_HEIGHT

    -- The height that the capsule wishes to have, before the physics system knows if it is valid.
    self.desiredHeight = self.height

    -- The physics index on which the height was changed.
    self.heightChangePhysicsIndex = nil

    -- The radius of the capsule.
    self.radius = 0.35

    -- The steepest slope the capsule can climb.
    self.slopeLimit = 60

    -- The highest y difference the capsule can step up.
    self.stepOffset = 0.4

    -- The mass of the capsule.
    self.mass = 0

    self.collisionGroup = PlayerCCT.DEFAULT_COLLISION_GROUP

    self.collisionMask = PlayerCCT.DEFAULT_COLLISION_MASK

    self.movementCollisionGroup = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_GROUP

    self.movementCollisionMask = PlayerCCT.DEFAULT_MOVEMENT_COLLISION_MASK

    -- Return the created instance.
    return self
end

























---Removes the CCT, if one exists.
function PlayerCCT:delete()

    -- Remove the CCT and set the index to nil.
    if self.capsuleId ~= nil then
        removeCCT(self.capsuleId)
        self.capsuleId = nil
    end
end































































































---Deletes and recreates the player's CCT.
function PlayerCCT:rebuild()

    -- Delete the old CCT.
    if self.capsuleId ~= nil then
        removeCCT(self.capsuleId)
        self.capsuleId = nil
    end

    -- Create the CCT again.
    self.capsuleId = createCCT(self.rootNode, self.radius, self.desiredHeight, self.stepOffset, self.slopeLimit, self:getSkinWidth(), self.collisionGroup, self.collisionMask, self.mass)

    -- Update the height members.
    self.height = self.desiredHeight
    self.heightChangePhysicsIndex = nil
end


---Moves the CCT using the given movement.
-- @param float movementX The x movement in metres.
-- @param float movementY The y movement in metres.
-- @param float movementZ The z movement in metres.
function PlayerCCT:move(movementX, movementY, movementZ)
--#profile     RemoteProfiler.zoneBeginN("PlayerCCT-move")
    moveCCT(self.capsuleId, movementX, movementY, movementZ, self.movementCollisionGroup, self.movementCollisionMask)
--#profile     RemoteProfiler.zoneEnd()
end















---Returns the position of the player's feet.
-- @return float x The x position.
-- @return float y The y position.
-- @return float z The z position.
function PlayerCCT:getPosition()
    local x, y, z = getWorldTranslation(self.rootNode)
    return x, y + self:getBottomOffsetY(), z
end


---Positions the player's foot position using the given position.
-- @param float x The x position.
-- @param float y The y position.
-- @param float z The z position.
-- @param boolean? setNodeTranslation If this is true, the player's root node will also be moved to the given position. Defaults to false.
function PlayerCCT:setPosition(x, y, z, setNodeTranslation)

    if setNodeTranslation then
        setWorldTranslation(self.rootNode, x, y - self:getBottomOffsetY(), z)
    end

    setCCTPosition(self.capsuleId, x, y - self:getBottomOffsetY(), z)
end


---Calculates if the bottom of the capsule is touching the ground.
-- @return boolean isGrounded Is true if the bottom of the capsule is touching the ground; otherwise false.
function PlayerCCT:calculateIfBottomTouchesGround()

    -- Get the collision flags for the top, middle, and bottom of the CCT. The bottom is the only part that matters.
    local _, _, isGrounded = getCCTCollisionFlags(self.capsuleId)

    -- Return the bottom flag.
    return isGrounded
end
























---Displays the debug information.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
-- @return float y The y position on the screen after the entire debug info was drawn.
function PlayerCCT:debugDraw(x, y, textSize)

    -- Render the header.
    y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "CCT", nil, true)

    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Height: %.2f", self.height))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Physics height: %.2f", getCCTHeight(self.capsuleId)))
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Desired height: %.2f", self.desiredHeight))

    return y
end
