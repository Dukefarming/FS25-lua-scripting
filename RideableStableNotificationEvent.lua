



---
local RideableStableNotificationEvent_mt = Class(RideableStableNotificationEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function RideableStableNotificationEvent.emptyNew()
    local self = Event.new(RideableStableNotificationEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer state state
function RideableStableNotificationEvent.new(isInStable, name)
    local self = RideableStableNotificationEvent.emptyNew()
    self.isInStable = isInStable
    self.name = name
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RideableStableNotificationEvent:readStream(streamId, connection)
    self.isInStable = streamReadBool(streamId)
    self.name = streamReadString(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RideableStableNotificationEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.isInStable)
    streamWriteString(streamId, self.name)
end


---Run action on receiving side
-- @param integer connection connection
function RideableStableNotificationEvent:run(connection)
    if self.isInStable then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("ingameNotification_horseInStable"), self.name))
    else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ingameNotification_horseNotInStable"), self.name))
    end
end
