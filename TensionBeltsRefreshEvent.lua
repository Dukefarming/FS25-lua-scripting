




---Event for tension belts state
local TensionBeltsRefreshEvent_mt = Class(TensionBeltsRefreshEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TensionBeltsRefreshEvent.emptyNew()
    local self = Event.new(TensionBeltsRefreshEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isActive belt is active
-- @param integer beltId id of belt
function TensionBeltsRefreshEvent.new(object)
    local self = TensionBeltsRefreshEvent.emptyNew()
    self.object = object
    return self
end


---Called on client side
-- @param integer streamId streamId
-- @param integer connection connection
function TensionBeltsRefreshEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side
-- @param integer streamId streamId
-- @param integer connection connection
function TensionBeltsRefreshEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function TensionBeltsRefreshEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:refreshTensionBelts()
    end
end
