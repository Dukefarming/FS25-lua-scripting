




---Event for sprayer doubled amount state
local SprayerDoubledAmountEvent_mt = Class(SprayerDoubledAmountEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SprayerDoubledAmountEvent.emptyNew()
    local self = Event.new(SprayerDoubledAmountEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer isActive pipe state
function SprayerDoubledAmountEvent.new(object, isActive)
    local self = SprayerDoubledAmountEvent.emptyNew()
    self.object = object
    self.isActive = isActive

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SprayerDoubledAmountEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isActive = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SprayerDoubledAmountEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isActive)
end


---Run action on receiving side
-- @param integer connection connection
function SprayerDoubledAmountEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setSprayerDoubledAmountActive(self.isActive, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SprayerDoubledAmountEvent.new(self.object, self.isActive), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean isActive is active
-- @param boolean noEventSend no event send
function SprayerDoubledAmountEvent.sendEvent(vehicle, isActive, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SprayerDoubledAmountEvent.new(vehicle, isActive), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(SprayerDoubledAmountEvent.new(vehicle, isActive))
        end
    end
end
