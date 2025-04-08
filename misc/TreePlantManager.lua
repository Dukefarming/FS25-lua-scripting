




















---
local TreePlantManager_mt = Class(TreePlantManager, AbstractManager)








---
function TreePlantManager.new(customMt)
    local self = AbstractManager.new(customMt or TreePlantManager_mt)

    return self
end


---
function TreePlantManager:initDataStructures()
    self.treeTypes = {}
    self.indexToTreeType = {}
    self.splitTypeIndexToTreeType = {}
    self.nameToTreeType = {}
    self.treeFileCache = {}

    self.loadTreeTrunkDatas = {}

    self.numTreesWithoutSplits = 0

    self.activeDecayingSplitShapes = {}
    self.updateDecayDtGame = 0
end


---
function TreePlantManager:initialize()
    local rootNode = createTransformGroup("trees")
    link(getRootNode(), rootNode)

    self.treesData = {}
    self.treesData.rootNode = rootNode
    self.treesData.growingTrees = {}
    self.treesData.splitTrees = {}
    self.treesData.clientTrees = {}
    self.treesData.updateDtGame = 0
    self.treesData.treeCutJoints = {}
    self.treesData.numTreesWithoutSplits = 0
end


---
function TreePlantManager:deleteTreesData()
    if self.treesData ~= nil then
        delete(self.treesData.rootNode)
        self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - self.treesData.numTreesWithoutSplits, 0)
        self:initDataStructures()
    end
end


---
function TreePlantManager:loadDefaultTypes(missionInfo, baseDirectory)
    local xmlFile = loadXMLFile("treeTypes", "data/maps/maps_treeTypes.xml")
    self:loadTreeTypes(xmlFile, missionInfo, baseDirectory, true)
    delete(xmlFile)
end


---Load data on map load
-- @return boolean true if loading was successful else false
function TreePlantManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    TreePlantManager:superClass().loadMapData(self)

    -- server only cheats
    if g_server ~= nil and g_addCheatCommands then
        addConsoleCommand("gsTreeCut", "Cut all trees around a given radius", "consoleCommandCutTrees", self)
        addConsoleCommand("gsTreeAdd", "Load a loose tree trunk", "consoleCommandLoadTree", self, "length; treeType; [growthState]; [delimb]")
        addConsoleCommand("gsTreePlant", "Plant given number of trees of a specified type", "consoleCommandPlantTrees", self, "treeType; number; growthState; variationIndex; isGrowing")
        addConsoleCommand("gsTreeLoadAll", "Spawn all trees in front of player", "consoleCommandLoadAll", self)
    end

    if g_addCheatCommands then
        addConsoleCommand("gsTreeDebug", "Toggle tree/splitshape debug mode", "consoleCommandDebug", self)
    end

    self.maxNumTrees = math.clamp(getXMLInt(xmlFile, "map.treeTypes#maxNumTrees") or 8000, 1, 30000)
    g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, TreePlantManager.onMissionStarted, self)

    self:loadDefaultTypes(missionInfo, baseDirectory)

    return XMLUtil.loadDataFromMapXML(xmlFile, "treeTypes", baseDirectory, self, self.loadTreeTypes, missionInfo, baseDirectory)
end


---
function TreePlantManager:unloadMapData()
    for i3dFilename, requestId in pairs(self.treeFileCache) do
        g_i3DManager:releaseSharedI3DFile(requestId)
        self.treeFileCache[i3dFilename] = true
    end

    removeConsoleCommand("gsTreeCut")
    removeConsoleCommand("gsTreeAdd")
    removeConsoleCommand("gsTreePlant")
    removeConsoleCommand("gsTreeDebug")

    self:deleteTreesData()

    g_messageCenter:unsubscribe(MessageType.CURRENT_MISSION_START, self)

    TreePlantManager:superClass().unloadMapData(self)
end







