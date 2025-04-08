




---Event for turned on state
local SetTurnedOnEvent_mt = Class(SetTurnedOnEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetTurnedOnEvent.emptyNew()
    local self = Event.new(SetTurnedOnEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isTurnedOn is turned on state
function SetTurnedOnEvent.new(object, isTurnedOn)
    local self = SetTurnedOnEvent.emptyNew()
    self.object = object
    self.isTurnedOn = isTurnedOn
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetTurnedOnEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isTurnedOn = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetTurnedOnEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isTurnedOn)
end


---Run action on receiving side
-- @param integer connection connection
function SetTurnedOnEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setIsTurnedOn(self.isTurnedOn, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean isTurnedOn is turned on state
-- @param boolean noEventSend no event send
function SetTurnedOnEvent.sendEvent(vehicle, isTurnedOn, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetTurnedOnEvent.new(vehicle, isTurnedOn), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(SetTurnedOnEvent.new(vehicle, isTurnedOn))
        end
    end
end
