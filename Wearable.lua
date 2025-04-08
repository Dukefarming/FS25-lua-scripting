



























---
function Wearable.prerequisitesPresent(specializations)
    return true
end


---
function Wearable.initSpecialization()
    if Platform.gameplay.hasVehicleDamage then
        g_storeManager:addSpecType("wearable", "shopListAttributeIconCondition", Wearable.loadSpecValueCondition, Wearable.getSpecValueCondition, StoreSpecies.VEHICLE)
    end

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Wearable")

    schema:register(XMLValueType.FLOAT, "vehicle.wearable#wearDuration", "Duration until fully worn (minutes)", 600)
    schema:register(XMLValueType.FLOAT, "vehicle.wearable#workMultiplier", "Multiplier while working", 20)
    schema:register(XMLValueType.FLOAT, "vehicle.wearable#fieldMultiplier", "Multiplier while on field", 2)
    schema:register(XMLValueType.BOOL, "vehicle.wearable#showOnHud", "Show the damage on the hud", true)

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).wearable.wearNode(?)#amount", "Wear amount")
    schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).wearable#damage", "Damage amount")
end


---
function Wearable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "addAllSubWearableNodes", Wearable.addAllSubWearableNodes)
    SpecializationUtil.registerFunction(vehicleType, "addDamageAmount", Wearable.addDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "addToGlobalWearableNode", Wearable.addToGlobalWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "addToLocalWearableNode", Wearable.addToLocalWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "addWearableNode", Wearable.addWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "addWearAmount", Wearable.addWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDamageAmount", Wearable.getDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "getDamageShowOnHud", Wearable.getDamageShowOnHud)
    SpecializationUtil.registerFunction(vehicleType, "getNodeWearAmount", Wearable.getNodeWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "getUsageCausesDamage", Wearable.getUsageCausesDamage)
    SpecializationUtil.registerFunction(vehicleType, "getUsageCausesWear", Wearable.getUsageCausesWear)
    SpecializationUtil.registerFunction(vehicleType, "getWearMultiplier", Wearable.getWearMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "getWearTotalAmount", Wearable.getWearTotalAmount)
    SpecializationUtil.registerFunction(vehicleType, "getWorkWearMultiplier", Wearable.getWorkWearMultiplier)
    SpecializationUtil.registerFunction(vehicleType, "removeAllSubWearableNodes", Wearable.removeAllSubWearableNodes)
    SpecializationUtil.registerFunction(vehicleType, "removeWearableNode", Wearable.removeWearableNode)
    SpecializationUtil.registerFunction(vehicleType, "repaintVehicle", Wearable.repaintVehicle)
    SpecializationUtil.registerFunction(vehicleType, "repairVehicle", Wearable.repairVehicle)
    SpecializationUtil.registerFunction(vehicleType, "setDamageAmount", Wearable.setDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "setNodeWearAmount", Wearable.setNodeWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "updateDamageAmount", Wearable.updateDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, "updateWearAmount", Wearable.updateWearAmount)
    SpecializationUtil.registerFunction(vehicleType, "validateWearableNode", Wearable.validateWearableNode)
end


---
function Wearable.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleDamage", Wearable.getVehicleDamage)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRepairPrice", Wearable.getRepairPrice)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRepaintPrice", Wearable.getRepaintPrice)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", Wearable.showInfo)
end


---
function Wearable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wearable)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wearable)

    if not GS_IS_MOBILE_VERSION then
        SpecializationUtil.registerEventListener(vehicleType, "onSaleItemSet", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wearable)
        SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wearable)
    end
end


---
function Wearable:onLoad(savegame)
    local spec = self.spec_wearable

    spec.wearableNodes = {}
    spec.wearableNodesByIndex = {}
    self:addToLocalWearableNode(nil, Wearable.updateWearAmount, nil, nil) -- create global / default wearableNode

    spec.wearDuration = self.xmlFile:getValue("vehicle.wearable#wearDuration", 600) * 60 * 1000 -- default 600min / 10h
    if spec.wearDuration ~= 0 then
        spec.wearDuration = 1 / spec.wearDuration * Wearable.WEAR_FACTOR
    end

    spec.totalAmount = 0

    spec.damage = 0
    spec.damageByCurve = 0
    spec.damageSent = 0

    spec.workMultiplier = self.xmlFile:getValue("vehicle.wearable#workMultiplier", 20)
    spec.fieldMultiplier = self.xmlFile:getValue("vehicle.wearable#fieldMultiplier", 2)

    spec.showOnHud = self.xmlFile:getValue("vehicle.wearable#showOnHud", true)

    spec.dirtyFlag = self:getNextDirtyFlag()
