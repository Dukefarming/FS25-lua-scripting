














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableShallowWaterSimulation.prerequisitesPresent(specializations)
    return true
end





















---Called on loading
-- @param table savegame savegame
function PlaceableShallowWaterSimulation:onLoad(savegame)
    local spec = self.spec_shallowWaterSimulation

    if g_currentMission.shallowWaterSimulation == nil then
        return
    end

    if self.propertyState == PlaceablePropertyState.CONSTRUCTION_PREVIEW then
        return  -- do not add SWS for preview
    end

    for _, waterPlaneKey in self.xmlFile:iterator("placeable.shallowWaterSimulation.waterPlane") do
        local waterPlane = self.xmlFile:getValue(waterPlaneKey .. "#node", nil, self.components, self.i3dMappings)

        if waterPlane == nil then
            continue
        end

        -- set material from material holder if specified
        local materialName = self.xmlFile:getValue(waterPlaneKey .. "#materialName", nil)
        if materialName ~= nil then
            local waterSimMat = g_materialManager:getBaseMaterialByName(materialName)
            if waterSimMat == nil then
                Logging.xmlError(self.xmlFile, "Unable to retrieve material %s for water plane %q at %q", materialName, getName(waterPlane), waterPlaneKey)
            else
                setMaterial(waterPlane, waterSimMat, 0)
            end
        end

        spec.waterPlanes = spec.waterPlanes or {}

        if g_currentMission.shallowWaterSimulation:addWaterPlane(waterPlane) then
            g_currentMission.shallowWaterSimulation:addAreaGeometry(waterPlane)
            table.insert(spec.waterPlanes, waterPlane)
        end
    end
end


---
function PlaceableShallowWaterSimulation:onDelete()
    local spec = self.spec_shallowWaterSimulation

    if spec.waterPlanes == nil then
        return
    end

    for _, waterPlane in ipairs(spec.waterPlanes) do
        g_currentMission.shallowWaterSimulation:removeAreaGeometry(waterPlane)
        g_currentMission.shallowWaterSimulation:removeWaterPlane(waterPlane)
    end

    spec.waterPlanes = nil
end
