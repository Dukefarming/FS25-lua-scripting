


---
local ForestryLog_mt = Class(ForestryLog, MountableObject)




















---Creating bale object
-- @param boolean isServer is server
-- @param boolean isClient is client
-- @param table? customMt customMt
-- @return table instance Instance of object
function ForestryLog.new(isServer, isClient, customMt)
    local self = MountableObject.new(isServer, isClient, customMt or ForestryLog_mt)

    registerObjectClassName(self, "ForestryLog")

    self.uniqueId = nil

    return self
end


---Deleting bale object
function ForestryLog:delete()
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end

    self:setForestryLogAIObstacle(false)

    unregisterObjectClassName(self)
    g_currentMission.itemSystem:removeItem(self)
    ForestryLog:superClass().delete(self)
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function ForestryLog:readStream(streamId, connection)
    local i3dFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    if self.nodeId == 0 then
        self:loadFromFilename(i3dFilename)
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function ForestryLog:writeStream(streamId, connection)
    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.i3dFilename))
end


---Load bale from bale XML
-- @param string i3dFilename xml file name
-- @param float x x world position
-- @param float y z world position
-- @param float z z world position
-- @param float rx rx world rotation
-- @param float ry ry world rotation
-- @param float rz rz world rotation
function ForestryLog:loadFromFilename(i3dFilename, x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments)
    if i3dFilename == nil then
        return false
    end

    i3dFilename = NetworkUtil.convertFromNetworkFilename(i3dFilename)
    if not fileExists(i3dFilename) then
        return false
    end

    self.i3dFilename = i3dFilename
    if self.i3dFilename ~= nil then
        self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.i3dFilename)

        setSplitShapesLoadingFileId(-1)
        setSplitShapesNextFileId(true)
        self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, true, self.onForestryLogLoaded, self, {x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments})
    else
        return false
    end

    return true
end


---Called when i3d file has been loaded
function ForestryLog:onForestryLogLoaded(nodeId, failedReason, asyncCallbackArguments)
    local x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments = asyncCallbackArguments[1], asyncCallbackArguments[2], asyncCallbackArguments[3], asyncCallbackArguments[4], asyncCallbackArguments[5], asyncCallbackArguments[6], asyncCallbackArguments[7], asyncCallbackArguments[8], asyncCallbackArguments[9]

    if failedReason == LoadI3DFailedReason.NONE then
        local numChildren = getNumOfChildren(nodeId)
        local nodeIndex = math.random(0, numChildren-1)
        local curNodeId = clone(getChildAt(nodeId, nodeIndex), false, false, true)
        link(getRootNode(), curNodeId)

        if x ~= nil and y ~= nil and z ~= nil and rx ~= nil and ry ~= nil and rz ~= nil then
            setTranslation(curNodeId, x, y, z)
            setRotation(curNodeId, rx, ry, rz)
        end

        self:setNodeId(curNodeId)
        self.tensionBeltMeshes = {}

        g_currentMission.itemSystem:addItem(self)
        self:setForestryLogAIObstacle(true)

        delete(nodeId)

        if asyncCallback ~= nil then
            asyncCallback(asyncTarget, self, true, asyncArguments)
            return
        end
    end

    if asyncCallback ~= nil then
        asyncCallback(asyncTarget, self, false, asyncArguments)
        return
    end
end


---Loading from attributes and nodes
-- @param integer xmlFile id of xml object
-- @param string key key
-- @param boolean resetVehicles reset vehicles
-- @return boolean success success
function ForestryLog:loadAsyncFromXMLFile(xmlFile, key, resetVehicles, asyncCallback, asyncTarget, asyncArguments)
    local x, y, z = xmlFile:getValue(key.."#position")
    local rx, ry, rz = xmlFile:getValue(key.."#rotation")
    if x == nil or y == nil or z == nil or rx == nil or ry == nil or rz == nil then
        return asyncCallback(asyncTarget, self, false, asyncArguments)
    end

    self:setUniqueId(xmlFile:getValue(key .. "#uniqueId", nil))

    local i3dFilename = xmlFile:getValue(key.."#filename")
    if not self:loadFromFilename(i3dFilename, x, y, z, rx, ry, rz, asyncCallback, asyncTarget, asyncArguments) then
        return asyncCallback(asyncTarget, self, false, asyncArguments)
    end

    return
