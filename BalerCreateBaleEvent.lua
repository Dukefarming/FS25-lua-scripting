




---Event for baler bale creation
local BalerCreateBaleEvent_mt = Class(BalerCreateBaleEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BalerCreateBaleEvent.emptyNew()
    local self = Event.new(BalerCreateBaleEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer baleFillType bale fill type
-- @param float baleTime bale time
function BalerCreateBaleEvent.new(object, baleFillType, baleTime, baleServerId)
    local self = BalerCreateBaleEvent.emptyNew()
    self.object = object
    self.baleFillType = baleFillType
    self.baleTime = baleTime
    self.baleServerId = baleServerId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerCreateBaleEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.baleTime = streamReadFloat32(streamId)
    self.baleFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    if streamReadBool(streamId) then
        self.baleServerId = NetworkUtil.readNodeObjectId(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BalerCreateBaleEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteFloat32(streamId, self.baleTime)
    streamWriteUIntN(streamId, self.baleFillType, FillTypeManager.SEND_NUM_BITS)
    if streamWriteBool(streamId, self.baleServerId ~= nil) then
        NetworkUtil.writeNodeObjectId(streamId, self.baleServerId)
    end
end


---Run action on receiving side
-- @param integer connection connection
function BalerCreateBaleEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:createBale(self.baleFillType, nil, self.baleServerId)
        self.object:setBaleTime(#self.object.spec_baler.bales, self.baleTime)
    end
end
