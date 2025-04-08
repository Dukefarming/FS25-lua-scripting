




---Event for pipe discharge to ground state
local SetPipeDischargeToGroundEvent_mt = Class(SetPipeDischargeToGroundEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetPipeDischargeToGroundEvent.emptyNew()
    local self = Event.new(SetPipeDischargeToGroundEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean dischargeState discharge to ground state
function SetPipeDischargeToGroundEvent.new(object, dischargeState)
    local self = SetPipeDischargeToGroundEvent.emptyNew()
    self.object = object
    self.dischargeState = dischargeState
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetPipeDischargeToGroundEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.dischargeState = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetPipeDischargeToGroundEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.dischargeState)
end


---Run action on receiving side
-- @param integer connection connection
function SetPipeDischargeToGroundEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPipeDischargeToGround(self.dischargeState, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SetPipeDischargeToGroundEvent.new(self.object, self.dischargeState), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean dischargeState discharge to ground state
-- @param boolean noEventSend no event send
function SetPipeDischargeToGroundEvent.sendEvent(object, dischargeState, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetPipeDischargeToGroundEvent.new(object, dischargeState), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(SetPipeDischargeToGroundEvent.new(object, dischargeState))
        end
    end
end
