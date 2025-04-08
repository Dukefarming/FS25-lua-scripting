




---Event for setting the tree type and variation index
local TreePlanterCreateTreeEvent_mt = Class(TreePlanterCreateTreeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TreePlanterCreateTreeEvent.emptyNew()
    local self = Event.new(TreePlanterCreateTreeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer palletObjectId object id of pallet
function TreePlanterCreateTreeEvent.new(object, treeTypeIndex, treeVariationIndex)
    local self = TreePlanterCreateTreeEvent.emptyNew()
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreePlanterCreateTreeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TreePlanterCreateTreeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function TreePlanterCreateTreeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:createTree(true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param integer palletObjectId object id of pallet
-- @param boolean noEventSend no event send
function TreePlanterCreateTreeEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(TreePlanterCreateTreeEvent.new(object), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(TreePlanterCreateTreeEvent.new(object))
        end
    end
end