---
function TreePlantManager:loadTreeTypes(xmlFile, missionInfo, baseDirectory, isBaseType, customEnvironment)
    if type(xmlFile) == "number" then
        xmlFile = XMLFile.wrap(xmlFile)
    end

    for _, treeTypeKey in xmlFile:iterator("map.treeTypes.treeType") do
        local name = xmlFile:getString(treeTypeKey .. "#name")
        local title = xmlFile:getString(treeTypeKey .. "#title")
        local growthTimeHours = xmlFile:getString(treeTypeKey .. "#growthTimeHours")
        local splitTypeName = xmlFile:getString(treeTypeKey .. "#splitType")
        local saplingPrice = xmlFile:getFloat(treeTypeKey .. "#saplingPrice", 0)

        if name == nil then
            Logging.xmlWarning(xmlFile, "Missing 'name' attribute for treeType %q", treeTypeKey)
            continue
        end
        if title == nil then
            Logging.xmlWarning(xmlFile, "Missing 'title' attribute for treeType %q", treeTypeKey)
            continue
        end
        if growthTimeHours == nil then
            Logging.xmlWarning(xmlFile, "Missing 'growthTimeHours' attribute for treeType %q", treeTypeKey)
            continue
        end
        if splitTypeName == nil then
            Logging.xmlWarning(xmlFile, "Missing 'splitType' attribute for treeType %q", treeTypeKey)
            continue
        end

        local splitTypeIndex = g_splitShapeManager:getSplitTypeIndexByName(splitTypeName)
        if splitTypeIndex == nil then
            Logging.xmlWarning(xmlFile, "SplitType '%s' not defined for treeType %q", splitTypeName, treeTypeKey)
            continue
        end

        local stages = {}
        for _, stageKey in xmlFile:iterator(treeTypeKey .. ".stage") do
            local filename = xmlFile:getString(stageKey .. "#filename")
            if filename ~= nil then
                -- single i3d file for this stage
                local variation = {}
                variation.filename = Utils.getFilename(filename, baseDirectory)

                local palletFilename = xmlFile:getString(stageKey .. ".pallet#filename")
                if palletFilename ~= nil then
                    variation.palletFilename = Utils.getFilename(palletFilename, baseDirectory)
                end

                local palletStoreItemFilename = xmlFile:getString(stageKey .. ".pallet#storeItem")
                if palletStoreItemFilename ~= nil then
                    variation.palletStoreItemFilename = Utils.getFilename(palletStoreItemFilename, baseDirectory)
                end

                local planterFilename = xmlFile:getString(stageKey .. ".planter#filename")
                if planterFilename ~= nil then
                    variation.planterFilename = Utils.getFilename(planterFilename, baseDirectory)
                end

                table.insert(stages, {variation})  -- single variation
            else
                -- multiple variations for this stage
                local variations = {}
                for _, variationKey in xmlFile:iterator(stageKey .. ".variation") do
                    filename = xmlFile:getString(variationKey .. "#filename")
                    if filename ~= nil then
                        if #variations >= TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE then
                            Logging.xmlWarning(xmlFile, "Unable to add variation %q for tree %q, max number of variations per stage (%d) reached", filename, name, TreePlantManager.MAX_NUM_VARIATIONS_PER_STAGE)
                            break
                        end

                        local variation = {}
                        variation.name = xmlFile:getString(variationKey .. "#name")
                        variation.filename = Utils.getFilename(filename, baseDirectory)

                        local palletFilename = xmlFile:getString(variationKey .. ".pallet#filename")
                        if palletFilename ~= nil then
                            variation.palletFilename = Utils.getFilename(palletFilename, baseDirectory)
                        end

                        local palletStoreItemFilename = xmlFile:getString(variationKey .. ".pallet#storeItem")
                        if palletStoreItemFilename ~= nil then
                            variation.palletStoreItemFilename = Utils.getFilename(palletStoreItemFilename, baseDirectory)
                        end

                        local planterFilename = xmlFile:getString(variationKey .. ".planter#filename")
                        if planterFilename ~= nil then
                            variation.planterFilename = Utils.getFilename(planterFilename, baseDirectory)
                        end

                        table.insert(variations, variation)
                    end
                end

                if #stages >= TreePlantManager.MAX_NUM_STAGES then
                    Logging.xmlWarning(xmlFile, "Unable to add stage %q for tree %q, max number of stages (%d) reached", stageKey, name, TreePlantManager.MAX_NUM_STAGES)
                    break
                end

                table.insert(stages, variations)
            end
        end
        if #stages == 0 then
            Logging.xmlWarning(xmlFile, "A treetype %q (%s) has no valid stages defined'", name, treeTypeKey)
            continue
        end

        title = g_i18n:convertText(title, customEnvironment)

        self:registerTreeType(name, title, stages, growthTimeHours, isBaseType, splitTypeIndex, saplingPrice)
    end

    return true
end


---
function TreePlantManager:registerTreeType(name, title, stages, growthTimeHours, isBaseType, splitTypeIndex, saplingPrice)
    name = string.upper(name)

    if #self.treeTypes >= TreePlantManager.MAX_NUM_TYPES then
        Logging.warning("Unable to register tree type %q, maximum number of tree types (%d) reached", name, TreePlantManager.MAX_NUM_TYPES)
        return nil
    end

    if isBaseType and self.nameToTreeType[name] ~= nil then
        Logging.warning("TreeType %q already exists. Ignoring treeType!", name)
        return nil
    end

    local treeType = self.nameToTreeType[name]
    if treeType == nil then
        treeType = {}
        treeType.name = name
        treeType.title = title
        treeType.index = #self.treeTypes + 1
        treeType.splitTypeIndex = splitTypeIndex
        table.insert(self.treeTypes, treeType)
        self.indexToTreeType[treeType.index] = treeType
        self.nameToTreeType[name] = treeType
        self.splitTypeIndexToTreeType[splitTypeIndex] = treeType
    end

    treeType.stages = stages
    treeType.growthTimeHours = growthTimeHours
    treeType.saplingPrice = saplingPrice

    return treeType
end


