

---
local PhysicsObject_mt = Class(PhysicsObject, Object)






---Creating physics object
-- @param boolean isServer is server
-- @param boolean isClient is client
-- @param table? customMt customMt
-- @return table instance Instance of object
function PhysicsObject.new(isServer, isClient, customMt)

    local self = Object.new(isServer, isClient, customMt or PhysicsObject_mt)

    self.nodeId = 0
    self.networkTimeInterpolator = InterpolationTime.new(1.2)
    self.forcedClipDistance = 60

    self.physicsObjectDirtyFlag = self:getNextDirtyFlag()
    self.isDeleted = false

    return self
end


---Deleting physics object
function PhysicsObject:delete()
    if self.nodeId ~= 0 then
        self:removeChildrenFromNodeObject(self.nodeId)
        delete(self.nodeId)
    end

    self.nodeId = 0

    self.isDeleted = true

    PhysicsObject:superClass().delete(self)
end


---Get allows auto delete
-- @return boolean allowsAutoDelete allows auto delete
function PhysicsObject:getAllowsAutoDelete()
    return true
end


---Load on create
-- @param integer nodeId node id
function PhysicsObject:loadOnCreate(nodeId)
    self:setNodeId(nodeId)
    if not self.isServer then
        self:onGhostRemove()
    end
end


---Set node id
-- @param integer nodeId node Id
function PhysicsObject:setNodeId(nodeId)
    self.nodeId = nodeId
    setRigidBodyType(self.nodeId, self:getDefaultRigidBodyType())
    addToPhysics(self.nodeId)

    local x, y, z = getTranslation(self.nodeId)
    local xRot, yRot, zRot = getRotation(self.nodeId)
    self.sendPosX, self.sendPosY, self.sendPosZ = x, y, z
    self.sendRotX, self.sendRotY, self.sendRotZ = xRot, yRot, zRot

    if not self.isServer then
        local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot, yRot, zRot)
        self.positionInterpolator = InterpolatorPosition.new(x, y, z)
        self.quaternionInterpolator = InterpolatorQuaternion.new(quatX, quatY, quatZ, quatW)
    end

    self:addChildenToNodeObject(self.nodeId)
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function PhysicsObject:readStream(streamId, connection, objectId)
    PhysicsObject:superClass().readStream(self, streamId, connection, objectId)

    assert(self.nodeId ~= 0)
    if connection:getIsServer() then
        local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
        local paramsY = g_currentMission.vehicleYPosCompressionParams
        local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
        local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local xRot = NetworkUtil.readCompressedAngle(streamId)
        local yRot = NetworkUtil.readCompressedAngle(streamId)
        local zRot = NetworkUtil.readCompressedAngle(streamId)

        local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot,yRot,zRot)
        self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)

        self.networkTimeInterpolator:reset()
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function PhysicsObject:writeStream(streamId, connection)
    PhysicsObject:superClass().writeStream(self, streamId, connection)

    if not connection:getIsServer() then
        local x,y,z = getWorldTranslation(self.nodeId)
        local xRot,yRot,zRot = getWorldRotation(self.nodeId)
        local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
        local paramsY = g_currentMission.vehicleYPosCompressionParams
        NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
        NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
        NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
        NetworkUtil.writeCompressedAngle(streamId, xRot)
        NetworkUtil.writeCompressedAngle(streamId, yRot)
        NetworkUtil.writeCompressedAngle(streamId, zRot)
    end
end


---Called on client side on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function PhysicsObject:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
            local paramsY = g_currentMission.vehicleYPosCompressionParams
            local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
            local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
            local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
            local xRot = NetworkUtil.readCompressedAngle(streamId)
            local yRot = NetworkUtil.readCompressedAngle(streamId)
            local zRot = NetworkUtil.readCompressedAngle(streamId)

            local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(xRot,yRot,zRot)
            self.positionInterpolator:setTargetPosition(x, y, z)
            self.quaternionInterpolator:setTargetQuaternion(quatX, quatY, quatZ, quatW)
            self.networkTimeInterpolator:startNewPhaseNetwork()
        end
    end
end


---Called on server side on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function PhysicsObject:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.physicsObjectDirtyFlag) ~= 0) then
            local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
            local paramsY = g_currentMission.vehicleYPosCompressionParams
            NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosX, paramsXZ)
            NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosY, paramsY)
            NetworkUtil.writeCompressedWorldPosition(streamId, self.sendPosZ, paramsXZ)

            NetworkUtil.writeCompressedAngle(streamId, self.sendRotX)
            NetworkUtil.writeCompressedAngle(streamId, self.sendRotY)
            NetworkUtil.writeCompressedAngle(streamId, self.sendRotZ)
        end
    end
end


---Update
-- @param float dt time since last call in ms
function PhysicsObject:update(dt)
    if not self.isServer then
        self.networkTimeInterpolator:update(dt)
        local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
        local posX, posY, posZ = self.positionInterpolator:getInterpolatedValues(interpolationAlpha)
        local quatX, quatY, quatZ, quatW = self.quaternionInterpolator:getInterpolatedValues(interpolationAlpha)
        self:setWorldPositionQuaternion(posX, posY, posZ, quatX, quatY, quatZ, quatW, false)

        if self.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    else
        if not getIsSleeping(self.nodeId) then
            self:raiseActive()
        end
    end
end



