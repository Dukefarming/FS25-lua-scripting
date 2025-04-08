




---Event from client to server to request a field course with the given settings from the server
local AIAutomaticSteeringRequestEvent_mt = Class(AIAutomaticSteeringRequestEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIAutomaticSteeringRequestEvent.emptyNew()
    local self = Event.new(AIAutomaticSteeringRequestEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer currentAngle current angle
function AIAutomaticSteeringRequestEvent.new(vehicle, x, z, fieldCourseSettings)
    local self = AIAutomaticSteeringRequestEvent.emptyNew()
    self.vehicle = vehicle
    self.x, self.z = x, z
    self.fieldCourseSettings = fieldCourseSettings

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringRequestEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.x, self.z = g_fieldCourseManager:readTerrainDetailPixel(streamId)

    local attributes = FieldCourseSettings.readStream(streamId, connection)

    self.fieldCourseSettings = FieldCourseSettings.new(self.vehicle)
    self.fieldCourseSettings:applyAttributes(attributes)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    g_fieldCourseManager:writeTerrainDetailPixel(streamId, self.x, self.z)

    self.fieldCourseSettings:writeStream(streamId, connection)
end


---Run action on receiving side
-- @param integer connection connection
function AIAutomaticSteeringRequestEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:generateSteeringFieldCourse(self.x, self.z, self.fieldCourseSettings)
    end
end
