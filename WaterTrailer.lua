












---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function WaterTrailer.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(FillUnit, specializations)
end


---
function WaterTrailer.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("WaterTrailer")

    schema:register(XMLValueType.INT, "vehicle.waterTrailer#fillUnitIndex", "Fill unit index")
    schema:register(XMLValueType.FLOAT, "vehicle.waterTrailer#fillLitersPerSecond", "Fill liters per second", 500)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.waterTrailer#fillNode", "Fill node", "Root component")

    SoundManager.registerSampleXMLPaths(schema, "vehicle.waterTrailer.sounds", "refill")

    schema:setXMLSpecializationType()
end


---
function WaterTrailer.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setIsWaterTrailerFilling", WaterTrailer.setIsWaterTrailerFilling)
end


---
function WaterTrailer.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", WaterTrailer.getDrawFirstFillText)
end


---
function WaterTrailer.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", WaterTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", WaterTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", WaterTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", WaterTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WaterTrailer)
    SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", WaterTrailer)
end


---Called on loading
-- @param table savegame savegame
function WaterTrailer:onLoad(savegame)
    local spec = self.spec_waterTrailer

    local fillUnitIndex = self.xmlFile:getValue("vehicle.waterTrailer#fillUnitIndex")
    if fillUnitIndex ~= nil then
        spec.fillUnitIndex = fillUnitIndex
        spec.fillLitersPerSecond = self.xmlFile:getValue("vehicle.waterTrailer#fillLitersPerSecond", 500)
        spec.waterFillNode = self.xmlFile:getValue("vehicle.waterTrailer#fillNode", self.components[1].node, self.components, self.i3dMappings)
    end

    spec.isFilling = false
    spec.activatable = WaterTrailerActivatable.new(self)

    if self.isClient then
        spec.samples = {}
        spec.samples.refill = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.waterTrailer.sounds", "refill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    self.needWaterInfo = true
end


---Called on deleting
function WaterTrailer:onDelete()
    local spec = self.spec_waterTrailer
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

    g_soundManager:deleteSamples(spec.samples)
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WaterTrailer:onReadStream(streamId, connection)
    local isFilling = streamReadBool(streamId)
    self:setIsWaterTrailerFilling(isFilling, true)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WaterTrailer:onWriteStream(streamId, connection)
    local spec = self.spec_waterTrailer
    streamWriteBool(streamId, spec.isFilling)
end


---Called on update tick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function WaterTrailer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_waterTrailer

    local _, y, _ = getWorldTranslation(spec.waterFillNode)
    local isNearWater = (y <= self.waterY + 0.2)

    if isNearWater then
        g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
    else
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end

    if self.isServer then
        if spec.isFilling then
            -- stop filling if not near the water anymore
            if not isNearWater then
                self:setIsWaterTrailerFilling(false)
            end
        end

        if spec.isFilling then
            if self:getFillUnitAllowsFillType(spec.fillUnitIndex, FillType.WATER) then
                local delta = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, spec.fillLitersPerSecond*dt*0.001, FillType.WATER, ToolType.TRIGGER, nil)
                if delta <= 0 then
                    self:setIsWaterTrailerFilling(false)
                end
            end
        end
    end
end


---Set is water trailer filling state
-- @param boolean isFilling new is filling state
-- @param boolean noEventSend no event send
function WaterTrailer:setIsWaterTrailerFilling(isFilling, noEventSend)
    local spec = self.spec_waterTrailer
    if isFilling ~= spec.isFilling then
        WaterTrailerSetIsFillingEvent.sendEvent(self, isFilling, noEventSend)

        spec.isFilling = isFilling

        if self.isClient then
            if isFilling then
                g_soundManager:playSample(spec.samples.refill)
            else
                g_soundManager:stopSample(spec.samples.refill)
            end
        end
    end
end


---
function WaterTrailer:getDrawFirstFillText(superFunc)
    local spec = self.spec_waterTrailer
    if self.isClient then
        if self:getIsActiveForInput() and self:getIsSelected() then
            if self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
                return true
            end
        end
    end

    return superFunc(self)
end


---Called if vehicle gets detached
-- @param table attacherVehicle attacher vehicle
-- @param table implement implement
function WaterTrailer:onPreDetach(attacherVehicle, implement)
    local spec = self.spec_waterTrailer
    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
end







---Called if vehicle gets detached
local WaterTrailerActivatable_mt = Class(WaterTrailerActivatable)


---
function WaterTrailerActivatable.new(trailer)
    local self = setmetatable({}, WaterTrailerActivatable_mt)

    self.trailer = trailer
    self.activateText = "unknown"

    return self
end


---
function WaterTrailerActivatable:getIsActivatable()
    local fillUnitIndex = self.trailer.spec_waterTrailer.fillUnitIndex
    if self.trailer:getIsActiveForInput(true) and self.trailer:getFillUnitFillLevel(fillUnitIndex) < self.trailer:getFillUnitCapacity(fillUnitIndex) and self.trailer:getFillUnitAllowsFillType(fillUnitIndex, FillType.WATER) then
        self:updateActivateText()
        return true
    end
    return false
end


---
function WaterTrailerActivatable:run()
    self.trailer:setIsWaterTrailerFilling(not self.trailer.spec_waterTrailer.isFilling)
    self:updateActivateText()
end


---
function WaterTrailerActivatable:updateActivateText()
    if self.trailer.spec_waterTrailer.isFilling then
        self.activateText = string.format(g_i18n:getText("action_stopRefillingOBJECT"), self.trailer.typeDesc)
    else
        self.activateText = string.format(g_i18n:getText("action_refillOBJECT"), self.trailer.typeDesc)
    end
end
