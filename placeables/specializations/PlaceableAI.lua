














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableAI.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableAI.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "setObstacleActive",   PlaceableAI.setObstacleActive)
    SpecializationUtil.registerFunction(placeableType, "loadAIUpdateArea",    PlaceableAI.loadAIUpdateArea)
    SpecializationUtil.registerFunction(placeableType, "loadAISpline",        PlaceableAI.loadAISpline)
    SpecializationUtil.registerFunction(placeableType, "loadAIObstacle",      PlaceableAI.loadAIObstacle)
    SpecializationUtil.registerFunction(placeableType, "updateAIUpdateAreas", PlaceableAI.updateAIUpdateAreas)
end


---
function PlaceableAI.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAI)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PlaceableAI)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAI)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableAI)
end


---
function PlaceableAI.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("AI")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.updateAreas.updateArea(?)#startNode", "Start node of ai update area")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.updateAreas.updateArea(?)#endNode",   "End node of ai update area")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.splines.spline(?)#node",              "Spline node or transform group containing splines. Spline direction not relevant")
    schema:register(XMLValueType.FLOAT,      basePath .. ".ai.splines.spline(?)#maxWidth",          "Maximum vehicle width supported by the spline")
    schema:register(XMLValueType.FLOAT,      basePath .. ".ai.splines.spline(?)#maxHeight",         "Maximum vehicle height supported by the spline")
    schema:register(XMLValueType.FLOAT,      basePath .. ".ai.splines.spline(?)#maxTurningRadius",  "Maximum vehicle turning supported by the spline")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".ai.obstacles.obstacle(?)#node",          "Node to be used for obstacle box", nil, true)
    schema:register(XMLValueType.VECTOR_3,   basePath .. ".ai.obstacles.obstacle(?)#size",          "Obstacle box size as x y z vector, required if node is not a rigid body")
    schema:register(XMLValueType.VECTOR_3,   basePath .. ".ai.obstacles.obstacle(?)#offset",        "Obstacle box offset to node as x y z vector")
    schema:register(XMLValueType.INT,        basePath .. ".ai.obstacles.obstacle(?).animatedObject#index",     "Index of corresponding animated object in xml", nil, true)
    schema:register(XMLValueType.FLOAT,      basePath .. ".ai.obstacles.obstacle(?).animatedObject#startTime", "Normalized start time to activate obstacle", nil, true)
    schema:register(XMLValueType.FLOAT,      basePath .. ".ai.obstacles.obstacle(?).animatedObject#endTime",   "Normalized end time to deactivate obstacle", nil, true)
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableAI:onLoad(savegame)
    local spec = self.spec_ai
    local xmlFile = self.xmlFile

    spec.updateAreaOnDelete = false

    spec.areas = {}
    xmlFile:iterate("placeable.ai.updateAreas.updateArea", function(_, key)
        local area = {}
        if self:loadAIUpdateArea(xmlFile, key, area) then
            table.insert(spec.areas, area)
        end
    end)

    if not self.xmlFile:hasProperty("placeable.ai.updateAreas") then
        Logging.xmlWarning(self.xmlFile, "Missing ai update areas")
    end

    spec.splines = {}
    xmlFile:iterate("placeable.ai.splines.spline", function(_, key)
        local spline = {}
        if self:loadAISpline(xmlFile, key, spline) then
            table.insert(spec.splines, spline)
        end
    end)

    spec.obstacles = {}
    xmlFile:iterate("placeable.ai.obstacles.obstacle", function(_, key)
        local obstacle = {}
        if self:loadAIObstacle(xmlFile, key, obstacle) then
            table.insert(spec.obstacles, obstacle)
        end
    end)
end


