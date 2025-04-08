










---
local Storage_mt = Class(Storage, Object)




---
function Storage.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Storage node")
    schema:register(XMLValueType.FLOAT, basePath .. "#capacity", "Total capacity", 100000)
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLevelSyncThreshold", "Fill level difference needed for synchronization in Multiplayer", 1)
    schema:register(XMLValueType.BOOL, basePath .. "#supportsMultipleFillTypes", "If true capacity can be used by multiple fill types at the same time. If false only one filltype is allowed", true)
    schema:register(XMLValueType.FLOAT, basePath .. "#costsPerFillLevelAndDay", "Costs per fill level and day", 0)
    schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported fill type categories")
    schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported fill types")
    schema:register(XMLValueType.BOOL, basePath .. "#isExtension", "If storage is an extension")
    schema:register(XMLValueType.STRING, basePath .. ".capacity(?)#fillType", "Custom filltype capacity")
    schema:register(XMLValueType.FLOAT, basePath .. ".capacity(?)#capacity", "Custom filltype capacity")
    schema:register(XMLValueType.STRING, basePath .. ".startFillLevel(?)#fillType", "Start filllevel fill type")
    schema:register(XMLValueType.FLOAT, basePath .. ".startFillLevel(?)#fillLevel", "Start filllevel")
    FillPlane.registerXMLPaths(schema, basePath .. ".fillPlane(?)")
    schema:register(XMLValueType.STRING, basePath .. ".fillPlane(?)#fillType", "Fillplane fill type")

    FillPlaneUtil.registerFillPlaneXMLPaths(schema, basePath .. ".dynamicFillPlane")
    schema:register(XMLValueType.STRING, basePath .. ".dynamicFillPlane#defaultFillType", "Fillplane default filltype")
end


---
function Storage.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.INT, basePath .. "#farmId", "Owner farm land id", 0)
    schema:register(XMLValueType.STRING, basePath .. ".node(?)#fillType", "Fill type name")
    schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#fillLevel", "Fill level", 0)
end


---Creating new instance of storage class
-- @param boolean isServer is server
-- @param boolean isClient is client
-- @param table? customMt custom metatable
-- @return table self new instance of object
function Storage.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or Storage_mt)

    self.unloadingStations = {}
    self.loadingStations = {}
    self.fillLevelChangedListeners = {}

    self.rootNode = 0
    self.foreignSilo = false

    return self
end


