

















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableSilo.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableSilo.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableSilo.collectPickObjects)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableSilo.setOwnerFarmId)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableSilo.canBeSold)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableSilo.updateInfo)
end


---
function PlaceableSilo.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "setAmount",                     PlaceableSilo.setAmount)
    SpecializationUtil.registerFunction(placeableType, "refillAmount",                  PlaceableSilo.refillAmount)
    SpecializationUtil.registerFunction(placeableType, "getFillLevels",                 PlaceableSilo.getFillLevels)
    SpecializationUtil.registerFunction(placeableType, "onPlayerActionTriggerCallback", PlaceableSilo.onPlayerActionTriggerCallback)
end


---
function PlaceableSilo.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSilo)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSilo)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSilo)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSilo)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSilo)
    SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableSilo)
end


---
function PlaceableSilo.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Silo")
    schema:register(XMLValueType.STRING,        basePath .. ".silo#sellWarningText", "Sell warning text")
    schema:register(XMLValueType.NODE_INDEX,    basePath .. ".silo#playerActionTrigger", "Trigger for player interaction")
    schema:register(XMLValueType.BOOL,          basePath .. ".silo.storages#perFarm", "Silo is per farm", false)
    schema:register(XMLValueType.BOOL,          basePath .. ".silo.storages#foreignSilo", "Shows as foreign silo in the menu", false)
    UnloadingStation.registerXMLPaths(schema,   basePath .. ".silo.unloadingStation")
    LoadingStation.registerXMLPaths(schema,     basePath .. ".silo.loadingStation")
    schema:register(XMLValueType.NODE_INDEX,    basePath .. ".silo.storages.storage(?)#node", "Storage node")
    Storage.registerXMLPaths(schema,            basePath .. ".silo.storages.storage(?)")
    schema:setXMLSpecializationType()
end


---
function PlaceableSilo.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("Silo")
    schema:register(XMLValueType.INT, basePath .. ".storage(?)#index", "Storage index")
    Storage.registerSavegameXMLPaths(schema, basePath .. ".storage(?)")
    schema:setXMLSpecializationType()
end


---
function PlaceableSilo.initSpecialization()
    g_storeManager:addSpecType("siloVolume", "shopListAttributeIconCapacity", PlaceableSilo.loadSpecValueVolume, PlaceableSilo.getSpecValueVolume, StoreSpecies.PLACEABLE)
end


