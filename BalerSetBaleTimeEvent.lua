











---Create instance of Event class
-- @return table self instance of class event
function BalerSetBaleTimeEvent.emptyNew()
    local self = Event.new(BalerSetBaleTimeEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer bale bale id
-- @param float baleTime bale time
function BalerSetBaleTimeEvent.new(object, bale, baleTime)
    local self =  BalerSetBaleTimeEvent.emptyNew()
    self.object = object
    self.bale = bale
    self.baleTime = baleTime
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerSetBaleTimeEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.bale = streamReadInt32(streamId)
    self.baleTime = streamReadFloat32(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerSetBaleTimeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteInt32(streamId, self.bale)
    streamWriteFloat32(streamId, self.baleTime)
end


---Run action on receiving side
-- @param integer connection connection
function BalerSetBaleTimeEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setBaleTime(self.bale, self.baleTime)
    end
end
