
















































---
function UnloadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX,    basePath .. "#exactFillRootNode", "Exact fill root node")
    schema:register(XMLValueType.FLOAT,         basePath .. "#priceScale", "Price scale added for sold goods")
    schema:register(XMLValueType.STRING,        basePath .. "#acceptedToolTypes", "List of accepted tool types")
    FillTypeManager.registerConfigXMLFilltypes(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX,    basePath .. "#aiNode", "AI target node, required for the station to support AI. AI drives to the node in positive Z direction. Height is not relevant.")
    schema:register(XMLValueType.STRING,        basePath .. ".fillTypeConversion(?)#incomingFillType", "Filltype to be converted")
    schema:register(XMLValueType.STRING,        basePath .. ".fillTypeConversion(?)#outgoingFillType", "Filltype to be converted to")
    schema:register(XMLValueType.FLOAT,         basePath .. ".fillTypeConversion(?)#ratio", "Conversion ratio between input- and output amount", 1)
end
---
local UnloadTrigger_mt = Class(UnloadTrigger, Object)



---Creates a new instance of the class
-- @param boolean isServer true if we are server
-- @param boolean isClient true if we are client
-- @param table? customMt meta table
-- @return table self returns the instance
function UnloadTrigger.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or UnloadTrigger_mt)

    self.fillTypes = {}
    self.acceptedToolTypes = {}
    self.fillTypeConversions = {}
    self.notAllowedWarningText = nil

    self.extraAttributes = nil

    return self
end


---Loads elements of the class
-- @param table components components
-- @param table xmlFile xml file object
-- @param string xmlNode xml key
-- @param table target target object
-- @param table extraAttributes extra attributes
-- @param table i3dMappings i3dMappings
-- @return boolean success success
function UnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
    self.exactFillRootNode = xmlFile:getValue(xmlNode .. "#exactFillRootNode", nil, components, i3dMappings)

    if self.exactFillRootNode ~= nil then
        if not CollisionFlag.getHasGroupFlagSet(self.exactFillRootNode, CollisionFlag.FILLABLE) then
            Logging.xmlWarning(xmlFile, "Missing collision group %s. Please add this bit to the collision filter group of exact fill node '%s'", CollisionFlag.getBitAndName(CollisionFlag.FILLABLE), I3DUtil.getNodePath(self.exactFillRootNode))
            return false
        end

        g_currentMission:addNodeObject(self.exactFillRootNode, self)
    end

    self.aiNode = xmlFile:getValue(xmlNode .. "#aiNode", nil, components, i3dMappings)
    self.supportsAIUnloading = self.aiNode ~= nil

    local priceScale = xmlFile:getValue(xmlNode .. "#priceScale", nil)
    if priceScale ~= nil then
        self.extraAttributes = {priceScale = priceScale}
    end

    for _, fillTypeConversionPath in xmlFile:iterator(xmlNode .. ".fillTypeConversion") do
        local fillTypeIndexIncoming = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(fillTypeConversionPath .. "#incomingFillType"))
        if fillTypeIndexIncoming ~= nil then
            local fillTypeIndexOutgoing = g_fillTypeManager:getFillTypeIndexByName(xmlFile:getValue(fillTypeConversionPath .. "#outgoingFillType"))
            if fillTypeIndexOutgoing ~= nil then
                local ratio = math.clamp(xmlFile:getValue(fillTypeConversionPath .. "#ratio", 1), 0.01, 10000)
                self.fillTypeConversions[fillTypeIndexIncoming] = {outgoingFillType=fillTypeIndexOutgoing, ratio=ratio}
            end
        end
    end

    if target ~= nil then
        self:setTarget(target)
    end

    self:loadFillTypes(xmlFile, xmlNode)
    self:loadAcceptedToolType(xmlFile, xmlNode)
    self.isEnabled = true

    --TODO: merge tables
    self.extraAttributes = extraAttributes or self.extraAttributes

    return true
end


---
function UnloadTrigger:delete()
    if self.exactFillRootNode ~= nil then
        g_currentMission:removeNodeObject(self.exactFillRootNode)
    end

    UnloadTrigger:superClass().delete(self)
end


---Loads accepted tool type
-- @param string xmlFile file to read
-- @param string xmlNode xmlNode to read from
function UnloadTrigger:loadAcceptedToolType(xmlFile, xmlNode)
    local acceptedToolTypeNames = xmlFile:getValue(xmlNode .. "#acceptedToolTypes")
    local acceptedToolTypes = string.getVector(acceptedToolTypeNames)

    if acceptedToolTypes ~= nil then
        for _,acceptedToolType in pairs(acceptedToolTypes) do
            local toolTypeInt = g_toolTypeManager:getToolTypeIndexByName(acceptedToolType)
            self.acceptedToolTypes[toolTypeInt] = true
        end
    else
        self.acceptedToolTypes = nil
    end
