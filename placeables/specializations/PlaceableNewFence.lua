













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableNewFence.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableNewFence.registerEvents(placeableType)
    SpecializationUtil.registerEvent(placeableType, "onCreateSegment")
end


---
function PlaceableNewFence.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getFence", PlaceableNewFence.getFence)
    SpecializationUtil.registerFunction(placeableType, "onSegmentCreated", PlaceableNewFence.onSegmentCreated)
    SpecializationUtil.registerFunction(placeableType, "getNumSequments", PlaceableNewFence.getNumSequments)
    SpecializationUtil.registerFunction(placeableType, "getPanelLength", PlaceableNewFence.getPanelLength)
    SpecializationUtil.registerFunction(placeableType, "getIsPanelLengthFixed", PlaceableNewFence.getIsPanelLengthFixed)
    SpecializationUtil.registerFunction(placeableType, "updateDirtyAreas", PlaceableNewFence.updateDirtyAreas)
    SpecializationUtil.registerFunction(placeableType, "getSupportsParallelSnapping", PlaceableNewFence.getSupportsParallelSnapping)
    SpecializationUtil.registerFunction(placeableType, "getSnapDistance", PlaceableNewFence.getSnapDistance)
    SpecializationUtil.registerFunction(placeableType, "getSnapAngle", PlaceableNewFence.getSnapAngle)
    SpecializationUtil.registerFunction(placeableType, "getSnapCheckDistance", PlaceableNewFence.getSnapCheckDistance)
    SpecializationUtil.registerFunction(placeableType, "getAllowExtendingOnly", PlaceableNewFence.getAllowExtendingOnly)
    SpecializationUtil.registerFunction(placeableType, "getMaxCornerAngle", PlaceableNewFence.getMaxCornerAngle)
    SpecializationUtil.registerFunction(placeableType, "getHasParallelSnapping", PlaceableNewFence.getHasParallelSnapping)
end


---
function PlaceableNewFence.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getIsOnFarmland", PlaceableNewFence.getIsOnFarmland)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableNewFence.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getDestructionMethod", PlaceableNewFence.getDestructionMethod)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "performNodeDestruction", PlaceableNewFence.performNodeDestruction)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "previewNodeDestructionNodes", PlaceableNewFence.previewNodeDestructionNodes)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableNewFence.setOwnerFarmId)
end


---
function PlaceableNewFence.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableNewFence)
    SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableNewFence)
end


---
function PlaceableNewFence.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    Fence.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end


---
function PlaceableNewFence.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Fence")
    Fence.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableNewFence:onLoad(savegame)
    local spec = self.spec_newFence
    local xmlFile = self.xmlFile

    local i3dFilename = xmlFile:getValue("placeable.base.filename")
    if string.isNilOrWhitespace(i3dFilename) then
        Logging.xmlError(xmlFile, "Unable to load fence, no i3d filename given at 'placeable.base.filename'!")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    end
    i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
    spec.fence = Fence.new(xmlFile, "placeable.fence", i3dFilename, self.components, self.i3dMappings, self)

    if not spec.fence:load(xmlFile, "placeable.fence") then
        Logging.xmlError(xmlFile, "Unable to load fence!")
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    end
end


---
function PlaceableNewFence:onDelete()
    local spec = self.spec_newFence

    if spec.fence ~= nil then
        spec.fence:delete()
        spec.fence = nil
    end
end


---
function PlaceableNewFence:onReadStream(streamId, connection)
    local spec = self.spec_newFence

    spec.fence:readStream(streamId, connection)
end


---
function PlaceableNewFence:onWriteStream(streamId, connection)
    local spec = self.spec_newFence

    spec.fence:writeStream(streamId, connection)
end


---
function PlaceableNewFence:onUpdate(dt)
    local spec = self.spec_newFence
    spec.fence:update(dt)
end






---
function PlaceableNewFence:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
    local spec = self.spec_newFence

    superFunc(self, ownerFarmId, noEventSend)

    if spec.fence ~= nil then
        spec.fence:setOwnerFarmId(ownerFarmId, noEventSend)
    end
