




---Event for setting rice field water target height
local PlaceableRiceFieldSetTargetHeightEvent_mt = Class(PlaceableRiceFieldSetTargetHeightEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableRiceFieldSetTargetHeightEvent.emptyNew()
    return Event.new(PlaceableRiceFieldSetTargetHeightEvent_mt)
end


---Create new instance of event
function PlaceableRiceFieldSetTargetHeightEvent.new(placeableRiceField, fieldIndex, targetHeight)
    local self = PlaceableRiceFieldSetTargetHeightEvent.emptyNew()

    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex
    self.targetHeight = targetHeight

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldSetTargetHeightEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)

    self.fieldIndex = streamReadUInt8(streamId)
    self.targetHeight = streamReadFloat32(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldSetTargetHeightEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)

    streamWriteUInt8(streamId, self.fieldIndex)
    streamWriteFloat32(streamId, self.targetHeight)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableRiceFieldSetTargetHeightEvent:run(connection)
    if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
        self.placeableRiceField:setWaterHeightTarget(self.fieldIndex, self.targetHeight, true)

        -- Server broadcasts to all clients
        if not connection:getIsServer() then
            g_server:broadcastEvent(self)
        end
    end
end