---
function PlaceableAI:onPostLoad(savegame)
    local spec = self.spec_ai
    if self.spec_animatedObjects ~= nil and g_currentMission.aiSystem ~= nil and g_currentMission.aiSystem.navigationMap ~= nil  then
        local animatedObjects = self.spec_animatedObjects.animatedObjects

        for obstacleIndex, obstacle in ipairs(spec.obstacles) do
            local animatedObject = animatedObjects[obstacle.animatedObjectIndex]
            if animatedObject == nil then
                Logging.warning("Placeable AI obstacle %d: AnimatedObject with index %d does not exist", obstacleIndex, obstacle.animatedObjectIndex)
            else
                obstacle.animatedObject = animatedObject
                obstacle.updateState = function(_, t, omitSound)
                    if t >= obstacle.animatedObjectTimeStart and t <= obstacle.animatedObjectTimeEnd then
                        if not obstacle.isActive then
                            self:setObstacleActive(obstacle, true)
                        end
                    else
                        if obstacle.isActive then
                            self:setObstacleActive(obstacle, false)
                        end
                    end
                end
                -- hook into setAnimTime to add and remove AI obstacle in animation
                animatedObject.setAnimTime = Utils.appendedFunction(animatedObject.setAnimTime, obstacle.updateState)
            end
        end
    end
end


---
function PlaceableAI:onDelete()
    if self.isServer then
        local spec = self.spec_ai
        if spec.updateAreaOnDelete then
            self:updateAIUpdateAreas()
        end

        if g_currentMission.aiSystem ~= nil then
            if spec.splines ~= nil then
                for _, spline in pairs(spec.splines) do
                    g_currentMission.aiSystem:removeRoadSpline(spline.splineNode)
                end
            end

            if self.spec_animatedObjects ~= nil and g_currentMission.aiSystem.navigationMap ~= nil then
                local animatedObjects = self.spec_animatedObjects.animatedObjects
                if animatedObjects ~= nil then
                    for _, obstacle in ipairs(spec.obstacles) do
                        if obstacle.isActive then
                            self:setObstacleActive(obstacle, false)
                        end
                    end
                end
            end
        end
    end
end


---
function PlaceableAI:loadAIUpdateArea(xmlFile, key, area)
    local startNode = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)
    local endNode = xmlFile:getValue(key .. "#endNode", nil, self.components, self.i3dMappings)

    if startNode == nil then
        Logging.xmlWarning(xmlFile, "Missing ai update area start node for '%s'", key)
        return false
    end

    if endNode == nil then
        Logging.xmlWarning(xmlFile, "Missing ai update area end node for '%s'", key)
        return false
    end


    local startX, _, startZ = localToLocal(startNode, self.rootNode, 0, 0, 0)
    local endX, _, endZ = localToLocal(endNode, self.rootNode, 0, 0, 0)

    local sizeX = math.abs(endX - startX)
    local sizeZ = math.abs(endZ - startZ)

    area.center = {}
    area.center.x = (endX + startX) * 0.5
    area.center.z = (endZ + startZ) * 0.5

    area.size = {}
    area.size.x = sizeX
    area.size.z = sizeZ

    area.startNode = startNode
    area.endNode = endNode

    return true
end


---
function PlaceableAI:loadAISpline(xmlFile, key, spline)
    local splineNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

    if splineNode == nil then
        Logging.xmlWarning(xmlFile, "Spline node does not exist in '%s'", key)
        return false
    end

    setVisibility(splineNode, false)

    local maxWidth = xmlFile:getValue(key .. "#maxWidth")
    local maxHeight = xmlFile:getValue(key .. "#maxHeight")
    local maxTurningRadius = xmlFile:getValue(key .. "#maxTurningRadius")

    spline.splineNode = splineNode
    spline.maxWidth = maxWidth
    spline.maxHeight = maxHeight
    spline.maxTurningRadius = maxTurningRadius

    return true
end


