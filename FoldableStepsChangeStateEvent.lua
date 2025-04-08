









---
local FoldableStepsChangeStateEvent_mt = Class(FoldableStepsChangeStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FoldableStepsChangeStateEvent.emptyNew()
    local self = Event.new(FoldableStepsChangeStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function FoldableStepsChangeStateEvent.new(object, targetState)
    local self = FoldableStepsChangeStateEvent.emptyNew()
    self.object = object
    self.targetState = targetState

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FoldableStepsChangeStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.targetState = streamReadUIntN(streamId, FoldableSteps.STATE_NUM_BITS)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FoldableStepsChangeStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.targetState, FoldableSteps.STATE_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function FoldableStepsChangeStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setFoldableStepsFoldState(self.targetState, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function FoldableStepsChangeStateEvent.sendEvent(vehicle, targetState, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FoldableStepsChangeStateEvent.new(vehicle, targetState), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(FoldableStepsChangeStateEvent.new(vehicle, targetState))
        end
    end
end
