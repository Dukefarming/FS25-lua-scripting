




---Event for limit to field state
local PlowLimitToFieldEvent_mt = Class(PlowLimitToFieldEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlowLimitToFieldEvent.emptyNew()
    local self = Event.new(PlowLimitToFieldEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean plowLimitToField plow is limited to field
function PlowLimitToFieldEvent.new(object, plowLimitToField)
    local self = PlowLimitToFieldEvent.emptyNew()
    self.object = object
    self.plowLimitToField = plowLimitToField
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlowLimitToFieldEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.plowLimitToField = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlowLimitToFieldEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.plowLimitToField)
end


---Run action on receiving side
-- @param integer connection connection
function PlowLimitToFieldEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPlowLimitToField(self.plowLimitToField, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(PlowLimitToFieldEvent.new(self.object, self.plowLimitToField), nil, connection, self.object)
    end
end
