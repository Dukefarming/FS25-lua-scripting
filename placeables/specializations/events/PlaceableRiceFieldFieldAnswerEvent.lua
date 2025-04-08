




---Event for a rice field
local PlaceableRiceFieldFieldAnswerEvent_mt = Class(PlaceableRiceFieldFieldAnswerEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableRiceFieldFieldAnswerEvent.emptyNew()
    return Event.new(PlaceableRiceFieldFieldAnswerEvent_mt, NetworkNode.CHANNEL_MAIN)
end


---Create new instance of event
function PlaceableRiceFieldFieldAnswerEvent.new(placeableRiceField, statusCode)
    local self = PlaceableRiceFieldFieldAnswerEvent.emptyNew()

    self.placeableRiceField = placeableRiceField
    self.statusCode = statusCode

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldFieldAnswerEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)

    self.statusCode = streamReadUInt8(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldFieldAnswerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)

    streamWriteUInt8(streamId, self.statusCode)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableRiceFieldFieldAnswerEvent:run(connection)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
        g_messageCenter:publish(PlaceableRiceFieldFieldAnswerEvent, self.statusCode)
    end
end
