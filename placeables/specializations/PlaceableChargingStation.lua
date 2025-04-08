














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableChargingStation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableBuyingStation, specializations)
end


---
function PlaceableChargingStation.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getIsCharging", PlaceableChargingStation.getIsCharging)
    SpecializationUtil.registerFunction(placeableType, "getChargeState", PlaceableChargingStation.getChargeState)
end




























---Called on loading
-- @param table savegame savegame
function PlaceableChargingStation:onLoad(savegame)
    local spec = self.spec_chargingStation

    spec.chargeIndicatorIntensity = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#intensity", 20)
    spec.chargeIndicatorBlinkSpeed = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#blinkSpeed", 5)

    spec.chargeIndicatorNode = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#node", nil, self.components, self.i3dMappings)
    if spec.chargeIndicatorNode ~= nil then
        setShaderParameter(spec.chargeIndicatorNode, "lightControl", spec.chargeIndicatorIntensity, 0, 0, 0, false)
        setShaderParameter(spec.chargeIndicatorNode, "emitColor", 1, 1, 0, 0, false)
    end

    spec.chargeIndicatorLight = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#light", nil, self.components, self.i3dMappings)
    if spec.chargeIndicatorLight then
        setLightColor(spec.chargeIndicatorLight, 0, 0, 0)
    end

    spec.chargeIndicatorColorFull = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#colorFull", "0 1 0 1", true)
    spec.chargeIndicatorColorEmpty = self.xmlFile:getValue("placeable.chargingStation.chargeIndicator#colorEmpty", "1 1 0 1", true)
    spec.chargeIndicatorLightColor = spec.chargeIndicatorColorFull

    spec.interactionRadius = self.xmlFile:getValue("placeable.chargingStation#interactionRadius", 5)

    spec.loadTrigger = nil

    spec.buyingStation = self:getBuyingStation()
    if spec.buyingStation ~= nil then
        for j=1, #spec.buyingStation.loadTriggers do
            local loadTrigger = spec.buyingStation.loadTriggers[j]

            spec.loadTrigger = loadTrigger

            spec.fillSample = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.chargingStation.sounds", "fill", self.baseDirectory, self.components, 0, AudioGroup.ENVIRONMENT, self.i3dMappings, nil)
            if spec.fillSample ~= nil then
                if loadTrigger.samples.load == nil then
                    loadTrigger.samples.load = spec.fillSample
                end
            end
        end
    end
end


---
function PlaceableChargingStation:getIsCharging()
    local spec = self.spec_chargingStation
    if spec.loadTrigger ~= nil then
        return spec.loadTrigger.isLoading
    end

    return false
end


---
function PlaceableChargingStation:getChargeState()
    local spec = self.spec_chargingStation
    if spec.loadTrigger ~= nil then
        local index = next(spec.loadTrigger.fillableObjects)
        if index ~= nil then
            local vehicle = spec.loadTrigger.fillableObjects[index].object
            if vehicle.getConsumerFillUnitIndex ~= nil then
                local fillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE)
                if fillUnitIndex ~= nil then
                    return vehicle:getFillUnitFillLevel(fillUnitIndex), vehicle:getFillUnitCapacity(fillUnitIndex)
                end
            end
        end
    end

    return 0, 1
end


---Update
-- @param float dt time since last call in ms
function PlaceableChargingStation:onUpdate(dt)
    local spec = self.spec_chargingStation

    if spec.loadTrigger ~= nil then
        local isActive = next(spec.loadTrigger.fillableObjects) ~= nil

        if spec.chargeIndicatorNode ~= nil then
            if isActive then
                local color = spec.chargeIndicatorColorEmpty
                local fillLevel, capacity = self:getChargeState()
                if fillLevel / capacity > 0.95 then
                    color = spec.chargeIndicatorColorFull
                end

                setShaderParameter(spec.chargeIndicatorNode, "colorScale", color[1], color[2], color[3], color[4], false)
                spec.chargeIndicatorLightColor = color
            end

            local blinkSpeed = spec.loadTrigger.isLoading and spec.chargeIndicatorBlinkSpeed or 0
            setShaderParameter(spec.chargeIndicatorNode, "blinkSimple", blinkSpeed, 0, 0, 0, false)
            setShaderParameter(spec.chargeIndicatorNode, "lightControl", isActive and spec.chargeIndicatorIntensity or 0, 0, 0, 0, false)

            if spec.chargeIndicatorLight ~= nil then
                local alpha = 0
                if isActive then
                    local blinkFrequency, blinkTimeOffset, _, _ = getShaderParameter(spec.chargeIndicatorNode, "blinkSimple")
                    alpha = math.clamp(4 * math.abs(math.fmod(blinkFrequency * getShaderTimeSec() + blinkTimeOffset, 1) - 0.5) - 0.8, 0, 1)
                end

                setLightColor(spec.chargeIndicatorLight, spec.chargeIndicatorLightColor[1]*alpha, spec.chargeIndicatorLightColor[2]*alpha, spec.chargeIndicatorLightColor[3]*alpha)
            end
        end

        if spec.loadTrigger.isLoading then
            local allowDisplay = false
            local localPlayer = g_localPlayer
            if localPlayer ~= nil and not localPlayer:getIsInVehicle() then
                local distance = calcDistanceFrom(localPlayer.rootNode, self.rootNode)
                if distance < spec.interactionRadius then
                    allowDisplay = true
                end
            else
                local playerVehicle = localPlayer:getCurrentVehicle()
                if playerVehicle ~= nil then
                    for _, object in pairs(spec.loadTrigger.fillableObjects) do
                        if object.object == playerVehicle then
                            allowDisplay = true
                        end
                    end
                end
            end

            if allowDisplay then
                local fillLevel, capacity = self:getChargeState()
                local fillLevelToFill = capacity - fillLevel
                local literPerSecond = spec.loadTrigger.fillLitersPerMS * 1000
                local seconds = fillLevelToFill / literPerSecond
                if seconds >= 1 then
                    local minutes = math.floor(seconds / 60)
                    seconds = seconds - (minutes * 60)
                    local chargingInfoText = string.format(g_i18n:getText("info_chargeTime"), minutes, seconds, fillLevel / capacity * 100)
                    g_currentMission:addExtraPrintText(chargingInfoText)
                end
            end
        end

        if isActive then
            self:raiseActive()
        end
    end
end
