










---
local YarderTowerFollowModeEvent_mt = Class(YarderTowerFollowModeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function YarderTowerFollowModeEvent.emptyNew()
    local self = Event.new(YarderTowerFollowModeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function YarderTowerFollowModeEvent.new(object, state)
    local self = YarderTowerFollowModeEvent.emptyNew()
    self.object = object
    self.state = state

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function YarderTowerFollowModeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadUIntN(streamId, 2)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function YarderTowerFollowModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.state, 2)
end


---Run action on receiving side
-- @param integer connection connection
function YarderTowerFollowModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setYarderCarriageFollowMode(self.state, connection, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer state state
-- @param boolean noEventSend no event send
function YarderTowerFollowModeEvent.sendEvent(vehicle, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(YarderTowerFollowModeEvent.new(vehicle, state), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(YarderTowerFollowModeEvent.new(vehicle, state))
        end
    end
end
