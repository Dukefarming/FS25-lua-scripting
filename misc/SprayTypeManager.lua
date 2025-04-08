











---This class handles all sprayTypes
local SprayTypeManager_mt = Class(SprayTypeManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function SprayTypeManager.new(customMt)
    local self = AbstractManager.new(customMt or SprayTypeManager_mt)
    return self
end


---Initialize data structures
function SprayTypeManager:initDataStructures()
    self.numSprayTypes = 0
    self.sprayTypes = {}
    self.nameToSprayType = {}
    self.nameToIndex = {}
    self.indexToName = {}
    self.fillTypeIndexToSprayType = {}

    SprayType = self.nameToIndex
end


---
function SprayTypeManager:loadDefaultTypes()
    local xmlFile = loadXMLFile("sprayTypes", "data/maps/maps_sprayTypes.xml")
    self:loadSprayTypes(xmlFile, nil, true)
    delete(xmlFile)
end


---Load data on map load
-- @return boolean true if loading was successful else false
function SprayTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    SprayTypeManager:superClass().loadMapData(self)
    self:loadDefaultTypes()
    return XMLUtil.loadDataFromMapXML(xmlFile, "sprayTypes", baseDirectory, self, self.loadSprayTypes, missionInfo)
end


---Load data on map load
-- @return boolean true if loading was successful else false
function SprayTypeManager:loadSprayTypes(xmlFile, missionInfo, isBaseType)
    local i = 0
    while true do
        local key = string.format("map.sprayTypes.sprayType(%d)", i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end

        local name = getXMLString(xmlFile, key.."#name")
        local litersPerSecond = getXMLFloat(xmlFile, key.."#litersPerSecond")
        local typeName = getXMLString(xmlFile, key.."#type")
        local sprayGroundType = FieldSprayType.getValueByName(getXMLString(xmlFile, key.."#sprayGroundType"))
        self:addSprayType(name, litersPerSecond, typeName, sprayGroundType, isBaseType)

        i = i + 1
    end

    return true
end


---Adds a new sprayType
-- @param string name sprayType index name
-- @param float litersPerSecond liter per second
-- @return table sprayType sprayType object
function SprayTypeManager:addSprayType(name, litersPerSecond, typeName, sprayGroundType, isBaseType)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: '"..tostring(name).."' is not a valid name for a sprayType. Ignoring sprayType!")
        return nil
    end

    name = name:upper()

    local fillType = g_fillTypeManager:getFillTypeByName(name)
    if fillType == nil then
        printWarning("Warning: Missing fillType '"..tostring(name).."' for sprayType definition. Ignoring sprayType!")
        return
    end

    if isBaseType and self.nameToSprayType[name] ~= nil then
        printWarning("Warning: SprayType '"..tostring(name).."' already exists. Ignoring sprayType!")
        return nil
    end

    local sprayType = self.nameToSprayType[name]
    if sprayType == nil then
        self.numSprayTypes = self.numSprayTypes + 1

        sprayType = {}
        sprayType.name = name
        sprayType.index = self.numSprayTypes
        sprayType.fillType = fillType
        sprayType.litersPerSecond = Utils.getNoNil(litersPerSecond, 0)
        typeName = typeName:upper()
        sprayType.isFertilizer = typeName == "FERTILIZER"
        sprayType.isLime = typeName == "LIME"
        sprayType.isHerbicide = typeName == "HERBICIDE"

        if not sprayType.isFertilizer and not sprayType.isLime and not sprayType.isHerbicide then
            printWarning("Warning: SprayType '"..tostring(name).."' type '"..tostring(typeName).."' is invalid. Possible values are 'FERTILIZER', 'HERBICIDE' or 'LIME'. Ignoring sprayType!")
            return nil
        end

        table.insert(self.sprayTypes, sprayType)
        self.nameToSprayType[name] = sprayType
        self.nameToIndex[name] = self.numSprayTypes
        self.indexToName[self.numSprayTypes] = name
        self.fillTypeIndexToSprayType[fillType.index] = sprayType
    end

    sprayType.litersPerSecond = litersPerSecond or sprayType.litersPerSecond or 0
    sprayType.sprayGroundType = sprayGroundType or sprayType.sprayGroundType or 1

    return sprayType
end


---Gets a sprayType by index
-- @param integer index the sprayType index
-- @return table sprayType the sprayType object
function SprayTypeManager:getSprayTypeByIndex(index)
    if index ~= nil then
        return self.sprayTypes[index]
    end
    return nil
end


---Gets a sprayType by name
-- @param string name the sprayType name
-- @return table sprayType the sprayType object
function SprayTypeManager:getSprayTypeByName(name)
    if name ~= nil then
        name = name:upper()
        return self.nameToSprayType[name]
    end
    return nil
end


---Gets a fillTypeName by index
-- @param integer index the sprayType index
-- @return string fillTypeName the sprayType name
function SprayTypeManager:getFillTypeNameByIndex(index)
    if index ~= nil then
        return self.indexToName[index]
    end
    return nil
end


---Gets a sprayType index by name
-- @param string name the sprayType index name
-- @return integer fillTypeIndex the sprayType index
function SprayTypeManager:getFillTypeIndexByName(name)
    if name ~= nil then
        name = name:upper()
        return self.nameToIndex[name]
    end
    return nil
end


---Gets a sprayType by index name
-- @param string name the sprayType index name
-- @return table sprayType the sprayType object
function SprayTypeManager:getFillTypeByName(name)
    if name ~= nil then
        name = name:upper()
        return self.nameToSprayType[name]
    end
    return nil
end


---
function SprayTypeManager:getSprayTypeByFillTypeIndex(index)
    if index ~= nil then
        return self.fillTypeIndexToSprayType[index]
    end
    return nil
end


---Gets a sprayTypeIndex by fillType index
-- @param integer index the fillType index
-- @return integer sprayTypeIndex the sprayType index
function SprayTypeManager:getSprayTypeIndexByFillTypeIndex(index)
    if index ~= nil then
        local sprayType = self.fillTypeIndexToSprayType[index]
        if sprayType ~= nil then
            return sprayType.index
        end
    end
    return nil
end


---Gets a list of sprayTypes
-- @return table sprayTypes list of sprayTypes
function SprayTypeManager:getSprayTypes()
    return self.sprayTypes
end
