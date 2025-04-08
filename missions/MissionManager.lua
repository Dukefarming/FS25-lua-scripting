


















---
local MissionManager_mt = Class(MissionManager, AbstractManager)





















































---Creating manager
-- @return table instance instance of object
function MissionManager.new(customMt)
    local self = AbstractManager.new(customMt or MissionManager_mt)

    self.defaultMissionMapWidth = 512
    self.defaultMissionMapHeight = 512
    self.missionMapNumChannels = 4

    return self
end


---
function MissionManager:initDataStructures()
    self.missions = {}
    self.missionsToDelete = {}
    self.missionTypes = {}
    self.nameToMissionType = {}
    self.missionByUniqueId = {}

    self.missionMap = nil
    self.currentMissionTypeIndex = 0
    self.startMissionTypeIndex = 0

    self.pendingMissionVehicleFiles = {}
    self.missionVehicles = {}

    -- Id used within a game-run. Not saved. To keep the items in order of generation
    -- On both server and client.
    self.nextGeneratedMissionId = 1
    self.generationTimer = 0
end


---Deletes field mission manager
function MissionManager:delete()
    if self.debugBitVectorMap ~= nil then
        g_debugManager:removeElement(self.debugBitVectorMap)
    end
end


---Load data on map load
-- @return boolean true if loading was successful else false
function MissionManager:loadMapData(xmlFile)
    MissionManager:superClass().loadMapData(self)

    local isEnabled = Utils.getNoNil(getXMLBool(xmlFile, "map.missions#enabled"), true)
    if not isEnabled then
        Logging.xmlInfo(xmlFile, "MissionManager: Disabled missions according to configuration")
        return
    end

    self:createMissionMap()
    local currentMission = g_currentMission

    local xmlFileObj = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
    for _, missionType in ipairs(self.missionTypes) do
        local classObject = missionType.classObject

        local key = string.format("map.missions.%s", missionType.name)
        local data = missionType.data
        data.maxNumInstances = xmlFileObj:getInt(key .. "#maxNumInstances") or data.maxNumInstances

        if classObject.loadMapData ~= nil then
            classObject.loadMapData(xmlFileObj, key, currentMission.baseDirectory)
        end
    end
    xmlFileObj:delete()

    if currentMission:getIsServer() then
        currentMission:addUpdateable(self)
    end

    local missionVehicleXmlFilename = getXMLString(xmlFile, "map.missions#vehicleFilename")
    if missionVehicleXmlFilename ~= nil then
        local path = Utils.getFilename(missionVehicleXmlFilename, currentMission.baseDirectory)
        if path ~= nil then
            self:loadVehicleGroups(path, currentMission.baseDirectory)
        end
    else
        Logging.xmlDevWarning(xmlFile, "MissionManager: No vehicleFilename defined for mission vehicles")
    end

    -- From mods and dlcs
    for _, info in ipairs(self.pendingMissionVehicleFiles) do
        self:loadVehicleGroups(info[1], info[2])
    end

    if g_addTestCommands and g_server ~= nil then
        addConsoleCommand("gsMissionGenerate", "Force generating a new mission for given farmland", "consoleGenerateMission", self, "farmlandId; missionType")
        addConsoleCommand("gsMissionLoadVehicleSet", "Loads a specific vehicle set", "consoleLoadVehicleSet", self, "missionType; size; groupIndex")
    end
end


---Unload data on mission delete
function MissionManager:unloadMapData()
    g_messageCenter:unsubscribeAll(self)

    local currentMission = g_currentMission
    currentMission:removeUpdateable(self)

    for _, missionType in ipairs(self.missionTypes) do
        local classObject = missionType.classObject
        if classObject.unloadMapData ~= nil then
            classObject.unloadMapData(missionType.data)
        end
    end

    self:destroyMissionMap()

    removeConsoleCommand("gsMissionGenerate")
    removeConsoleCommand("gsMissionLoadVehicleSet")

    MissionManager:superClass().unloadMapData(self)
end


