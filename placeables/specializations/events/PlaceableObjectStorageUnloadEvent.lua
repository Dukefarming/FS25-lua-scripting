




---Event from client to server to unload a specific object and amount
local PlaceableObjectStorageUnloadEvent_mt = Class(PlaceableObjectStorageUnloadEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableObjectStorageUnloadEvent.emptyNew()
    return Event.new(PlaceableObjectStorageUnloadEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param integer objectInfoIndex index of object to unload
-- @param boolean objectAmount amount of objects to be unloaded
function PlaceableObjectStorageUnloadEvent.new(placeable, objectInfoIndex, objectAmount)
    local self = PlaceableObjectStorageUnloadEvent.emptyNew()
    self.placeable = placeable
    self.objectInfoIndex = objectInfoIndex
    self.objectAmount = objectAmount
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableObjectStorageUnloadEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.objectInfoIndex = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)
    self.objectAmount = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_AMOUNT)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableObjectStorageUnloadEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.objectInfoIndex, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)
    streamWriteUIntN(streamId, self.objectAmount, PlaceableObjectStorage.NUM_BITS_AMOUNT)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableObjectStorageUnloadEvent:run(connection)
    if self.placeable ~= nil and self.placeable:getIsSynchronized() and self.placeable.removeAbstractObjectsFromStorage ~= nil then
        self.placeable:removeAbstractObjectsFromStorage(self.objectInfoIndex, self.objectAmount, connection)
    end
end
