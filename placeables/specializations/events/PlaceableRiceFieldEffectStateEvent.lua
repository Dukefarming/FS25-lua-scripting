




---Event for a rice field state used in RiceFieldDialog
local PlaceableRiceFieldEffectStateEvent_mt = Class(PlaceableRiceFieldEffectStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableRiceFieldEffectStateEvent.emptyNew()
    return Event.new(PlaceableRiceFieldEffectStateEvent_mt)
end


---Create new instance of event
function PlaceableRiceFieldEffectStateEvent.new(placeableRiceField, fieldIndex, isFilling, isEmptying)
    local self = PlaceableRiceFieldEffectStateEvent.emptyNew()

    self.placeableRiceField = placeableRiceField
    self.fieldIndex = fieldIndex
    self.isFilling = isFilling
    self.isEmptying = isEmptying

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldEffectStateEvent:readStream(streamId, connection)
    self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
    self.fieldIndex = streamReadUInt8(streamId)
    self.isFilling = streamReadBool(streamId)
    self.isEmptying = streamReadBool(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableRiceFieldEffectStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
    streamWriteUInt8(streamId, self.fieldIndex)
    streamWriteBool(streamId, self.isFilling)
    streamWriteBool(streamId, self.isEmptying)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableRiceFieldEffectStateEvent:run(connection)
    if self.placeableRiceField == nil or not self.placeableRiceField:getIsSynchronized() then
        return
    end

    self.placeableRiceField:setEffectVisibility(self.fieldIndex, self.isFilling, self.isEmptying)
end
