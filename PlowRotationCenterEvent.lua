




---Event for plow center rotation
local PlowRotationCenterEvent_mt = Class(PlowRotationCenterEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlowRotationCenterEvent.emptyNew()
    local self = Event.new(PlowRotationCenterEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean rotationMax rotation max
function PlowRotationCenterEvent.new(object)
    local self = PlowRotationCenterEvent.emptyNew()
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlowRotationCenterEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlowRotationCenterEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function PlowRotationCenterEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setRotationCenter(true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(PlowRotationCenterEvent.new(self.object), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean noEventSend no event send
function PlowRotationCenterEvent.sendEvent(object, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlowRotationCenterEvent.new(object), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(PlowRotationCenterEvent.new(object))
        end
    end
end