end


---
function Wearable:onLoadFinished(savegame)
    local spec = self.spec_wearable

    if savegame ~= nil then
        spec.damage = savegame.xmlFile:getValue(savegame.key .. ".wearable#damage", 0)
        spec.damageByCurve = math.max(spec.damage - 0.3, 0) / 0.7
    end

    -- getting als wearable nodes in postLoad to make sure also linked nodes are wearable
    if spec.wearableNodes ~= nil then
        for _, component in pairs(self.components) do
            self:addAllSubWearableNodes(component.node)
        end

        if savegame ~= nil then
            for i, nodeData in ipairs(spec.wearableNodes) do
                local nodeKey = string.format("%s.wearable.wearNode(%d)", savegame.key, i-1)
                local amount = savegame.xmlFile:getValue(nodeKey.."#amount", 0)
                self:setNodeWearAmount(nodeData, amount, true)
            end
        else
            for _, nodeData in ipairs(spec.wearableNodes) do
                self:setNodeWearAmount(nodeData, 0, true)
            end
        end
    end
end


---
function Wearable:onSaleItemSet(saleItem)
    self:addDamageAmount(saleItem.damage or 0, true)
    self:addWearAmount(saleItem.wear or 0, true)
end


---
function Wearable:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_wearable

    xmlFile:setValue(key.."#damage", spec.damage)

    if spec.wearableNodes ~= nil then
        for i, nodeData in ipairs(spec.wearableNodes) do
            local nodeKey = string.format("%s.wearNode(%d)", key, i-1)
            xmlFile:setValue(nodeKey.."#amount", self:getNodeWearAmount(nodeData))
        end
    end
end


---
function Wearable:onReadStream(streamId, connection)
    local spec = self.spec_wearable

    self:setDamageAmount(streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)

    if spec.wearableNodes ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            local wearAmount = streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE
            self:setNodeWearAmount(nodeData, wearAmount, true)
        end
    end
end


---
function Wearable:onWriteStream(streamId, connection)
    local spec = self.spec_wearable

    streamWriteUIntN(streamId, math.floor(spec.damage * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)

    if spec.wearableNodes ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            streamWriteUIntN(streamId, math.floor(self:getNodeWearAmount(nodeData) * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
        end
    end
end


---
function Wearable:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_wearable

    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:setDamageAmount(streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE, true)

            if spec.wearableNodes ~= nil then
                for _, nodeData in ipairs(spec.wearableNodes) do
                    local wearAmount = streamReadUIntN(streamId, Wearable.SEND_NUM_BITS) / Wearable.SEND_MAX_VALUE
                    self:setNodeWearAmount(nodeData, wearAmount, true)
                end
            end
        end
    end
end


---
function Wearable:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_wearable

    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, math.floor(spec.damage * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)

            if spec.wearableNodes ~= nil then
                for _, nodeData in ipairs(spec.wearableNodes) do
                    streamWriteUIntN(streamId, math.floor(self:getNodeWearAmount(nodeData) * Wearable.SEND_MAX_VALUE + 0.5), Wearable.SEND_NUM_BITS)
                end
            end
        end
    end
end


---
function Wearable:onUpdateTick(dt, isActive, isActiveForInput, isSelected)
    local spec = self.spec_wearable

    if spec.wearableNodes ~= nil then
        if self.isServer then
            local changeAmount = self:updateDamageAmount(dt)
            if changeAmount ~= 0 then
                self:setDamageAmount(spec.damage + changeAmount)
            end

            for _, nodeData in ipairs(spec.wearableNodes) do
                local changedAmount = nodeData.updateFunc(self, nodeData, dt)
                if changedAmount ~= 0 then
                    self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) + changedAmount)
                end
            end
        end
    end
end


---
function Wearable:setDamageAmount(amount, force)
    local spec = self.spec_wearable

    spec.damage = math.min(math.max(amount, 0), 1)
    spec.damageByCurve = math.max(spec.damage - 0.3, 0) / 0.7

    local diff = spec.damageSent - spec.damage
    if math.abs(diff) > Wearable.SEND_THRESHOLD or force then
        if self.isServer then
            self:raiseDirtyFlags(spec.dirtyFlag)
            spec.damageSent = spec.damage
        end
    end
end


---
function Wearable:updateWearAmount(nodeData, dt)
    local spec = self.spec_wearable
    if self:getUsageCausesWear() then
        return dt * spec.wearDuration * self:getWearMultiplier(nodeData) * 0.5
    else
        return 0
    end
end


---
function Wearable:updateDamageAmount(dt)
    local spec = self.spec_wearable
    if self:getUsageCausesDamage() then
        local factor = 1
        if self.lifetime ~= nil and self.lifetime ~= 0 then
            local ageMultiplier = 0.15 * math.min(self.age / self.lifetime, 1)
            local operatingTime = self.operatingTime / (1000*60*60)
            local operatingTimeMultiplier =  0.85 * math.min(operatingTime / (self.lifetime * EconomyManager.LIFETIME_OPERATINGTIME_RATIO), 1)

            factor = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * (ageMultiplier + operatingTimeMultiplier)
        end

        return dt * spec.wearDuration * 0.35 * factor
    else
        return 0
    end
end


---
function Wearable:getUsageCausesWear()
    return true
end


---Damage causes lower performance which impacts mission results.
function Wearable:getUsageCausesDamage()
    if self.spec_motorized == nil then
        if getIsSleeping(self.rootNode) then
            return false
        end
    end

    return self.isActive and self.propertyState ~= VehiclePropertyState.MISSION
end


---
function Wearable:addWearAmount(wearAmount, force)
    local spec = self.spec_wearable
    if spec.wearableNodes ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) + wearAmount, force)
        end
    end
