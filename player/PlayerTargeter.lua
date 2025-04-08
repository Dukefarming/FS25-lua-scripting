










---Exists for the client's player, and handles raycasting and finding specific objects for them to interact with.
local PlayerTargeter_mt = Class(PlayerTargeter)


---Creates a new targeter for the given player.
-- @param Player player The player for whom the targeter is made.
-- @return PlayerTargeter self The created instance.
function PlayerTargeter.new(player)

    -- Create the instance.
    local self = setmetatable({}, PlayerTargeter_mt)

    -- The player that this targeter belongs to.
    self.player = player

    -- The pool of unused target tables.
    self.pooledTargets = ObjectPool.new()

    -- The total combined mask.
    self.combinedTargetMask = 0

    -- The collection of specifically targeted masks.
    self.targetedMasks = {}

    self.closestTargetsByKey = {}
    self.currentTargetsByKey = {}

    -- The highest maximum distance that is targeted.
    self.highestMaxDistance = 0

    -- The components of the last ray that was fired by this targeter.
    self.lastRayX, self.lastRayY, self.lastRayZ = nil, nil, nil
    self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ = nil, nil, nil

    -- Return the created instance.
    return self
end






---Gets the last look ray components.
-- @return float lastRayX The origin's x position.
-- @return float lastRayY The origin's y position.
-- @return float lastRayZ The origin's z position.
-- @return float lastRayDirectionX The ray's x direction.
-- @return float lastRayDirectionY The ray's y direction.
-- @return float lastRayDirectionZ The ray's z direction.
function PlayerTargeter:getLastLookRay()
    return self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ
end


---Returns true if the given key is targeted; otherwise false.
-- @param CollisionFlag targetKey The key of the objects to target.
-- @return boolean hasTargetedMask True if the mask is targeted; otherwise false.
function PlayerTargeter:getHasTargetedKey(targetKey)
    return self.targetedMasks[targetKey] ~= nil
end


---Adds the given target type to the targeter, so that the raycasts will include objects with these collision masks.
-- @param any targetKey An object used as a key to later retrieve or remove the target type.
-- @param CollisionFlag targetMask The mask of the objects to target.
-- @param float? minDistance The optional minimum distance that an object of this type can be targeted. Defaults to 0.
-- @param float maxDistance The maximum distance that an object of this type can be targeted.
function PlayerTargeter:addTargetType(targetKey, targetMask, minDistance, maxDistance)

    --#debug Assert.isNilOrType(minDistance, "number", "Minimum distance must be a number or nil!")
    --#debug Assert.isType(maxDistance, "number", "Maximum distance must be a number!")

    -- Check that the key is not already being targeted.
    if self:getHasTargetedKey(targetKey) then
        return
    end

    -- Set the highest max distance of the ray based on the given distance and the current max.
    self.highestMaxDistance = math.max(self.highestMaxDistance, maxDistance)

    -- Create the targeted mask table.
    self.targetedMasks[targetKey] = { key = targetKey, mask = targetMask, minDistance = minDistance or 0, maxDistance = maxDistance, filterFunctions = {}}

    -- Recalculate the combined mask to use for the ray.
    self:recalculateCombinedTargetMask()
end


---Adds the given filter function to the given target type.
-- @param any targetKey The key of the objects to target.
-- @param function filterFunction A function that is called for each raycast object that matches the mask and helps filter out unwanted items. bool function(hitObject, x, y, z)
function PlayerTargeter:addFilterToTargetType(targetKey, filterFunction)

    --#debug Assert.isType(filterFunction, "function", "Filter function must be a function!")
    --#debug Assert.isTrue(self:getHasTargetedKey(targetKey), "Cannot add filter function to key that does not exist!")

    -- Get the mask for the given target.
    local targetedMask = self.targetedMasks[targetKey]
    table.insert(targetedMask.filterFunctions, filterFunction)
end


