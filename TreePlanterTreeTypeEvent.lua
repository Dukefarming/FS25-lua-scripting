




---Event for setting the tree type and variation index
local TreePlanterTreeTypeEvent_mt = Class(TreePlanterTreeTypeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TreePlanterTreeTypeEvent.emptyNew()
    local self = Event.new(TreePlanterTreeTypeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer palletObjectId object id of pallet
function TreePlanterTreeTypeEvent.new(object, treeTypeIndex, treeVariationIndex)
    local self = TreePlanterTreeTypeEvent.emptyNew()
    self.object = object
    self.treeTypeIndex = treeTypeIndex
    self.treeVariationIndex = treeVariationIndex
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreePlanterTreeTypeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.treeTypeIndex = streamReadUInt32(streamId)
    self.treeVariationIndex = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreePlanterTreeTypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUInt32(streamId, self.treeTypeIndex)
    streamWriteUIntN(streamId, self.treeVariationIndex or 1, TreePlantManager.VARIATION_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function TreePlanterTreeTypeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setTreePlanterTreeTypeIndex(self.treeTypeIndex, self.treeVariationIndex, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param integer palletObjectId object id of pallet
-- @param boolean noEventSend no event send
function TreePlanterTreeTypeEvent.sendEvent(object, treeTypeIndex, treeVariationIndex, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreePlanterTreeTypeEvent.new(object, treeTypeIndex, treeVariationIndex), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(TreePlanterTreeTypeEvent.new(object, treeTypeIndex, treeVariationIndex))
        end
    end
end