---
function PlaceableAI:loadAIObstacle(xmlFile, key, obstacle)
    obstacle.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
    if obstacle.node == nil then
        Logging.xmlWarning(xmlFile, "Obstacle '%s' node does not exist", key)
        return false
    end

    obstacle.size = xmlFile:getValue(key .. "#size", "0 0 0", true)
    obstacle.offset = xmlFile:getValue(key .. "#offset", "0 0 0", true)

    -- size can only be omitted if node is a rigid body / has a collision box
    if getRigidBodyType(obstacle.node) == RigidBodyType.NONE and obstacle.size[1] == 0 then
        Logging.xmlWarning(xmlFile, "Obstacle '%s' is not a rigid body and needs a size", key)
        return false
    end

    obstacle.animatedObjectIndex = xmlFile:getValue(key .. ".animatedObject#index")
    if obstacle.animatedObjectIndex == nil then
        Logging.xmlWarning(xmlFile, "Obstacle '%s' is missing animated object index", key)
        return false
    end

    obstacle.animatedObjectTimeStart = xmlFile:getValue(key .. ".animatedObject#startTime")
    obstacle.animatedObjectTimeEnd = xmlFile:getValue(key .. ".animatedObject#endTime")

    if obstacle.animatedObjectTimeStart == nil or obstacle.animatedObjectTimeEnd == nil then
        Logging.xmlWarning(xmlFile, "Obstacle '%s' is missing start or end time", key)
        return false
    end

    if obstacle.animatedObjectTimeStart >= obstacle.animatedObjectTimeEnd then
        Logging.xmlWarning(xmlFile, "Obstacle '%s' start time need to be smaller than end time", key)
        return false
    end

    obstacle.isActive = false

    return true
end


---
function PlaceableAI:onFinalizePlacement()
    if self.isServer then
        local spec = self.spec_ai
        local missionInfo = g_currentMission.missionInfo

        spec.updateAreaOnDelete = true

        if not self.isLoadedFromSavegame or not missionInfo.isValid or g_currentMission.placeableSystem.isReloadRunning then
            self:updateAIUpdateAreas()
        end

        if g_currentMission.aiSystem ~= nil then
            for _, spline in ipairs(spec.splines) do
                g_currentMission.aiSystem:addRoadSpline(spline.splineNode, spline.maxWidth, spline.maxTurningRadius, spline.maxHeight)
            end

            -- explicitly update state once
            if g_currentMission.aiSystem.navigationMap ~= nil then
                for _, obstacle in ipairs(spec.obstacles) do
                    if obstacle.animatedObject ~= nil then
                        obstacle.updateState(nil, obstacle.animatedObject.animation.time)
                    end
                end
            end
        end
    end
end


---
function PlaceableAI:setObstacleActive(obstacle, active)
    if g_currentMission.aiSystem == nil then
        return
    end

    if active then
        g_currentMission.aiSystem:addObstacle(obstacle.node, obstacle.offset[1],obstacle.offset[2],obstacle.offset[3], obstacle.size[1],obstacle.size[2],obstacle.size[3], 0, false)
    else
        g_currentMission.aiSystem:removeObstacle(obstacle.node)
    end

    obstacle.isActive = active
end


---
function PlaceableAI:updateAIUpdateAreas()
    if self.isServer then
        local spec = self.spec_ai
        for _, area in pairs(spec.areas) do
            local x, z = area.center.x, area.center.z
            local sizeX, sizeZ = area.size.x, area.size.z

            local x1, _, z1 = localToWorld(self.rootNode, x + sizeX * 0.5, 0, z + sizeZ * 0.5)
            local x2, _, z2 = localToWorld(self.rootNode, x - sizeX * 0.5, 0, z + sizeZ * 0.5)
            local x3, _, z3 = localToWorld(self.rootNode, x + sizeX * 0.5, 0, z - sizeZ * 0.5)
            local x4, _, z4 = localToWorld(self.rootNode, x - sizeX * 0.5, 0, z - sizeZ * 0.5)

            local minX = math.min(x1, x2, x3, x4)
            local maxX = math.max(x1, x2, x3, x4)
            local minZ = math.min(z1, z2, z3, z4)
            local maxZ = math.max(z1, z2, z3, z4)
            g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
        end
    end
end
