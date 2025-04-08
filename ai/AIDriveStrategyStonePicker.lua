



---drive strategy to
-- - stop when stone picker is full
-- 
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.
local AIDriveStrategyStonePicker_mt = Class(AIDriveStrategyStonePicker, AIDriveStrategy)


---
function AIDriveStrategyStonePicker.new(reconstructionData, customMt)
    local self = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyStonePicker_mt)

    self.stonePickers = {}

    self.notificationFullTankShown = false

    return self
end


---
function AIDriveStrategyStonePicker:setAIVehicle(vehicle)
    AIDriveStrategyStonePicker:superClass().setAIVehicle(self, vehicle)

    if SpecializationUtil.hasSpecialization(StonePicker, self.vehicle.specializations) then
        table.insert(self.stonePickers, self.vehicle)
    end
    for _,implement in pairs(self.vehicle:getAttachedAIImplements()) do
        if SpecializationUtil.hasSpecialization(StonePicker, implement.object.specializations) then
            table.insert(self.stonePickers, implement.object)
        end
    end
end


---
function AIDriveStrategyStonePicker:update(dt)
end


---
function AIDriveStrategyStonePicker:getDriveData(dt, vX,vY,vZ)
    local allowedToDrive = true
    local maxSpeed = math.huge

    for _, stonePicker in pairs(self.stonePickers) do
        local spec = stonePicker.spec_stonePicker
        local fillLevel = stonePicker:getFillUnitFillLevel(spec.fillUnitIndex)
        local capacity = stonePicker:getFillUnitCapacity(spec.fillUnitIndex)

        if stonePicker.getDischargeState ~= nil then
            if stonePicker:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF then
                allowedToDrive = false

                local dischargeNode = stonePicker:getCurrentDischargeNode()
                if dischargeNode ~= nil then
                    local targetObject, _ = stonePicker:getDischargeTargetObject(dischargeNode)
                    if targetObject == nil or fillLevel <= 0 then
                        stonePicker:setDischargeState(Dischargeable.DISCHARGE_STATE_OFF)
                    end
                end
            end
        end

        if stonePicker.getTipState ~= nil then
            if stonePicker:getTipState() ~= Trailer.TIPSTATE_CLOSED then
                allowedToDrive = false
            end
        end

        if fillLevel >= capacity then
            allowedToDrive = false
            if VehicleDebug.state == VehicleDebug.DEBUG_AI then
                self.vehicle:addAIDebugText(string.format("STONE PICKER -> full"))
            end

            if self.notificationFullTankShown ~= true then
               g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ai_messageErrorTankIsFull"), self.vehicle:getCurrentHelper().name) )
                self.notificationFullTankShown = true
            end

            if stonePicker.getCurrentDischargeNode ~= nil then
                local dischargeNode = stonePicker:getCurrentDischargeNode()
                if dischargeNode ~= nil then
                    local targetObject, _ = stonePicker:getDischargeTargetObject(dischargeNode)
                    if targetObject ~= nil then
                        stonePicker:setDischargeState(Dischargeable.DISCHARGE_STATE_OBJECT)
                    end
                end
            end
        else
            self.notificationFullTankShown = false
        end
    end

    if not allowedToDrive then
        return 0, 1, true, 0, math.huge
    else
        return nil, nil, nil, maxSpeed, nil
    end
end


---
function AIDriveStrategyStonePicker:updateDriving(dt)
end
