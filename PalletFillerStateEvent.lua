









---
local PalletFillerStateEvent_mt = Class(PalletFillerStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PalletFillerStateEvent.emptyNew()
    local self = Event.new(PalletFillerStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function PalletFillerStateEvent.new(object, state)
    local self = PalletFillerStateEvent.emptyNew()
    self.object = object
    self.state = state

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PalletFillerStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = PalletFillerState.readStream(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PalletFillerStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    PalletFillerState.writeStream(streamId, self.state)
end


---Run action on receiving side
-- @param integer connection connection
function PalletFillerStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPalletFillerState(self.state, false, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function PalletFillerStateEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PalletFillerStateEvent.new(vehicle, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(PalletFillerStateEvent.new(vehicle, state))
        end
    end
end
