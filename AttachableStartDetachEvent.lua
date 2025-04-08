




---Event for starting the detach process
local AttachableStartDetachEvent_mt = Class(AttachableStartDetachEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AttachableStartDetachEvent.emptyNew()
    local self = Event.new(AttachableStartDetachEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer currentAngle current angle
function AttachableStartDetachEvent.new(vehicle, state, segmentIndex, segmentIsLeft)
    local self = AttachableStartDetachEvent.emptyNew()
    self.vehicle = vehicle

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AttachableStartDetachEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AttachableStartDetachEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
end


---Run action on receiving side
-- @param integer connection connection
function AttachableStartDetachEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:startDetachProcess(true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(AttachableStartDetachEvent.new(self.vehicle), nil, nil, self.vehicle)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer aiMode aiMode
-- @param boolean noEventSend no event send
function AttachableStartDetachEvent.sendEvent(vehicle, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(AttachableStartDetachEvent.new(vehicle), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(AttachableStartDetachEvent.new(vehicle))
        end
    end
end
