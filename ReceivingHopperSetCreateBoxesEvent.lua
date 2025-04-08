




---Event for toggle box creation
local ReceivingHopperSetCreateBoxesEvent_mt = Class(ReceivingHopperSetCreateBoxesEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function ReceivingHopperSetCreateBoxesEvent.emptyNew()
    local self = Event.new(ReceivingHopperSetCreateBoxesEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean state state
function ReceivingHopperSetCreateBoxesEvent.new(object, state)
    local self = ReceivingHopperSetCreateBoxesEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ReceivingHopperSetCreateBoxesEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ReceivingHopperSetCreateBoxesEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
end


---Run action on receiving side
-- @param integer connection connection
function ReceivingHopperSetCreateBoxesEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setCreateBoxes(self.state, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(ReceivingHopperSetCreateBoxesEvent.new(self.object, self.state), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean state state
-- @param boolean noEventSend no event send
function ReceivingHopperSetCreateBoxesEvent.sendEvent(vehicle, state, noEventSend)
    if state ~= vehicle.state then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(ReceivingHopperSetCreateBoxesEvent.new(vehicle, state), nil, nil, vehicle)
            else
                g_client:getServerConnection():sendEvent(ReceivingHopperSetCreateBoxesEvent.new(vehicle, state))
            end
        end
    end
end
