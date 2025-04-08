



---Event for production point production state change
local ProductionPointProductionStateEvent_mt = Class(ProductionPointProductionStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function ProductionPointProductionStateEvent.emptyNew()
    local self = Event.new(ProductionPointProductionStateEvent_mt)
    return self
end


---Create new instance of event
function ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled)
    local self = ProductionPointProductionStateEvent.emptyNew()
    self.productionPoint = productionPoint
    self.productionId = productionId
    self.isEnabled = isEnabled
    return self
end


---Called on client side on join
function ProductionPointProductionStateEvent:readStream(streamId, connection)
    self.productionPoint = NetworkUtil.readNodeObject(streamId)
    self.productionId = streamReadString(streamId)
    self.isEnabled = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
function ProductionPointProductionStateEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.productionPoint)
    streamWriteString(streamId, self.productionId)
    streamWriteBool(streamId, self.isEnabled)
end


---Run action on receiving side
function ProductionPointProductionStateEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end

    if self.productionPoint ~= nil then
        self.productionPoint:setProductionState(self.productionId, self.isEnabled, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
function ProductionPointProductionStateEvent.sendEvent(productionPoint, productionId, isEnabled, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled))
        else
            g_client:getServerConnection():sendEvent(ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled))
        end
    end
end