---Update move
-- @return boolean hasMoved has moved
function PhysicsObject:updateMove()
    local x, y, z = getWorldTranslation(self.nodeId)
    local xRot, yRot, zRot = getWorldRotation(self.nodeId)
    local hasMoved = math.abs(self.sendPosX-x)>0.005 or math.abs(self.sendPosY-y)>0.005 or math.abs(self.sendPosZ-z)>0.005 or
                     math.abs(self.sendRotX-xRot)>0.02 or math.abs(self.sendRotY-yRot)>0.02 or math.abs(self.sendRotZ-zRot)>0.02

    if hasMoved then
        self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
        self.sendPosX, self.sendPosY, self.sendPosZ = x, y ,z
        self.sendRotX, self.sendRotY, self.sendRotZ = xRot, yRot, zRot
    end

    return hasMoved
end


---updateTick
-- @param float dt time since last call in ms
function PhysicsObject:updateTick(dt)
    if self.isServer then
        self:updateMove()
    end
end


---Test scope
-- @param float x x position
-- @param float y y position
-- @param float z z position
-- @param float coeff coeff
-- @return boolean inScope in scope
function PhysicsObject:testScope(x,y,z, coeff)
    local x1, y1, z1 = getWorldTranslation(self.nodeId)
    local dist =  (x1-x)*(x1-x) + (y1-y)*(y1-y) + (z1-z)*(z1-z)
    local clipDist = math.min(getClipDistance(self.nodeId)*coeff, self.forcedClipDistance)
    if dist < clipDist*clipDist then
        return true
    else
        return false
    end
end


---Get update priority
-- @param float skipCount skip count
-- @param float x x position
-- @param float y y position
-- @param float z z position
-- @param float coeff coeff
-- @param table connection connection
-- @return float priority priority
function PhysicsObject:getUpdatePriority(skipCount, x, y, z, coeff, connection, isGuiVisible)
    local x1, y1, z1 = getWorldTranslation(self.nodeId)
    local dist = math.sqrt((x1-x)*(x1-x) + (y1-y)*(y1-y) + (z1-z)*(z1-z))
    local clipDist = math.min(getClipDistance(self.nodeId)*coeff, self.forcedClipDistance)
    return (1-dist/clipDist)* 0.8 + 0.5*skipCount * 0.2
end


---On ghost remove
function PhysicsObject:onGhostRemove()
    setVisibility(self.nodeId, false)
    removeFromPhysics(self.nodeId)
end


---On ghost add
function PhysicsObject:onGhostAdd()
    setVisibility(self.nodeId, true)
    addToPhysics(self.nodeId)
end


---Wake of the physics of the object
function PhysicsObject:wakeUp()
    I3DUtil.wakeUpObject(self.nodeId)
end










---Set world pose
-- @param float x x position
-- @param float y z position
-- @param float z z position
-- @param float xRot x rotation
-- @param float yRot y rotation
-- @param float zRot z rotation
-- @param float w_rot w rotation
function PhysicsObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    setWorldTranslation(self.nodeId, x, y, z)
    setWorldQuaternion(self.nodeId, quatX, quatY, quatZ, quatW)

    if changeInterp then
        if not self.isServer then
            self.positionInterpolator:setPosition(x, y, z)
            self.quaternionInterpolator:setQuaternion(quatX, quatY, quatZ, quatW)
        else
            self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
            self.sendPosX, self.sendPosY, self.sendPosZ = x, y ,z
            self.sendRotX, self.sendRotY, self.sendRotZ = getWorldRotation(self.nodeId)
        end
    end
end


---Set local pose
-- @param float x x position
-- @param float y z position
-- @param float z z position
-- @param float xRot x rotation
-- @param float yRot y rotation
-- @param float zRot z rotation
-- @param float w_rot w rotation
function PhysicsObject:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
    setTranslation(self.nodeId, x, y, z)
    setQuaternion(self.nodeId, quatX, quatY, quatZ, quatW)

    if changeInterp then
        if not self.isServer then
            self.positionInterpolator:setPosition(getWorldTranslation(self.nodeId))
            self.quaternionInterpolator:setQuaternion(getWorldQuaternion(self.nodeId))
        else
            self:raiseDirtyFlags(self.physicsObjectDirtyFlag)
            self.sendPosX, self.sendPosY, self.sendPosZ = getWorldTranslation(self.nodeId)
            self.sendRotX, self.sendRotY, self.sendRotZ = getWorldRotation(self.nodeId)
        end
    end
end



---Get default rigid body type
-- @return string rigidBodyType rigid body type
function PhysicsObject:getDefaultRigidBodyType()
    if self.isServer then
        return RigidBodyType.DYNAMIC
    else
        return RigidBodyType.KINEMATIC
    end
end

















---Add node and its children to node object mapping
-- @param integer nodeId id of node
function PhysicsObject:addChildenToNodeObject(nodeId)
    for i=0,getNumOfChildren(nodeId)-1 do
        self:addChildenToNodeObject(getChildAt(nodeId, i))
    end

    local rigidBodyType = getRigidBodyType(nodeId)
    if rigidBodyType ~= RigidBodyType.NONE then
        g_currentMission:addNodeObject(nodeId, self)

        if self.isServer then
            addWakeUpReport(nodeId, "onPhysicObjectWakeUpCallback", self)
        end
    end
end