---Called on loading
-- @param table savegame savegame
function PlaceableSilo:onLoad(savegame)
    local spec = self.spec_silo
    local xmlFile = self.xmlFile

    spec.playerActionTrigger = xmlFile:getValue("placeable.silo#playerActionTrigger", nil, self.components, self.i3dMappings)

    if spec.playerActionTrigger ~= nil then
        spec.activatable = PlaceableSiloActivatable.new(self)
    end

    spec.storagePerFarm = xmlFile:getValue("placeable.silo.storages#perFarm", false)
    spec.foreignSilo = xmlFile:getValue("placeable.silo.storages#foreignSilo", spec.storagePerFarm) -- Shows as foreign silo in the menu

    spec.unloadingStation = UnloadingStation.new(self.isServer, self.isClient)
    spec.unloadingStation:load(self.components, xmlFile, "placeable.silo.unloadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
    spec.unloadingStation.owningPlaceable = self
    spec.unloadingStation.hasStoragePerFarm = spec.storagePerFarm

    spec.loadingStation = LoadingStation.new(self.isServer, self.isClient)
    spec.loadingStation:load(self.components, xmlFile, "placeable.silo.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
    spec.loadingStation.owningPlaceable = self
    spec.loadingStation.hasStoragePerFarm = spec.storagePerFarm

    spec.fillTypesAndLevelsAuxiliary = {}
    spec.fillTypeToFillTypeStorageTable = {}
    spec.infoTriggerFillTypesAndLevels = {}

    local numStorageSets = spec.storagePerFarm and FarmManager.MAX_NUM_FARMS or 1
    if not g_currentMission.missionDynamicInfo.isMultiplayer then
        numStorageSets = 1
    end

    spec.storages = {}
    local i = 0
    while true do
        local storageKey = string.format("placeable.silo.storages.storage(%d)", i)
        if not xmlFile:hasProperty(storageKey) then
            break
        end

        for j = 1, numStorageSets do
            local storage = Storage.new(self.isServer, self.isClient)
            if storage:load(self.components, xmlFile, storageKey, self.i3dMappings) then
                storage.ownerFarmId = j
                storage.foreignSilo = spec.foreignSilo -- Pass along for usage by prices menu
                table.insert(spec.storages, storage)
            end
        end

        i = i + 1
    end

    spec.sellWarningText = g_i18n:convertText(xmlFile:getValue("placeable.silo#sellWarningText", "$l10n_info_siloExtensionNotEmpty"))
end


---
function PlaceableSilo:onDelete()
    local spec = self.spec_silo

    local storageSystem = g_currentMission.storageSystem
    if spec.storages ~= nil then
        for _, storage in ipairs(spec.storages) do
            if spec.unloadingStation ~= nil then
                storageSystem:removeStorageFromUnloadingStations(storage, {spec.unloadingStation})
            end
            if spec.loadingStation ~= nil then
                storageSystem:removeStorageFromLoadingStations(storage, {spec.loadingStation})
            end

            storage:removeFillLevelChangedListeners(spec.storageFilLLevelChangedCallback)
            storageSystem:removeStorage(storage)
        end

        -- delete storages later to avoid access to already deleted storages
        for _, storage in ipairs(spec.storages) do
            storage:delete()
        end
    end

    if spec.unloadingStation ~= nil then
        storageSystem:removeUnloadingStation(spec.unloadingStation, self)
        spec.unloadingStation:delete()
    end

    if spec.loadingStation ~= nil then
        if spec.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
            g_currentMission:removeLiquidManureLoadingStation(spec.loadingStation)
        end

        storageSystem:removeLoadingStation(spec.loadingStation, self)
        spec.loadingStation:delete()
    end

    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

    if spec.playerActionTrigger ~= nil then
        removeTrigger(spec.playerActionTrigger)
    end
end


---
function PlaceableSilo:onFinalizePlacement()
    local spec = self.spec_silo

    local storageSystem = g_currentMission.storageSystem

    spec.unloadingStation:register(true)
    storageSystem:addUnloadingStation(spec.unloadingStation, self)

    if spec.loadingStation ~= nil then
        spec.loadingStation:register(true)
        storageSystem:addLoadingStation(spec.loadingStation, self)

        if spec.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
            g_currentMission:addLiquidManureLoadingStation(spec.loadingStation)
        end
    end

    for _, storage in ipairs(spec.storages) do
        if not spec.storagePerFarm then
            storage:setOwnerFarmId(self:getOwnerFarmId(), true)
        end

        storageSystem:addStorage(storage)

        storage:register(true)

        storageSystem:addStorageToUnloadingStation(storage, spec.unloadingStation)
        storageSystem:addStorageToLoadingStation(storage, spec.loadingStation)
    end

    -- now check if there are some storages in range which can also be used
    local storagesInRange = storageSystem:getStorageExtensionsInRange(spec.unloadingStation, self:getOwnerFarmId())
    if storagesInRange ~= nil then
        for _, storage in ipairs(storagesInRange) do
            if spec.unloadingStation.targetStorages[storage] == nil then
                storageSystem:addStorageToUnloadingStation(storage, spec.unloadingStation)
            end
        end
    end

    storagesInRange = storageSystem:getStorageExtensionsInRange(spec.loadingStation, self:getOwnerFarmId())
    if storagesInRange ~= nil then
        for _, storage in ipairs(storagesInRange) do
            if spec.loadingStation.sourceStorages[storage] == nil then
                storageSystem:addStorageToLoadingStation(storage, spec.loadingStation)
            end
        end
    end

    if spec.playerActionTrigger ~= nil then
        addTrigger(spec.playerActionTrigger, "onPlayerActionTriggerCallback", self)
    end
end


---
function PlaceableSilo:onReadStream(streamId, connection)
    local spec = self.spec_silo

    local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)
    spec.unloadingStation:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.unloadingStation, unloadingStationId)

    local loadingStationId = NetworkUtil.readNodeObjectId(streamId)
    spec.loadingStation:readStream(streamId, connection)
    g_client:finishRegisterObject(spec.loadingStation, loadingStationId)

    for _, storage in ipairs(spec.storages) do
        local storageId = NetworkUtil.readNodeObjectId(streamId)
        storage:readStream(streamId, connection)
        g_client:finishRegisterObject(storage, storageId)
    end
end


---
function PlaceableSilo:onWriteStream(streamId, connection)
    local spec = self.spec_silo

    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.unloadingStation))
    spec.unloadingStation:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.unloadingStation)

    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.loadingStation))
    spec.loadingStation:writeStream(streamId, connection)
    g_server:registerObjectInStream(connection, spec.loadingStation)

    for _, storage in ipairs(spec.storages) do
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(storage))
        storage:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, storage)
    end
end


---
function PlaceableSilo:collectPickObjects(superFunc, node)
    local spec = self.spec_silo

    local foundNode = false
    for _, unloadTrigger in ipairs(spec.unloadingStation.unloadTriggers) do
        if node == unloadTrigger.exactFillRootNode then
            foundNode = true
            break
        end
    end

    if not foundNode then
        for _, loadTrigger in ipairs(spec.loadingStation.loadTriggers) do
            if node == loadTrigger.triggerNode then
                foundNode = true
                break
            end
        end
    end

    if not foundNode then
        superFunc(self, node)
    end
