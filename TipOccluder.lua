














---
function TipOccluder.prerequisitesPresent(specializations)
    return true
end


---
function TipOccluder.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TipOccluder")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#start", "Start node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#width", "Width node")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.tipOccluder.occlusionArea(?)#height", "Height node")

    schema:setXMLSpecializationType()
end


---
function TipOccluder.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getTipOcclusionAreas",                 TipOccluder.getTipOcclusionAreas)
    SpecializationUtil.registerFunction(vehicleType, "getWheelsWithTipOcclisionAreaGroupId", TipOccluder.getWheelsWithTipOcclisionAreaGroupId)
    SpecializationUtil.registerFunction(vehicleType, "getRequiresTipOcclusionArea",          TipOccluder.getRequiresTipOcclusionArea)
end


---
function TipOccluder.registerOverwrittenFunctions(vehicleType)
end


---
function TipOccluder.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TipOccluder)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", TipOccluder)
end


---
function TipOccluder:onLoad(savegame)
    local spec = self.spec_tipOccluder

    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.tipOcclusionAreas.tipOcclusionArea", "vehicle.tipOccluder.occlusionArea") --FS17 to FS19

    -- load tip occlusion areas
    spec.tipOcclusionAreas = {}
    local i = 0
    while true do
        local key = string.format("vehicle.tipOccluder.occlusionArea(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        local entry = {}
        entry.start = self.xmlFile:getValue(key .. "#start", nil, self.components, self.i3dMappings)
        entry.width = self.xmlFile:getValue(key .. "#width", nil, self.components, self.i3dMappings)
        entry.height = self.xmlFile:getValue(key .. "#height", nil, self.components, self.i3dMappings)
        if entry.start ~= nil and entry.width ~= nil and entry.height ~= nil then
            table.insert(spec.tipOcclusionAreas, entry)
        end
        i = i + 1
    end

    spec.createdTipOcclusionAreaGroupIds = {}
end


---
function TipOccluder:onLoadFinished(savegame)
    if self.getWheels ~= nil then
        for i, wheel in ipairs(self:getWheels()) do
            local spec = self.spec_tipOccluder
            local wheelGroupId = wheel.physics.tipOcclusionAreaGroupId
            if wheelGroupId ~= nil then
                local vehicleRootNode = self.components[1].node
                local doCreate = true
                local area
                for groupId, occluderArea in pairs(spec.createdTipOcclusionAreaGroupIds) do
                    if groupId == wheelGroupId then
                        doCreate = false
                        area = occluderArea
                        break
                    end
                end

                -- the first wheel with the group id creates the area, the other just recalculate the area
                if doCreate then
                    local start = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheelGroupId))
                    local width = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheelGroupId))
                    local height = createTransformGroup(string.format("tipOcclusionAreaGroupId%d", wheelGroupId))
                    link(vehicleRootNode, start)
                    link(vehicleRootNode, width)
                    link(vehicleRootNode, height)

                    area = {start=start, width=width, height=height}
                    table.insert(spec.tipOcclusionAreas, area)
                    spec.createdTipOcclusionAreaGroupIds[wheelGroupId] = area
                end

                if area ~= nil then
                    local xMax = -math.huge
                    local xMin = math.huge
                    local zMax = -math.huge
                    local zMin = math.huge

                    -- get other wheels with the same area group id
                    local usedWheels = self:getWheelsWithTipOcclisionAreaGroupId(self:getWheels(), wheelGroupId)

                    -- also include myself into the calculation
                    table.insert(usedWheels, wheel)

                    local rootNodeToUse = usedWheels[#usedWheels].node

                    link(rootNodeToUse, area.start)
                    link(rootNodeToUse, area.width)
                    link(rootNodeToUse, area.height)

                    for _,usedWheel in pairs(usedWheels) do
                        local x,_,z = localToLocal(usedWheel.driveNode, rootNodeToUse, usedWheel.physics.wheelShapeWidth - 0.5 * usedWheel.physics.width, 0, -usedWheel.physics.radius)
                        xMax = math.max(x, xMax)
                        zMin = math.min(z, zMin)
                        x,_,z = localToLocal(usedWheel.driveNode, rootNodeToUse, -usedWheel.physics.wheelShapeWidth + 0.5 * usedWheel.physics.width, 0, usedWheel.physics.radius)
                        xMin = math.min(x, xMin)
                        zMax = math.max(z, zMax)
                    end

                    setTranslation(area.start, xMax,0,zMin)
                    setTranslation(area.width, xMin,0,zMin)
                    setTranslation(area.height, xMax,0,zMax)
                end
            end
        end
    end

    if self:getRequiresTipOcclusionArea() then
        if #self.spec_tipOccluder.tipOcclusionAreas == 0 then
            Logging.xmlDevWarning(self.xmlFile, "No TipOcclusionArea defined")
        end
    end
end


---
function TipOccluder:getTipOcclusionAreas()
    return self.spec_tipOccluder.tipOcclusionAreas
end


---
function TipOccluder:getWheelsWithTipOcclisionAreaGroupId(wheels, groupId)
    local returnWheels = {}
    for _,wheel in pairs(wheels) do
        if wheel.physics.tipOcclusionAreaGroupId == groupId then
            table.insert(returnWheels, wheel)
        end
    end
    return returnWheels
end


---
function TipOccluder:getRequiresTipOcclusionArea()
    return false
end