---Load storage attributes from object
-- @param table components components
-- @param table xmlFile xml file object
-- @param string key xml key
-- @param table i3dMappings i3dMappings
-- @return boolean success success
function Storage:load(components, xmlFile, key, i3dMappings)
    self.rootNode = xmlFile:getValue(key .. "#node", components[1].node, components, i3dMappings)

    self.costsPerFillLevelAndDay = xmlFile:getValue(key .. "#costsPerFillLevelAndDay") or 0
    self.capacity = xmlFile:getValue(key .. "#capacity", 100000)
    self.fillLevelSyncThreshold = xmlFile:getValue(key .. "#fillLevelSyncThreshold", 1) -- sync every liter unless defined differently in xml
    self.supportsMultipleFillTypes = xmlFile:getValue(key .. "#supportsMultipleFillTypes", true)

    self.capacities = {}
    self.fillTypes = {}
    self.fillLevels = {}
    self.fillLevelsLastSynced = {}  -- MP sync
    self.fillLevelsLastPublished = {}  -- fillLevelChangedListeners
    self.sortedFillTypes = {}

    local fillTypeCategories = xmlFile:getValue(key .. "#fillTypeCategories")
    local fillTypeNames = xmlFile:getValue(key .. "#fillTypes")
    local fillTypes

    if fillTypeCategories ~= nil and fillTypeNames == nil then
        fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '"..tostring(key).. "' has invalid fillTypeCategory '%s'.")
    elseif fillTypeCategories == nil and fillTypeNames ~= nil then
        fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '"..tostring(key).. "' has invalid fillType '%s'.")
    end

    if fillTypes ~= nil then
        for _,fillType in pairs(fillTypes) do
            self.fillTypes[fillType] = true
        end
    end

    xmlFile:iterate(key .. ".capacity", function(_, capacityKey)
        local fillTypeName = xmlFile:getValue(capacityKey.."#fillType")
        local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        if fillType ~= nil then
            self.fillTypes[fillType] = true
            local capacity = xmlFile:getValue(capacityKey.. "#capacity", 100000)
            self.capacities[fillType] = capacity
        else
            Logging.xmlWarning(xmlFile, "FillType '%s' not defined for '%s'", fillTypeName, capacityKey)
        end
    end)

    if table.size(self.fillTypes) == 0 then
        Logging.xmlError(xmlFile, "'Storage' entry %s needs either the 'fillTypeCategories', 'fillTypes' attribute or fillType specific capacities.", key)
        return false
    end

    for fillType,_ in pairs(self.fillTypes) do
        table.insert(self.sortedFillTypes, fillType)
        self.fillLevels[fillType] = 0
        self.fillLevelsLastSynced[fillType] = 0
        self.fillLevelsLastPublished[fillType] = 0
    end
    table.sort(self.sortedFillTypes)

    local usedCapacity = 0
    xmlFile:iterate(key .. ".startFillLevel", function(_, fillLevelKey)
        local fillTypeName = xmlFile:getValue(fillLevelKey.."#fillType")
        local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        if fillType ~= nil then
            if self.fillLevels[fillType] ~= nil then
                local fillLevel = xmlFile:getValue(fillLevelKey.. "#fillLevel")
                if self.supportsMultipleFillTypes then
                    if self.capacities[fillType] ~= nil then
                        fillLevel = math.clamp(fillLevel, 0, self.capacities[fillType])
                        self.fillLevels[fillType] = fillLevel
                    else
                        fillLevel = math.clamp(fillLevel, 0, self.capacity - usedCapacity)
                        usedCapacity = usedCapacity + fillLevel
                        self.fillLevels[fillType] = fillLevel
                    end
                else
                    if usedCapacity == 0 then
                        fillLevel = math.clamp(fillLevel, 0, self.capacities[fillType] or self.capacity)
                        usedCapacity = fillLevel
                        self.fillLevels[fillType] = fillLevel
                    else
                        Logging.xmlWarning(xmlFile, "Failed to set start fill level for '%s' because only one filltype allowed at the same time for '%s'", fillTypeName, fillLevelKey)
                    end
                end
            else

                Logging.xmlWarning(xmlFile, "FillType '%s' not supported for '%s'", fillTypeName, fillLevelKey)
            end
        else
            Logging.xmlWarning(xmlFile, "FillType '%s' not defined for '%s'", fillTypeName, fillLevelKey)
        end
    end)

    self.fillPlanes = {}
    xmlFile:iterate(key .. ".fillPlane", function(_, fillPlaneKey)
        local fillTypeName = xmlFile:getValue(fillPlaneKey .. "#fillType")
        local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        if fillType ~= nil then
            local fillPlane = FillPlane.new()
            fillPlane:load(components, xmlFile, fillPlaneKey, i3dMappings)
            self.fillPlanes[fillType] = fillPlane
        end
    end)

    self.dynamicFillPlaneBaseNode = xmlFile:getValue(key .. ".dynamicFillPlane#node", nil, components, i3dMappings)
    if self.dynamicFillPlaneBaseNode ~= nil then
        local defaultFillTypeName = xmlFile:getValue(key.. ".dynamicFillPlane#defaultFillType")
        local defaultFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(defaultFillTypeName) or self.sortedFillTypes[1]

        local fillPlane = FillPlaneUtil.createFromXML(xmlFile, key ..  ".dynamicFillPlane", self.dynamicFillPlaneBaseNode, self.capacities[defaultFillTypeIndex] or self.capacity)

        if fillPlane ~= nil then
            FillPlaneUtil.assignDefaultMaterialsFromTerrain(fillPlane, g_terrainNode)
            FillPlaneUtil.setFillType(fillPlane, defaultFillTypeIndex)

            self.dynamicFillPlane = fillPlane
        end
    end

    self.isExtension = xmlFile:getValue(key .. "#isExtension", false)

    self.storageDirtyFlag = self:getNextDirtyFlag()

    g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)

    return true
end


---Deleting storage
function Storage:delete()
    g_messageCenter:unsubscribeAll(self)

    if self.fillPlanes ~= nil then
        for _, fillPlane in pairs(self.fillPlanes) do
            fillPlane:delete()
        end
        self.fillPlanes = nil
    end

    Storage:superClass().delete(self)
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Storage:readStream(streamId, connection)
    Storage:superClass().readStream(self, streamId, connection)

    for _, fillType in ipairs(self.sortedFillTypes) do
        local fillLevel = 0
        if streamReadBool(streamId) then
            fillLevel = streamReadFloat32(streamId)
        end
        self:setFillLevel(fillLevel, fillType)
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Storage:writeStream(streamId, connection)
    Storage:superClass().writeStream(self, streamId, connection)

    for _, fillType in ipairs(self.sortedFillTypes) do
        local fillLevel = self.fillLevels[fillType]
        if streamWriteBool(streamId, fillLevel > 0) then
            streamWriteFloat32(streamId, fillLevel)
            self.fillLevelsLastSynced[fillType] = fillLevel
        end
    end
