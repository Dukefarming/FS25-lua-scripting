




---Event for on cut tree
local WoodHarvesterOnCutTreeEvent_mt = Class(WoodHarvesterOnCutTreeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WoodHarvesterOnCutTreeEvent.emptyNew()
    local self = Event.new(WoodHarvesterOnCutTreeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param float radius radius
function WoodHarvesterOnCutTreeEvent.new(object, radius)
    local self = WoodHarvesterOnCutTreeEvent.emptyNew()
    self.object = object
    self.radius = radius
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterOnCutTreeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.radius = streamReadFloat32(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterOnCutTreeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteFloat32(streamId, self.radius)
end


---Run action on receiving side
-- @param integer connection connection
function WoodHarvesterOnCutTreeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self.object, self.radius), nil, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        SpecializationUtil.raiseEvent(self.object, "onCutTree", self.radius)
    end
end
