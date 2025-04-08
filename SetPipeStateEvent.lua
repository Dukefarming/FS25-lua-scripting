




---Event for pipe state
local SetPipeStateEvent_mt = Class(SetPipeStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function SetPipeStateEvent.emptyNew()
    local self = Event.new(SetPipeStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer pipeState pipe state
function SetPipeStateEvent.new(object, pipeState)
    local self = SetPipeStateEvent.emptyNew()
    self.object = object
    self.pipeState = pipeState
    assert(self.pipeState >= 0 and self.pipeState < 8)
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetPipeStateEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.pipeState = streamReadUIntN(streamId, 3)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SetPipeStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.pipeState, 3)
end


---Run action on receiving side
-- @param integer connection connection
function SetPipeStateEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPipeState(self.pipeState, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(SetPipeStateEvent.new(self.object, self.pipeState), nil, connection, self.object)
    end
end