end


---Called on client side on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function Storage:readUpdateStream(streamId, timestamp, connection)
    Storage:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            for _, fillType in ipairs(self.sortedFillTypes) do
                local fillLevel = 0
                if streamReadBool(streamId) then
                    fillLevel = streamReadFloat32(streamId)
                end
                self:setFillLevel(fillLevel, fillType)
            end
        end
    end
end


---Called on server side on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function Storage:writeUpdateStream(streamId, connection, dirtyMask)
    Storage:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.storageDirtyFlag) ~= 0) then
            for _, fillType in ipairs(self.sortedFillTypes) do
                local fillLevel = self.fillLevels[fillType]
                if streamWriteBool(streamId, fillLevel > 0) then
                    streamWriteFloat32(streamId, fillLevel)
                    self.fillLevelsLastSynced[fillType] = fillLevel
                end
            end
        end
    end
end


---Loading from attributes and nodes
-- @param integer xmlFile id of xml object
-- @param string key key
-- @return boolean success success
function Storage:loadFromXMLFile(xmlFile, key)
    self:setOwnerFarmId(xmlFile:getValue(key .. "#farmId", AccessHandler.EVERYONE), true)

    -- reset all fillLevels because we only save fillevels > 0
    for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
        self.fillLevels[fillTypeIndex] = 0
    end

    local i = 0
    while true do
        local siloKey = string.format(key .. ".node(%d)", i)
        if not xmlFile:hasProperty(siloKey) then
            break
        end

        local fillTypeStr = xmlFile:getValue(siloKey.."#fillType")
        local fillLevel = math.max(xmlFile:getValue(siloKey.."#fillLevel", 0), 0)
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

        if fillTypeIndex ~= nil then
            if self.fillLevels[fillTypeIndex] ~= nil then
                self:setFillLevel(fillLevel, fillTypeIndex, nil)
            else
                Logging.xmlWarning(xmlFile, "FillType '%s' is not supported by storage", fillTypeStr)
            end
        else
            Logging.xmlWarning(xmlFile, "FillType Invalid filltype '%s'", fillTypeStr)
        end

        i = i + 1
    end

    return true
end


---
function Storage:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key.."#farmId", self:getOwnerFarmId())

    local index = 0
    for fillTypeIndex, fillLevel in pairs(self.fillLevels) do
        if fillLevel > 0 then
            local fillLevelKey = string.format("%s.node(%d)", key, index)
            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
            xmlFile:setValue(fillLevelKey.."#fillType", fillTypeName)
            xmlFile:setValue(fillLevelKey.."#fillLevel", fillLevel)
            index = index + 1
        end
    end
end


---
function Storage:empty()
    for fillType, _ in pairs(self.fillLevels) do
        self.fillLevels[fillType] = 0
        if self.isServer then
            self:raiseDirtyFlags(self.storageDirtyFlag)
        end
    end
end


---
function Storage:updateFillPlanes()
    if self.fillPlanes ~= nil then
        for fillType, fillPlane in pairs(self.fillPlanes) do
            local fillLevel = self.fillLevels[fillType]
            local capacity = self:getCapacity(fillType)
            local factor = 1
            if capacity > 0 then
                factor = fillLevel / capacity
            end
            fillPlane:setState(factor)
        end
    end
end


---Returns if storage allows fill type
-- @param integer fillType fill type
-- @return boolean allow allow fill type
function Storage:getIsFillTypeSupported(fillType)
    return self.fillTypes[fillType] == true
end


---Returns fill level
-- @param integer fillType fill type
-- @return float fillLevel fill level
function Storage:getFillLevel(fillType)
    return self.fillLevels[fillType] or 0
end


---
function Storage:getFillLevels()
    return self.fillLevels
end


---
function Storage:getCapacity(fillType)
    return self.capacities[fillType] or self.capacity
end


