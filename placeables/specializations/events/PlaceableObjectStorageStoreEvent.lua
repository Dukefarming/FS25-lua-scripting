




---Event from client to server to store the manual objects in the trigger
local PlaceableObjectStorageStoreEvent_mt = Class(PlaceableObjectStorageStoreEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableObjectStorageStoreEvent.emptyNew()
    return Event.new(PlaceableObjectStorageStoreEvent_mt)
end


---Create new instance of event
-- @param Object placeable placeable object
-- @return PlaceableObjectStorageStoreEvent self
function PlaceableObjectStorageStoreEvent.new(placeable)
    local self = PlaceableObjectStorageStoreEvent.emptyNew()
    self.placeable = placeable
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableObjectStorageStoreEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableObjectStorageStoreEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableObjectStorageStoreEvent:run(connection)
    if self.placeable ~= nil and self.placeable:getIsSynchronized() and self.placeable.storePendingManualObjects ~= nil then
        self.placeable:storePendingManualObjects()
    end
end
