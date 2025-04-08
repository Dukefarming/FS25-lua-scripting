




---Event for straw enable state
local CombineStrawEnableEvent_mt = Class(CombineStrawEnableEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function CombineStrawEnableEvent.emptyNew()
    local self = Event.new(CombineStrawEnableEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean isSwathActive is straw enabled
function CombineStrawEnableEvent.new(vehicle, isSwathActive)
    local self = CombineStrawEnableEvent.emptyNew()
    self.vehicle = vehicle
    self.isSwathActive = isSwathActive
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function CombineStrawEnableEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isSwathActive = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function CombineStrawEnableEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isSwathActive)
end


---Run action on receiving side
-- @param integer connection connection
function CombineStrawEnableEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setIsSwathActive(self.isSwathActive, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(CombineStrawEnableEvent.new(self.vehicle, self.isSwathActive), nil, connection, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isSwathActive is straw enabled
-- @param boolean noEventSend no event send
function CombineStrawEnableEvent.sendEvent(vehicle, isSwathActive, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(CombineStrawEnableEvent.new(vehicle, isSwathActive), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(CombineStrawEnableEvent.new(vehicle, isSwathActive))
        end
    end
end
