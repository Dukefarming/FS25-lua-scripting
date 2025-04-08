




---Event for honking
local MixerWagonBaleNotAcceptedEvent_mt = Class(MixerWagonBaleNotAcceptedEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function MixerWagonBaleNotAcceptedEvent.emptyNew()
    local self = Event.new(MixerWagonBaleNotAcceptedEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
function MixerWagonBaleNotAcceptedEvent.new()
    local self = MixerWagonBaleNotAcceptedEvent.emptyNew()
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MixerWagonBaleNotAcceptedEvent:readStream(streamId, connection)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MixerWagonBaleNotAcceptedEvent:writeStream(streamId, connection)
end


---
function MixerWagonBaleNotAcceptedEvent:run(connection)
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("warning_baleNotSupported"))
end
