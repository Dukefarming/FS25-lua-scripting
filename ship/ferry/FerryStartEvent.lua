




---Event for washing stations
local FerryStartEvent_mt = Class(FerryStartEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FerryStartEvent.emptyNew()
    local self = Event.new(FerryStartEvent_mt)
    return self
end


---Create new instance of event
-- @param table ferry ferry
-- @return table instance instance of event
function FerryStartEvent.new(ferry)
    local self = FerryStartEvent.emptyNew()
    self.ferry = ferry
    return self
end









---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FerryStartEvent:readStream(streamId, connection)
    self.ferry = NetworkUtil.readNodeObject(streamId)

    if connection:getIsServer() then
        self.errorCode = streamReadUIntN(streamId, Ferry.ERROR_SEND_NUM_BITS)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FerryStartEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.ferry)

    if not connection:getIsServer() then
        streamWriteUIntN(streamId, self.errorCode, Ferry.ERROR_SEND_NUM_BITS)
    end
end


---Run action on receiving side
-- @param integer connection connection
function FerryStartEvent:run(connection)
    if not connection:getIsServer() then
        self.ferry:start(connection)
    else
        if self.errorCode == Ferry.ERROR_SUCCESS then
            self.ferry:onStarted()
        else
            self.ferry:onStartFailed(self.errorCode)
        end
    end
end
