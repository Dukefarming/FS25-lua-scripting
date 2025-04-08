




---Event for removing a rice field
local PlaceableRiceFieldRemoveFieldEvent_mt = Class(PlaceableRiceFieldRemoveFieldEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableRiceFieldRemoveFieldEvent.emptyNew()
    return Event.new(PlaceableRiceFieldRemoveFieldEvent_mt, NetworkNode.CHANNEL_MAIN)
end


---Create new instance of event
function PlaceableRiceFieldRemoveFieldEvent.new(placeableRiceField, fieldIndex)
    local self = PlaceableRiceFieldRemoveFieldEvent.emptyNew()

    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldRemoveFieldEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)

    self.fieldIndex = streamReadUInt8(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldRemoveFieldEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)

    streamWriteUInt8(streamId, self.fieldIndex)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableRiceFieldRemoveFieldEvent:run(connection)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
        self.placeableRiceField:removeFieldByIndex(self.fieldIndex)

        -- Server broadcasts to all clients
        if not connection:getIsServer() then
            g_server:broadcastEvent(self)
        end
    end
end
