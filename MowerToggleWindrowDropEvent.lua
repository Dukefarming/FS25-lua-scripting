




---Event for mower toggle drop
local MowerToggleWindrowDropEvent_mt = Class(MowerToggleWindrowDropEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function MowerToggleWindrowDropEvent.emptyNew()
    local self = Event.new(MowerToggleWindrowDropEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean useMowerWindrowDropAreas use mower windrow drop areas
function MowerToggleWindrowDropEvent.new(object, useMowerWindrowDropAreas)
    local self = MowerToggleWindrowDropEvent.emptyNew()
    self.object = object
    self.useMowerWindrowDropAreas = useMowerWindrowDropAreas
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MowerToggleWindrowDropEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.useMowerWindrowDropAreas = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function MowerToggleWindrowDropEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.useMowerWindrowDropAreas)
end


---Run action on receiving side
-- @param integer connection connection
function MowerToggleWindrowDropEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setUseMowerWindrowDropAreas(self.useMowerWindrowDropAreas, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean useMowerWindrowDropAreas use mower windrow drop areas
-- @param boolean noEventSend no event send
function MowerToggleWindrowDropEvent.sendEvent(vehicle, useMowerWindrowDropAreas, noEventSend)
    if useMowerWindrowDropAreas ~= vehicle.useMowerWindrowDropAreas then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(MowerToggleWindrowDropEvent.new(vehicle, useMowerWindrowDropAreas), nil, nil, vehicle)
            else
                g_client:getServerConnection():sendEvent(MowerToggleWindrowDropEvent.new(vehicle, useMowerWindrowDropAreas))
            end
        end
    end
end
