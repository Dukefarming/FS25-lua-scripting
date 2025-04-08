















---
function TireTracks.prerequisitesPresent(specializations)
    return true
end


---Called on specialization initializing
function TireTracks.initSpecialization()
end


---
function TireTracks.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getAllowTireTracks", TireTracks.getAllowTireTracks)
    SpecializationUtil.registerFunction(vehicleType, "addTireTrackNode", TireTracks.addTireTrackNode)
    SpecializationUtil.registerFunction(vehicleType, "removeTireTrackNode", TireTracks.removeTireTrackNode)
    SpecializationUtil.registerFunction(vehicleType, "updateTireTrackNode", TireTracks.updateTireTrackNode)
end


---
function TireTracks.registerOverwrittenFunctions(vehicleType)
end


---
function TireTracks.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", TireTracks)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TireTracks)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TireTracks)
end


---Called on load
-- @param table savegame savegame
function TireTracks:onPreLoad(savegame)
    local spec = self.spec_tireTracks
    spec.tireTrackNodes = {}
    spec.hasTireTrackNodes = false

    spec.segmentsCoeff = getTyreTracksSegmentsCoeff()

    spec.tireTrackSystem = g_currentMission.tireTrackSystem
end


---Called on deleting
function TireTracks:onDelete()
    local spec = self.spec_tireTracks
    if spec.tireTrackNodes ~= nil then
        for _, tireTrackNode in pairs(spec.tireTrackNodes) do
            spec.tireTrackSystem:destroyTrack(tireTrackNode.tireTrackIndex)
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function TireTracks:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if self.isActive then
        local spec = self.spec_tireTracks
        if spec.hasTireTrackNodes then
            local allowTireTracks = self:getAllowTireTracks()
            for _, tireTrackNode in pairs(spec.tireTrackNodes) do
                self:updateTireTrackNode(tireTrackNode, allowTireTracks)
            end
        end
    end
end


---
function TireTracks:getAllowTireTracks()
    return self.currentUpdateDistance < TireTracks.MAX_CREATION_DISTANCE and self.spec_tireTracks.segmentsCoeff > 0
end


---
function TireTracks:addTireTrackNode(wheel, parent, linkNode, tireTrackAtlasIndex, width, radius, inverted, activeFunc)
    local spec = self.spec_tireTracks

    local tireTrackNode = {}
    tireTrackNode.wheel = wheel
    tireTrackNode.parent = parent
    tireTrackNode.linkNode = linkNode
    tireTrackNode.tireTrackAtlasIndex = tireTrackAtlasIndex
    tireTrackNode.width = width
    tireTrackNode.radius = radius
    tireTrackNode.inverted = inverted
    tireTrackNode.activeFunc = activeFunc

    if spec.tireTrackSystem ~= nil then
        tireTrackNode.tireTrackIndex = spec.tireTrackSystem:createTrack(width, tireTrackAtlasIndex)

        if tireTrackNode.tireTrackIndex ~= nil then
            table.insert(spec.tireTrackNodes, tireTrackNode)
            spec.hasTireTrackNodes = next(spec.tireTrackNodes) ~= nil

            return #spec.tireTrackNodes
        end
    end

    return nil
end


---
function TireTracks:removeTireTrackNode(tireTrackNodeIndex)
    local spec = self.spec_tireTracks
    spec.tireTrackNodes[tireTrackNodeIndex] = nil
    spec.hasTireTrackNodes = next(spec.tireTrackNodes) ~= nil
end


---
function TireTracks:updateTireTrackNode(tireTrackNode, allowTireTracks)
    local spec = self.spec_tireTracks
    local wheel = tireTrackNode.wheel

    if not allowTireTracks then
        spec.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
        return
    end

    if tireTrackNode.activeFunc ~= nil and not tireTrackNode.activeFunc() then
        spec.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
        return
    end

    local wx, wy, wz = worldToLocal(tireTrackNode.parent, getWorldTranslation(tireTrackNode.linkNode))
    wy = wy - tireTrackNode.radius
    wx, wy, wz = localToWorld(tireTrackNode.parent, wx, wy, wz)
    wy = math.max(wy, getTerrainHeightAtWorldPos(g_terrainNode, wx, wy, wz))

    if wheel.physics.contact ~= WheelContactType.NONE and wheel.physics.lastContactObjectAllowsTireTracks then
        local r, g, b, groundDepth, t, dirtAmount, colorBlendWithTerrain = wheel.physics:getGroundAttributes()
        if dirtAmount > 0 then
            -- we are using wheel shape direction to be independent from component(s) direction
            local ux, uy, uz = localDirectionToWorld(wheel.node, -wheel.physics.directionX, -wheel.physics.directionY, -wheel.physics.directionZ)

            local tireDirection = self.movingDirection
            if tireTrackNode.inverted then
                tireDirection = tireDirection * -1
            end

            spec.tireTrackSystem:addTrackPoint(tireTrackNode.tireTrackIndex, wx, wy, wz, ux, uy, uz, r, g, b, dirtAmount, groundDepth, tireDirection, wheel.physics.contact ~= WheelContactType.OBJECT, colorBlendWithTerrain)
        else
            spec.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
        end
    else
        spec.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
    end
end