end


---
function Wearable:addDamageAmount(amount, force)
    local spec = self.spec_wearable
    self:setDamageAmount(spec.damage + amount, force)
end


---
function Wearable:setNodeWearAmount(nodeData, wearAmount, force)
    local spec = self.spec_wearable
    nodeData.wearAmount = math.clamp(wearAmount, 0, 1)

    local diff = nodeData.wearAmountSent - nodeData.wearAmount
    if math.abs(diff) > Wearable.SEND_THRESHOLD or force then
        for _, node in pairs(nodeData.nodes) do
            setShaderParameter(node, "scratches_dirt_snow_wetness", nodeData.wearAmount, nil, nil, nil, false)
        end

        if self.isServer then
            self:raiseDirtyFlags(spec.dirtyFlag)
            nodeData.wearAmountSent = nodeData.wearAmount
        end

        -- calculate total wearable amount
        spec.totalAmount = 0
        for i = 1, #spec.wearableNodes do
            spec.totalAmount = spec.totalAmount + spec.wearableNodes[i].wearAmount
        end
        spec.totalAmount = spec.totalAmount / #spec.wearableNodes
    end
end


---
function Wearable:getNodeWearAmount(nodeData)
    return nodeData.wearAmount
end


---Get the total wear
-- @return number total
function Wearable:getWearTotalAmount()
    return self.spec_wearable.totalAmount
end


---Get the amount of damage this vehicle has.
-- @return number total
function Wearable:getDamageAmount()
    return self.spec_wearable.damage
end


---Returns if the damage should be visualized on the hud
-- @return boolean showOnHud show damage on hud
function Wearable:getDamageShowOnHud()
    return self.spec_wearable.showOnHud
end


---Repair the vehicle. Owner pays. Causes damage to be reset
function Wearable:repairVehicle()
    self:setDamageAmount(0)

    if self.isServer then
        g_currentMission:addMoney(-self:getRepairPrice(), self:getOwnerFarmId(), MoneyType.VEHICLE_REPAIR, true, true)

        local total, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "repairVehicleCount", 1)
        if total ~= nil then
            g_achievementManager:tryUnlock("VehicleRepairFirst", total)
            g_achievementManager:tryUnlock("VehicleRepair", total)
        end
    end
end



















---Get the price of a repair
function Wearable:getRepairPrice(superFunc)
    return superFunc(self) + Wearable.calculateRepairPrice(self:getPrice(), self.spec_wearable.damage)
end



---Also used by the sale system
function Wearable.calculateRepairPrice(price, damage)
    -- up to 9% of the price at full damage
    -- repairing more often at low damages is rewarded - repairing always at 10% saves about half of the repair price
    return price * math.pow(damage, 1.5) * 0.09
end


---
function Wearable:getRepaintPrice(superFunc)
    return superFunc(self) + Wearable.calculateRepaintPrice(self:getPrice() ,self:getWearTotalAmount())
end