---Set fill level of storage
-- @param float fillLevel new fill level
-- @param integer fillType fill type
-- @param table fillInfo fill info table
function Storage:setFillLevel(fillLevel, fillType, fillInfo)
    local capacity = self.capacities[fillType] or self.capacity
    fillLevel = math.clamp(fillLevel, 0, capacity)
    if self.fillLevels[fillType] ~= nil and fillLevel ~= self.fillLevels[fillType] then
        local oldLevel = self.fillLevels[fillType]
        self.fillLevels[fillType] = fillLevel

        local delta = self.fillLevels[fillType] - oldLevel
        local newFillLevelInt = MathUtil.round(self.fillLevels[fillType])
        if math.abs(delta) > 0.1 or (self.fillLevelsLastPublished[fillType] ~= newFillLevelInt) then  -- publish if a full unit change accumulated even if delta is smaller than threshold
            for _, func in ipairs(self.fillLevelChangedListeners) do
                func(fillType, delta)
            end
            self.fillLevelsLastPublished[fillType] = newFillLevelInt
        end

        if self.isServer then
            if (fillLevel < 0.1) or (math.abs(self.fillLevelsLastSynced[fillType] - fillLevel) >= self.fillLevelSyncThreshold) or (capacity - fillLevel < 0.1) then
                self:raiseDirtyFlags(self.storageDirtyFlag)
            end
        end

        self:updateFillPlanes()

        if self.dynamicFillPlane ~= nil then

            FillPlaneUtil.setFillType(self.dynamicFillPlane, fillType)

            local refNode = self.dynamicFillPlane
            local width, length = 1, 1
            if fillInfo ~= nil then
                refNode = fillInfo.node
                length = fillInfo.length
                width = fillInfo.width
            end
            local x,y,z = localToWorld(refNode, 0,0,0)
            local d1x,d1y,d1z = localDirectionToWorld(refNode, width, 0, 0)
            local d2x,d2y,d2z = localDirectionToWorld(refNode, 0, 0, length)

            local steps = math.clamp(math.floor(delta/400), 1, 25)
            for _=1, steps do
                fillPlaneAdd(self.dynamicFillPlane, delta/steps, x,y,z, d1x,d1y,d1z, d2x,d2y,d2z)
            end
        end
    end
end


---Returns free capacity
-- @param integer fillType fill type
-- @return float freeCapacity free capacity
function Storage:getFreeCapacity(fillType)
    if self.fillLevels[fillType] == nil then
        return 0
    end

    if self.supportsMultipleFillTypes then
        if self.capacities[fillType] ~= nil then
            return math.max(self.capacities[fillType] - self.fillLevels[fillType], 0)
        else
            local usedCapacity = 0
            for _, fillLevel in pairs(self.fillLevels) do
                usedCapacity = usedCapacity + fillLevel
            end

            return math.max(self.capacity - usedCapacity, 0)
        end
    end

    local capacity = self.capacities[fillType] or self.capacity
    local usedCapacity = 0
    for usedFillType, usedFillLevel in pairs(self.fillLevels) do
        if fillType == usedFillType then
            usedCapacity = usedFillLevel
        else
            if usedFillLevel > 0 then
                return 0
            end
        end
    end

    return math.max(capacity - usedCapacity, 0)
end


---
function Storage:getSupportedFillTypes()
    return self.fillTypes
end


---Called on hour change
function Storage:hourChanged()
    if self.isServer then
        local fillLevelFactor = (self.costsPerFillLevelAndDay / 24) * EconomyManager.getCostMultiplier()

        local costs = 0
        for _, fillLevel in pairs(self.fillLevels) do
            costs = costs + fillLevel * fillLevelFactor
        end

        g_currentMission:addMoney(-costs, self:getOwnerFarmId(), MoneyType.PROPERTY_MAINTENANCE, true)
    end
end


---
function Storage:addUnloadingStation(station)
    self.unloadingStations[station] = station
end


---
function Storage:removeUnloadingStation(station)
    self.unloadingStations[station] = nil
end


---
function Storage:addLoadingStation(loadingStation)
    self.loadingStations[loadingStation] = loadingStation
end


---
function Storage:removeLoadingStation(loadingStation)
    self.loadingStations[loadingStation] = nil
end


---
function Storage:farmDestroyed(farmId)
    if self:getOwnerFarmId() == farmId then
        for fillType, accepted in pairs(self.fillTypes) do
            if accepted then
                self:setFillLevel(0, fillType)
            end
        end
    end
end


---
function Storage:addFillLevelChangedListeners(func)
    table.addElement(self.fillLevelChangedListeners, func)
end


---
function Storage:removeFillLevelChangedListeners(func)
    table.removeElement(self.fillLevelChangedListeners, func)
end


---Draws fillLevels and capacities for all fillTypes at storage root node
function Storage:draw()
    local debugTable = DebugInfoTable.new()
    local content = {}
    for fillType, accepted in pairs(self.fillTypes) do
        if accepted then
            table.insert(content, {name=g_fillTypeManager:getFillTypeNameByIndex(fillType), value=string.format("%.3f / %.3f\n", self.fillLevels[fillType] or 0, self.capacities[fillType] or self.capacity or -1)})
        end
    end

    debugTable:createWithNodeToCamera(self.rootNode, {{title="Storage (without extensions)", content=content}}, 1, 0.05)
    g_debugManager:addFrameElement(debugTable)
end