---Write mission data to savegame file
-- @param string xmlFilename file path
-- @return boolean true if loading was successful else false
function MissionManager:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("missionXML", xmlFilename, "missions", MissionManager.xmlSchemaSavegame)

    if xmlFile ~= nil then
        for _, missionType in ipairs(self.missionTypes) do
            local classObject = missionType.classObject
            local key = string.format("missions.meta.%s", missionType.name)
            if classObject.saveMetaDataToXMLFile ~= nil then
                classObject.saveMetaDataToXMLFile(xmlFile, key)
            end
        end

        local counts = {}
        xmlFile:setValue("missions#version", MissionManager.VERSION)
        for k, mission in ipairs(self.missions) do
            counts[mission.type.name] = (counts[mission.type.name] or 0) + 1

            local missionKey = string.format("missions.%s(%d)", mission.type.name, counts[mission.type.name] - 1)
            mission:saveToXMLFile(xmlFile, missionKey)
        end

        xmlFile:save()
        xmlFile:delete()
    end

    return false
end


---Load fieldjob data from xml savegame file
-- @param string xmlFilename xml filename
function MissionManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        return false
    end

    local xmlFile = XMLFile.load("missionsXML", xmlFilename, MissionManager.xmlSchemaSavegame)
    if xmlFile == nil then
        return false
    end

    local version = xmlFile:getValue("missions#version")
    if version ~= MissionManager.VERSION then
        Logging.xmlWarning(xmlFile, "Missions version does not match current mission manager version")
        xmlFile:delete()
        return true
    end

    for _, missionType in ipairs(self.missionTypes) do
        local classObject = missionType.classObject
        local key = string.format("missions.meta.%s", missionType.name)
        if classObject.loadMetaDataFromXMLFile ~= nil then
            classObject.loadMetaDataFromXMLFile(xmlFile, key)
        end
    end

    local numElements = {}
    for _, key in xmlFile:iterator("missions.*") do
        local missionTypeName = xmlFile:getElementName(key)
        numElements[missionTypeName] = (numElements[missionTypeName] or 0) + 1
        local missionTypeKey = string.format("missions.%s(%d)", missionTypeName, numElements[missionTypeName]-1)

        if missionTypeName ~= "meta" then
            local missionType = self:getMissionType(missionTypeName)
            if missionType ~= nil then
                local mission = missionType.classObject.new(true, g_client ~= nil)
                mission.type = missionType

                self:assignGenerationTime(mission)

                if mission:loadFromXMLFile(xmlFile, missionTypeKey) then
                    local hasValidFarm = mission.farmId == nil or g_farmManager:getFarmById(mission.farmId) ~= nil
                    if hasValidFarm then
                        mission:register()
                        self:addMission(mission)
                    else
                        table.insert(self.missionsToDelete, mission)
                    end
                else
                    table.insert(self.missionsToDelete, mission)
                end
            else
                Logging.xmlWarning(xmlFile, "Mission type '%s' not found for '%s!", missionTypeName, missionTypeKey)
            end
        end
    end

    xmlFile:delete()

    return true
end


---
function MissionManager:getCanStartNewMissionGeneration()
    return not self.missionGenerationInProgress and #self.missions < MissionManager.MAX_MISSIONS and self.generationTimer < 0
end


---Updates field mission ownership data from xml savegame file
-- @param string filename xml filename
function MissionManager:update(dt)
    local currentMission = g_currentMission
    if currentMission:getIsServer() and Platform.gameplay.hasMissions then
        self.generationTimer = self.generationTimer - currentMission:getEffectiveTimeScale() * dt

--#profile     RemoteProfiler.zoneBeginN("MissionManager-UpdateMissions")
        self:updateMissions(dt)
--#profile     RemoteProfiler.zoneEnd()

--#profile     RemoteProfiler.zoneBeginN("MissionManager-MissionGeneration")
        if self:getCanStartNewMissionGeneration() then
            self:startMissionGeneration()
        elseif self.missionGenerationInProgress then
            self:generateMission()
        end
--#profile     RemoteProfiler.zoneEnd()
    end
end


---Update mission timeouts
function MissionManager:updateMissions(dt)
    for _, mission in ipairs(self.missions) do
        if mission.status == MissionStatus.CREATED then
            if not mission:validate() then
                table.insert(self.missionsToDelete, mission)
            end
        end
    end

    for i=#self.missionsToDelete, 1, -1 do
        local mission = table.remove(self.missionsToDelete, i)
        mission:delete()
    end
end


