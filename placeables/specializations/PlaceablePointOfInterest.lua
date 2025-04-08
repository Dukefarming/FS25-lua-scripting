














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceablePointOfInterest.prerequisitesPresent(specializations)
    return true
end



---
function PlaceablePointOfInterest.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PointOfInterest")
    schema:register(XMLValueType.STRING,     basePath .. ".pointOfInterest.point(?)#class")
    PointOfInterest.registerXMLPaths(schema, basePath .. ".pointOfInterest.point(?)")
    schema:setXMLSpecializationType()
end


---
function PlaceablePointOfInterest.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceablePointOfInterest.setOwnerFarmId)
end


---
function PlaceablePointOfInterest.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceablePointOfInterest)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceablePointOfInterest)
end


---Called on loading
-- @param table savegame savegame
function PlaceablePointOfInterest:onLoad(savegame)
    local spec = self.spec_pointOfInterest

    spec.points = {}
    self.xmlFile:iterate("placeable.pointOfInterest.point", function(_, key)
        local className = self.xmlFile:getValue(key .. "#class", "PointOfInterest")
        local class = ClassUtil.getClassObject(className)
        if class == nil then
            Logging.xmlError(self.xmlFile, "PointOfInterest class '%s' not defined for '%s'", className, key)
            return
        end

        local poi = class.new(self, self.customEnvironment)
        if poi:load(self.components, self.xmlFile, key, self.customEnvironment, self.i3dMappings, self.rootNode) then
            table.insert(spec.points, poi)
        else
            poi:delete()
        end
    end)
end


---
function PlaceablePointOfInterest:onDelete()
    local spec = self.spec_pointOfInterest

    if spec.points ~= nil then
        for _, poi in ipairs(spec.points) do
            poi:delete()
        end
    end
end


---
function PlaceablePointOfInterest:setOwnerFarmId(superFunc, farmId, noEventSend)
    local spec = self.spec_pointOfInterest

    superFunc(self, farmId, noEventSend)

    for _, point in ipairs(spec.points) do
        point:setOwnerFarmId(farmId)
    end
end
