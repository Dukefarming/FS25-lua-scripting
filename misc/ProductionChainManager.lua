











---This class handles the interaction between Production- and/or SellingPoints
local ProductionChainManager_mt = Class(ProductionChainManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function ProductionChainManager.new(isServer, customMt)
    local self = AbstractManager.new(customMt or ProductionChainManager_mt)

    self.isServer = isServer

--#debug     self.debugEnabled = false

--#debug     addConsoleCommand("gsProductionPointToggleDebug", "Toggle production point debugging", "consoleCommandToggleProdPointDebug", self)
    addConsoleCommand("gsProductionPointsList", "List all production points on map", "commandListProductionPoints", self)
    addConsoleCommand("gsProductionPointsPrintAutoDeliverMapping", "Prints which fillTypes are required by which production points", "commandPrintAutoDeliverMapping", self)
    addConsoleCommand("gsProductionPointSetOwner", "", "commandSetOwner", self)
    addConsoleCommand("gsProductionPointSetProductionState", "", "commandSetProductionState", self)
    addConsoleCommand("gsProductionPointSetOutputMode", "", "commandSetOutputMode", self)
    addConsoleCommand("gsProductionPointSetFillLevel", "", "commandSetFillLevel", self)

    if self.isServer then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    end

    return self
end


---Initialize data structures
function ProductionChainManager:initDataStructures()
    self.productionPoints = {}
    self.reverseProductionPoint = {}

    self.factories = {}
    self.reverseFactory = {}

    self.farmIds = {}

    self.currentUpdateIndex = 1
    self.hourChangedDirty = false
    self.hourChangeUpdating = false
end


---
function ProductionChainManager:unloadMapData()
--#debug     removeConsoleCommand("gsProductionPointToggleDebug")
    removeConsoleCommand("gsProductionPointsList")
    removeConsoleCommand("gsProductionPointsPrintAutoDeliverMapping")
    removeConsoleCommand("gsProductionPointSetOwner")
    removeConsoleCommand("gsProductionPointSetProductionState")
    removeConsoleCommand("gsProductionPointSetOutputMode")
    removeConsoleCommand("gsProductionPointSetFillLevel")

    if self.isServer then
        g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
    end

    ProductionChainManager:superClass().unloadMapData(self)
end


---
function ProductionChainManager:addProductionPoint(productionPoint)
    if self.reverseProductionPoint[productionPoint] then
        Logging.warning("Production point '%s' already registered.", productionPoint:tableId())
        return false
    end
    if #self.productionPoints >= ProductionChainManager.NUM_MAX_PRODUCTION_POINTS then
        printf("Maximum number of %i Production Points reached.", ProductionChainManager.NUM_MAX_PRODUCTION_POINTS)
        return false
    end

    if #self.productionPoints == 0 and self.isServer then
        g_currentMission:addUpdateable(self)
    end

    self.reverseProductionPoint[productionPoint] = true
    table.insert(self.productionPoints, productionPoint)

--#debug     if self.debugEnabled then
--#debug         g_currentMission:addDrawable(productionPoint)
--#debug     end

    local farmId = productionPoint:getOwnerFarmId()
    if farmId ~= AccessHandler.EVERYONE then
        if not self.farmIds[farmId] then
            self.farmIds[farmId] = {}
        end
        self:addProductionPointToFarm(productionPoint, self.farmIds[farmId])
    end
    return true
end


---
function ProductionChainManager:addProductionPointToFarm(productionPoint, farmTable)
    if not farmTable.productionPoints then
        farmTable.productionPoints = {}
    end
    table.insert(farmTable.productionPoints, productionPoint)

    if not farmTable.inputTypeToProductionPoints then
        farmTable.inputTypeToProductionPoints = {}
    end

    for inputType in pairs(productionPoint.inputFillTypeIds) do
        if not farmTable.inputTypeToProductionPoints[inputType] then
            farmTable.inputTypeToProductionPoints[inputType] = {}
        end
        table.insert(farmTable.inputTypeToProductionPoints[inputType], productionPoint)
    end
end


---
function ProductionChainManager:addFactory(factory)
    if self.reverseFactory[factory] then
        Logging.warning("Factory '%s' already registered.", factory:tableId())
        return false
    end

    self.reverseFactory[factory] = true
    table.insert(self.factories, factory)

    local farmId = factory:getOwnerFarmId()
    if farmId ~= AccessHandler.EVERYONE then
        if not self.farmIds[farmId] then
            self.farmIds[farmId] = {}
        end
        self:addFactoryToFarm(factory, self.farmIds[farmId])
    end
    return true
end


---
function ProductionChainManager:addFactoryToFarm(factory, farmTable)
    if not farmTable.factories then
        farmTable.factories = {}
    end
    table.insert(farmTable.factories, factory)
end



---
function ProductionChainManager:removeProductionPoint(productionPoint)
    self.reverseProductionPoint[productionPoint] = nil

    if table.removeElement(self.productionPoints, productionPoint) then
        local farmId = productionPoint:getOwnerFarmId()
        if farmId ~= AccessHandler.EVERYONE then
            self.farmIds[farmId] = self:removeProductionPointFromFarm(productionPoint, self.farmIds[farmId])
        end

--#debug         if self.debugEnabled then
--#debug             g_currentMission:removeDrawable(productionPoint)
--#debug         end
    end

    if #self.productionPoints == 0 and self.isServer then
        g_currentMission:removeUpdateable(self)
    end
end


---
function ProductionChainManager:removeProductionPointFromFarm(productionPoint, farmTable)
    if farmTable.productionPoints == nil then
        return farmTable
    end

    table.removeElement(farmTable.productionPoints, productionPoint)

    local inputTypeToProductionPoints = farmTable.inputTypeToProductionPoints
    for inputType in pairs(productionPoint.inputFillTypeIds) do
        if inputTypeToProductionPoints[inputType] then
            if not table.removeElement(inputTypeToProductionPoints[inputType], productionPoint) then
                printError("Error: ProductionChainManager:removeProductionPoint(): Unable to remove production point from input type mapping")
            end
            if #inputTypeToProductionPoints[inputType] == 0 then
                inputTypeToProductionPoints[inputType] = nil
            end
        end
    end
    if #farmTable.productionPoints == 0 and farmTable.factories == nil then
        farmTable = nil
    end

    return farmTable
end


---
function ProductionChainManager:removeFactory(factory, farmId)
    self.reverseFactory[factory] = nil

    if table.removeElement(self.factories, factory) then
        if farmId ~= AccessHandler.EVERYONE and self.farmIds[farmId] ~= nil then
            self.farmIds[farmId] = self:removeFactoryFromFarm(factory, self.farmIds[farmId])
        end
    end
end


---
function ProductionChainManager:removeFactoryFromFarm(factory, farmTable)
    if farmTable.factories == nil then
        return farmTable
    end

    table.removeElement(farmTable.factories, factory)

    if #farmTable.factories == 0 and farmTable.productionPoints == nil then
        farmTable = nil
    end

    return farmTable
end


---
function ProductionChainManager:getProductionPointsForFarmId(farmId)
    return self.farmIds[farmId] and self.farmIds[farmId].productionPoints or {}
end


---
function ProductionChainManager:getFactoriesForFarmId(farmId)
    return self.farmIds[farmId] and self.farmIds[farmId].factories or {}
end


---
function ProductionChainManager:getNumOfProductionPoints()
    return #self.productionPoints
end


---
function ProductionChainManager:getUnownedProductionPoints()
    local unownedPoints = {}
    for _, point in pairs(self.productionPoints) do
        if point:getOwnerFarmId() == AccessHandler.EVERYONE then
            table.insert(unownedPoints, point)
        end
    end

    return unownedPoints
end


---
function ProductionChainManager:getUnownedFactories()
    local unownedFactories = {}
    for _, factory in pairs(self.factories) do
        if factory:getOwnerFarmId() == AccessHandler.EVERYONE then
            table.insert(unownedFactories, factory)
        end
    end

    return unownedFactories
end


---
function ProductionChainManager:getHasFreeSlots()
    return #self.productionPoints < ProductionChainManager.NUM_MAX_PRODUCTION_POINTS
end









































---
function ProductionChainManager:hourChanged()
    self.hourChangedDirty = true
end






























































---
function ProductionChainManager:updateBalance()

end
