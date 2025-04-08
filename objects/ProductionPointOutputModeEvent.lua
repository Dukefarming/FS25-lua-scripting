



---Event for production point output mode changes
local ProductionPointOutputModeEvent_mt = Class(ProductionPointOutputModeEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function ProductionPointOutputModeEvent.emptyNew()
    local self = Event.new(ProductionPointOutputModeEvent_mt)
    return self
end


---Create new instance of event
function ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode)
    local self = ProductionPointOutputModeEvent.emptyNew()
    self.productionPoint = productionPoint
    self.outputFillTypeId = outputFillTypeId
    self.outputMode = outputMode
    return self
end


---Called on client side on join
function ProductionPointOutputModeEvent:readStream(streamId, connection)
    self.productionPoint = NetworkUtil.readNodeObject(streamId)
    self.outputFillTypeId = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    self.outputMode = streamReadUIntN(streamId, ProductionPoint.OUTPUT_MODE_NUM_BITS)
    self:run(connection)
end


---Called on server side on join
function ProductionPointOutputModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.productionPoint)
    streamWriteUIntN(streamId, self.outputFillTypeId, FillTypeManager.SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.outputMode, ProductionPoint.OUTPUT_MODE_NUM_BITS)
end


---Run action on receiving side
function ProductionPointOutputModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end

    if self.productionPoint ~= nil then
        self.productionPoint:setOutputDistributionMode(self.outputFillTypeId, self.outputMode, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
function ProductionPointOutputModeEvent.sendEvent(productionPoint, outputFillTypeId, outputMode, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode))
        else
            g_client:getServerConnection():sendEvent(ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode))
        end
    end
end
