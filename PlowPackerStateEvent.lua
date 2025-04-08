




---Event for setting the plow packer state
local PlowPackerStateEvent_mt = Class(PlowPackerStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlowPackerStateEvent.emptyNew()
    return Event.new(PlowPackerStateEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param boolean state state
-- @param boolean updateAnimations updateAnimations
function PlowPackerStateEvent.new(object, state, updateAnimations)
    local self = PlowPackerStateEvent.emptyNew()
    self.object = object
    self.state = state
    self.updateAnimations = updateAnimations
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlowPackerStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self.updateAnimations = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlowPackerStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
    streamWriteBool(streamId, self.updateAnimations)
end


---Run action on receiving side
-- @param integer connection connection
function PlowPackerStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPackerState(self.state, self.updateAnimations, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param boolean state state
-- @param boolean updateAnimations updateAnimations
-- @param boolean noEventSend no event send
function PlowPackerStateEvent.sendEvent(object, state, updateAnimations, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlowPackerStateEvent.new(object, state, updateAnimations), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(PlowPackerStateEvent.new(object, state, updateAnimations))
        end
    end
end