end


---
function PlaceableSilo:canBeSold(superFunc)
    local spec = self.spec_silo
    -- We do not support selling silos used by more than one farm because of the gameplay complexity. (What do to with contents, when to allow)
    if spec.storagePerFarm then
        return false, nil
    end

    local warning = spec.sellWarningText .. "\n"
    local totalFillLevel = 0

    spec.totalFillTypeSellPrice = 0
    for fillTypeIndex, fillLevel in pairs(spec.storages[1].fillLevels) do
        totalFillLevel = totalFillLevel + fillLevel

        if fillLevel > 0 then
            local lowestSellPrice = math.huge

            for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
                if unloadingStation.owningPlaceable ~= nil
                    and unloadingStation.isSellingPoint
                    and unloadingStation.acceptedFillTypes[fillTypeIndex] then
                    local price = unloadingStation:getEffectiveFillTypePrice(fillTypeIndex)

                    if price > 0 then
                        lowestSellPrice = math.min(lowestSellPrice, price)
                    end
                end
            end

            if lowestSellPrice == math.huge then
                lowestSellPrice = 0.5
            end

            local price = fillLevel * lowestSellPrice * PlaceableSilo.PRICE_SELL_FACTOR
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            warning = string.format("%s%s (%s) - %s: %s\n", warning, fillType.title, g_i18n:formatVolume(fillLevel), g_i18n:getText("ui_sellValue"), g_i18n:formatMoney(price, 0, true, true))
            spec.totalFillTypeSellPrice = spec.totalFillTypeSellPrice + price
        end
    end

    if totalFillLevel > 0 then
        return true, warning
    end

    return true, nil
end


---
function PlaceableSilo:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_silo

    xmlFile:iterate(key .. ".storage", function(_, storageKey)
        local index = xmlFile:getValue(storageKey.."#index")

        if index ~= nil then
            if spec.storages[index] ~= nil then
                if not spec.storages[index]:loadFromXMLFile(xmlFile, storageKey) then
                    return false
                end
            end
        end
        return
    end)
end


---
function PlaceableSilo:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_silo

    for k, storage in ipairs(spec.storages) do
        local storageKey = string.format("%s.storage(%d)", key, k-1)
        xmlFile:setValue(storageKey .. "#index", k)
        storage:saveToXMLFile(xmlFile, storageKey, usedModNames)
    end
end


---
function PlaceableSilo:setOwnerFarmId(superFunc, farmId, noEventSend)
    local spec = self.spec_silo

    superFunc(self, farmId, noEventSend)

    if self.isServer and not spec.storagePerFarm then
        if spec.storages ~= nil then
            for _, storage in ipairs(spec.storages) do
                storage:setOwnerFarmId(farmId, true)
            end
        end
    end
end


---
function PlaceableSilo:setAmount(fillType, amount)
    local spec = self.spec_silo

    for _, storage in ipairs(spec.storages) do
        local capacity = storage:getFreeCapacity(fillType)
        if capacity > 0 then
            local moved = math.min(amount, capacity)
            storage:setFillLevel(moved, fillType)

            amount = amount - moved
        end

        if amount <= 0.001 then
            break
        end
    end
end


---
function PlaceableSilo:refillAmount(fillTypeIndex, amount, price)
    if fillTypeIndex == nil or amount == nil or price == nil then
        return
    end

    if not self.isServer then
        g_client:getServerConnection():sendEvent(PlaceableSiloRefillEvent.new(self, fillTypeIndex, amount, price))
        return
    end

    local spec = self.spec_silo
    for _, storage in ipairs(spec.storages) do
        local freeCapacity = storage:getFreeCapacity(fillTypeIndex)
        if freeCapacity > 0 then
            local moved = math.min(amount, freeCapacity)
            local fillLevel = storage:getFillLevel(fillTypeIndex)
            storage:setFillLevel(fillLevel + moved, fillTypeIndex)

            amount = amount - moved
        end

        if amount <= 0.001 then
            break
        end
    end

    if self.isServer then
        g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.BOUGHT_MATERIALS, true)
    end
    g_currentMission:showMoneyChange(MoneyType.BOUGHT_MATERIALS)
end


---
function PlaceableSilo:getFillLevels()
    local spec = self.spec_silo

    local validFillLevels = {}
    for _, storage in ipairs(spec.storages) do
        for fillTypeIndex, fillLevel in pairs(storage:getFillLevels()) do
            if self.fillTypes == nil or self.fillTypes[fillTypeIndex] then
                validFillLevels[fillTypeIndex] = fillLevel
            end
        end
    end
    return validFillLevels
end


