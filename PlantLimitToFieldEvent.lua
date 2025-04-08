




---Event for limit to field state
local PlantLimitToFieldEvent_mt = Class(PlantLimitToFieldEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlantLimitToFieldEvent.emptyNew()
    local self = Event.new(PlantLimitToFieldEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean plantLimitToField plant is limited to field
function PlantLimitToFieldEvent.new(object, plantLimitToField)
    local self = PlantLimitToFieldEvent.emptyNew()
    self.object = object
    self.plantLimitToField = plantLimitToField
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlantLimitToFieldEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.plantLimitToField = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlantLimitToFieldEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.plantLimitToField)
end


---Run action on receiving side
-- @param integer connection connection
function PlantLimitToFieldEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPlantLimitToField(self.plantLimitToField, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(PlantLimitToFieldEvent.new(self.object, self.plantLimitToField), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isPickupLowered is pickup lowered
-- @param boolean noEventSend no event send
function PlantLimitToFieldEvent.sendEvent(vehicle, plantLimitToField, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlantLimitToFieldEvent.new(vehicle, plantLimitToField), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(PlantLimitToFieldEvent.new(vehicle, plantLimitToField))
        end
    end
end
