












---
local UnloadingStation_mt = Class(UnloadingStation, Object)



























































































































---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function UnloadingStation:readStream(streamId, connection)
    UnloadingStation:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        for _, unloadTrigger in ipairs(self.unloadTriggers) do
            local unloadTriggerId = NetworkUtil.readNodeObjectId(streamId)
            unloadTrigger:readStream(streamId, connection)
            g_client:finishRegisterObject(unloadTrigger, unloadTriggerId)
        end
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function UnloadingStation:writeStream(streamId, connection)
    UnloadingStation:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        for _, unloadTrigger in ipairs(self.unloadTriggers) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(unloadTrigger))
            unloadTrigger:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, unloadTrigger)
        end
    end
end






















































































































































































































































---
function UnloadingStation:validateUnloadTriggers(xmlFile, key)
    for fillTypeIndex, _ in pairs(self.supportedFillTypes) do
        local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillTypeDesc.isPalletType then
            local isValid = false
            for _, unloadTrigger in pairs(self.unloadTriggers) do
                if unloadTrigger.fillTypes[fillTypeIndex] ~= nil then
                    if ClassUtil.getClassObjectByObject(unloadTrigger) == PalletUnloadTrigger then
                        isValid = true
                    elseif unloadTrigger.exactFillRootNode == nil and ClassUtil.getClassObjectByObject(unloadTrigger) == UnloadTrigger then
                        isValid = true
                    end
                end
            end

            if not isValid then
                Logging.xmlWarning(xmlFile, "UnloadingStation does not have a PalletUnloadTrigger for fillType '%s'", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
            end
        end

        -- train stations unload directly without trigger
        if not self.isTrainStation and not self.isPalletStation then
            if fillTypeDesc.isBaleType then
                local isValid = false
                for _, unloadTrigger in pairs(self.unloadTriggers) do
                    if unloadTrigger.fillTypes[fillTypeIndex] ~= nil then
                        if ClassUtil.getClassObjectByObject(unloadTrigger) == BaleUnloadTrigger then
                            isValid = true
                        elseif unloadTrigger.exactFillRootNode == nil and ClassUtil.getClassObjectByObject(unloadTrigger) == UnloadTrigger then
                            isValid = true
                        end
                    end
                end

                if not isValid then
                    -- husbandries do not require bale triggers due to mixer wagon / straw blower
                    if not string.contains(key, "husbandry") then
                        Logging.xmlWarning(xmlFile, "UnloadingStation does not have a BaleUnloadTrigger for fillType '%s'", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
                    end
                end
            end

            if fillTypeDesc.isBulkType then
                local isValid = false
                for _, unloadTrigger in pairs(self.unloadTriggers) do
                    if ClassUtil.getClassObjectByObject(unloadTrigger) == UnloadTrigger and unloadTrigger.fillTypes[fillTypeIndex] ~= nil then
                        isValid = true
                    end
                end

                if not isValid then
                    Logging.xmlWarning(xmlFile, "UnloadingStation does not have a regular UnloadTrigger for fillType '%s'", g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex))
                end
            end
        end
    end
end


---
function UnloadingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Unloading station node")
    schema:register(XMLValueType.STRING,     basePath .. "#stationName", "Station name", "LoadingStation")
    schema:register(XMLValueType.FLOAT,      basePath .. "#storageRadius", "Inside of this radius storages can be placed", 50)
    schema:register(XMLValueType.BOOL,       basePath .. "#hideFromPricesMenu", "Hide station from prices menu", false)
    schema:register(XMLValueType.BOOL,       basePath .. "#supportsExtension", "Supports extensions", false)
    schema:register(XMLValueType.BOOL,       basePath .. "#isTrainStation", "Is part of the train system", false)
    schema:register(XMLValueType.BOOL,       basePath .. "#isPalletStation", "At this selling station good can be unloaded only as pallets", false)

    UnloadTrigger.registerTriggerXMLPaths(schema, basePath)

    SoundManager.registerSampleXMLPaths(schema,  basePath .. ".sounds", "active")
    SoundManager.registerSampleXMLPaths(schema,  basePath .. ".sounds", "idle")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".effectNodes")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".simpleFillplane(?)#node", "A fillplane that should be visible after unloading")
    FillTypeManager.registerConfigXMLFilltypes(schema, basePath .. ".simpleFillplane(?)")
end
