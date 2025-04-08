




---Event for toggle manual trailer tipping
local TrailerToggleManualTipEvent_mt = Class(TrailerToggleManualTipEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TrailerToggleManualTipEvent.emptyNew()
    local self = Event.new(TrailerToggleManualTipEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean state state
-- @return TrailerToggleManualTipEvent self
function TrailerToggleManualTipEvent.new(object, state)
    local self = TrailerToggleManualTipEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TrailerToggleManualTipEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TrailerToggleManualTipEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
end


---Run action on receiving side
-- @param integer connection connection
function TrailerToggleManualTipEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.state then
            self.object:startTipping(nil, true)
        else
            self.object:stopTipping(true)
        end
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean state belt is active
-- @param boolean? noEventSend no event send
function TrailerToggleManualTipEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TrailerToggleManualTipEvent.new(vehicle, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(TrailerToggleManualTipEvent.new(vehicle, state))
        end
    end
end
