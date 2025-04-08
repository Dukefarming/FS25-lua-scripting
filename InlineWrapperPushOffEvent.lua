



---Event for pushing off the bales from inline wrapper
local InlineWrapperPushOffEvent_mt = Class(InlineWrapperPushOffEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function InlineWrapperPushOffEvent.emptyNew()
    local self = Event.new(InlineWrapperPushOffEvent_mt)
    return self
end


---Create new instance of event
-- @param table inlineWrapper inlineWrapper
-- @return table instance instance of event
function InlineWrapperPushOffEvent.new(inlineWrapper)
    local self = InlineWrapperPushOffEvent.emptyNew()
    self.inlineWrapper = inlineWrapper
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function InlineWrapperPushOffEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.inlineWrapper = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function InlineWrapperPushOffEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.inlineWrapper)
    end
end


---Run action on receiving side
-- @param integer connection connection
function InlineWrapperPushOffEvent:run(connection)
    if not connection:getIsServer() then
        if self.inlineWrapper ~= nil and self.inlineWrapper:getIsSynchronized() then
            self.inlineWrapper:pushOffInlineBale()
        end
    end
end
