










---
local ConsumableRefillEvent_mt = Class(ConsumableRefillEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function ConsumableRefillEvent.emptyNew()
    local self = Event.new(ConsumableRefillEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function ConsumableRefillEvent.new(object, typeIndex, variationIndex)
    local self = ConsumableRefillEvent.emptyNew()
    self.object = object
    self.typeIndex = typeIndex
    self.variationIndex = variationIndex

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ConsumableRefillEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.typeIndex = streamReadUInt8(streamId)
    self.variationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)

    if not connection:getIsServer() then
        self:run(connection)
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function ConsumableRefillEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteUInt8(streamId, self.typeIndex)
    streamWriteUIntN(streamId, self.variationIndex, ConsumableManager.NUM_VARIATION_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function ConsumableRefillEvent:run(connection)
    if self.object ~= nil then
        local spec = self.object.spec_consumable
        local type = spec.types[self.typeIndex]

        type.consumingVariationIndex = self.variationIndex

        local delta = self.object:addFillUnitFillLevel(self.object:getOwnerFarmId(), type.fillUnitIndex, type.numStorageSlots, self.object:getFillUnitFirstSupportedFillType(type.fillUnitIndex), ToolType.UNDEFINED, nil)
        self.object:updateConsumable(type.typeName, 0)

        -- fill another time, in case some consumables moved to the consuming slots
        delta = delta + self.object:addFillUnitFillLevel(self.object:getOwnerFarmId(), type.fillUnitIndex, type.numConsumingSlots, self.object:getFillUnitFirstSupportedFillType(type.fillUnitIndex), ToolType.UNDEFINED, nil)
        self.object:updateConsumable(type.typeName, 0)

        local price = g_consumableManager:getConsumableVariationPriceByIndex(self.variationIndex) * delta
        if price > 0 then
            g_farmManager:updateFarmStats(self.object:getActiveFarm(), "expenses", price)
            g_currentMission:addMoney(-price, self.object:getActiveFarm(), MoneyType.PURCHASE_CONSUMABLES, true)
            g_currentMission:showMoneyChange(MoneyType.PURCHASE_CONSUMABLES, nil, false, self.object:getActiveFarm())
        end
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param integer typeIndex typeIndex
-- @param integer variationIndex variationIndex
function ConsumableRefillEvent.sendEvent(vehicle, typeIndex, variationIndex)
    if g_server ~= nil then
        g_server:broadcastEvent(ConsumableRefillEvent.new(vehicle, typeIndex, variationIndex), true, nil, vehicle)
    else
        g_client:getServerConnection():sendEvent(ConsumableRefillEvent.new(vehicle, typeIndex, variationIndex))
    end
end
