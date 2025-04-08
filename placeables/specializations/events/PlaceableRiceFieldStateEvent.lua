




---Event for a rice field state used in RiceFieldDialog
local PlaceableRiceFieldStateEvent_mt = Class(PlaceableRiceFieldStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableRiceFieldStateEvent.emptyNew()
    return Event.new(PlaceableRiceFieldStateEvent_mt)
end


---Create new instance of event
function PlaceableRiceFieldStateEvent.new(placeableRiceField, fieldIndex)
    local self = PlaceableRiceFieldStateEvent.emptyNew()

    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex

    return self
end


---Create new instance of event
function PlaceableRiceFieldStateEvent.newServerToClient(placeableRiceField, fieldIndex, fruitTypeIndex, growthStateIndex)
    local self = PlaceableRiceFieldStateEvent.emptyNew()

    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex

    self.fruitTypeIndex = fruitTypeIndex
    self.growthStateIndex = growthStateIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldStateEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
    self.fieldIndex = streamReadUInt8(streamId)

    if connection:getIsServer() then
        self.fruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
        self.growthStateIndex = streamReadUInt8(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
    streamWriteUInt8(streamId, self.fieldIndex)

    if not connection:getIsServer() then
        -- answer with from server to client
        streamWriteUIntN(streamId, self.fruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
        streamWriteUInt8(streamId, self.growthStateIndex)
    end
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableRiceFieldStateEvent:run(connection)
    if self.placeableRiceField == nil or not self.placeableRiceField:getIsSynchronized() then
        return
    end

    if not connection:getIsServer() then
        self.placeableRiceField:getRiceFieldState(self.fieldIndex, function(_, fruitTypeIndex, growthStateIndex)
            connection:sendEvent(PlaceableRiceFieldStateEvent.newServerToClient(self.placeableRiceField, self.fieldIndex, fruitTypeIndex, growthStateIndex))
        end)
    else
        g_messageCenter:publish(PlaceableRiceFieldStateEvent, self.fruitTypeIndex, self.growthStateIndex)
    end
end
