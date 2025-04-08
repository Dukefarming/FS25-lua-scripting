




---Event for lower and lift pickup
local PickupSetStateEvent_mt = Class(PickupSetStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PickupSetStateEvent.emptyNew()
    local self = Event.new(PickupSetStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isPickupLowered is pickup lowered
function PickupSetStateEvent.new(object, isPickupLowered)
    local self = PickupSetStateEvent.emptyNew()
    self.object = object
    self.isPickupLowered = isPickupLowered
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PickupSetStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isPickupLowered = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PickupSetStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isPickupLowered)
end


---Run action on receiving side
-- @param integer connection connection
function PickupSetStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPickupState(self.isPickupLowered, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isPickupLowered is pickup lowered
-- @param boolean noEventSend no event send
function PickupSetStateEvent.sendEvent(vehicle, isPickupLowered, noEventSend)
    if isPickupLowered ~= vehicle.spec_pickup.isLowered then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(PickupSetStateEvent.new(vehicle, isPickupLowered), nil, nil, vehicle)
            else
                g_client:getServerConnection():sendEvent(PickupSetStateEvent.new(vehicle, isPickupLowered))
            end
        end
    end
end