---
function PlaceableSilo:onSell()
    local spec = self.spec_silo

    if self.isServer then
        if spec.totalFillTypeSellPrice > 0 then
            g_currentMission:addMoney(spec.totalFillTypeSellPrice, self:getOwnerFarmId(), MoneyType.HARVEST_INCOME, true, true)
        end
    end
end


---
function PlaceableSilo:onPlayerActionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    local spec = self.spec_silo
    if self:getOwnerFarmId() == g_currentMission:getFarmId() then
        if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
            if onEnter then
                g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            else
                g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
            end
        end
    end
end


---
function PlaceableSilo:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_silo

    -- collect all fillTypes and levels from storage

    local farmId = g_currentMission:getFarmId()
    for fillType, fillLevel in pairs(spec.loadingStation:getAllFillLevels(farmId)) do
        spec.fillTypesAndLevelsAuxiliary[fillType] = (spec.fillTypesAndLevelsAuxiliary[fillType] or 0) + fillLevel
    end

    -- filter empty fillType, merge to index table for sorting
    table.clear(spec.infoTriggerFillTypesAndLevels)
    for fillType, fillLevel in pairs(spec.fillTypesAndLevelsAuxiliary) do
        if fillLevel > 0.1 then
            spec.fillTypeToFillTypeStorageTable[fillType] = spec.fillTypeToFillTypeStorageTable[fillType] or {fillType=fillType, fillLevel=fillLevel}
            spec.fillTypeToFillTypeStorageTable[fillType].fillLevel = fillLevel
            table.insert(spec.infoTriggerFillTypesAndLevels, spec.fillTypeToFillTypeStorageTable[fillType])
        end
    end

    table.clear(spec.fillTypesAndLevelsAuxiliary)

    table.sort(spec.infoTriggerFillTypesAndLevels, function(a, b) return a.fillLevel > b.fillLevel end)

    local numEntries = math.min(#spec.infoTriggerFillTypesAndLevels, PlaceableSilo.INFO_TRIGGER_NUM_DISPLAYED_FILLTYPES)
    if numEntries > 0 then
        for i=1, numEntries do
            local fillTypeAndLevel = spec.infoTriggerFillTypesAndLevels[i]
            table.insert(infoTable, {title=g_fillTypeManager:getFillTypeTitleByIndex(fillTypeAndLevel.fillType), text=g_i18n:formatVolume(fillTypeAndLevel.fillLevel, 0)})
        end
    else
        table.insert(infoTable, {title="", text=g_i18n:getText("infohud_siloEmpty")})
    end
end


---
function PlaceableSilo.loadSpecValueVolume(xmlFile, customEnvironment, baseDir)
    return xmlFile:getValue("placeable.silo.storages.storage(0)#capacity")
end


---
function PlaceableSilo.getSpecValueVolume(storeItem, realItem)
    if storeItem.specs.siloVolume == nil then
        return nil
    end

    return g_i18n:formatVolume(storeItem.specs.siloVolume)
end



---
local PlaceableSiloActivatable_mt = Class(PlaceableSiloActivatable)


---
function PlaceableSiloActivatable.new(placeable)
    local self = setmetatable({}, PlaceableSiloActivatable_mt)

    self.placeable = placeable
    self.activateText = g_i18n:getText("action_refillSilo")

    return self
end


---
function PlaceableSiloActivatable:run()
    local freeCapacities = {}

    for _, storage in pairs(self.placeable.spec_silo.storages) do
        for fillType, fillLevel in pairs(storage:getFillLevels()) do
            if freeCapacities[fillType] == nil then
                freeCapacities[fillType] = 0
            end

            freeCapacities[fillType] = freeCapacities[fillType] + storage:getFreeCapacity(fillType)
        end
    end

    RefillDialog.show(self.placeable.refillAmount, self.placeable, freeCapacities, PlaceableSilo.REFILL_PRICE_FACTOR)
end




---
local PlaceableSiloRefillEvent_mt = Class(PlaceableSiloRefillEvent, Event)




---
function PlaceableSiloRefillEvent.emptyNew()
    local self = Event.new(PlaceableSiloRefillEvent_mt)
    return self
end


---
function PlaceableSiloRefillEvent.new(placeable, fillTypeIndex, amount, price)
    local self = PlaceableSiloRefillEvent.emptyNew()

    self.placeable = placeable
    self.fillTypeIndex = fillTypeIndex
    self.amount = amount
    self.price = price

    return self
end


---
function PlaceableSiloRefillEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteInt32(streamId, self.amount)
    streamWriteInt32(streamId, self.price)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end


---
function PlaceableSiloRefillEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.amount = streamReadInt32(streamId)
    self.price = streamReadInt32(streamId)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    self:run(connection)
end


---
function PlaceableSiloRefillEvent:run(connection)
    if not connection:getIsServer() then
        self.placeable:refillAmount(self.fillTypeIndex, self.amount, self.price)
    end
end