end


---
function PlaceableNewFence:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_newFence

    spec.fence:loadFromXMLFile(xmlFile, key)
end



---
function PlaceableNewFence:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_newFence

    spec.fence:saveToXMLFile(xmlFile, key, usedModNames)
end












---Get the length of a segment
function PlaceableNewFence:getSegmentLength(segment)
    return MathUtil.getPointPointDistance(segment.x1, segment.z1, segment.x2, segment.z2)
end


---
function PlaceableNewFence:getPanelLength()
    return self.spec_newFence.panelLength
end


---
function PlaceableNewFence:getIsPanelLengthFixed()
    return self.spec_newFence.panelLengthFixed
end


---Sets collision map and AI navigationmap dirty for AABB of given line
function PlaceableNewFence:updateDirtyAreas(x1, z1, x2, z2)
    local minX = math.min(x1, x2)
    local maxX = math.max(x1, x2)
    local minZ = math.min(z1, z2)
    local maxZ = math.max(z1, z2)

    g_densityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, true)
    g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
end


---
function PlaceableNewFence:getNumSequments()
    local spec = self.spec_newFence
    return spec.fence:getNumSegments()
end


---
function PlaceableNewFence:getMaxVerticalAngle()
    local spec = self.spec_newFence
    return spec.maxVerticalAngle
end


---
function PlaceableNewFence:getMaxVerticalGateAngle()
    local spec = self.spec_newFence
    return spec.maxVerticalGateAngle
end


---
function PlaceableNewFence:getSnapDistance()
    return self.spec_newFence.snapDistance
end






---
function PlaceableNewFence:getSnapCheckDistance()
    return self.spec_newFence.snapCheckDistance
end


---
function PlaceableNewFence:getAllowExtendingOnly()
    return self.spec_newFence.allowExtendingOnly
end


---
function PlaceableNewFence:getMaxCornerAngle()
    return self.spec_newFence.maxCornerAngle
end


---
function PlaceableNewFence:getHasParallelSnapping()
    return false
end


---
function PlaceableNewFence:getSupportsParallelSnapping()
    return false
--     return self.spec_newFence.supportsParallelSnapping
end


---
function PlaceableNewFence:addPickingNodesForSegment(segment)
    if segment == self.spec_newFence.previewSegment then
        return
    end

    if segment.group ~= nil then
        local objects = {}
        self:recursivelyAddPickingNodes(objects, segment.group)

        for i = 1, #objects do
            g_currentMission:addNodeObject(objects[i], self)
        end
    end

    -- Reset
    self.overlayColorNodes = nil
end


---
function PlaceableNewFence:removePickingNodesForSegment(segment)
    if segment == self.spec_newFence.previewSegment then
        return
    end

    if segment.group ~= nil then
        local objects = {}
        self:recursivelyAddPickingNodes(objects, segment.group)

        for i = 1, #objects do
            g_currentMission:removeNodeObject(objects[i])
        end
    end
end


---
function PlaceableNewFence:recursivelyAddPickingNodes(objects, node)
    if getRigidBodyType(node) ~= RigidBodyType.NONE then
        table.insert(objects, node)
    end

    local numChildren = getNumOfChildren(node)
    for i=1, numChildren do
        self:recursivelyAddPickingNodes(objects, getChildAt(node, i-1))
    end
end


---Deletion is in pieces so not instantly
function PlaceableNewFence:getDestructionMethod(superFunc)
    return Placeable.DESTRUCTION.PER_NODE
end


---
function PlaceableNewFence:previewNodeDestructionNodes(superFunc, node)
    return self:getNodesToDeleteForPanel(node)
end


---
function PlaceableNewFence:performNodeDestruction(superFunc, node)
    local destroyedNode = self:deletePanel(node)
    local destroyPlaceable = self:getNumSequments() == 0
    return destroyedNode, destroyPlaceable
end


---
function PlaceableNewFence:collectPickObjects(superFunc, node)
    ---Default picking objects is disabled
end
