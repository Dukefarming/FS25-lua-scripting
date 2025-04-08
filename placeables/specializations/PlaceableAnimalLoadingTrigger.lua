














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableAnimalLoadingTrigger.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableAnimalLoadingTrigger.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAnimalLoadingTrigger)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAnimalLoadingTrigger)
end


---
function PlaceableAnimalLoadingTrigger.registerFunctions(placeableType)
end


---
function PlaceableAnimalLoadingTrigger.registerOverwrittenFunctions(placeableType)
end


---
function PlaceableAnimalLoadingTrigger.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("AnimalLoadingTrigger")
    AnimalLoadingTrigger.registerXMLPaths(schema, basePath .. ".animalLoadingTrigger")
    schema:setXMLSpecializationType()
end


---
function PlaceableAnimalLoadingTrigger.registerSavegameXMLPaths(schema, basePath)
end


---Called on loading
-- @param table savegame savegame
function PlaceableAnimalLoadingTrigger:onLoad(savegame)
    local spec = self.spec_animalLoadingTrigger

    spec.animalLoadingTrigger = AnimalLoadingTrigger.new(self.isServer, self.isClient)
    if not spec.animalLoadingTrigger:loadFromXML(self.xmlFile, "placeable.animalLoadingTrigger", self.components, self.i3dMappings) then
        spec.animalLoadingTrigger:delete()
        spec.animalLoadingTrigger = nil
    end
end


---
function PlaceableAnimalLoadingTrigger:onDelete()
    local spec = self.spec_animalLoadingTrigger
    if spec.animalLoadingTrigger ~= nil then
        spec.animalLoadingTrigger:delete()
        spec.animalLoadingTrigger = nil
    end
end
