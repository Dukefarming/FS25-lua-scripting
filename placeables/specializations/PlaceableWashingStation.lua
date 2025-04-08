














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableWashingStation.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableWashingStation.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableWashingStation.setOwnerFarmId)
end


---
function PlaceableWashingStation.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWashingStation)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWashingStation)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWashingStation)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableWashingStation)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableWashingStation)
end


---
function PlaceableWashingStation.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("WashingStation")
    WashingStation.registerXMLPaths(schema, basePath .. ".washingStation.station(?)")
    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableWashingStation:onLoad(savegame)
    local spec = self.spec_washingStation

    spec.washingStations = {}
    self.xmlFile:iterate("placeable.washingStation.station", function(_, key)
        local washingStation = WashingStation.new(self.isServer, self.isClient)
        if washingStation:load(self.components, self.xmlFile, key, self.customEnvironment, self.i3dMappings, self.rootNode) then
            table.insert(spec.washingStations, washingStation)
        else
            washingStation:delete()
        end
    end)
end


---
function PlaceableWashingStation:onDelete()
    local spec = self.spec_washingStation

    if spec.washingStations ~= nil then
        for _, washingStation in ipairs(spec.washingStations) do
            washingStation:delete()
        end
    end
end


---
function PlaceableWashingStation:onFinalizePlacement()
    local spec = self.spec_washingStation
    if spec.washingStations ~= nil then
        for _, washingStation in ipairs(spec.washingStations) do
            washingStation:setOwnerFarmId(self:getOwnerFarmId(), true)
            washingStation:register(true)
        end
    end
end


---
function PlaceableWashingStation:onReadStream(streamId, connection)
    local spec = self.spec_washingStation

    if spec.washingStations ~= nil then
        for _, washingStation in ipairs(spec.washingStations) do
            local washingStationId = NetworkUtil.readNodeObjectId(streamId)
            washingStation:readStream(streamId, connection)
            g_client:finishRegisterObject(washingStation, washingStationId)
        end
    end
end


---
function PlaceableWashingStation:onWriteStream(streamId, connection)
    local spec = self.spec_washingStation

    if spec.washingStations ~= nil then
        for _, washingStation in ipairs(spec.washingStations) do
            NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(washingStation))
            washingStation:writeStream(streamId, connection)
            g_server:registerObjectInStream(connection, washingStation)
        end
    end
end


---
function PlaceableWashingStation:setOwnerFarmId(superFunc, farmId, noEventSend)
    local spec = self.spec_washingStation

    superFunc(self, farmId, noEventSend)

    if spec.washingStations ~= nil then
        for _, washingStation in ipairs(spec.washingStations) do
            washingStation:setOwnerFarmId(farmId, true)
        end
    end
end
