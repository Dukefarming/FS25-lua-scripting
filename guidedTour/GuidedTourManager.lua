









---This class handles guided tours
local GuidedTourManager_mt = Class(GuidedTourManager, AbstractManager)

















---Creating manager
-- @return table instance instance of object
function GuidedTourManager.new(customMt)
    local self = AbstractManager.new(customMt or GuidedTourManager_mt)

    return self
end


---Initialize data structures
function GuidedTourManager:initDataStructures()
    self.guidedTours = {}
    self.nameToGuidedTour = {}
    self.nameToVehicle = {}
    self.nameToPlaceable = {}
    self.goalClasses = {}
    self.actionClasses = {}
    self.progressClasses = {}
end







---Load data on map load
-- @return boolean true if loading was successful else false
function GuidedTourManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    GuidedTourManager:superClass().loadMapData(self)

    local success = XMLUtil.loadDataFromMapXML(xmlFile, "guidedTours", baseDirectory, self, self.loadGuidedTours, missionInfo, baseDirectory)

    if success then
        GuidedTourHelp.init()
    end

    return success
end


---Load data on map load
-- @return boolean true if loading was successful else false
function GuidedTourManager:loadGuidedTours(xmlFileHandle, missionInfo, baseDirectory, isBaseType)
--     if g_currentMission.missionDynamicInfo.isMultiplayer then
--         return false
--     end

    local xmlFile = XMLFile.wrap(xmlFileHandle, Mission00.xmlSchema)

    for _, key in xmlFile:iterator("map.guidedTours.guidedTour") do
        local xmlFilename = xmlFile:getValue(key .. "#filename")
        if xmlFilename == nil then
            Logging.xmlWarning(xmlFile, "Missing filename for guidedTour '%s'", key)
            continue
        end

        local name = xmlFile:getValue(key .. "#name")
        if name == nil then
            Logging.xmlWarning(xmlFile, "Missing name for guidedTour '%s'", key)
            continue
        end

        xmlFilename = Utils.getFilename(xmlFilename, baseDirectory)
        local upperName = string.upper(name)

        if self.nameToGuidedTour[upperName] ~= nil then
            Logging.xmlWarning(xmlFile, "GuidedTour with name '%s' already exists for '%s'!", name, key)
            continue
        end

        local guidedTour = GuidedTourUtil.createFromXML(xmlFilename)
        if guidedTour ~= nil then
            table.insert(self.guidedTours, guidedTour)
            self.nameToGuidedTour[upperName] = guidedTour

            guidedTour.name = upperName
            guidedTour.index = #self.guidedTours
        end
    end

    g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GuidedTourManager.onMissionStarted, self)

    xmlFile:delete()

    return true
end


---Write data to savegame file
-- @param string xmlFilename file path
-- @return boolean true if loading was successful else false
function GuidedTourManager:saveToXMLFile(xmlFilename)
    local xmlFile = XMLFile.create("guidedTourXML", xmlFilename, "guidedTour", GuidedTourManager.xmlSchema)
    if xmlFile == nil then
        Logging.error("Failed to create guidedTour xml file")
        return false
    end

    local tour = self.activeTour
    if tour ~= nil then
        xmlFile:setValue("guidedTour.tour#name", tour.name)
        tour:saveToXMLFile(xmlFile, "guidedTour.tour")
    end

    xmlFile:save()
    xmlFile:delete()

    return true
end


---Load data from xml savegame file
-- @param string xmlFilename xml filename
-- @return boolean true if loading was successful else false
function GuidedTourManager:loadFromXMLFile(xmlFilename)
    if xmlFilename == nil then
        return false
    end

    local xmlFile = XMLFile.load("guidedTourXML", xmlFilename, GuidedTourManager.xmlSchema)
    if xmlFile == nil then
        return false
    end

    local tourName = xmlFile:getValue("guidedTour.tour#name")
    local tour = self.nameToGuidedTour[tourName]
    if tour ~= nil then
        if tour:loadFromXMLFile(xmlFile, "guidedTour.tour") then
            self.pendingStartTour = tour
        else
            Logging.xmlWarning(xmlFile, "Could not load guided tour from savegame!")
        end
    end

    xmlFile:delete()

    return true
end
