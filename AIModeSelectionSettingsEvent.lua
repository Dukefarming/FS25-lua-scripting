




---Event from client to server to send the latest settings that were used on the client side
local AIModeSelectionSettingsEvent_mt = Class(AIModeSelectionSettingsEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIModeSelectionSettingsEvent.emptyNew()
    local self = Event.new(AIModeSelectionSettingsEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer currentAngle current angle
function AIModeSelectionSettingsEvent.new(vehicle, fieldCourseSettings)
    local self = AIModeSelectionSettingsEvent.emptyNew()
    self.vehicle = vehicle
    self.fieldCourseSettings = fieldCourseSettings

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIModeSelectionSettingsEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    local attributes = FieldCourseSettings.readStream(streamId, connection)

    self.fieldCourseSettings = FieldCourseSettings.new(self.vehicle)
    self.fieldCourseSettings:applyAttributes(attributes)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIModeSelectionSettingsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    self.fieldCourseSettings:writeStream(streamId, connection)
end


---Run action on receiving side
-- @param integer connection connection
function AIModeSelectionSettingsEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setAIModeFieldCourseSettings(self.fieldCourseSettings)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(AIModeSelectionSettingsEvent.new(self.vehicle, self.fieldCourseSettings), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function AIModeSelectionSettingsEvent.sendEvent(vehicle, fieldCourseSettings, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AIModeSelectionSettingsEvent.new(vehicle, fieldCourseSettings), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(AIModeSelectionSettingsEvent.new(vehicle, fieldCourseSettings))
        end
    end
end
