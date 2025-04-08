













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableBeehivePalletSpawner.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableBeehivePalletSpawner.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "addFillLevel", PlaceableBeehivePalletSpawner.addFillLevel)
    SpecializationUtil.registerFunction(placeableType, "updatePallets", PlaceableBeehivePalletSpawner.updatePallets)
    SpecializationUtil.registerFunction(placeableType, "getPalletCallback", PlaceableBeehivePalletSpawner.getPalletCallback)
end


---
function PlaceableBeehivePalletSpawner.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableBeehivePalletSpawner.canBuy)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableBeehivePalletSpawner.updateInfo)
end


---
function PlaceableBeehivePalletSpawner.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBeehivePalletSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBeehivePalletSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBeehivePalletSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBeehivePalletSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBeehivePalletSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableBeehivePalletSpawner)
    SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableBeehivePalletSpawner)
end


---
function PlaceableBeehivePalletSpawner.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("BeehivePalletSpawner")
    PalletSpawner.registerXMLPaths(schema, basePath .. ".beehivePalletSpawner")
    schema:setXMLSpecializationType()
end


---
function PlaceableBeehivePalletSpawner.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. ".beehivePalletSpawner#pendingLiters", "Pending liters to be spawned")
end


---Called on loading
-- @param table savegame savegame
function PlaceableBeehivePalletSpawner:onLoad(savegame)
    local spec = self.spec_beehivePalletSpawner
    local xmlFile = self.xmlFile

    local palletSpawnerKey = "placeable.beehivePalletSpawner"
    spec.palletSpawner = PalletSpawner.new(self.baseDirectory)
    if not spec.palletSpawner:load(self.components, xmlFile, palletSpawnerKey, self.customEnvironment, self.i3dMappings) then
        Logging.xmlError(xmlFile, "Unable to load pallet spawner %s", palletSpawnerKey)
        self:setLoadingState(PlaceableLoadingState.ERROR)
        return
    end

    spec.pendingLiters = 0
    spec.spawnPending = false
    spec.palletLimitReached = false
    spec.infoHudTooManyPallets = {title=g_i18n:getText("infohud_tooManyPallets")}
    spec.fillType = g_fillTypeManager:getFillTypeIndexByName("HONEY")

    spec.dirtyFlag = self:getNextDirtyFlag()
end


---
function PlaceableBeehivePalletSpawner:onDelete()
    local spec = self.spec_beehivePalletSpawner
    if spec.palletSpawner ~= nil then
        spec.palletSpawner:delete()
    end
    g_currentMission.beehiveSystem:removeBeehivePalletSpawner(self)
end


---
function PlaceableBeehivePalletSpawner:onFinalizePlacement()
    g_currentMission.beehiveSystem:addBeehivePalletSpawner(self)
end


---
function PlaceableBeehivePalletSpawner:onReadStream(streamId, connection)
    if connection:getIsServer() then
        local spec = self.spec_beehivePalletSpawner
        spec.palletLimitReached = streamReadBool(streamId)
    end
end


---
function PlaceableBeehivePalletSpawner:onWriteStream(streamId, connection)
    if not connection:getIsServer() then
        local spec = self.spec_beehivePalletSpawner
        streamWriteBool(streamId, spec.palletLimitReached)
    end
end



---
function PlaceableBeehivePalletSpawner:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        local spec = self.spec_beehivePalletSpawner
        spec.palletLimitReached = streamReadBool(streamId)
    end
end


---
function PlaceableBeehivePalletSpawner:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_beehivePalletSpawner
        streamWriteBool(streamId, spec.palletLimitReached)
    end
end



---
function PlaceableBeehivePalletSpawner:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_beehivePalletSpawner

    spec.pendingLiters = xmlFile:getValue(key..".beehivePalletSpawner#pendingLiters") or spec.pendingLiters
end


---
function PlaceableBeehivePalletSpawner:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_beehivePalletSpawner

    if spec.pendingLiters > 0 then
        xmlFile:setValue(key..".beehivePalletSpawner#pendingLiters", spec.pendingLiters)
    end
end



---
function PlaceableBeehivePalletSpawner:addFillLevel(fillLevel)
    if self.isServer then
        local spec = self.spec_beehivePalletSpawner

        if fillLevel ~= nil then
            spec.pendingLiters = spec.pendingLiters + fillLevel
        end
    end
end


---
function PlaceableBeehivePalletSpawner:updatePallets()
    if self.isServer then
        local spec = self.spec_beehivePalletSpawner

        if not spec.spawnPending and spec.pendingLiters > 10 then
            spec.spawnPending = true
            spec.palletSpawner:getOrSpawnPallet(self:getOwnerFarmId(), spec.fillType, self.getPalletCallback, self)
        end
    end
end


---
function PlaceableBeehivePalletSpawner:getPalletCallback(pallet, result, fillTypeIndex)
    local spec = self.spec_beehivePalletSpawner
    spec.spawnPending = false

    if pallet ~= nil then
        if result == PalletSpawner.RESULT_SUCCESS then
            if spec.palletLimitReached then
                spec.palletLimitReached = false
                self:raiseDirtyFlags(spec.dirtyFlag)
            end
            pallet:emptyAllFillUnits(true)
        end

        local delta = pallet:addFillUnitFillLevel(self:getOwnerFarmId(), 1, spec.pendingLiters, fillTypeIndex, ToolType.UNDEFINED)

        spec.pendingLiters = math.max(spec.pendingLiters - delta, 0)

    elseif result == PalletSpawner.RESULT_NO_SPACE then
        -- TODO: add cooldown or "pallet removed" callback to prevent overlap boxes in every frame
    elseif result == PalletSpawner.PALLET_LIMITED_REACHED then
        if not spec.palletLimitReached then
            spec.palletLimitReached = true
            self:raiseDirtyFlags(spec.dirtyFlag)
        end
    end
end


---
function PlaceableBeehivePalletSpawner:updateInfo(superFunc, infoTable)
    superFunc(self, infoTable)
    local spec = self.spec_beehivePalletSpawner
    if spec.palletLimitReached then
        table.insert(infoTable, spec.infoHudTooManyPallets)
    end
end


---
function PlaceableBeehivePalletSpawner:canBuy(superFunc)
    local canBuy, warning = superFunc(self)
    if not canBuy then
        return false, warning
    end

    if g_currentMission.beehiveSystem:getFarmBeehivePalletSpawner(g_localPlayer.farmId) ~= nil then
        return false, g_i18n:getText("warning_onlyOneOfThisItemAllowedPerFarm")
    end

    return true, nil
end