end


---
function ForestryLog:saveToXMLFile(xmlFile, key)
    local x, y, z = getTranslation(self.nodeId)
    local xRot, yRot, zRot = getRotation(self.nodeId)

    xmlFile:setValue(key.."#uniqueId", self.uniqueId)
    xmlFile:setValue(key.."#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.i3dFilename)))
    xmlFile:setValue(key.."#position", x, y, z)
    xmlFile:setValue(key.."#rotation", xRot, yRot, zRot)
    xmlFile:setValue(key.."#farmId", self:getOwnerFarmId())
end


---Mount bale to object
-- @param table object target object
-- @param integer node target node id
-- @param float x x position
-- @param float y z position
-- @param float z z position
-- @param float rx rx rotation
-- @param float ry ry rotation
-- @param float rz rz rotation
function ForestryLog:mount(object, node, x,y,z, rx,ry,rz)
    ForestryLog:superClass().mount(self, object, node, x,y,z, rx,ry,rz)
    g_currentMission.itemSystem:removeItem(self)
    self:setForestryLogAIObstacle(false)
end


---Unmount bale
function ForestryLog:unmount()
    if ForestryLog:superClass().unmount(self) then
        g_currentMission.itemSystem:addItem(self)
        self:setForestryLogAIObstacle(true)
        return true
    end
    return false
end


---Mount bale to object kinematic
-- @param table object target object
-- @param integer node target node id
-- @param float x x position
-- @param float y z position
-- @param float z z position
-- @param float rx rx rotation
-- @param float ry ry rotation
-- @param float rz rz rotation
function ForestryLog:mountKinematic(object, node, x,y,z, rx,ry,rz)
    ForestryLog:superClass().mountKinematic(self, object, node, x,y,z, rx,ry,rz)
    g_currentMission.itemSystem:removeItem(self)
    self:setForestryLogAIObstacle(false)
end


---Unmount bale kinematic
function ForestryLog:unmountKinematic()
    if ForestryLog:superClass().unmountKinematic(self) then
        g_currentMission.itemSystem:addItem(self)
        self:setForestryLogAIObstacle(true)
        return true
    end
    return false
end


---
function ForestryLog:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
    ForestryLog:superClass().mountDynamic(self, object, objectActorId, jointNode, mountType, forceAcceleration)
    self:setForestryLogAIObstacle(false)
end


---
function ForestryLog:unmountDynamic(isDelete)
    ForestryLog:superClass().unmountDynamic(self, isDelete)
    self:setForestryLogAIObstacle(true)
end


---
function ForestryLog:setForestryLogAIObstacle(isActive)
    if isActive and self.obstacleNodeId == nil then
        g_currentMission.aiSystem:addObstacle(self.nodeId, nil, nil, nil, nil, nil, nil, nil)
        self.obstacleNodeId = self.nodeId
    elseif not isActive and self.obstacleNodeId ~= nil then
        g_currentMission.aiSystem:removeObstacle(self.obstacleNodeId)
        self.obstacleNodeId = nil
    end
end


---
function ForestryLog:getMeshNodes()
    return self.tensionBeltMeshes
end


---
function ForestryLog:getSupportsTensionBelts()
    return true
end


---
function ForestryLog:getAllowPickup()
    return false
end


---Get default rigid body type
-- @return string rigidBodyType rigid body type
function ForestryLog:getDefaultRigidBodyType()
    return RigidBodyType.KINEMATIC
end
