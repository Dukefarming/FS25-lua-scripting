





---Class for fill triggers
local FillTrigger_mt = Class(FillTrigger)


---On create fill trigger
-- @param integer id id of trigger node
function FillTrigger:onCreate(id)
    local fillTrigger = FillTrigger.new(id)
    -- we can register this on client and server because onCreate is called on map load only
    local moneyChangeType = MoneyType.register("other", "finance_purchaseFuel")
    fillTrigger:setMoneyChangeType(moneyChangeType)
    g_currentMission:addNonUpdateable(fillTrigger)
end


---Create fill trigger object
-- @param integer id id of trigger node
-- @param table sourceObject sourceObject
-- @param integer fillUnitIndex fillUnitIndex
-- @param table? customMt custom metatable (optional)
-- @return table instance instance of gas station trigger
function FillTrigger.new(id, sourceObject, fillUnitIndex, fillLitersPerSecond, defaultFillType, customMt)
    local self = setmetatable({}, customMt or FillTrigger_mt)

    self.customEnvironment = g_currentMission.loadingMapModName

    self.triggerId = id
    addTrigger(id, "fillTriggerCallback", self)

    -- place sound at the same position as the trigger
    self.soundNode = createTransformGroup("fillTriggerSoundNode")
    link(getParent(id), self.soundNode)
    setTranslation(self.soundNode, getTranslation(id))

    self.sourceObject = sourceObject
    self.vehiclesTriggerCount = {}
    self.vehicleToFillUnitIndices = {}
    self.fillUnitIndex = fillUnitIndex
    self.fillLitersPerSecond = fillLitersPerSecond
    self.isEnabled = true

    self.fillTypeIndex = FillType.DIESEL

    return self
end






---Delete fill trigger
function FillTrigger:delete()
    -- remove the gas stations from all vehicles that are triggered by this trigger
    for vehicle,count in pairs(self.vehiclesTriggerCount) do
        if count > 0 then
            if vehicle.removeFillUnitTrigger ~= nil then
                vehicle:removeFillUnitTrigger(self)
            end
        end
    end

    g_soundManager:deleteSample(self.sample)

    removeTrigger(self.triggerId)
end


---Called if vehicle gets out of trigger
-- @param table vehicle vehicle
function FillTrigger:onVehicleDeleted(vehicle)
    self.vehiclesTriggerCount[vehicle] = nil
    g_currentMission:showMoneyChange(self.moneyChangeType, nil, false, vehicle:getActiveFarm())
end


---Fill vehicle
-- @param table vehicle vehicle to fill
-- @param float delta delta
-- @return float delta real delta
function FillTrigger:fillVehicle(vehicle, delta, dt)
    if self.fillLitersPerSecond ~= nil then
        delta = math.min(delta, self.fillLitersPerSecond * 0.001 * dt)
    end

    local farmId = vehicle:getActiveFarm()

    if self.sourceObject ~= nil then
        local sourceFuelFillLevel = self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex)
        if sourceFuelFillLevel > 0 and g_currentMission.accessHandler:canFarmAccess(farmId, self.sourceObject) then
            delta = math.min(delta, sourceFuelFillLevel)
            if delta <= 0 then
                return 0
            end
        else
            return 0
        end
    end

    local fillType = self:getCurrentFillType()

    local fillUnitIndex
    if self.vehicleToFillUnitIndices[vehicle] ~= nil then
        for _, _fillUnitIndex in pairs(self.vehicleToFillUnitIndices[vehicle]) do
            if vehicle:getFillUnitCanBeFilled(_fillUnitIndex, fillType) then
                fillUnitIndex = _fillUnitIndex
                break
            end
        end
    end

    if fillUnitIndex == nil then
        return 0
    end

    if vehicle.getCustomFillTriggerSpeedFactor ~= nil then
        delta = delta * vehicle:getCustomFillTriggerSpeedFactor(self, fillUnitIndex, fillType)
    end

    delta = vehicle:addFillUnitFillLevel(farmId, fillUnitIndex, delta, fillType, ToolType.TRIGGER, nil)

    if delta > 0 then
        if self.sourceObject ~= nil then
            self.sourceObject:addFillUnitFillLevel(farmId, self.fillUnitIndex, -delta, fillType, ToolType.TRIGGER, nil)
        else
            local price = delta * g_currentMission.economyManager:getPricePerLiter(fillType)
            g_farmManager:updateFarmStats(farmId, "expenses", price)
            g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true)
        end
    end

    return delta
end


---Returns true if is activateable
-- @param table vehicle vehicle
-- @return boolean isActivateable is activateable
function FillTrigger:getIsActivatable(vehicle)
    if self.sourceObject ~= nil then
        if self.sourceObject:getFillUnitFillLevel(self.fillUnitIndex) > 0 and g_currentMission.accessHandler:canFarmAccess(vehicle:getActiveFarm(), self.sourceObject) then
            return true
        end
    end

    return false
end


---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherId id of actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
function FillTrigger:fillTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if self.isEnabled and (onEnter or onLeave) then
        local vehicle = g_currentMission:getNodeObject(otherId)
        if vehicle ~= nil and vehicle.addFillUnitTrigger ~= nil and vehicle.removeFillUnitTrigger ~= nil and vehicle ~= self and vehicle ~= self.sourceObject then
            local count = Utils.getNoNil(self.vehiclesTriggerCount[vehicle], 0)
            if onEnter then
                local fillType = self:getCurrentFillType()

                local fillUnitIndex = vehicle:getFillUnitIndexFromNode(otherId)
                if fillUnitIndex ~= nil then
                    if not vehicle:getFillUnitCanBeFilled(fillUnitIndex, fillType) then
                        fillUnitIndex = nil
                    end
                end

                if fillUnitIndex ~= nil then
                    self.vehiclesTriggerCount[vehicle] = count + 1
                    if self.vehicleToFillUnitIndices[vehicle] == nil then
                        self.vehicleToFillUnitIndices[vehicle] = {}
                    end
                    self.vehicleToFillUnitIndices[vehicle][otherId] = fillUnitIndex

                    if count == 0 then
                        vehicle:addFillUnitTrigger(self, fillType, fillUnitIndex)
                    end
                end
            else
                self.vehiclesTriggerCount[vehicle] = count - 1

                if self.vehicleToFillUnitIndices[vehicle] ~= nil then
                    self.vehicleToFillUnitIndices[vehicle][otherId] = nil
                end

                if count <= 1 then
                    self.vehiclesTriggerCount[vehicle] = nil
                    vehicle:removeFillUnitTrigger(self)
                    g_currentMission:showMoneyChange(self.moneyChangeType, nil, false, vehicle:getActiveFarm())
                end
            end
        end
    end
end
