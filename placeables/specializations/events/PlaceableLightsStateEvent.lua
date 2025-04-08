




---Event for toggling placeable light state
local PlaceableLightsStateEvent_mt = Class(PlaceableLightsStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableLightsStateEvent.emptyNew()
    return Event.new(PlaceableLightsStateEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param integer groupIndex index of group
-- @param boolean isActive is active
function PlaceableLightsStateEvent.new(placeable, groupIndex, isActive)
    local self = PlaceableLightsStateEvent.emptyNew()
    self.placeable = placeable
    self.groupIndex = groupIndex
    self.isActive = isActive
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableLightsStateEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.groupIndex = streamReadUIntN(streamId, PlaceableLights.MAX_NUM_BITS)
    self.isActive = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableLightsStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.groupIndex, PlaceableLights.MAX_NUM_BITS)
    streamWriteBool(streamId, self.isActive)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableLightsStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.placeable)
    end

    if self.placeable ~= nil and self.placeable:getIsSynchronized() and self.placeable.setGroupIsActive ~= nil then
        self.placeable:setGroupIsActive(self.groupIndex, self.isActive, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table lightSystem lightSystem object
-- @param integer groupIndex index of group
-- @param boolean isActive is active
function PlaceableLightsStateEvent.sendEvent(placeable, groupIndex, isActive, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlaceableLightsStateEvent.new(placeable, groupIndex, isActive), nil, nil, placeable)
        else
            g_client:getServerConnection():sendEvent(PlaceableLightsStateEvent.new(placeable, groupIndex, isActive))
        end
    end
end