---Removes the given target type from this targeter.
-- @param any targetKey The key of the objects to stop targeting.
function PlayerTargeter:removeTargetType(targetKey)

    -- Remove the target from the collection.
    self.targetedMasks[targetKey] = nil

    -- Recalculate the combined target mask and maximum distance.
    self:recalculateCombinedTargetMask()
    self.highestMaxDistance = 0
    for _, targetedMask in pairs(self.targetedMasks) do
        self.highestMaxDistance = math.max(self.highestMaxDistance, targetedMask.maxDistance)
    end
end


---Resets and recalculates the combined target mask using all targeted masks.
function PlayerTargeter:recalculateCombinedTargetMask()
    self.combinedTargetMask = 0
    for _, targetedMask in pairs(self.targetedMasks) do
        self.combinedTargetMask = bitOR(self.combinedTargetMask, targetedMask.mask)
    end
end


---Gets the last found node from the given target mask, or nil if none was found.
-- @param any targetKey The key of the objects to stop targeting.
-- @return entityId? node The last found node from the given target mask, or nil if none was found.
function PlayerTargeter:getClosestTargetedNodeFromType(targetKey)
    local closestTarget = self.closestTargetsByKey[targetKey]
    return closestTarget ~= nil and closestTarget.node or nil
end


---Updates the targeter to find targeted objects.
-- @param float dt Delta time in ms.
function PlayerTargeter:update(dt)
    -- Get the position and direction from the player's camera, do nothing if it was invalid.
    self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ = self.player:getLookRay()
    if self.lastRayX == nil then
        return
    end

    self:resetState()

    -- Cast the ray.
    raycastAllAsync(self.lastRayX, self.lastRayY, self.lastRayZ, self.lastRayDirectionX, self.lastRayDirectionY, self.lastRayDirectionZ, self.highestMaxDistance, "raycastCallback", self, self.combinedTargetMask)
end

























---Attempts to add the given information to the given target mask's target.
-- @param entityId hitNode The node that was hit.
-- @param float x The hit x position.
-- @param float y The hit y position.
-- @param float z The hit z position.
-- @param table targetedMask The targeted mask table to attempt to add to.
-- @param float distance The distance of the ray.
function PlayerTargeter:tryAddTargetWithMask(hitNode, x, y, z, targetedMask, distance)

    -- If the distance is greater than the max distance or the hit node does not have the right mask, do nothing.
    if distance > targetedMask.maxDistance or distance < targetedMask.minDistance or not CollisionFlag.getHasGroupFlagSet(hitNode, targetedMask.mask) then
        return
    end

    -- If the ray already hit something with this mask that's closer, check the distances. If the hit object is further away than the existing one, do nothing.
    local existingClosestTarget = self.currentTargetsByKey[targetedMask.key]
    if existingClosestTarget ~= nil and existingClosestTarget.distance < distance then
        return
    end

    -- If the any of the filter functions from the targeted mask returns false; do nothing.
    for i, filterFunction in ipairs(targetedMask.filterFunctions) do
        if not filterFunction(hitNode, x, y, z) then
            return
        end
    end

    -- Set the closest target of the mask to the hit node.
    local target = self.pooledTargets:getOrCreateNext()
    target.x, target.y, target.z = x, y, z
    target.node = hitNode
    target.distance = distance
    self.currentTargetsByKey[targetedMask.key] = target
end


---Displays the debug information.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
-- @return float y The y position on the screen after the entire debug info was drawn.
function PlayerTargeter:debugDraw(x, y, textSize)

    -- Render the header.
    y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Targeter", nil, true)

    local combinedMaskName = CollisionFlag.getFlagsStringFromMask(self.combinedTargetMask)
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Combined mask: %q", combinedMaskName), nil, true)
    y = DebugUtil.renderTextLine(x, y, textSize, "Masks:", nil, true)

    for key, targetedMask in pairs(self.targetedMasks) do
        local maskNode = self:getClosestTargetedNodeFromType(key)
        local nodeName = (maskNode ~= nil and entityExists(maskNode)) and getName(maskNode) or "none"

        local maskName = CollisionFlag.getFlagsStringFromMask(targetedMask.mask)

        y = DebugUtil.renderTextLine(x, y, textSize, string.format("Mask %q: %q", maskName, nodeName))
    end

    return y
end
