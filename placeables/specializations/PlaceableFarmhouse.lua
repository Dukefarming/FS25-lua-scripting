















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableFarmhouse.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableFarmhouse.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "farmhouseSleepingTriggerCallback", PlaceableFarmhouse.farmhouseSleepingTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "getSleepCamera", PlaceableFarmhouse.getSleepCamera)
    SpecializationUtil.registerFunction(placeableType, "getSpawnWorldPosition", PlaceableFarmhouse.getSpawnWorldPosition)
    SpecializationUtil.registerFunction(placeableType, "getSpawnPoint", PlaceableFarmhouse.getSpawnPoint)
    SpecializationUtil.registerFunction(placeableType, "getIsAllowedToSleep", PlaceableFarmhouse.getIsAllowedToSleep)
end


---
function PlaceableFarmhouse.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableFarmhouse)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableFarmhouse)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableFarmhouse)
end


---
function PlaceableFarmhouse.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Farmhouse")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse#spawnNode", "Player spawn node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#triggerNode", "Sleeping trigger")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".farmhouse.sleeping#cameraNode", "Camera while sleeping")
    schema:register(XMLValueType.BOOL, basePath .. ".farmhouse.sleeping#isFreeForAll", "Marks if everybody can sleep there")
    schema:setXMLSpecializationType()
end


---
function PlaceableFarmhouse.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Farmhouse")
    schema:register(XMLValueType.BOOL, basePath .. "#isFreeForAll", "Marks if everybody can sleep there")
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableFarmhouse:onLoad(savegame)
    local spec = self.spec_farmhouse

    spec.activatable = FarmhouseActivatable.new(self)

    spec.spawnNode = self.xmlFile:getValue("placeable.farmhouse#spawnNode", nil, self.components, self.i3dMappings)
    if spec.spawnNode == nil then
        Logging.xmlError(self.xmlFile, "No spawn node defined for farmhouse")
        spec.spawnNode = self.rootNode
    end

    local sleepingTriggerKey = "placeable.farmhouse.sleeping#triggerNode"
    spec.sleepingTrigger = self.xmlFile:getValue(sleepingTriggerKey, nil, self.components, self.i3dMappings)
    if spec.sleepingTrigger ~= nil then
        if not CollisionFlag.getHasMaskFlagSet(spec.sleepingTrigger, CollisionFlag.PLAYER) then
            Logging.warning("%s sleep trigger '%s' does not have 'TRIGGER_PLAYER' bit (%s) set", self.configFileName, sleepingTriggerKey, CollisionFlag.getBit(CollisionFlag.PLAYER))
        end
        addTrigger(spec.sleepingTrigger, "farmhouseSleepingTriggerCallback", self)
    end

    local cameraKey = "placeable.farmhouse.sleeping#cameraNode"
    local camera = self.xmlFile:getValue(cameraKey, nil, self.components, self.i3dMappings)
    if camera then
        if getHasClassId(camera, ClassIds.CAMERA) then
            spec.sleepingCamera = camera
            g_cameraManager:addCamera(camera, nil, false)
        else
            Logging.xmlError(self.xmlFile, "Sleeping camera node '%s' (%s) is not a camera!", getName(camera), cameraKey)
        end
    end

    spec.isFreeForAll = self.xmlFile:getValue("placeable.farmhouse.sleeping#isFreeForAll", false)
end


---
function PlaceableFarmhouse:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_farmhouse
    local isFreeForAll = xmlFile:getValue(key .. "#isFreeForAll")
    if isFreeForAll ~= nil then
        spec.isFreeForAll = isFreeForAll
    end
end


---
function PlaceableFarmhouse:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key .. "#isFreeForAll", self.spec_farmhouse.isFreeForAll)
end


---
function PlaceableFarmhouse:onFinalizePlacement()
    g_currentMission.placeableSystem:addFarmhouse(self)
end


---
function PlaceableFarmhouse:onDelete()
    local spec = self.spec_farmhouse

    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

    g_currentMission.placeableSystem:removeFarmhouse(self)

    if spec.sleepingTrigger ~= nil then
        removeTrigger(spec.sleepingTrigger)
    end

    if spec.sleepingCamera ~= nil then
        g_cameraManager:removeCamera(spec.sleepingCamera)
    end
end


---
function PlaceableFarmhouse:getSpawnPoint()
    return self.spec_farmhouse.spawnNode
end


---
function PlaceableFarmhouse:getSpawnWorldPosition()
    return getWorldTranslation(self.spec_farmhouse.spawnNode)
end


---
function PlaceableFarmhouse:getSleepCamera()
    return self.spec_farmhouse.sleepingCamera
end


















---
function PlaceableFarmhouse:farmhouseSleepingTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter or onLeave then
        if g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode then
--             if onEnter then
--                 TODO: reset player dog to spawn, old code:
--                 function Player:onEnterFarmhouse()
--                     if self.isServer then
--                         local dogHouse = g_currentMission:getDoghouse(self.farmId)
--                         if dogHouse ~= nil and dogHouse.dog ~= nil and dogHouse.dog.entityFollow == self.rootNode then
--                             dogHouse.dog:teleportToSpawn()
--                         end
--                     end
--                 end
--             end

            local spec = self.spec_farmhouse
            if onEnter then
                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            else
                g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
            end
        end
    end
end
