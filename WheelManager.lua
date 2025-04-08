




















---This class manages the available wheels
local WheelManager_mt = Class(WheelManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function WheelManager.new(customMt)
    return AbstractManager.new(customMt or WheelManager_mt)
end


---Initialize data structures
function WheelManager:initDataStructures()
    self.wheels = {}
    self.wheelsByBasePath = {}
    self.sortedTypedWheels = {}
    self.wheelFilenameToAttributes = {}
end


---Load data on map load
-- @return boolean true if loading was successful else false
function WheelManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    WheelManager:superClass().loadMapData(self)
    self.baseDirectory = baseDirectory

    local wheelsXMLFile = XMLFile.load("wheelsXML", WheelManager.DEFAULT_FILENAME)
    if wheelsXMLFile ~= nil then
        self:loadWheelsFromXML(wheelsXMLFile, "wheels", baseDirectory)

        wheelsXMLFile:delete()
    end

    return true
end


---Load wheels from xml
-- @param table xmlFile xml file object
-- @param string key xml key to laod from
-- @param string baseDirectory base directory
function WheelManager:loadWheelsFromXML(xmlFile, key, baseDirectory)
    xmlFile:iterate(key .. ".wheel", function(_, wheelKey)
        local wheel = {}
        wheel.path = xmlFile:getString(wheelKey .. "#filename")
        if wheel.path == nil then
            Logging.xmlWarning(xmlFile, "Missing filename for wheel '%s'", wheelKey)
            return
        else
            wheel.path = Utils.getFilename(wheel.path, baseDirectory)
        end

        wheel.radius = xmlFile:getFloat(wheelKey .. "#radius")
        if wheel.radius == nil then
            Logging.xmlWarning(xmlFile, "Missing radius for wheel '%s'", wheelKey)
            return
        end

        wheel.width = xmlFile:getFloat(wheelKey .. "#width")
        if wheel.width == nil then
            Logging.xmlWarning(xmlFile, "Missing width for wheel '%s'", wheelKey)
            return
        end

        wheel.category = xmlFile:getString(wheelKey .. "#category", "UNKNOWN")

        wheel.allowMixture = xmlFile:getBool(wheelKey .. "#allowMixture", true)
        wheel.priority = xmlFile:getInt(wheelKey .. "#priority", 1)

        wheel.filename = Utils.getFilenameFromPath(wheel.path)
        wheel.filename = string.split(wheel.filename, ".")[1]

        wheel.basePath = Utils.getDirectory(wheel.path)

        local pathParts = wheel.basePath:split("/")
        wheel.wheelBrand = g_brandManager:getBrandByName(pathParts[#pathParts - 2]) or g_brandManager:getBrandByIndex(Brand.NONE)

        wheel.wheelName = pathParts[#pathParts - 1] or "Unknown"

        if self.wheelFilenameToAttributes[wheel.filename] == nil then
            self.wheelFilenameToAttributes[wheel.filename] = {baseFilename=wheel.path, radius=wheel.radius, width=wheel.width}
        else
            local targetAttributes = self.wheelFilenameToAttributes[wheel.filename]
            if math.abs(wheel.radius - targetAttributes.radius) > 0.001 then
               Logging.xmlWarning(xmlFile, "Invalid radius for wheel '%s'. Does not equal the default radius for this tire size. (Base: %.3f from %s)", wheel.path, targetAttributes.radius, targetAttributes.baseFilename)
            end
            if math.abs(wheel.width - targetAttributes.width) > 0.001 then
                Logging.xmlWarning(xmlFile, "Invalid width for wheel '%s'. Does not equal the default width for this tire size. (Base: %.3f from %s)", wheel.path, targetAttributes.width, targetAttributes.baseFilename)
            end
        end

        table.insert(self.wheels, wheel)

        if self.wheelsByBasePath[wheel.basePath] == nil then
            self.wheelsByBasePath[wheel.basePath] = {}
            table.insert(self.sortedTypedWheels, self.wheelsByBasePath[wheel.basePath])
        end
        table.insert(self.wheelsByBasePath[wheel.basePath], wheel)
    end)

    table.sort(self.sortedTypedWheels, function(a, b)
        if a[1].wheelBrand.name == b[1].wheelBrand.name then
            if a[1].priority == b[1].priority then
                return a[1].wheelName < b[1].wheelName
            else
                return a[1].priority > b[1].priority
            end
        else
            return a[1].wheelBrand.name < b[1].wheelBrand.name
        end
    end)
end



































































































































































































---Returns the radius and width for the given wheel dimension string (if available)
-- @param string dimension dimension string (e.g. '600_70R34')
-- @return float radius radius (nil, if not available)
-- @return float width width (nil, if not available)
function WheelManager:getWheelRadiusAndWidthFromDimension(dimension)
    for _, wheels in ipairs(self.sortedTypedWheels) do
        for _, wheel in ipairs(wheels) do
            if wheel.filename == dimension then
                return wheel.radius, wheel.width
            end
        end
    end

    return nil, nil
end


---Returns the radius and width for the given wheel xml path
-- @param string filename filename (e.g. 'data/shared/wheels/tires/trelleborg/TM1000/900_60R42.xml')
-- @return float radius radius (nil, if not available)
-- @return float width width (nil, if not available)
function WheelManager:getWheelRadiusAndWidthFromFilename(filename)
    for _, wheels in ipairs(self.sortedTypedWheels) do
        for _, wheel in ipairs(wheels) do
            if wheel.path == filename then
                return wheel.radius, wheel.width
            end
        end
    end

    return nil, nil
end
