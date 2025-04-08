




---Event for reverse driving state
local ReverseDrivingSetStateEvent_mt = Class(ReverseDrivingSetStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function ReverseDrivingSetStateEvent.emptyNew()
    local self = Event.new(ReverseDrivingSetStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean isReverseDriving is reverse driving
function ReverseDrivingSetStateEvent.new(vehicle, isReverseDriving)
    local self = ReverseDrivingSetStateEvent.emptyNew()
    self.vehicle = vehicle
    self.isReverseDriving = isReverseDriving
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ReverseDrivingSetStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isReverseDriving = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ReverseDrivingSetStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isReverseDriving)
end


---Run action on receiving side
-- @param integer connection connection
function ReverseDrivingSetStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setIsReverseDriving(self.isReverseDriving, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isReverseDriving is reverse driving
-- @param boolean noEventSend no event send
function ReverseDrivingSetStateEvent.sendEvent(vehicle, isReverseDriving, noEventSend)
    if isReverseDriving ~= vehicle.isReverseDriving then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(ReverseDrivingSetStateEvent.new(vehicle, isReverseDriving), nil, nil, vehicle)
            else
                g_client:getServerConnection():sendEvent(ReverseDrivingSetStateEvent.new(vehicle, isReverseDriving))
            end
        end
    end
end