end



---Loads fill Types
-- @param string xmlFile file to read
-- @param string xmlNode xmlNode to read from
function UnloadTrigger:loadFillTypes(xmlFile, xmlNode)
    local fillTypes = g_fillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, xmlNode)

    if fillTypes ~= nil then
        for _, fillType in pairs(fillTypes) do
            self.fillTypes[fillType] = true
        end
    else
        self.fillTypes = nil
    end
end


---Connects object using the trigger to the trigger
-- @param table object target on which the unload trigger is attached
function UnloadTrigger:setTarget(object)
    assert(object.getIsFillTypeAllowed ~= nil, "Missing 'getIsFillTypeAllowed' method for given target")
    assert(object.getIsToolTypeAllowed ~= nil, "Missing 'getIsToolTypeAllowed' method for given target")
    assert(object.addFillLevelFromTool ~= nil, "Missing 'addFillLevelFromTool' method for given target")
    assert(object.getFreeCapacity ~= nil, "Missing 'getFreeCapacity' method for given target")

    self.target = object
end






---Returns default value '1'
-- @param integer node scenegraph node
function UnloadTrigger:getFillUnitIndexFromNode(node)
    return 1
end


---Returns exactFillRootNode
-- @param integer fillUnitIndex index of fillunit
function UnloadTrigger:getFillUnitExactFillRootNode(fillUnitIndex)
    return self.exactFillRootNode
end


---Increase fill level
-- @param integer fillUnitIndex
-- @param float fillLevelDelta
-- @param integer fillTypeIndex
-- @param table toolType
-- @param table fillPositionData
-- @return float addedAmount
function UnloadTrigger:addFillUnitFillLevel(farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, extraAttributes)
    -- TODO: merge tables
    local fillTypeConverison = self.fillTypeConversions[fillTypeIndex]
    if fillTypeConverison ~= nil then
        local convertedFillType, ratio = fillTypeConverison.outgoingFillType, fillTypeConverison.ratio
        local applied = self.target:addFillLevelFromTool(farmId, fillLevelDelta*ratio, convertedFillType, fillPositionData, toolType, extraAttributes or self.extraAttributes)
        return applied / ratio
    end
    local applied = self.target:addFillLevelFromTool(farmId, fillLevelDelta, fillTypeIndex, fillPositionData, toolType, extraAttributes or self.extraAttributes)
    return applied
end











---Checks if fill type is allowed
-- @param integer fillUnitIndex
-- @param integer fillType
-- @return boolean true if allowed
function UnloadTrigger:getFillUnitAllowsFillType(fillUnitIndex, fillType)
    return self:getIsFillTypeAllowed(fillType)
end


---Checks if fillType is allowed
-- @param integer fillType
-- @return boolean isAllowed true if fillType is supported else false
function UnloadTrigger:getIsFillTypeAllowed(fillType)
    return self:getIsFillTypeSupported(fillType)
end


---Checks if fillType is supported
-- @param integer fillType
-- @return boolean isSupported true if fillType is supported else false
function UnloadTrigger:getIsFillTypeSupported(fillType)
    if self.fillTypes ~= nil then
        if not self.fillTypes[fillType] then
            return false
        end
    end

    if self.target ~= nil then
        local conversion = self.fillTypeConversions[fillType]
        if conversion ~= nil then
            fillType = conversion.outgoingFillType
        end
        if not self.target:getIsFillTypeAllowed(fillType, self.extraAttributes) then
            return false
        end
    end

    return true
end










---Returns the free capacity
-- @param integer fillUnitIndex fill unit index
-- @param integer fillTypeIndex fill type index
-- @return float freeCapacity free capacity
function UnloadTrigger:getFillUnitFreeCapacity(fillUnitIndex, fillTypeIndex, farmId)
    if self.target.getFreeCapacity ~= nil then
        local conversion = self.fillTypeConversions[fillTypeIndex]
        if conversion ~= nil then
            return self.target:getFreeCapacity(conversion.outgoingFillType, farmId, self.extraAttributes) / conversion.ratio
        end
        return self.target:getFreeCapacity(fillTypeIndex, farmId, self.extraAttributes)
    end
    return 0
end


---Checks if toolType is allowed
-- @param integer toolType
-- @return boolean isAllowed true if toolType is allowed else false
function UnloadTrigger:getIsToolTypeAllowed(toolType)
    local accepted = true

    if self.acceptedToolTypes ~= nil then
        if self.acceptedToolTypes[toolType] ~= true then
            accepted = false
        end
    end

    if accepted then
        return self.target:getIsToolTypeAllowed(toolType)
    else
        return false
    end
end


---
function UnloadTrigger:getCustomDischargeNotAllowedWarning()
    return self.notAllowedWarningText
end