---
function TreePlantManager:getTreeTypeFilename(treeTypeDesc, growthStateI)
    if treeTypeDesc == nil then
        return nil
    end

    local stage = treeTypeDesc.stages[math.min(growthStateI, #treeTypeDesc.stages)]
    local variation = stage[math.random(1, #stage)]
    return variation.filename
end


---
function TreePlantManager:canPlantTree()
    local totalNumSplit, numSplit = getNumOfSplitShapes()
    local numUnsplit = totalNumSplit - numSplit
    return (numUnsplit + self.numTreesWithoutSplits) < self.maxNumTrees
end


---
-- @param integer treeTypeIndex
-- @param float x
-- @param float y
-- @param float z
-- @param float rx
-- @param float ry
-- @param float rz
-- @param integer growthStateI
-- @param integer variationIndex
-- @param boolean? isGrowing
-- @param float? nextGrowthTargetHour
-- @param integer? existingSplitShapeFileId
-- @return entityId? treeId
function TreePlantManager:plantTree(treeTypeIndex, x,y,z, rx,ry,rz, growthStateI, variationIndex, isGrowing, nextGrowthTargetHour, existingSplitShapeFileId)
    local treeTypeDesc = self.indexToTreeType[treeTypeIndex]
    if treeTypeDesc == nil then
        return nil
    end

    local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x,y,z, rx,ry,rz, growthStateI, variationIndex, existingSplitShapeFileId)

    if treeId == 0 then
        return nil
    end

    local treesData = self.treesData

    local tree = {}
    tree.node = treeId
    tree.growthStateI = growthStateI
    tree.variationIndex = variationIndex or 1
    tree.isGrowing = Utils.getNoNil(isGrowing, true) and growthStateI < #treeTypeDesc.stages  -- tree can only grow if not at the last stage already
    tree.x, tree.y, tree.z = x,y,z
    tree.rx, tree.ry, tree.rz = rx,ry,rz
    tree.treeType = treeTypeIndex
    tree.splitShapeFileId = splitShapeFileId
    tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)

    if tree.isGrowing then
        tree.origSplitShape = getChildAt(treeId, 0)

        if nextGrowthTargetHour == nil then
            -- freshly planted, use growth time defined ni tree type
            tree.nextGrowthTargetHour = g_currentMission.environment:getMonotonicHour() + treeTypeDesc.growthTimeHours
        else
            -- tree loaded from savegame, use stored growth target hour
            tree.nextGrowthTargetHour = nextGrowthTargetHour
        end

        table.insert(treesData.growingTrees, tree)
    else
        table.insert(treesData.splitTrees, tree)
    end

    if not tree.hasSplitShapes then
        self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
        treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
    end

    g_server:broadcastEvent(TreePlantEvent.new(treeTypeIndex, x,y,z, rx,ry,rz, growthStateI, tree.variationIndex, splitShapeFileId, tree.isGrowing))

    return treeId
end


---
function TreePlantManager:loadTreeNode(treeTypeDesc, x,y,z, rx,ry,rz, growthStateI, variationIndex, splitShapeLoadingFileId)
    local treesData = self.treesData

    local stage = math.min(growthStateI, #treeTypeDesc.stages)
    local variations = treeTypeDesc.stages[stage]
    if variations == nil then
        Logging.error("TreePlantManager:loadTreeNode failed due to invalid stage index (stage %d of %d)", stage, #treeTypeDesc.stages)
        return 0
    end

    local variation = variations[math.clamp(variationIndex, 1, #variations)]
    local i3dFilename = variation.filename

    if self.treeFileCache[i3dFilename] == nil then
        -- make sure the i3d is loaded, so that the file id will not be used by the i3d clone source
        setSplitShapesLoadingFileId(-1)
        setSplitShapesNextFileId(true)
        local node, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
        if node ~= 0 then
            delete(node)
            self.treeFileCache[i3dFilename] = requestId
        end
    end

    setSplitShapesLoadingFileId(splitShapeLoadingFileId or -1)
    local splitShapeFileId = setSplitShapesNextFileId()

    local treeId, requestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
    g_i3DManager:releaseSharedI3DFile(requestId)

    if treeId ~= 0 then
        link(treesData.rootNode, treeId)

        setTranslation(treeId, x,y,z)
        setRotation(treeId, rx,ry,rz)
        -- Split shapes loaded from savegames/streams are placed at world space, so correct the position after we moved our node
        local numChildren = getNumOfChildren(treeId)
        for i=0, numChildren-1 do
            local child = getChildAt(treeId, i)
            if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) and getIsSplitShapeSplit(child) then
                setWorldRotation(child, getRotation(child))
                setWorldTranslation(child, getTranslation(child))
            end
        end

        I3DUtil.iterateRecursively(treeId, function(node, _)
            if getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) then
                local splitTypeIndex = getSplitType(node)
                if splitTypeIndex ~= treeTypeDesc.splitTypeIndex then
                    Logging.warning("Tree has wrong splitType '%s' assigned. Should be '%s'. File: '%s'", splitTypeIndex, treeTypeDesc.splitTypeIndex, i3dFilename)
                end

                -- on client side the trees must be kinematic (required for pre-cut trees which are not handled by an dedicated class like TreeTransportMissionTree - due to bug or mods)
                if g_server == nil then
                    if getRigidBodyType(node) == RigidBodyType.DYNAMIC then
                        setRigidBodyType(node, RigidBodyType.KINEMATIC)
                    end
                end
            end

            return true
        end)

        addToPhysics(treeId)
    end

    local updateRange = 2
    g_densityMapHeightManager:setCollisionMapAreaDirty(x-updateRange, z-updateRange, x+updateRange, z+updateRange, true)
    g_currentMission.aiSystem:setAreaDirty(x-updateRange, x+updateRange, z-updateRange, z+updateRange)

    return treeId, splitShapeFileId
end


---
function TreePlantManager:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, dirY, dirZ, length, growthStateI, variationIndex, delimb, useOnlyStump)
    local treeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, 0,0,0, growthStateI, variationIndex)

    if treeId ~= 0 then
        if getFileIdHasSplitShapes(splitShapeFileId) then
            local tree = {}
            tree.node = treeId
            tree.growthStateI = growthStateI
            tree.variationIndex = variationIndex
            tree.x, tree.y, tree.z = x,y,z
            tree.rx, tree.ry, tree.rz = 0, 0, 0
            tree.treeType = treeTypeDesc.index
            tree.splitShapeFileId = splitShapeFileId
            tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
            table.insert(self.treesData.splitTrees, tree)

            local loadTreeTrunkData = {framesLeft=2, shape=treeId+2, x=x, y=y, z=z, length=length, offset=0.5, dirX=dirX, dirY=dirY, dirZ=dirZ, delimb=delimb, useOnlyStump=useOnlyStump, cutTreeTrunkCallback=TreePlantManager.cutTreeTrunkCallback}

            table.insert(self.loadTreeTrunkDatas, loadTreeTrunkData)
        else
            delete(treeId)
        end
    end
end


---
function TreePlantManager.cutTreeTrunkCallback(loadTreeTrunkData, shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    g_treePlantManager:addingSplitShape(shape, loadTreeTrunkData.shapeBeingCut)

--#debug     if g_treePlantManager.debugActive then
--#debug         local splitType = getSplitType(shape)
--#debug         Logging.devInfo("cutTreeTrunkCallback shape=%d splitType=%d (%s)", shape, splitType, g_splitShapeManager:getSplitTypeNameByIndex(splitType))
--#debug     end

    table.insert(loadTreeTrunkData.parts, {shape=shape, isBelow=isBelow, isAbove=isAbove, minY=minY, maxY=maxY, minZ=minZ, maxZ=maxZ})
end


---
function TreePlantManager:updateTrees(dt, dtGame)
    local treesData = self.treesData
    treesData.updateDtGame = treesData.updateDtGame + dtGame

    -- update all 60 ingame minutes
    if treesData.updateDtGame > 1000*60*60 then
        self:cleanupDeletedTrees()

        treesData.updateDtGame = 0

        local currentMonotonicHour = g_currentMission.environment:getMonotonicHour()

        local numGrowingTrees = #treesData.growingTrees
        local i = 1
        while i <= numGrowingTrees do  -- TODO: time slice?
            local tree = treesData.growingTrees[i]

            -- Check if the tree has been cut in the mean time
            if getChildAt(tree.node, 0) ~= tree.origSplitShape then
                -- The tree has been cut, it will not grow anymore

                if self.debugActive then
                    Logging.info("Removing cut tree %d from growing trees", tree.node)
                end

                table.remove(treesData.growingTrees, i)
                numGrowingTrees = numGrowingTrees - 1
                tree.origSplitShape = nil
                table.insert(treesData.splitTrees, tree)
            else
                local treeTypeDesc = self.indexToTreeType[tree.treeType]
                local numStages = #treeTypeDesc.stages

                if currentMonotonicHour > tree.nextGrowthTargetHour then

                    local growthStateNew = math.min(tree.growthStateI + 1, #treeTypeDesc.stages)

                    if self.debugActive then
                        Logging.info("growing tree %s from stage %d to %d", treeTypeDesc.name, tree.growthStateI, growthStateNew)
                    end

                    tree.growthStateI = growthStateNew
                    if tree.growthStateI >= numStages then
                        -- tree is fully grown
                        tree.nextGrowthTargetHour = nil
                    else
                        -- setup next target hour for growth
                        tree.nextGrowthTargetHour = currentMonotonicHour + treeTypeDesc.growthTimeHours
                    end

                    -- Delete the old tree
                    delete(tree.node)

                    if not tree.hasSplitShapes then
                        self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
                        treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
                    end

                    -- Create the new tree
                    local variations = treeTypeDesc.stages[tree.growthStateI]
                    tree.variationIndex = math.random(1, #variations)

                    local treeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, tree.growthStateI, tree.variationIndex, -1)

                    g_server:broadcastEvent(TreeGrowEvent.new(tree.treeType, tree.x, tree.y, tree.z, tree.rx, tree.ry, tree.rz, tree.growthStateI, tree.variationIndex, splitShapeFileId, tree.splitShapeFileId))

                    tree.origSplitShape = getChildAt(treeId, 0)
                    tree.splitShapeFileId = splitShapeFileId
                    tree.hasSplitShapes = getFileIdHasSplitShapes(splitShapeFileId)
                    tree.node = treeId

                    -- update collision map
                    local range = 2.5
                    local x, _, z = getWorldTranslation(treeId)
                    g_densityMapHeightManager:setCollisionMapAreaDirty(x-range, z-range, x+range, z+range, true)
                    g_currentMission.aiSystem:setAreaDirty(x-range, x+range, z-range, z+range)

                    if not tree.hasSplitShapes then
                        self.numTreesWithoutSplits = self.numTreesWithoutSplits + 1
                        treesData.numTreesWithoutSplits = treesData.numTreesWithoutSplits + 1
                    end
                end

                if tree.growthStateI >= numStages then

                    if self.debugActive then
                        Logging.info("Removing fully grown tree %d (%s stage %d) from growth", tree.node, treeTypeDesc.name, tree.growthStateI)
                    end

                    -- Reached max grow level, can't grow any more
                    table.remove(treesData.growingTrees, i)
                    numGrowingTrees = numGrowingTrees-1
                    tree.origSplitShape = nil
                    table.insert(treesData.splitTrees, tree)
                else
                    i = i+1
                end
            end
        end
    end

    -- update cut joints of recently cut trees making it fall over
    local curTime = g_currentMission.time
    for joint in pairs(treesData.treeCutJoints) do
        if joint.destroyTime <= curTime or not entityExists(joint.shape) then
            removeJoint(joint.jointIndex)
            treesData.treeCutJoints[joint] = nil
        else
            local x1,y1,z1 = localDirectionToWorld(joint.shape, joint.lnx, joint.lny, joint.lnz)
            if x1*joint.nx + y1*joint.ny + z1*joint.nz < joint.maxCosAngle then
                removeJoint(joint.jointIndex)
                treesData.treeCutJoints[joint] = nil
            end
        end
    end

    -- process enqueued tree trunks for cutting
    if #self.loadTreeTrunkDatas > 0 then
        for i=#self.loadTreeTrunkDatas, 1, -1 do
            local loadTreeTrunkData = self.loadTreeTrunkDatas[i]

            loadTreeTrunkData.framesLeft = loadTreeTrunkData.framesLeft - 1
            -- first cut and remove upper part of tree
            if loadTreeTrunkData.framesLeft == 1 then
                local nx,ny,nz = 0, 1, 0
                local yx,yy,yz = -1, 0, 0
                local x,y,z = loadTreeTrunkData.x+1, loadTreeTrunkData.y, loadTreeTrunkData.z-1

                loadTreeTrunkData.parts = {}

                local shape = loadTreeTrunkData.shape
                if shape ~= nil and shape ~= 0 then
                    loadTreeTrunkData.shapeBeingCut = shape

    --#debug                 if self.debugActive then
    --#debug                     local splitType = getSplitType(shape)
    --#debug                     Logging.devInfo("splitShape %s splitType=%s (%s)", shape, splitType, g_splitShapeManager:getSplitTypeNameByIndex(splitType))
    --#debug                 end

                    splitShape(shape, x,y+loadTreeTrunkData.length+loadTreeTrunkData.offset,z, nx,ny,nz, yx,yy,yz, 4, 4, "cutTreeTrunkCallback", loadTreeTrunkData)
                    self:removingSplitShape(shape)
                    for _, p in pairs(loadTreeTrunkData.parts) do
                        if p.isAbove then
                            delete(p.shape)
                        else
                            loadTreeTrunkData.shape = p.shape
                        end
                    end
                end

            -- second cut lower part to get final length
            elseif loadTreeTrunkData.framesLeft == 0 then
                local nx,ny,nz = 0, 1, 0
                local yx,yy,yz = -1, 0, 0
                local x,y,z = loadTreeTrunkData.x+1, loadTreeTrunkData.y, loadTreeTrunkData.z-1

                loadTreeTrunkData.parts = {}
                local shape = loadTreeTrunkData.shape
                if shape ~= nil and shape ~= 0 then

    --#debug                 if self.debugActive then
    --#debug                     local splitType = getSplitType(shape)
    --#debug                     Logging.devInfo("splitShape %s splitType=%s (%s)", shape, splitType, g_splitShapeManager:getSplitTypeNameByIndex(splitType))
    --#debug                 end

                    local cutDiameter = 2.5
                    splitShape(shape, x,y+loadTreeTrunkData.offset,z, nx,ny,nz, yx,yy,yz, cutDiameter*2, cutDiameter*2, "cutTreeTrunkCallback", loadTreeTrunkData)

                    if loadTreeTrunkData.useOnlyStump then
                        for _, p in pairs(loadTreeTrunkData.parts) do
                            if not p.isBelow then
                                delete(p.shape)
                            end
                        end
                    else
                        local finalShape = nil
                        for _, p in pairs(loadTreeTrunkData.parts) do
                            if p.isBelow then
                                delete(p.shape)
                            else
                                finalShape = p.shape
                            end
                        end
                        -- set correct rotation of final chunk
                        if finalShape ~= nil then
                            if loadTreeTrunkData.delimb then
                                removeSplitShapeAttachments(finalShape, x,y+loadTreeTrunkData.offset,z, nx,ny,nz, yx,yy,yz, loadTreeTrunkData.length, 4, 4)
                            end

                            removeFromPhysics(finalShape)
                            setDirection(finalShape, 0, -1, 0, loadTreeTrunkData.dirX, loadTreeTrunkData.dirY, loadTreeTrunkData.dirZ)
                            addToPhysics(finalShape)
                        else
                            Logging.error("Unable to cut tree trunk with length '%s'. Try using a different value", loadTreeTrunkData.length)
                        end
                    end
                end

                table.remove(self.loadTreeTrunkDatas, i)
            end
        end
    end

    if self.commandCutTreeData ~= nil then
        if #self.commandCutTreeData.trees > 0 then
            local treeId = self.commandCutTreeData.trees[1]

            local x, y, z = getWorldTranslation(treeId)
            local localX, localY, localZ = worldToLocal(treeId, x, y + 0.5, z)
            local cx, cy, cz = localToWorld(treeId, localX - 2, localY, localZ - 2)
            local nx, ny, nz = localDirectionToWorld(treeId, 0, 1, 0)
            local yx, yy, yz = localDirectionToWorld(treeId, 0, 0, 1)

            self.commandCutTreeData.shapeBeingCut = treeId
            Logging.info("Cut tree '%s' (%d left)", getName(treeId), #self.commandCutTreeData.trees - 1)
            splitShape(treeId, cx, cy, cz, nx, ny, nz, yx, yy, yz, 4, 4, "onTreeCutCommandSplitCallback", self)

            table.remove(self.commandCutTreeData.trees, 1)
        else
            self.commandCutTreeData = nil
        end
    end

    self.updateDecayDtGame = self.updateDecayDtGame + dtGame
    if self.updateDecayDtGame > TreePlantManager.DECAY_INTERVAL then
        -- Update seasonal state of active split shapes
        for shape, data in pairs(self.activeDecayingSplitShapes) do
            if not entityExists(shape) then
                self.activeDecayingSplitShapes[shape] = nil
            elseif data.state > 0 then
                local newState = math.max(data.state - TreePlantManager.DECAY_DURATION_INV * self.updateDecayDtGame, 0)

                self:setSplitShapeLeafScaleAndVariation(shape, newState, data.variation)
                self.activeDecayingSplitShapes[shape].state = newState
            end
        end

        self.updateDecayDtGame = 0
    end
end























---
function TreePlantManager:addTreeCutJoint(jointIndex, shape, nx,ny,nz, maxAngle, maxLifetime)
    local treesData = self.treesData
    local lnx,lny,lnz = worldDirectionToLocal(shape, nx,ny,nz)
    local joint = {jointIndex=jointIndex, shape=shape, nx=nx,ny=ny,nz=nz, lnx=lnx,lny=lny,lnz=lnz, maxCosAngle=math.cos(maxAngle), destroyTime=g_currentMission.time+maxLifetime}
    treesData.treeCutJoints[joint] = joint
end


---
function TreePlantManager:getIsTreeDeleted(node)
    for i=1, getNumOfChildren(node) do
        local child = getChildAt(node, i-1)
        if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) or getHasClassId(child, ClassIds.SHAPE) then
            return false
        else
            if not self:getIsTreeDeleted(child) then
                return false
            end
        end
    end

    return true
end


---
function TreePlantManager:getTreeRigidBodyType(node)
    for i=1, getNumOfChildren(node) do
        local child = getChildAt(node, i-1)
        if getHasClassId(child, ClassIds.MESH_SPLIT_SHAPE) then
            return getRigidBodyType(child)
        else
            local rigidBodyType = self:getTreeRigidBodyType(child)
            if rigidBodyType ~= nil then
                return rigidBodyType
            end
        end
    end

    return nil
end


---
function TreePlantManager:cleanupDeletedTrees()
    local treesData = self.treesData

    local numGrowingTrees = #treesData.growingTrees
    local growingTreeIndex = 1
    while growingTreeIndex<=numGrowingTrees do
        local tree = treesData.growingTrees[growingTreeIndex]
        -- Check if the tree has been cut in the mean time
        if self:getIsTreeDeleted(tree.node) then
            -- The tree has been removed completely, remove from list
            table.remove(treesData.growingTrees, growingTreeIndex)
            numGrowingTrees = numGrowingTrees - 1
            delete(tree.node)

            if not tree.hasSplitShapes then
                self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
                treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
            end
        else
            growingTreeIndex = growingTreeIndex + 1
        end
    end

    local numSplitTrees = #treesData.splitTrees
    local splitTreeIndex = 1
    while splitTreeIndex<=numSplitTrees do
        local tree = treesData.splitTrees[splitTreeIndex]
        -- Check if the tree has been cut in the mean time
        if self:getIsTreeDeleted(tree.node) then
            -- The tree has been removed completely, remove from list
            table.remove(treesData.splitTrees, splitTreeIndex)
            numSplitTrees = numSplitTrees - 1
            delete(tree.node)

            if not tree.hasSplitShapes then
                self.numTreesWithoutSplits = math.max(self.numTreesWithoutSplits - 1, 0)
                treesData.numTreesWithoutSplits = math.max(treesData.numTreesWithoutSplits - 1, 0)
            end
        else
            splitTreeIndex = splitTreeIndex + 1
        end
    end
end


---
function TreePlantManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        return false
    end
    local xmlFile = loadXMLFile("treePlantXML", xmlFilename)
    if xmlFile == 0 then
        return false
    end

    local i = 0
    while true do

        local key = string.format("treePlant.tree(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end

        local treeTypeName = getXMLString(xmlFile, key.."#treeType")
        local treeType = self.nameToTreeType[treeTypeName]

        local pos = string.getVector(getXMLString(xmlFile, key.."#position"), 3)
        local rot = string.getRadians(getXMLString(xmlFile, key.."#rotation"), 3)

        if #pos == 3 and #rot == 3 and treeType ~= nil then
            local growthStateI = getXMLInt(xmlFile, key.."#growthStateI")
            local variationIndex = getXMLInt(xmlFile, key.."#variationIndex") or 1
            local nextGrowthTargetHour = getXMLFloat(xmlFile, key.."#nextGrowthTargetHour")
            local isGrowing = Utils.getNoNil(getXMLBool(xmlFile, key.."#isGrowing"), true)
            local splitShapeFileId = getXMLInt(xmlFile, key.."#splitShapeFileId") -- note: might be nil if not available

            self:plantTree(treeType.index, pos[1], pos[2], pos[3], rot[1], rot[2], rot[3], growthStateI, variationIndex, isGrowing, nextGrowthTargetHour, splitShapeFileId)
        end

        i = i + 1
    end
    delete(xmlFile)

    return true
end


---
function TreePlantManager:saveToXMLFile(xmlFilename)

    self:cleanupDeletedTrees()

    --save mappings to xml
    local xmlFile = createXMLFile("treePlantXML", xmlFilename, "treePlant")
    if xmlFile == 0 then
        Logging.error("Failed to create xml file %q", xmlFilename)
        return false
    end

    local function saveTreeToXML(tree, xmlIndex)
        local treeTypeDesc = self:getTreeTypeDescFromIndex(tree.treeType)
        local treeTypeName = treeTypeDesc.name
        local isGrowing = (getChildAt(tree.node, 0) == tree.origSplitShape)
        local splitShapeFileId = tree.splitShapeFileId or -1

        local treeKey = string.format("treePlant.tree(%d)", xmlIndex)
        setXMLString(xmlFile, treeKey.."#treeType", treeTypeName)
        setXMLString(xmlFile, treeKey.."#position", string.format("%.4f %.4f %.4f", tree.x, tree.y, tree.z))
        setXMLString(xmlFile, treeKey.."#rotation", string.format("%.4f %.4f %.4f", math.deg(tree.rx), math.deg(tree.ry), math.deg(tree.rz)))
        setXMLInt(xmlFile, treeKey.."#growthStateI", tree.growthStateI)
        if tree.variationIndex ~= 1 then  -- 1 is the default set on load
            setXMLInt(xmlFile, treeKey.."#variationIndex", tree.variationIndex)
        end
        if tree.nextGrowthTargetHour ~= nil then
            setXMLFloat(xmlFile, treeKey.."#nextGrowthTargetHour", tree.nextGrowthTargetHour)
        end
        setXMLBool(xmlFile, treeKey.."#isGrowing", isGrowing)
        setXMLInt(xmlFile, treeKey.."#splitShapeFileId", splitShapeFileId)
    end

    local index = 0
    for _, tree in ipairs(self.treesData.growingTrees) do
        saveTreeToXML(tree, index)
        index = index + 1
    end

    for _, tree in ipairs(self.treesData.splitTrees) do
        saveTreeToXML(tree, index)
        index = index + 1
    end

    saveXMLFile(xmlFile)
    delete(xmlFile)

    return true
end


---
function TreePlantManager:readFromServerStream(streamId)
    local treesData = self.treesData

    local numTrees = streamReadInt32(streamId)
    for i=1, numTrees do
        local treeType = streamReadUInt8(streamId)
        local x = streamReadFloat32(streamId)
        local y = streamReadFloat32(streamId)
        local z = streamReadFloat32(streamId)
        local rx = streamReadFloat32(streamId)
        local ry = streamReadFloat32(streamId)
        local rz = streamReadFloat32(streamId)
        local growthStateI = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
        local variationIndex = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
        local serverSplitShapeFileId = streamReadInt32(streamId)

        local treeTypeDesc = self.indexToTreeType[treeType]
        if treeTypeDesc ~= nil then
            local nodeId, splitShapeFileId = self:loadTreeNode(treeTypeDesc, x,y,z, rx,ry,rz, growthStateI, variationIndex, -1)
            setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
            treesData.clientTrees[serverSplitShapeFileId] = nodeId
        end
    end
end


---
function TreePlantManager:writeToClientStream(streamId)
    local treesData = self.treesData

    self:cleanupDeletedTrees()

    local numTrees = #treesData.growingTrees + #treesData.splitTrees

    streamWriteInt32(streamId, numTrees)
    for _, tree in ipairs(treesData.growingTrees) do
        streamWriteUInt8(streamId, tree.treeType)
        streamWriteFloat32(streamId, tree.x)
        streamWriteFloat32(streamId, tree.y)
        streamWriteFloat32(streamId, tree.z)
        streamWriteFloat32(streamId, tree.rx)
        streamWriteFloat32(streamId, tree.ry)
        streamWriteFloat32(streamId, tree.rz)
        streamWriteUIntN(streamId, tree.growthStateI, TreePlantManager.STAGE_NUM_BITS)
        streamWriteUIntN(streamId, tree.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
        streamWriteInt32(streamId, tree.splitShapeFileId)
    end
    for _, tree in ipairs(treesData.splitTrees) do
        streamWriteUInt8(streamId, tree.treeType)
        streamWriteFloat32(streamId, tree.x)
        streamWriteFloat32(streamId, tree.y)
        streamWriteFloat32(streamId, tree.z)
        streamWriteFloat32(streamId, tree.rx)
        streamWriteFloat32(streamId, tree.ry)
        streamWriteFloat32(streamId, tree.rz)
        streamWriteUIntN(streamId, tree.growthStateI, TreePlantManager.STAGE_NUM_BITS)
        streamWriteUIntN(streamId, tree.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
        streamWriteInt32(streamId, tree.splitShapeFileId)
    end
end


---
function TreePlantManager:getTreeTypeDescFromIndex(index)
    if self.treeTypes ~= nil then
        return self.treeTypes[index]
    end
    return nil
end


---
function TreePlantManager:getTreeTypeNameFromIndex(index)
    if self.treeTypes ~= nil then
        if self.treeTypes[index] ~= nil then
            return self.treeTypes[index].name
        end
    end
    return nil
end


---
function TreePlantManager:getTreeTypeDescFromName(name)
    if self.nameToTreeType ~= nil and name ~= nil then
        name = name:upper()
        return self.nameToTreeType[name]
    end
    return nil
end


---
function TreePlantManager:getTreeTypeIndexAndVariationFromName(name, stageIndex, variationName)
    if self.nameToTreeType ~= nil and name ~= nil then
        name = name:upper()
        local treeTypeDesc = self.nameToTreeType[name]
        if treeTypeDesc ~= nil then
            local stage = treeTypeDesc.stages[stageIndex]
            if stage ~= nil then
                local variationIndex
                for index, variation in ipairs(stage) do
                    if string.lower(variation.name or "DEFAULT") == string.lower(variationName or "DEFAULT") then
                        variationIndex = index
                        break
                    end
                end

                return treeTypeDesc.index, variationIndex
            end
        end
    end

    return nil, nil
end


---
function TreePlantManager:getTreeTypeNameAndVariationByIndex(treeTypeIndex, stageIndex, variationIndex)
    if self.treeTypes ~= nil then
        local treeTypeDesc = self.treeTypes[treeTypeIndex]
        if treeTypeDesc ~= nil then
            local variations = treeTypeDesc.stages[stageIndex or 1]
            if variations ~= nil then
                local variation = variations[variationIndex] or variations[1]
                if variation ~= nil then
                    return treeTypeDesc.name, variation.name or "DEFAULT"
                end
            end
        end
    end

    return nil, nil
end


---
function TreePlantManager:getPalletStoreItemFilenameByIndex(treeTypeIndex, stageIndex, variationIndex)
    if self.treeTypes ~= nil then
        local treeTypeDesc = self.treeTypes[treeTypeIndex]
        if treeTypeDesc ~= nil then
            local variations = treeTypeDesc.stages[stageIndex or 1]
            if variations ~= nil then
                local variation = variations[variationIndex] or variations[1]
                if variation ~= nil then
                    return variation.palletStoreItemFilename
                end
            end
        end
    end

    return nil
end


---
function TreePlantManager:getTreeTypeDescFromSplitType(splitTypeIndex)
    if self.splitTypeIndexToTreeType ~= nil and splitTypeIndex ~= nil then
        return self.splitTypeIndexToTreeType[splitTypeIndex]
    end

    return nil
end


---
function TreePlantManager:getTreeTypeIndexFromName(name)
    if self.nameToTreeType ~= nil and name ~= nil then
        name = name:upper()
        if self.nameToTreeType[name] ~= nil then
            return self.nameToTreeType[name].index
        end
    end

    return nil
end


---
function TreePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
    if self.treesData ~= nil then
        self.treesData.clientTrees[serverSplitShapeFileId] = nodeId
    end
end


---
function TreePlantManager:removeClientTree(serverSplitShapeFileId)
    if self.treesData ~= nil then
        self.treesData.clientTrees[serverSplitShapeFileId] = nil
    end
end


---
function TreePlantManager:getClientTree(serverSplitShapeFileId)
    if self.treesData ~= nil then
        return self.treesData.clientTrees[serverSplitShapeFileId]
    end

    return nil
end






---
function TreePlantManager:addingSplitShape(shape, oldShape, fromTree)
    local state
    local variation

    -- If a parent is provided, copy the info if we still actively update
    if oldShape ~= nil and self.activeDecayingSplitShapes[oldShape] ~= nil then
        state = self.activeDecayingSplitShapes[oldShape].state
        variation = self.activeDecayingSplitShapes[oldShape].variation
    elseif fromTree then
        state = 1
        local x, y, z = getWorldTranslation(shape)
        variation = math.abs(x) + math.abs(y) + math.abs(z)
    else
        state = 0
        variation = 80
    end

    -- With no children, the shape has no branches and we need to update nothing
    -- And as cuts from this item cannot have branches either, we do not need to store
    -- it for parent state either.
    if state ~= nil and getNumOfChildren(shape) > 0 then
        self.activeDecayingSplitShapes[shape] = {state=state, variation=variation}

        self:setSplitShapeLeafScaleAndVariation(shape, state, variation)
    end

    g_messageCenter:publish(MessageType.TREE_SHAPE_CUT, oldShape, shape)
end



---Remove any known state about a split shape
function TreePlantManager:removingSplitShape(shape)
    -- At this point the shape does not exist anymore!
    self.activeDecayingSplitShapes[shape] = nil
end





















---
function TreePlantManager:setSplitShapeLeafScaleAndVariation(shape, scale, variation)
    -- Splitshape is a trunk, and possibly has attachments. (Engine removes attachments when needed)
    I3DUtil.setShaderParameterRec(shape, "windSnowLeafScale", 0, 0, scale, variation)
end


---
function TreePlantManager:consoleCommandCutTrees(radius)
    radius = tonumber(radius or "50")

    self.commandCutTreeData = {}
    self.commandCutTreeData.trees = {}

    local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
    overlapSphere(x, y, z, radius, "onTreeCutCommandOverlapCallback", self, CollisionFlag.TREE, false, false, true, false)

    return string.format("Found %d trees to cut", #self.commandCutTreeData.trees)
end


---
function TreePlantManager:onTreeCutCommandOverlapCallback(objectId, ...)
    if getHasClassId(objectId, ClassIds.MESH_SPLIT_SHAPE) and getSplitType(objectId) ~= 0 and getRigidBodyType(objectId) == RigidBodyType.STATIC and not getIsSplitShapeSplit(objectId) then
        table.insert(self.commandCutTreeData.trees, objectId)
    end
end


---
function TreePlantManager:onTreeCutCommandSplitCallback(shape, isBelow, isAbove, minY, maxY, minZ, maxZ)
    rotate(shape, 0.1, 0, 0)

    g_currentMission:addKnownSplitShape(shape)
    self:addingSplitShape(shape, self.commandCutTreeData.shapeBeingCut, true)
end

















































---
function TreePlantManager:consoleCommandPlantTrees(treeTypeName, number, growthStateI, variationIndex, isGrowing)
    local usage = "Usage: gsTreePlant treeType number growthState variationIndex isGrowing"

    local treeType = self:getTreeTypeDescFromName(treeTypeName)
    if treeTypeName ~= nil and treeType == nil then
        printError(string.format("Error: unknown tree type %q", treeTypeName))
        print("Available types:\n" .. table.concatKeys(g_treePlantManager.nameToTreeType, ", "))
        return usage
    end

    treeType = treeType or self:getTreeTypeDescFromName("lodgepolePine") or self:getTreeTypeDescFromName("aspen") or self.treeTypes[1]

    number = tonumber(number) or 1
    growthStateI = tonumber(growthStateI) or #treeType.stages  -- max growth by default
    growthStateI = math.clamp(growthStateI, 1, #treeType.stages)  -- clamp user input to valid range
    variationIndex = tonumber(variationIndex) or math.random(1, #treeType.stages[growthStateI])
    variationIndex = math.clamp(variationIndex, 1, #treeType.stages[growthStateI])
    isGrowing = Utils.stringToBoolean(isGrowing)

    local x, y, z = g_localPlayer:getPosition()
    local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()

    x,z = x+dirX*5, z+dirZ*5

    -- TODO: async
    local numPlantedTrees = 0
    for i=0, number-1 do
        local tx, tz = x+dirX*i*5, z+dirZ*i*5
        local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, y, tz)
        local ry = math.random()*2*math.pi

        self.plantTreeCommandHasCollision = false
        overlapBox(tx,ty,tz, 0,0,0, 0.5,1,0.5, "onTreeOverlapCheckCallback", self, CollisionFlag.TREE)

        if not self.plantTreeCommandHasCollision then
            if self:plantTree(treeType.index, tx,ty,tz, 0,ry,0, growthStateI, variationIndex, isGrowing) then
                numPlantedTrees = numPlantedTrees + 1
            end
        else
            -- TODO: retry instead
            printWarning("Warning: skipped tree due to overlap with existing tree")
        end
    end

    return string.format("Planted %d trees of type %s", numPlantedTrees, treeType.name)
end


---
function TreePlantManager:consoleCommandLoadAll(treeTypeName, number, growthStateI, variationIndex, isGrowing)
    g_debugManager:removeGroup("treeLoadAll")

    local x, _, z = g_localPlayer:getPosition()
    local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
    local yRot = MathUtil.getYRotationFromDirection(-dirX, -dirZ)

    x, z = x + dirX * 5, z + dirZ * 5
    local xOffset = 10
    local zOffset = 10

    local numPlantedTrees = 0
    for index, treeType in ipairs(self.treeTypes) do
        local tx, tz = x + dirZ * index * xOffset, z - dirX * index * xOffset

        for stageIndex, stage in ipairs(treeType.stages) do
            for variationIndex, variation in ipairs(stage) do
                local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, 0, tz)

                local treeId = self:plantTree(treeType.index, tx, ty, tz, 0, math.random() * math.pi, 0, stageIndex, variationIndex, false)
                if treeId ~= nil and treeId ~= 0 then
                    local splitShapeId = getChildAt(getChildAt(treeId, 0), 0)

                    local splitTypeIndex = -1
                    local splitTypeName = "<NO_SPLIT_TYPE>"
                    local allowWoodHarvester = false
                    local sizeX, sizeY, sizeZ, numConvexes, numAttachments
                    if splitShapeId ~= 0 and getHasClassId(splitShapeId, ClassIds.MESH_SPLIT_SHAPE) then
                        splitTypeIndex = getSplitType(splitShapeId)
                        splitTypeName = g_splitShapeManager:getSplitTypeNameByIndex(splitTypeIndex)
                        allowWoodHarvester = g_splitShapeManager:getSplitShapeAllowsHarvester(splitShapeId)
                        sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(splitShapeId)
                    end

                    local splitShapeDescStr = ""
                    if sizeX ~= nil then
                        splitShapeDescStr = string.format("\nSplit Shape Size: Height: %.2f | Width: %.2f | Length: %.2f | Area: %.2f m² | convexes: %d | attachments: %d", sizeX, sizeY, sizeZ, sizeY * sizeZ, numConvexes, numAttachments)
                    end

                    local debugText = DebugText3D.new():createWithWorldPos(tx - dirX, ty + 0.5, tz - dirZ, 0, yRot, 0, string.format("%s : %s\nsplitType: %s / %s%s%s", treeType.name, Utils.getFilenameInfo(variation.filename, true), splitTypeIndex, splitTypeName, splitShapeDescStr, allowWoodHarvester and "\n\nSupports Wood Harvester" or ""), 0.07)
                    if allowWoodHarvester then
                        debugText:setColor(Color.PRESETS.GREEN)
                    end
                    g_debugManager:addElement(debugText, "treeLoadAll")

                    self:loadTreeTrunk(treeType, tx + dirZ * 2, ty, tz - dirX * 2, dirX, 0, dirZ, 0.25, stageIndex, variationIndex, true, true)

                    numPlantedTrees = numPlantedTrees + 1

                    tx, tz = tx + dirX * zOffset, tz + dirZ * zOffset
                end
            end
        end
    end

    return string.format("Planted %d trees", numPlantedTrees)
end
