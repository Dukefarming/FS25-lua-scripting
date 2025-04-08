




---Event for variable work width state
local VariableWorkWidthStateEvent_mt = Class(VariableWorkWidthStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function VariableWorkWidthStateEvent.emptyNew()
    local self = Event.new(VariableWorkWidthStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer leftSide leftSide
-- @param integer rightSide rightSide
function VariableWorkWidthStateEvent.new(vehicle, leftSide, rightSide)
    local self = VariableWorkWidthStateEvent.emptyNew()
    self.vehicle = vehicle
    self.leftSide = leftSide
    self.rightSide = rightSide
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VariableWorkWidthStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.leftSide = streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS)
    self.rightSide = streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function VariableWorkWidthStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.leftSide, VariableWorkWidth.SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.rightSide, VariableWorkWidth.SEND_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function VariableWorkWidthStateEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setSectionsActive(self.leftSide, self.rightSide, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(VariableWorkWidthStateEvent.new(self.vehicle, self.leftSide, self.rightSide), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer leftSide leftSide
-- @param integer rightSide rightSide
-- @param boolean noEventSend no event send
function VariableWorkWidthStateEvent.sendEvent(vehicle, leftSide, rightSide, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(VariableWorkWidthStateEvent.new(vehicle, leftSide, rightSide), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(VariableWorkWidthStateEvent.new(vehicle, leftSide, rightSide))
        end
    end
end
