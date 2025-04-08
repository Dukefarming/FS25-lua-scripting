




---Event for set folding direction
local FoldableSetFoldDirectionEvent_mt = Class(FoldableSetFoldDirectionEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FoldableSetFoldDirectionEvent.emptyNew()
    local self = Event.new(FoldableSetFoldDirectionEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer direction direction
-- @param boolean moveToMiddle move to middle
function FoldableSetFoldDirectionEvent.new(object, direction, moveToMiddle)
    local self = FoldableSetFoldDirectionEvent.emptyNew()
    self.object = object
    self.direction = math.sign(direction)
    self.moveToMiddle = moveToMiddle
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FoldableSetFoldDirectionEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.direction = streamReadUIntN(streamId, 2)-1
    self.moveToMiddle = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FoldableSetFoldDirectionEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.direction+1, 2)
    streamWriteBool(streamId, self.moveToMiddle)
end


---Run action on receiving side
-- @param integer connection connection
function FoldableSetFoldDirectionEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setFoldState(self.direction, self.moveToMiddle, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self.object, self.direction, self.moveToMiddle), nil, connection, self.object)
    end
end