---
function MissionManager:startMissionGeneration()
    g_messageCenter:publish(MessageType.MISSION_GENERATION_START)
    self.currentMissionTypeIndex = math.random(1, #self.missionTypes)
    self.startMissionTypeIndex = self.currentMissionTypeIndex
    self.missionGenerationInProgress = true
end


---
function MissionManager:finishMissionGeneration()
    g_messageCenter:publish(MessageType.MISSION_GENERATION_END)
    self.generationTimer = MissionManager.MISSION_GENERATION_INTERVAL
    self.missionGenerationInProgress = false
end


---
function MissionManager:generateMission()
    local missionType = self.missionTypes[self.currentMissionTypeIndex]
    if missionType == nil then
        self:finishMissionGeneration()
        return
    end

    local success = false
    local classObject = missionType.classObject
    if classObject.tryGenerateMission ~= nil then
        local mission = classObject.tryGenerateMission()
        if mission ~= nil then
            self:registerMission(mission, missionType)
            success = true
        end
    end

    self.currentMissionTypeIndex = self.currentMissionTypeIndex + 1
    if self.currentMissionTypeIndex > #self.missionTypes then
        self.currentMissionTypeIndex = 1
    end

    if self.currentMissionTypeIndex == self.startMissionTypeIndex then
        self:finishMissionGeneration()
        return
    end

    if success then
        self:finishMissionGeneration()
        return
    end
end


---
function MissionManager:registerMission(mission, missionType)
    mission.type = missionType
    mission:register()
    self:addMission(mission)
    g_messageCenter:publish(MessageType.MISSION_GENERATED, mission)
end


---
function MissionManager:addMission(mission)
    -- Ensure the mission has not already been added.
    if mission:getUniqueId() ~= nil and self.missionByUniqueId[mission:getUniqueId()] ~= nil then
        Logging.warning("Tried to add existing mission with unique id of %s! Existing: %s, new: %s", mission:getUniqueId(), tostring(self.missionByUniqueId[mission:getUniqueId()]), tostring(mission))
        return
    end

    -- If the mission has no unique id, give it one.
    if mission:getUniqueId() == nil then
        mission:setUniqueId(Utils.getUniqueId(mission, self.missionByUniqueId, MissionManager.UNIQUE_ID_PREFIX))
    end
    self.missionByUniqueId[mission:getUniqueId()] = mission

    table.addElement(self.missions, mission)
end


---
function MissionManager:removeMission(mission)
    table.removeElement(self.missions, mission)

    local uniqueId = mission:getUniqueId()
    if uniqueId ~= nil then
        self.missionByUniqueId[uniqueId] = nil
    end
end


---
function MissionManager:markMissionForDeletion(mission)
    table.addElement(self.missionsToDelete, mission)
end


---
function MissionManager:getMissionByUniqueId(uniqueId)
    return self.missionByUniqueId[uniqueId]
end


---Start given mission for a farm.
function MissionManager:startMission(mission, farmId, spawnVehicles)
    local currentMission = g_currentMission
    assert(currentMission:getIsServer(), "MissionManager:startMission is a server-only function")

    if farmId == FarmManager.SPECTATOR_FARM_ID then
        return MissionStartState.NO_ACCESS
    end

    -- Allow only one mission per farm
    if self:hasFarmReachedMissionLimit(farmId) then
        return MissionStartState.LIMIT_REACHED
    end

    -- Mission already started
    if mission.activeMissionId then
        return MissionStartState.ALREADY_STARTED
    end

    for _, activeMission in ipairs(self.missions) do
        if activeMission.status == MissionStatus.PREPARING then
            return MissionStartState.PENDING_MISSION
        end
    end

    if not mission:validate() then
        mission:delete()
        return MissionStartState.NOT_AVAILABLE_ANYMORE
    end

    mission.activeMissionId = self:getFreeActiveMissionId()
    if mission.activeMissionId == 0 then
        return MissionStartState.CANNOT_BE_STARTED_NOW
    end

    mission.farmId = farmId

    if not mission:start(spawnVehicles) then
        mission:delete()
        return MissionStartState.CANNOT_BE_STARTED_NOW
    end

    g_messageCenter:publish(MissionStartedEvent, mission)

    return MissionStartState.OK
end


---Cancel mission: sets it to finished without success
function MissionManager:cancelMission(mission)
    local currentMission = g_currentMission
    assert(currentMission:getIsServer(), "MissionManager:cancelMission is a server-only function")

    if mission ~= nil and mission.status ~= MissionStatus.FINISHED then
        mission:finish(MissionFinishState.CANCELED)
        return true
    end

    return false
end


---Dismiss a (finished or cancelled) mission. Deletes it completely. Calls dismiss on the mission to handle money exchange to farm.
-- On a client it sends an event instead
function MissionManager:dismissMission(mission)
    local currentMission = g_currentMission
    assert(currentMission:getIsServer(), "MissionManager:dismissMission is a server-only function")

    mission:dismiss()
    mission:delete()

    return true
end


---
function MissionManager:getMissions()
    return self.missions
end


---Get a missions list. Used in the game menu.
function MissionManager:getMissionsByFarmId(farmId)
    return table.ifilter(self.missions, function (mission)
        -- All missions, but only for active it needs to match the farm
        return mission.farmId == nil or mission.farmId == farmId
    end)
end


---
function MissionManager:getIsMissionRunningOnFarmland(farmland)
    if farmland == nil then
        return false
    end

    local farmlandId = farmland:getId()
    for _, mission in ipairs(self.missions) do
        if mission.getFarmlandId ~= nil and mission:getFarmlandId() == farmlandId then
            if mission:getIsInProgress() then
                return true
            end
        end
    end

    return false
end


---
function MissionManager:getMissionsByType(typeIndex)
    local missionType = self.missionTypes[typeIndex]
    if missionType == nil then
        return nil
    end

    return table.ifilter(self.missions, function(mission)
        return mission:isa(missionType.classObject)
    end)
end


---Get whether given farm has an active mission
function MissionManager:hasFarmReachedMissionLimit(farmId)
    local total = 0

    for _, mission in ipairs(self.missions) do
        if mission.farmId == farmId and mission:getWasStarted() then
            total = total + 1
        end
    end

    return total >= MissionManager.MAX_MISSIONS_PER_FARM
end


---
function MissionManager:createMissionMap()
    self.missionMap = InfoLayer.new("MissionAccessMap")
    self.missionMap:create(self.defaultMissionMapWidth, self.defaultMissionMapHeight, self.missionMapNumChannels, false)

    local currentMission = g_currentMission
    -- disable the growth in the mission field
    if currentMission:getIsServer() then
        currentMission.growthSystem:setGrowthMask(self.missionMap:getId(), 0, self.missionMapNumChannels)
    end

    if MissionManager.DEBUG_ENABLED then
        local cellsize = currentMission.terrainSize / self.defaultMissionMapWidth
        self.debugBitVectorMap = DebugBitVectorMap.newSimple(20, cellsize, false, 0.2)
        self.debugBitVectorMap:createWithCustomFunc(function(instance, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
            local centerX = (startWorldX + widthWorldX + heightWorldX) / 3
            local centerZ = (startWorldZ + widthWorldZ + heightWorldZ) / 3

            local value = self.missionMap:getValueAtWorldPos(centerX, centerZ)
    --         local text = string.format("%d %d: %f", startWorldX / 10, startWorldZ / 10, value)
    --         Utils.renderTextAtWorldPosition(startWorldX / 10, 0, startWorldZ / 10, text)
            return value
        end)
        g_debugManager:addElement(self.debugBitVectorMap)
    end
end


---
function MissionManager:destroyMissionMap()
    local currentMission = g_currentMission
    -- remove the access density map from the growth updaters
    if currentMission:getIsServer() then
        currentMission.growthSystem:resetGrowthMask()
    end

    if self.missionMap ~= nil then
        self.missionMap:delete()
        self.missionMap = nil
    end
end


---
function MissionManager:setMissionMapActiveMissionId(area, missionId)
    if self.missionMap ~= nil then
        self.missionMap:setValueAtArea(area, missionId)
    end
end


---
function MissionManager:getMissionMapActiveMissionIdAtWorldPosition(worldX, worldZ)
    if self.missionMap == nil then
        return 0
    end

    return self.missionMap:getValueAtWorldPos(worldX, worldZ, nil, nil)
end


---Get the mission at given position
-- @return mission or nil if no mission
function MissionManager:getMissionAtWorldPosition(worldX, worldZ)
    local missionId = self:getMissionMapActiveMissionIdAtWorldPosition(worldX, worldZ)

    if missionId > 0 then
        return self:getMissionByActiveMissionId(missionId)
    end

    return nil
end


---Get the mission associated with the activeMissionId
function MissionManager:getMissionByActiveMissionId(activeMissionId)
    for _, mission in ipairs(self.missions) do
        if mission.activeMissionId == activeMissionId then
            return mission
        end
    end

    return nil
end


---Get a free activeMissionId, used for active missions only.
function MissionManager:getFreeActiveMissionId()
    for i = 1, MissionManager.MAX_MISSIONS do
        if self:getMissionByActiveMissionId(i) == nil then
            return i
        end
    end

    return 0
end


---Check whether the player is allowed to work the farm at given location for mission purposes
function MissionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, vehicle)
    local mission = self:getMissionAtWorldPosition(x, z)

    if mission ~= nil then
        if mission.farmId == farmId and mission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle) then
            return true
        end
    end

    return false
