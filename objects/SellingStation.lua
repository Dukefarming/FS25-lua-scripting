

















---
local SellingStation_mt = Class(SellingStation, UnloadingStation)




















































































































































































































































































































































---Loading from attributes and nodes
-- @param integer xmlFile id of xml object
-- @param string key key
-- @return boolean success success
function SellingStation:loadFromXMLFile(xmlFile, key)
    local i=0
    while true do
        local statsKey = string.format(key..".stats(%d)", i)
        if not xmlFile:hasProperty(statsKey) then
            break
        end
        local fillTypeStr = xmlFile:getValue(statsKey.."#fillType")
        local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
        if fillType ~= nil and self.acceptedFillTypes[fillType] then
            self.totalReceived[fillType] = xmlFile:getValue(statsKey.."#received", 0)
            self.totalPaid[fillType] = xmlFile:getValue(statsKey.."#paid", 0)
            self.pricingDynamics[fillType]:loadFromXMLFile(xmlFile, statsKey)
        end
        i = i + 1
    end

    return true
end

















































































































































































































































































































---
function SellingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.BOOL, basePath .. "#appearsOnStats", "Appears on Stats", false)
    schema:register(XMLValueType.BOOL, basePath .. "#suppressWarnings", "Suppress warnings", false)
    schema:register(XMLValueType.BOOL, basePath .. "#allowMissions", "Allow missions", true)
    schema:register(XMLValueType.BOOL, basePath .. "#hasDynamic", "Has dynamic prices", true)
    schema:register(XMLValueType.INT, basePath .. "#litersForFullPriceDrop", "Liters for full price drop")
    schema:register(XMLValueType.FLOAT, basePath .. "#fullPriceRecoverHours", "Full price recover ingame hours")
    schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported filltypes if no unloadtriggers defined")
    schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported filltypes if no unloadtriggers defined")
    schema:register(XMLValueType.STRING, basePath .. "#incomeName", "Income name for stats")

    schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)
    schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#supportsGreatDemand", "Supports great demand", true)
    schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#disablePriceDrop", "Disable price drop", false)

    UnloadingStation.registerXMLPaths(schema, basePath)
end


---
function SellingStation.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.STRING, basePath .. ".stats(?)#fillType", "Fill type")
    schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#received", "Recieved fill level", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#paid", "Payed fill level", 0)

    PricingDynamics.registerSavegameXMLPaths(schema, basePath .. ".stats(?)")
end


---
-- @param XMLFile xmlFile
-- @param string? customEnvironment
-- @param string? baseDir
-- @return table? fillTypeNames
function SellingStation.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
    local fillTypeNames
    local fillTypesNamesString = xmlFile:getValue("placeable.sellingStation#fillTypes")

    if not string.isNilOrWhitespace(fillTypesNamesString) then
        fillTypeNames = {}
        for _, fillTypeName in pairs(string.split(fillTypesNamesString, " ")) do
            fillTypeNames[fillTypeName] = true
        end
    end

    if xmlFile:hasProperty("placeable.sellingStation") then
        local unloadTriggerFillTypeNames = UnloadTrigger.loadSpecValueFillTypes(xmlFile, "placeable.sellingStation", customEnvironment, baseDir)
        if unloadTriggerFillTypeNames ~= nil then
            fillTypeNames = fillTypeNames or {}
            for fillTypeName in pairs(unloadTriggerFillTypeNames) do
                fillTypeNames[fillTypeName] = true
            end
        end
    end

    if PlaceableConstructible ~= nil and xmlFile:hasProperty("placeable.constructible") then
        fillTypeNames = PlaceableConstructible.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, fillTypeNames)
    end

    return fillTypeNames
end


---
function SellingStation.getSpecValueFillTypes(storeItem, realItem)
    if storeItem.specs.sellingStationFillTypes == nil then
        return nil
    end

    return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.sellingStationFillTypes, " "))
end
