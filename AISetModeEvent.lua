




---Event for ai mode (worker or steering assist)
local AISetModeEvent_mt = Class(AISetModeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AISetModeEvent.emptyNew()
    local self = Event.new(AISetModeEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer aiMode aiMode
function AISetModeEvent.new(vehicle, aiMode)
    local self = AISetModeEvent.emptyNew()
    self.vehicle = vehicle
    self.aiMode = aiMode
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AISetModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.aiMode = streamReadUIntN(streamId, AIModeSelection.NUM_BITS) + 1
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AISetModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.aiMode - 1, AIModeSelection.NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function AISetModeEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setAIModeSelection(self.aiMode, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(AISetModeEvent.new(self.vehicle, self.aiMode), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer aiMode aiMode
-- @param boolean noEventSend no event send
function AISetModeEvent.sendEvent(vehicle, aiMode, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AISetModeEvent.new(vehicle, aiMode), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(AISetModeEvent.new(vehicle, aiMode))
        end
    end
end