end


---Register a new mission type
function MissionManager:registerMissionType(classObject, name, defaultMaxNumInstances)
    if classObject ~= nil and name ~= nil then
        local missionType = {
            name = name,
            classObject = classObject,
            typeId = #self.missionTypes + 1,
            data = {
                numInstances = 0,
                maxNumInstances = defaultMaxNumInstances or 2
            }
        }

        table.insert(self.missionTypes, missionType)
        self.nameToMissionType[string.upper(name)] = missionType
    end
end


---Unregister a mission type
function MissionManager:unregisterMissionType(name)
    if name ~= nil then
        for i, type in ipairs(self.missionTypes) do
            if type.name == name then
                table.remove(self.missionType, i)
                break
            end
        end
    end
end


---Get a mission type with given name
function MissionManager:getMissionType(name)
    return self.nameToMissionType[string.upper(name)]
end


---Get a mission type with given id
function MissionManager:getMissionTypeById(id)
    return self.missionTypes[id]
end


---
function MissionManager:getMissionTypeDataByName(name)
    if name == nil then
        Logging.devError("MissionManager.getMissionTypeDataByName: no mission type name defined")
        if g_isDevelopmentVersion then
            printCallstack()
        end

        return nil
    end

    local missionType = self.nameToMissionType[string.upper(name)]
    if missionType ~= nil then
        return missionType.data
    end

    return nil
