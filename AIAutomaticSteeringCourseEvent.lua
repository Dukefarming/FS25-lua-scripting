




---Event for current automatic steering course
local AIAutomaticSteeringCourseEvent_mt = Class(AIAutomaticSteeringCourseEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIAutomaticSteeringCourseEvent.emptyNew()
    local self = Event.new(AIAutomaticSteeringCourseEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer currentAngle current angle
function AIAutomaticSteeringCourseEvent.new(vehicle, steeringFieldCourse)
    local self = AIAutomaticSteeringCourseEvent.emptyNew()
    self.vehicle = vehicle
    self.steeringFieldCourse = steeringFieldCourse

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringCourseEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setAIAutomaticSteeringCourse(nil, true)
    end

    if streamReadBool(streamId) then
        SteeringFieldCourse.readStream(streamId, connection, function(steeringFieldCourse)
            if steeringFieldCourse ~= nil then
                if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
                    self.vehicle:setAIAutomaticSteeringCourse(steeringFieldCourse, true)
                end
            end
        end)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIAutomaticSteeringCourseEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    if streamWriteBool(streamId, self.steeringFieldCourse ~= nil) then
        self.steeringFieldCourse:writeStream(streamId, connection)
    end
end


---Run action on receiving side
-- @param integer connection connection
function AIAutomaticSteeringCourseEvent:run(connection)
end
