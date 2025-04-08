




---Event for tilting the harvester header
local WoodHarvesterHeaderTiltEvent_mt = Class(WoodHarvesterHeaderTiltEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WoodHarvesterHeaderTiltEvent.emptyNew()
    local self = Event.new(WoodHarvesterHeaderTiltEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param float length length
function WoodHarvesterHeaderTiltEvent.new(object, state)
    local self = WoodHarvesterHeaderTiltEvent.emptyNew()
    self.object = object
    self.state = state
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterHeaderTiltEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WoodHarvesterHeaderTiltEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.state)
end


---Run action on receiving side
-- @param integer connection connection
function WoodHarvesterHeaderTiltEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:setWoodHarvesterTiltState(self.state, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table object object
-- @param float state state
-- @param boolean noEventSend no event send
function WoodHarvesterHeaderTiltEvent.sendEvent(object, state, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(WoodHarvesterHeaderTiltEvent.new(object, state), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(WoodHarvesterHeaderTiltEvent.new(object, state))
        end
    end
end