end


---
function MissionManager:getMissionBySplitShape(shape)
    if shape == nil or shape == 0 then
        return nil
    end

    for _, mission in ipairs(self.missions) do
        if mission.getIsMissionSplitShape ~= nil then
            if mission:getIsMissionSplitShape(shape) then
                return mission
            end
        end
    end

    return nil
end


---
function MissionManager:getIsShapeCutAllowed(shape, x, z, farmId)
    for _, mission in ipairs(self.missions) do
        if mission.getIsShapeCutAllowed ~= nil then
            local isAllowed = mission:getIsShapeCutAllowed(shape, x, z, farmId)
            if isAllowed ~= nil then
                return isAllowed
            end
        end
    end

    return nil
end


---
function MissionManager:getIsMissionDestructible(farmId, nodeId)
    for _, mission in ipairs(self.missions) do
        if mission.getDestructibleIsInMissionArea ~= nil then
            if mission:getDestructibleIsInMissionArea(nodeId, farmId) then
                return true
            end
        end
    end

    return false
end


---
function MissionManager:addPendingMissionVehiclesFile(filename, baseDirectory)
    table.insert(self.pendingMissionVehicleFiles, {filename, baseDirectory})
end


---Load vehicles for use with field missions
function MissionManager:loadVehicleGroups(xmlFilename, baseDirectory)
    local xmlFile = XMLFile.load("MissionVehicles", xmlFilename, MissionManager.xmlSchema)
    if xmlFile == nil then
        return false
    end

    for _, missionKey in xmlFile:iterator("missionVehicles.mission") do
        local missionTypeName = xmlFile:getValue(missionKey .. "#type")
        if missionTypeName == nil then
            Logging.xmlError(xmlFile, "Property type must exist on each mission - '%s'", missionKey)
            continue
        end

        local missionType = self:getMissionType(missionTypeName)
        if missionType == nil then
            Logging.xmlError(xmlFile, "Mission type '%s' is not defined - '%s'", missionTypeName, missionKey)
            continue
        end

        if self.missionVehicles[missionTypeName] == nil then
            self.missionVehicles[missionTypeName] = {}
        end
        local groups = self.missionVehicles[missionTypeName]

        for _, groupKey in xmlFile:iterator(missionKey .. ".group") do
            local size = xmlFile:getValue(groupKey .. "#size", "medium")
            local rewardScale = xmlFile:getValue(groupKey .. "#rewardScale", 1.0)
            local success = true
            local vehicles = {}
            local group = {
                rewardScale = rewardScale,
                vehicles = vehicles,
                variant = xmlFile:getValue(groupKey .. "#variant"),
            }

            for _, vehicleKey in xmlFile:iterator(groupKey .. ".vehicle") do
                local vehicleXMLFilename = Utils.getFilename(xmlFile:getValue(vehicleKey .. "#filename"), baseDirectory)
                if vehicleXMLFilename == nil then
                    success = false
                    Logging.xmlError(xmlFile, "Missing 'filename' attribute for vehicle %q", vehicleKey)
                    break
                end

                local storeItem = g_storeManager:getItemByXMLFilename(vehicleXMLFilename)
                if storeItem == nil then
                    success = false
                    Logging.xmlError(xmlFile, "Unable to load store item for xml filename '%q at %q", vehicleXMLFilename, vehicleKey)
                    break
                end

                -- Read configurations
                local configurations
                for _, configKey in xmlFile:iterator(vehicleKey .. ".configuration") do
                    local name = xmlFile:getValue(configKey .. "#name")
                    local id = xmlFile:getValue(configKey .. "#id")

                    if name == nil then
                        Logging.xmlError(xmlFile, "Missing 'name' attribute for configuration at %q", configKey)
                        continue
                    end
                    if id == nil then
                        Logging.xmlError(xmlFile, "Missing 'id' attribute for configuration %q at %q", name, configKey)
                        continue
                    end
