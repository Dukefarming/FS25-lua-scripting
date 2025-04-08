




---Event for tension belts state
local TensionBeltsEvent_mt = Class(TensionBeltsEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TensionBeltsEvent.emptyNew()
    local self = Event.new(TensionBeltsEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isActive belt is active
-- @param integer beltId id of belt
function TensionBeltsEvent.new(object, isActive, beltId)
    local self = TensionBeltsEvent.emptyNew()
    self.object = object
    self.isActive = isActive
    self.beltId = beltId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TensionBeltsEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    if not streamReadBool(streamId) then
        self.beltId = streamReadUIntN(streamId, TensionBelts.NUM_SEND_BITS)+1
    end
    self.isActive = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TensionBeltsEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.beltId == nil)
    if self.beltId ~= nil then
        streamWriteUIntN(streamId, self.beltId-1, TensionBelts.NUM_SEND_BITS)
    end
    streamWriteBool(streamId, self.isActive)
end


---Run action on receiving side
-- @param integer connection connection
function TensionBeltsEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setTensionBeltsActive(self.isActive, self.beltId, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isActive belt is active
-- @param integer beltId id of belt
-- @param boolean noEventSend no event send
function TensionBeltsEvent.sendEvent(vehicle, isActive, beltId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TensionBeltsEvent.new(vehicle, isActive, beltId), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(TensionBeltsEvent.new(vehicle, isActive, beltId))
        end
    end
end
