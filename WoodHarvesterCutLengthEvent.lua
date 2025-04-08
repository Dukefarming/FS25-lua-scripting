




---Event for tilting the harvester header
local WoodHarvesterCutLengthEvent_mt = Class(WoodHarvesterCutLengthEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WoodHarvesterCutLengthEvent.emptyNew()
    local self = Event.new(WoodHarvesterCutLengthEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param float length length
function WoodHarvesterCutLengthEvent.new(object, index)
    local self = WoodHarvesterCutLengthEvent.emptyNew()
    self.object = object
    self.index = index
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterCutLengthEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, WoodHarvester.NUM_BITS_CUT_LENGTH)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterCutLengthEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUIntN(streamId, self.index, WoodHarvester.NUM_BITS_CUT_LENGTH)
end


---Run action on receiving side
-- @param integer connection connection
function WoodHarvesterCutLengthEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setWoodHarvesterCutLengthIndex(self.index, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param float index index
-- @param boolean noEventSend no event send
function WoodHarvesterCutLengthEvent.sendEvent(object, index, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(WoodHarvesterCutLengthEvent.new(object, index), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(WoodHarvesterCutLengthEvent.new(object, index))
        end
    end
end
