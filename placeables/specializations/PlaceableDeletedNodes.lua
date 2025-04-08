














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableDeletedNodes.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableDeletedNodes.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoadFinished", PlaceableDeletedNodes)
end


---
function PlaceableDeletedNodes.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("DeletedNodes")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".deletedNodes.deletedNode(?)#node", "The node that should be deleted")
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableDeletedNodes:onLoadFinished(savegame)

    if self.xmlFile == nil then
        return
    end

    if self.xmlFile:getNumOfElements("placeable.deletedNodes.deletedNode") == 0 then
        return
    end

    local nodes = {}

    -- get set of all bones of the placeable to check against
    local bones = {}
    I3DUtil.iterateRecursively(self.rootNode, function(node)
        if getHasClassId(node, ClassIds.SHAPE) and getShapeIsSkinned(node) then
            local numBones = getNumOfShapeBones(node)
            for boneIndex = 0, numBones - 1 do
                local bone = getShapeBone(node, boneIndex)
                bones[bone] = node  -- keep skinned node ref for printing error
            end
        end
    end)

    -- create list of nodes to delete, filter out any bones to avoid deleting those resulting in a crash
    for _, deletedNodeKey in self.xmlFile:iterator("placeable.deletedNodes.deletedNode") do
        local node = self.xmlFile:getValue(deletedNodeKey .. "#node", nil, self.components, self.i3dMappings)
        if node == nil then
            continue
        end
        -- check if the deletedNode is a bone of a skinned mesh, unless it is the skinned mesh itself
        if bones[node] ~= nil and bones[node] ~= node then
            Logging.xmlWarning(self.xmlFile, "DeleteNode %q at %q is a bone of the skinned mesh %q and cannot be deleted on its own, ignoring", getName(node), deletedNodeKey, getName(bones[node]))
            continue
        end

        table.insert(nodes, node)
    end

    -- loop over node again and delete them to avoid conflicts with index paths
    for _, node in ipairs(nodes) do
        delete(node)
    end
end
