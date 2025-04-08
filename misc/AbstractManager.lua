









---This class is an abstract template to be implemented by all map-bound manager classes
local AbstractManager_mt = Class(AbstractManager)


---Creating manager
-- @return table instance instance of object
function AbstractManager.new(customMt)
    if customMt ~= nil and type(customMt) ~= "table" then
        printCallstack()
    end
    local self = setmetatable({}, customMt or AbstractManager_mt)

    self:initDataStructures()
    self.loadedMapData = false

    return self
end


---Initialize data structures
function AbstractManager:initDataStructures()
end


---Loads initial manager
-- @return boolean true if loading was successful else false
function AbstractManager:load()
    return true
end


---Load data on map load
-- @return boolean true if loading was successful else false
function AbstractManager:loadMapData()
    if g_isDevelopmentVersion and self.loadedMapData then
        Logging.error("Manager map-data already loaded or not deleted after last game load!")
        printCallstack()
    end
    self.loadedMapData = true
    return true
end


---Unload data on mission delete
function AbstractManager:unloadMapData()
    self.loadedMapData = false
    self:initDataStructures()
end
