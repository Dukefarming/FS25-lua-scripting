










---
local BuyingStation_mt = Class(BuyingStation, LoadingStation)










































































































































































---
function BuyingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#statsName", "Name in stats", "other")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)

    LoadingStation.registerXMLPaths(schema, basePath)
end


---
function BuyingStation.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
    local fillTypeNames
    local fillTypesNamesString = xmlFile:getValue("placeable.buyingStation#fillTypes")

    if fillTypesNamesString ~= nil and fillTypesNamesString:trim() ~= "" then
        fillTypeNames = {}
        for _, fillTypeName in pairs(string.split(fillTypesNamesString, " ")) do
            fillTypeNames[string.upper(fillTypeName)] = true
        end
    end

    for _, unloadTriggerKey in xmlFile:iterator("placeable.buyingStation.loadTrigger") do
        local fillTypeNamesString = xmlFile:getValue(unloadTriggerKey .. "#fillTypes")
        if fillTypeNamesString ~= nil and fillTypeNamesString:trim() ~= "" then
            fillTypeNames = fillTypeNames or {}
            for _, fillTypeName in pairs(string.split(fillTypeNamesString, " ")) do
                fillTypeNames[string.upper(fillTypeName)] = true
            end
        end
    end

    -- also include heapSpawner
    fillTypeNames = PlaceableHeapSpawner.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, fillTypeNames)

    return fillTypeNames
end


---
function BuyingStation.getSpecValueFillTypes(storeItem, realItem)
    if storeItem.specs.buyingStationFillTypes == nil then
        return nil
    end

    return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.buyingStationFillTypes, " "))
end
