












---
local MountableObject_mt = Class(MountableObject, PhysicsObject)

























































































































































































































































































































---Updates the dynamic mount joint force limit dynamically based on how many objects are stacked on top of each
function MountableObject:updateDynamicMountJointForceLimit(dt)
    if not self.forceLimitUpdate.raycastActive then
        self.forceLimitUpdate.timer = self.forceLimitUpdate.timer - dt
        if self.forceLimitUpdate.timer <= 0 then
            self.forceLimitUpdate.raycastActive = true
            self.forceLimitUpdate.timer = MountableObject.FORCE_LIMIT_UPDATE_TIME
            self.forceLimitUpdate.lastDistance = 0
            self.forceLimitUpdate.lastObject = nil
            self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance()
            self.forceLimitUpdate.additionalMass = 0

            local x, y, z = getWorldTranslation(self.nodeId)
            raycastAllAsync(x, y, z, 0, 1, 0, MountableObject.FORCE_LIMIT_RAYCAST_DISTANCE, "additionalMountingMassRaycastCallback", self, CollisionFlag.DYNAMIC_OBJECT)
        end
    end
end


---Empty function to no break compatibility
function MountableObject:getAdditionalMountingMass()
    return 0
end


---Callback used when raycast hits an object.
-- @param integer hitObjectId scenegraph object id
-- @param float x world x hit position
-- @param float y world y hit position
-- @param float z world z hit position
-- @param float distance distance at which the cast hit the object
-- @param float nx normal x direction
-- @param float ny normal y direction
-- @param float nz normal z direction
-- @param integer subShapeIndex sub shape index
-- @param integer shapeId id of shape
-- @param boolean isLast is last hit
-- @return boolean return false to stop raycast
function MountableObject:additionalMountingMassRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    if g_currentMission == nil then
        return
    end

    self.forceLimitUpdate.raycastActive = false

    local object = g_currentMission.nodeToObject[hitObjectId]
    if object ~= self and object ~= nil and object:isa(MountableObject) and self.getAdditionalMountingDistance ~= nil then
        if object ~= self.forceLimitUpdate.lastObject then
            local offset = distance - self.forceLimitUpdate.lastDistance
            if math.abs(offset - self.forceLimitUpdate.nextMountingDistance) < 0.25 then
                self.forceLimitUpdate.lastDistance = distance
                self.forceLimitUpdate.nextMountingDistance = self:getAdditionalMountingDistance() * 2
                self.forceLimitUpdate.additionalMass = self.forceLimitUpdate.additionalMass + object:getMass()
                self.forceLimitUpdate.lastObject = object
            end
        end
    end

    if isLast then
        if self.dynamicMountJointIndex ~= nil then
            local massFactor = (self.forceLimitUpdate.additionalMass + self.mountBaseMass) / self.mountBaseMass
            local forceAcceleration = self.mountBaseForceAcceleration * massFactor
            local forceLimit = self.mountBaseMass * forceAcceleration
            setJointLinearDrive(self.dynamicMountJointIndex, 2, false, true, 0, 0, forceLimit, 0, 0)
        end
    end

    return true
end























---Set world pose
-- @param float x x position
-- @param float y z position
-- @param float z z position
-- @param float xRot x rotation
-- @param float yRot y rotation
-- @param float zRot z rotation
-- @param float w_rot w rotation
function MountableObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    if not self.isServer then
        if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_KINEMATIC and self.dynamicMountType ~= MountableObject.MOUNT_TYPE_DEFAULT then
            MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
        end
    else
        MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    end
end
