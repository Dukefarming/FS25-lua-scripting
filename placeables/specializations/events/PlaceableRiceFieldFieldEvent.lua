




---Event for a rice field
local PlaceableRiceFieldFieldEvent_mt = Class(PlaceableRiceFieldFieldEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableRiceFieldFieldEvent.emptyNew()
    return Event.new(PlaceableRiceFieldFieldEvent_mt, NetworkNode.CHANNEL_MAIN)
end


---Create new instance of event
function PlaceableRiceFieldFieldEvent.new(placeableRiceField, field)
    local self = PlaceableRiceFieldFieldEvent.emptyNew()

    self.placeableRiceField = placeableRiceField
    self.field = field

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldFieldEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)

    local height = streamReadFloat32(streamId)
    local field = self.placeableRiceField:createNewField(height)

    local numVertices = streamReadUInt16(streamId)
    field.polygon = Polygon2D.new(numVertices)

    for i=1, numVertices do
        field.polygon:addPos(streamReadFloat32(streamId), streamReadFloat32(streamId))
    end

    field.waterHeight = streamReadFloat32(streamId)

    self.field = field

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldFieldEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)

    streamWriteFloat32(streamId, self.field.height)

    streamWriteUInt16(streamId, self.field.polygon:getNumVertices())

    for _, vertex in ipairs(self.field.polygon:getVertices()) do
        streamWriteFloat32(streamId, vertex)
    end

    streamWriteFloat32(streamId, self.field.waterHeight)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableRiceFieldFieldEvent:run(connection)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then

        self.placeableRiceField:finalizeNewField(self.field, true, function (statusCode)
            -- answer client with status code
            connection:sendEvent(PlaceableRiceFieldFieldAnswerEvent.new(self.placeableRiceField, statusCode))
        end)
    end
end
