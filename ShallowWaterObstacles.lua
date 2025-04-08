















---
function ShallowWaterObstacles.prerequisitesPresent(specializations)
    return true
end


---
function ShallowWaterObstacles.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ShallowWaterObstacles")

    local key = ShallowWaterObstacles.OBSTACLE_NODE_XML_KEY
    schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Obstacle node")
    schema:register(XMLValueType.NODE_INDEX, key .. "#directionNode", "Node that is used as reference for the moving direction", "Same as #node")
    schema:register(XMLValueType.VECTOR_3, key .. "#size", "Size of the obstacle in m", "1 1 1")
    schema:register(XMLValueType.VECTOR_TRANS, key .. "#offset", "Offset of the obstacle in local space", "0 0 0")

    schema:setXMLSpecializationType()
end


---
function ShallowWaterObstacles.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadObstacleNodeFromXML", ShallowWaterObstacles.loadObstacleNodeFromXML)
end


---
function ShallowWaterObstacles.registerEventListeners(vehicleType)
    if not Platform.hasShallowWaterSimulation then
        return
    end

    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ShallowWaterObstacles)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ShallowWaterObstacles)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", ShallowWaterObstacles)
end


---
function ShallowWaterObstacles:onPostLoad(savegame)
    local spec = self.spec_shallowWaterObstacles

    spec.obstacleNodes = {}
    for _, key in self.xmlFile:iterator("vehicle.shallowWaterObstacle.obstacleNode") do
        local obstacleNode = {}
        if self:loadObstacleNodeFromXML(self.xmlFile, key, obstacleNode) then
            table.insert(spec.obstacleNodes, obstacleNode)
            obstacleNode.vehicle = self
            obstacleNode.index = #spec.obstacleNodes
        end
    end

    if #spec.obstacleNodes == 0 then
        SpecializationUtil.removeEventListener(self, "onLoadFinished", ShallowWaterObstacles)
        SpecializationUtil.removeEventListener(self, "onDelete", ShallowWaterObstacles)
        spec.obstacleNodes = nil
    end
end


---Called after loading
-- @param table savegame savegame
function ShallowWaterObstacles:onLoadFinished(savegame)
    if self.propertyState == VehiclePropertyState.SHOP_CONFIG then
        return  -- avoid interference with water planes while in shop under the map
    end

    local spec = self.spec_shallowWaterObstacles
    for _, obstacleNode in ipairs(spec.obstacleNodes) do
        obstacleNode.shallowWaterObstacle = g_currentMission.shallowWaterSimulation:addObstacle(obstacleNode.node, obstacleNode.size[1], obstacleNode.size[2], obstacleNode.size[3], ShallowWaterObstacles.getShallowWaterParameters, obstacleNode, obstacleNode.offset)
    end
end


---
function ShallowWaterObstacles:onDelete()
    local spec = self.spec_shallowWaterObstacles
    if spec.obstacleNodes ~= nil then
        for _, obstacleNode in ipairs(spec.obstacleNodes) do
            if obstacleNode.shallowWaterObstacle ~= nil then
                g_currentMission.shallowWaterSimulation:removeObstacle(obstacleNode.shallowWaterObstacle)
                obstacleNode.shallowWaterObstacle = nil
            end
        end
    end
end


---
function ShallowWaterObstacles:loadObstacleNodeFromXML(xmlFile, key, obstacleNode)
    local node = xmlFile:getValue(key.."#node", nil, self.components, self.i3dMappings)
    if node == nil then
        Logging.xmlWarning(xmlFile, "Missing node for obstacle node '%s'", key)
        return false
    end

    obstacleNode.node = node
    obstacleNode.directionNode = xmlFile:getValue(key.."#directionNode", node, self.components, self.i3dMappings)

    obstacleNode.size = xmlFile:getValue(key.."#size", "1 1 1", true)
    obstacleNode.offset = xmlFile:getValue(key.."#offset", nil, true)

    return true
end


---
function ShallowWaterObstacles.getShallowWaterParameters(obstacleNode)
    local velocity = obstacleNode.vehicle.lastSignedSpeed * 1000
    local dx, _, dz = localDirectionToWorld(obstacleNode.directionNode, 0, 0, 1)
    return dx * velocity, dz * velocity, MathUtil.getYRotationFromDirection(dx, dz)
end