---
function Wearable:showInfo(superFunc, box)
    local damage = self.spec_wearable.damage
    if damage > 0.01 then
        box:addLine(g_i18n:getText("infohud_damage"), string.format("%d %%", damage * 100))
    end

    superFunc(self, box)
end



---Also used by the sale system
function Wearable.calculateRepaintPrice(price, wear)
    return price * math.sqrt(wear / 100) * 2
end


---Get damage: affects how well the machine works
function Wearable:getVehicleDamage(superFunc)
    return math.min(superFunc(self) + self.spec_wearable.damageByCurve, 1)
end


---
function Wearable:addAllSubWearableNodes(rootNode)
    if rootNode ~= nil then
        I3DUtil.iterateShaderParameterNodesRecursively(rootNode, "scratches_dirt_snow_wetness", self.addWearableNode, self)
    end
end


---
function Wearable:addWearableNode(node)
    local isGlobal, updateFunc, customIndex, extraParams = self:validateWearableNode(node)
    if isGlobal then
        self:addToGlobalWearableNode(node)
    elseif updateFunc ~= nil then
        self:addToLocalWearableNode(node, updateFunc, customIndex, extraParams)
    end
end


---
function Wearable:validateWearableNode(node)
    return true, nil -- by default all nodes are global
end


---
function Wearable:addToGlobalWearableNode(node)
    local spec = self.spec_wearable
    if spec.wearableNodes[1] ~= nil then
        spec.wearableNodes[1].nodes[node] = node
    end
end


---
function Wearable:addToLocalWearableNode(node, updateFunc, customIndex, extraParams)
    local spec = self.spec_wearable

    local nodeData = {}

    --if wearableNode already exists we add node to existing wearableNode
    if customIndex ~= nil then
        if spec.wearableNodesByIndex[customIndex] ~= nil then
            spec.wearableNodesByIndex[customIndex].nodes[node] = node
            return
        else
            spec.wearableNodesByIndex[customIndex] = nodeData
        end
    end

    --if wearableNode doesn't exists we create a new one
    nodeData.nodes = {}
    if node ~= nil then
        nodeData.nodes[node] = node
    end

    nodeData.updateFunc = updateFunc
    nodeData.wearAmount = 0
    nodeData.wearAmountSent = 0
    if extraParams ~= nil then
        for i, v in pairs(extraParams) do
            nodeData[i] = v
        end
    end

    table.insert(spec.wearableNodes, nodeData)
end


---
function Wearable:removeAllSubWearableNodes(rootNode)
    if rootNode ~= nil then
        I3DUtil.iterateShaderParameterNodesRecursively(rootNode, "scratches_dirt_snow_wetness", self.removeWearableNode, self)
    end
end


---Remove wearable node
-- @param node table node
function Wearable:removeWearableNode(node)
    local spec = self.spec_wearable

    if spec.wearableNodes ~= nil and node ~= nil then
        for _, nodeData in ipairs(spec.wearableNodes) do
            nodeData.nodes[node] = nil
        end
    end
end


---Get wear multiplier
-- @return number multiplier
function Wearable:getWearMultiplier()
    local spec = self.spec_wearable

    local multiplier = 1
    if self:getLastSpeed() < 1 then
        multiplier = 0
    end

    if self:getIsOnField() then
        multiplier = multiplier * spec.fieldMultiplier
    end

    return multiplier
end


---Get work wear multiplier
-- @return number multiplier
function Wearable:getWorkWearMultiplier()
    local spec = self.spec_wearable

    return spec.workMultiplier
end


---
function Wearable:updateDebugValues(values)
    local spec = self.spec_wearable

    local changedAmount = self:updateDamageAmount(3600000)
    table.insert(values, {name="Damage", value=string.format("%.4f a/h (%.2f)", changedAmount, self:getDamageAmount())})

    if spec.wearableNodes ~= nil then
        if self.isServer then
            for i, nodeData in ipairs(spec.wearableNodes) do
                changedAmount = nodeData.updateFunc(self, nodeData, 3600000)
                table.insert(values, {name="WearableNode"..i, value=string.format("%.4f a/h (%.6f)", changedAmount, self:getNodeWearAmount(nodeData))})
            end
        end
    end
end


---
function Wearable.loadSpecValueCondition(xmlFile, customEnvironment, baseDir)
    -- No data to load as this spec is only for existing items
    return nil
end


---
function Wearable.getSpecValueCondition(storeItem, realItem)
    if realItem == nil then
        return nil
    end

    return string.format("%d%%", realItem:getDamageAmount() * 100)
end
