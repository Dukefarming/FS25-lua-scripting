




---Event for loading of pallet on tree planter
local TreePlanterLoadPalletEvent_mt = Class(TreePlanterLoadPalletEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TreePlanterLoadPalletEvent.emptyNew()
    local self = Event.new(TreePlanterLoadPalletEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer palletObjectId object id of pallet
function TreePlanterLoadPalletEvent.new(object, palletObjectId)
    local self = TreePlanterLoadPalletEvent.emptyNew()
    self.object = object
    self.palletObjectId = palletObjectId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreePlanterLoadPalletEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.palletObjectId = NetworkUtil.readNodeObjectId(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreePlanterLoadPalletEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    NetworkUtil.writeNodeObjectId(streamId, self.palletObjectId)
end


---Run action on receiving side
-- @param integer connection connection
function TreePlanterLoadPalletEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:loadPallet(self.palletObjectId, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param integer palletObjectId object id of pallet
-- @param boolean noEventSend no event send
function TreePlanterLoadPalletEvent.sendEvent(object, palletObjectId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreePlanterLoadPalletEvent.new(object, palletObjectId), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(TreePlanterLoadPalletEvent.new(object, palletObjectId))
        end
    end
end
