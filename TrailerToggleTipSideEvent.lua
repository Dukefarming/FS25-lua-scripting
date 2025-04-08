




---Event for toggle trailer tipping
local TrailerToggleTipSideEvent_mt = Class(TrailerToggleTipSideEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function TrailerToggleTipSideEvent.emptyNew()
    local self = Event.new(TrailerToggleTipSideEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isStart is start
-- @param table tipTrigger tip trigger
-- @param integer tipSideIndex index of tip side
function TrailerToggleTipSideEvent.new(object, tipSideIndex)
    local self = TrailerToggleTipSideEvent.emptyNew()
    self.object = object
    self.tipSideIndex = tipSideIndex
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TrailerToggleTipSideEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.tipSideIndex = streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function TrailerToggleTipSideEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.tipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function TrailerToggleTipSideEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setPreferedTipSide(self.tipSideIndex, true)
    end
end
