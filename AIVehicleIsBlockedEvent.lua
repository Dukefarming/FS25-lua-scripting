




---Event for ai block
local AIVehicleIsBlockedEvent_mt = Class(AIVehicleIsBlockedEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIVehicleIsBlockedEvent.emptyNew()
    local self = Event.new(AIVehicleIsBlockedEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isBlocked is blocked
function AIVehicleIsBlockedEvent.new(object, isBlocked)
    local self = AIVehicleIsBlockedEvent.emptyNew()
    self.object = object
    self.isBlocked = isBlocked
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIVehicleIsBlockedEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isBlocked = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIVehicleIsBlockedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isBlocked)
end


---Run action on receiving side
-- @param integer connection connection
function AIVehicleIsBlockedEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.isBlocked then
            self.object:aiBlock()
        else
            self.object:aiContinue()
        end
    end
end
