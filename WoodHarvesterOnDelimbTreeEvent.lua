




---Event for delimb tree state
local WoodHarvesterOnDelimbTreeEvent_mt = Class(WoodHarvesterOnDelimbTreeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WoodHarvesterOnDelimbTreeEvent.emptyNew()
    return Event.new(WoodHarvesterOnDelimbTreeEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param boolean state state
function WoodHarvesterOnDelimbTreeEvent.new(object, state)
    local self = WoodHarvesterOnDelimbTreeEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterOnDelimbTreeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterOnDelimbTreeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
end


---Run action on receiving side
-- @param integer connection connection
function WoodHarvesterOnDelimbTreeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent.new(self.object, self.state), nil, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:onDelimbTree(self.state)
    end
end
