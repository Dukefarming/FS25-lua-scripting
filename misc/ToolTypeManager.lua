











---This class handles all toolTypes
local ToolTypeManager_mt = Class(ToolTypeManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function ToolTypeManager.new(customMt)
    local self = AbstractManager.new(customMt or ToolTypeManager_mt)

    return self
end


---Initialize data structures
function ToolTypeManager:initDataStructures()
    self.indexToName = {}
    self.nameToInt = {}

    ToolType = self.nameToInt
end


---Loads initial manager
-- @return boolean true if loading was successful else false
function ToolTypeManager:loadMapData()
    ToolTypeManager:superClass().loadMapData(self)

    self:addToolType("undefined")
    self:addToolType("dischargeable")
    self:addToolType("pallet")
    self:addToolType("trigger")
    self:addToolType("bale")

    return true
end


---Adds a new baleType
-- @param string name baleType index name
-- @param float litersPerSecond liter per second
-- @return table baleType baleType object
function ToolTypeManager:addToolType(name)
    name = string.upper(name)
    if not ClassUtil.getIsValidIndexName(name) then
        printWarning("Warning: '"..tostring(name).."' is not a valid name for a toolType. Ignoring toolType!")
        return nil
    end

    if ToolType[name] == nil then
        table.insert(self.indexToName, name)
        self.nameToInt[name] = #self.indexToName
    end
    return ToolType[name]
end


---Returns tool type name by given index
-- @param integer toolTypeIndex tool type index
-- @return string toolTypeName tool type name
function ToolTypeManager:getToolTypeNameByIndex(index)
    if self.indexToName[index] ~= nil then
        return self.indexToName[index]
    end

    return "UNDEFINED"
end


---Returns tool type index by given name
-- @param string toolTypeName tool type name
-- @return integer toolTypeIndex tool type index
function ToolTypeManager:getToolTypeIndexByName(name)
    name = name:upper()
    if self.nameToInt[name] ~= nil then
        return self.nameToInt[name]
    end

    return ToolType.UNDEFINED
end


---Returns number of tool types
-- @return integer numToolTypes number of tool types
function ToolTypeManager:getNumberOfToolTypes()
    return #self.indexToName
end
