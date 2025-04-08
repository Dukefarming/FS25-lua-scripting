









---
local PushHandToolDriveModeEvent_mt = Class(PushHandToolDriveModeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PushHandToolDriveModeEvent.emptyNew()
    local self = Event.new(PushHandToolDriveModeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer driveModeState driveModeState
-- @return PushHandToolDriveModeEvent instance instance of event
function PushHandToolDriveModeEvent.new(object, driveModeState)
    local self = PushHandToolDriveModeEvent.emptyNew()
    self.object = object
    self.driveModeState = driveModeState

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PushHandToolDriveModeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.driveModeState = streamReadBool(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PushHandToolDriveModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.driveModeState)
end


---Run action on receiving side
-- @param integer connection connection
function PushHandToolDriveModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPushHandToolDriveMode(self.driveModeState, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer driveModeState driveModeState
-- @param boolean noEventSend no event send
function PushHandToolDriveModeEvent.sendEvent(vehicle, driveModeState, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PushHandToolDriveModeEvent.new(vehicle, driveModeState), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(PushHandToolDriveModeEvent.new(vehicle, driveModeState))
        end
    end
end
