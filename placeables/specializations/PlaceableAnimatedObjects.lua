














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableAnimatedObjects.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableAnimatedObjects.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getCanTriggerAnimatedObject", PlaceableAnimatedObjects.getCanTriggerAnimatedObject)
end


---
function PlaceableAnimatedObjects.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableAnimatedObjects.setOwnerFarmId)
end


---
function PlaceableAnimatedObjects.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableAnimatedObjects)
    SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", PlaceableAnimatedObjects)
end


---
function PlaceableAnimatedObjects.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("AnimatedObjects")
    AnimatedObject.registerXMLPaths(schema, basePath .. ".animatedObjects")
    schema:register(XMLValueType.INT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#animatedObjectIndex", "Animated object index")
    schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#minTime", "Min Time")
    schema:register(XMLValueType.FLOAT, basePath .. ".animatedObjects.animatedObject(?).dependency(?)#maxTime", "Max Time")
    schema:setXMLSpecializationType()
end


---
function PlaceableAnimatedObjects.registerSavegameXMLPaths(schema, basePath)
    AnimatedObject.registerSavegameXMLPaths(schema, basePath .. ".animatedObject(?)")
end


---Called on loading
-- @param table savegame savegame
function PlaceableAnimatedObjects:onLoad(savegame)
    local spec = self.spec_animatedObjects
    local xmlFile = self.xmlFile

    spec.animatedObjects = {}
    for index, animationKey in xmlFile:iterator("placeable.animatedObjects.animatedObject") do
        local animatedObject = AnimatedObject.new(self.isServer, self.isClient)
        animatedObject.dependencies = {}

        for _, dependencyKey in xmlFile:iterator(animationKey .. ".dependency") do
            local dependendIndex = xmlFile:getInt(dependencyKey.."#animatedObjectIndex")
            if dependendIndex ~= nil then
                local minTime = xmlFile:getValue(dependencyKey.."#minTime", 0)
                local maxTime = xmlFile:getValue(dependencyKey.."#maxTime", 0)
                local dependency = {objectIndex=dependendIndex, minTime=minTime, maxTime=maxTime}
                table.insert(animatedObject.dependencies, dependency)
            else
                Logging.xmlError(xmlFile, "Missing animatedObjectIndex for '%s'", dependencyKey)
            end
        end

        if animatedObject:load(self.components, xmlFile, animationKey, self.configFileName, self.i3dMappings) then
            table.insert(spec.animatedObjects, animatedObject)
        else
            Logging.xmlError(xmlFile, "Failed to load animated object %i", index)
        end
    end

    for _, animatedObject in ipairs(spec.animatedObjects) do
        animatedObject.getCanBeTriggered = Utils.overwrittenFunction(animatedObject.getCanBeTriggered, function(_, superFunc)
            if not superFunc(animatedObject) then
                return false
            end

            if not self:getCanTriggerAnimatedObject(animatedObject) then
                return false
            end

            if #animatedObject.dependencies > 0 then
                for _, dependency in ipairs(animatedObject.dependencies) do
                    local dependendObject = spec.animatedObjects[dependency.objectIndex]
                    if dependendObject ~= nil then
                        local t = dependendObject.animation.time
                        if t < dependency.minTime or t > dependency.maxTime then
                            return false
                        end
                    else
                        Logging.xmlWarning(xmlFile, "Invalid dependency animated object index '%d'", dependency.objectIndex)
                    end
                end
            end

            return true
        end)
    end
end


---
function PlaceableAnimatedObjects:onDelete()
    local spec = self.spec_animatedObjects

    if spec.animatedObjects ~= nil then
        for _, animatedObject in ipairs(spec.animatedObjects) do
            animatedObject:delete()
        end
        spec.animatedObjects = nil
    end
end


---
function PlaceableAnimatedObjects:onPostFinalizePlacement()
    local spec = self.spec_animatedObjects

    for _, animatedObject in ipairs(spec.animatedObjects) do
        animatedObject:register(true)
        animatedObject:setOwnerFarmId(self.ownerFarmId, true)
    end
end


---
function PlaceableAnimatedObjects:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_animatedObjects
        for _, animatedObject in ipairs(spec.animatedObjects) do
            local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)
            animatedObject:readStream(streamId, connection)
            g_client:finishRegisterObject(animatedObject, animatedObjectId)
        end
    end
end


---Called on server side when placeable was fully loaded on client side
-- @param integer streamId stream ID
-- @param table connection connection
function PlaceableAnimatedObjects:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_animatedObjects
        for _, animatedObject in ipairs(spec.animatedObjects) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
            animatedObject:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, animatedObject)
        end
    end
end


---
function PlaceableAnimatedObjects:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_animatedObjects
    for i, animatedObject in ipairs(spec.animatedObjects) do
        animatedObject:loadFromXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, i - 1))
    end
end


---
function PlaceableAnimatedObjects:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_animatedObjects

    for i, animatedObject in ipairs(spec.animatedObjects) do
        animatedObject:saveToXMLFile(xmlFile, string.format("%s.animatedObject(%d)", key, i - 1), usedModNames)
    end
end












---
function PlaceableAnimatedObjects:setOwnerFarmId(superFunc, ownerFarmId, noEventSend)
    superFunc(self, ownerFarmId, noEventSend)

    local spec = self.spec_animatedObjects

    if spec.animatedObjects ~= nil then
        for _, animatedObject in ipairs(spec.animatedObjects) do
            animatedObject:setOwnerFarmId(ownerFarmId, true)
        end
    end
end