--#debug                         if ConfigurationUtil.getConfigItemByConfigId(vehicleXMLFilename, name, id) == nil then
--#debug                             Logging.xmlError(xmlFile, "Config id %q for config %q in vehicle %q at %q does not exist", id, name, vehicleXMLFilename, configKey)
--#debug                             continue
--#debug                         end
                    configurations = configurations or {}
                    configurations[name] = id
                end

                table.insert(vehicles, {
                    filename = vehicleXMLFilename,
                    configurations = configurations
                })
            end

            if success then
                if groups[size] == nil then
                    groups[size] = {}
                end

                table.insert(groups[size], group)
                group.identifier = #groups[size]
            end
        end
    end

    xmlFile:delete()

    return true
end



---Get a randomly chosen group of vehicles fitting for given mission type and field size
-- @param string missionType type of mission (string)
-- @param string size size of field: 'small', 'medium', 'large'
-- @param string variant variant identifier
-- @return list vehicles each element is a table with filaname and configuration properties.
-- @return integer group identifier
function MissionManager:getRandomVehicleGroup(missionType, size, variant)
    local groups = self.missionVehicles[missionType]
    if groups == nil then
        return nil, 1
    end

    local sized = groups[size]
    if sized == nil then
        return nil, 1
    end

    local variantGroups = table.ifilter(sized, function (group)
        return variant == nil or group.variant == variant
    end)

    local group = table.getRandomElement(variantGroups)
    if group == nil then
        return nil, 1
    end

    return group.vehicles, group.identifier
end


---Used on the client. Make sure it never crashes on nil (patches)
function MissionManager:getVehicleGroupFromIdentifier(missionType, fieldSize, identifier)
    local groups = self.missionVehicles[missionType]
    if groups == nil then
        return nil, 1.0
    end

    local sized = groups[fieldSize]
    if sized == nil then
        return nil, 1.0
    end

    local group = sized[identifier]
    if group == nil then
        return nil, 1.0
    end

    return group.vehicles, group.rewardScale
end


---Generation time is used for reliably sorting
function MissionManager:assignGenerationTime(mission)
    mission.generationTime = self.nextGeneratedMissionId
    self.nextGeneratedMissionId = self.nextGeneratedMissionId + 1
end
