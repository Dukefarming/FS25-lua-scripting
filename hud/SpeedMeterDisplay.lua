


























---
local SpeedMeterDisplay_mt = Class(SpeedMeterDisplay, HUDDisplay)


---Create a new SpeedMeterDisplay instance.
function SpeedMeterDisplay.new()
    local self = SpeedMeterDisplay:superClass().new(SpeedMeterDisplay_mt)

    self.vehicle = nil -- currently controlled vehicle reference
    self.isVehicleDrawSafe = false -- safety flag for drawing, must always run one update after setting a vehicle before drawing

    local r, g, b, a = unpack(HUD.COLOR.ACTIVE)

    self.speedBg = g_overlayManager:createOverlay("gui.speedBg", 0, 0, 0, 0)
    self.speedBgScale = g_overlayManager:createOverlay("gui.speedBgScale", 0, 0, 0, 0)
    self.speedBgRight = g_overlayManager:createOverlay("gui.speedBgRight", 0, 0, 0, 0)

    self.speedIndicatorBg = g_overlayManager:createOverlay("gui.speedGaugeBg", 0, 0, 0, 0)

    self.workingHours = g_overlayManager:createOverlay("gui.icon_usage", 0, 0, 0, 0)
    self.workingHours:setColor(r, g, b, a)

    self.cruiseControl = g_overlayManager:createOverlay("gui.icon_tempomat", 0, 0, 0, 0)
    self.cruiseControl:setColor(r, g, b, a)

    self.aiWorkerIcon = g_overlayManager:createOverlay("gui.icon_gps", 0, 0, 0, 0)
    self.aiWorkerIcon:setColor(r, g, b, a)

    self.aiSteeringIcon = g_overlayManager:createOverlay("gui.icon_guidance", 0, 0, 0, 0)
    self.aiSteeringIcon:setColor(r, g, b, a)

    self.fuelIcon = g_overlayManager:createOverlay("gui.icon_fuel", 0, 0, 0, 0)
    self.repairIcon = g_overlayManager:createOverlay("gui.icon_repair", 0, 0, 0, 0)

    self.bar = ThreePartOverlay.new()
    self.bar:setLeftPart("gui.progressbar_left", 0, 0)
    self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
    self.bar:setRightPart("gui.progressbar_right", 0, 0)
    self.bar:setRotation(math.rad(90))

    self.gearIcon = g_overlayManager:createOverlay("gui.icon_gear", 0, 0, 0, 0)
    self.gearBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
    self.gearBg:setColor(r, g, b, a)
    self.gearTexts = {"A", "B", "C"}
    self.gearWarningTime = 0

    self.lastGaugeValue = 0

    self.rpmUnitText = g_i18n:getText("unit_rpmShort")
    self.kmhUnitText = g_i18n:getText("unit_kmh")
    self.mphUnitText = g_i18n:getText("unit_mph")

    self.aiInactiveText = g_i18n:getText("ui_gpsInactive")
    self.aiReadyText = g_i18n:getText("ui_gpsReady")
    self.aiActiveText = g_i18n:getText("ui_gpsActive")

    return self
end


















---Store scaled positioning, size and offset values.
function SpeedMeterDisplay:storeScaledValues()
    self:setPosition(g_hudAnchorRight, g_hudAnchorBottom)

    local speedBgWidth, speedBgHeight = self:scalePixelValuesToScreenVector(232, 232)
    self.speedBg:setDimension(speedBgWidth, speedBgHeight)
    self.speedBgScale:setDimension(0, speedBgHeight)

    local speedBgRightWidth, speedBgRightHeight = self:scalePixelValuesToScreenVector(23, 232)
    self.speedBgRight:setDimension(speedBgRightWidth, speedBgRightHeight)

    local speedGaugeBgWidth, speedGaugeBgHeight = self:scalePixelValuesToScreenVector(13, 23)
    self.speedIndicatorBg:setDimension(speedGaugeBgWidth, speedGaugeBgHeight)

    self.speedGaugeCenterOffsetX, self.speedGaugeCenterOffsetY = self:scalePixelValuesToScreenVector(117, 116)
    self.speedGaugeRadiusX, self.speedGaugeRadiusY = self:scalePixelValuesToScreenVector(68, 68)

    self.gaugeTextOffsets = {}
    local function addOffset(x, y, alignment)
        x, y = self:scalePixelValuesToScreenVector(x, y)
        table.insert(self.gaugeTextOffsets, {offsetX=x, offsetY=y, alignment=alignment})
    end
    addOffset(-57, -33, RenderText.ALIGN_LEFT)
    addOffset(-64, -7, RenderText.ALIGN_LEFT)
    addOffset(-60, 19, RenderText.ALIGN_LEFT)
    addOffset(-46, 40, RenderText.ALIGN_LEFT)
    addOffset(-22, 54, RenderText.ALIGN_LEFT)
    addOffset(22, 54, RenderText.ALIGN_RIGHT)
    addOffset(46, 40, RenderText.ALIGN_RIGHT)
    addOffset(60, 19, RenderText.ALIGN_RIGHT)
    addOffset(64, -7, RenderText.ALIGN_RIGHT)
    addOffset(57, -33, RenderText.ALIGN_RIGHT)

    self.gaugeTextRadiusX, self.gaugeTextRadiusY = self:scalePixelValuesToScreenVector(58, 58)

    self.gaugeUnitTextSize = self:scalePixelToScreenHeight(9)
    self.gaugeFactorTextSize = self:scalePixelToScreenHeight(9)

    self.gaugeUnitOffsetX, self.gaugeUnitOffsetY = self:scalePixelValuesToScreenVector(-64, -50)
    self.gaugeFactorOffsetX, self.gaugeFactorOffsetY = self:scalePixelValuesToScreenVector(64, -50)

    self.speedTextSize = self:scalePixelToScreenHeight(58)
    self.speedTextOffsetX, self.speedTextOffsetY = self:scalePixelValuesToScreenVector(0, -12)

    self.speedUnitTextSize = self:scalePixelToScreenHeight(15)
    self.speedUnitTextOffsetX, self.speedUnitTextOffsetY = self:scalePixelValuesToScreenVector(0, -27)

    self.workingHoursOffsetX, self.workingHoursOffsetY = self:scalePixelValuesToScreenVector(-45, -73)
    local workingHoursWidth, workingHoursHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.workingHours:setDimension(workingHoursWidth, workingHoursHeight)
    self.workingHoursTextSize = self:scalePixelToScreenHeight(17)
    self.workingHoursTextOffsetX, self.workingHoursTextOffsetY = self:scalePixelValuesToScreenVector(35, -64)
    self.workingHoursSeperatorOffsetX, self.workingHoursSeperatorOffsetY = self:scalePixelValuesToScreenVector(-39, -43)

    self.cruiseControlOffsetX, self.cruiseControlOffsetY = self:scalePixelValuesToScreenVector(-30, -100)
    local cruiseControlWidth, cruiseControlHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.cruiseControl:setDimension(cruiseControlWidth, cruiseControlHeight)
    self.cruiseControlTextSize = self:scalePixelToScreenHeight(17)
    self.cruiseControlTextOffsetX, self.cruiseControlTextOffsetY = self:scalePixelValuesToScreenVector(2, -94)

    self.cruiseControlSeperatorOffsetX, self.cruiseControlSeperatorOffsetY = self:scalePixelValuesToScreenVector(-39, -73)
    self.seperatorWidth = self:scalePixelToScreenWidth(78)

    self.sectionOffsetX, self.sectionOffsetY = self:scalePixelValuesToScreenVector(9, 47)

    local fuelIconWidth, fuelIconHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.fuelIcon:setDimension(fuelIconWidth, fuelIconHeight)
    self.fuelIconOffsetX, self.fuelIconOffsetY = self:scalePixelValuesToScreenVector(-16, 144)
    self.fuelBarScaleWidth = self:scalePixelToScreenWidth(21)
    self.fuelBarOffsetX, self.fuelBarOffsetY = self:scalePixelValuesToScreenVector(0, 0)
    self.fuelOffsetX, self.fuelOffsetY = self:scalePixelValuesToScreenVector(-30, 0)

    local repairWidth, repairHeight = self:scalePixelValuesToScreenVector(25, 30)
    self.repairIcon:setDimension(repairWidth, repairHeight)
    self.repairIconOffsetX, self.repairIconOffsetY = self:scalePixelValuesToScreenVector(-16, 144)
    self.repairBarOffsetX, self.repairBarOffsetY = self:scalePixelValuesToScreenVector(0, 0)
    self.repairBarScaleWidth = self:scalePixelToScreenWidth(21)
    self.repairOffsetX, self.repairOffsetY = self:scalePixelValuesToScreenVector(-30, 0)

    local gearWidth, gearHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.gearIcon:setDimension(gearWidth, gearHeight)
    self.gearIconOffsetX, self.gearIconOffsetY = self:scalePixelValuesToScreenVector(-16, 144)
    self.gearBarScaleWidth = self:scalePixelToScreenWidth(30)
    self.gearOffsetX, self.gearOffsetY = self:scalePixelValuesToScreenVector(-30, 0)
    local gearBgWidth, gearBgHeight = self:scalePixelValuesToScreenVector(26, 26)
    self.gearBg:setDimension(gearBgWidth, gearBgHeight)

    self.gearTextOffsetY = {}
    self.gearTextOffsetY[1] = self:scalePixelToScreenHeight(9)
    self.gearTextOffsetY[2] = self:scalePixelToScreenHeight(37)
    self.gearTextOffsetY[3] = self:scalePixelToScreenHeight(65)
    self.gearGroupTextOffsetY = self:scalePixelToScreenHeight(102)
    self.gearTextSize = self:scalePixelToScreenHeight(12)

    self.gearBgOffsetX = self:scalePixelToScreenWidth(-13)
    local offsetY = self:scalePixelToScreenHeight(-8)
    self.gearBgOffsetY = {}
    self.gearBgOffsetY[1] = self.gearTextOffsetY[1] + offsetY
    self.gearBgOffsetY[2] = self.gearTextOffsetY[2] + offsetY
    self.gearBgOffsetY[3] = self.gearTextOffsetY[3] + offsetY

    local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(6, 6)
    local barTotalWidth, _ = self:scalePixelValuesToScreenVector(130, 0)
    self.barMaxScaleWidth = barTotalWidth-2*barPartWidth
    self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
    self.bar:setMiddlePart(nil, self.barMaxScaleWidth, barPartHeight)
    self.bar:setRightPart(nil, barPartWidth, barPartHeight)

    local aiIconWidth, aiIconHeight = self:scalePixelValuesToScreenVector(30, 30)
    self.aiWorkerIcon:setDimension(aiIconWidth, aiIconHeight)
    self.aiSteeringIcon:setDimension(aiIconWidth, aiIconHeight)
    self.aiIconOffsetX, self.aiIconOffsetY = self:scalePixelValuesToScreenVector(-109, 2)
    self.aiTextOffsetX, self.aiTextOffsetY = self:scalePixelValuesToScreenVector(-49, 12)
    self.aiTextSize = self:scalePixelToScreenHeight(16)
    self.aiSeperatorOffsetX, self.aiSeperatorOffsetY = self:scalePixelValuesToScreenVector(-114, 34)
    self.aiSeperatorWidth = self:scalePixelToScreenWidth(100)
end








---Draw the speed meter.
function SpeedMeterDisplay:draw()
    local vehicle = self.vehicle
    if vehicle == nil or not self.isVehicleDrawSafe then
        return
    end

    local scaleWidth = 0
    local _
    local hasFuel = false
    local fuelLevel, fuelCapacity
    local isMotorized = vehicle.spec_motorized ~= nil
    if isMotorized then
        fuelLevel, fuelCapacity, _ = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
        hasFuel = fuelCapacity ~= nil
        scaleWidth = scaleWidth + self.fuelBarScaleWidth
    end

    local hasRepair = false
    if vehicle.getDamageAmount ~= nil and vehicle:getDamageAmount() ~= nil then
        hasRepair = true
        scaleWidth = scaleWidth + self.repairBarScaleWidth
    end

    local hasGear = true
    if hasGear then
       scaleWidth = scaleWidth + self.gearBarScaleWidth
    end

    local posX, posY = self:getPosition()
    self.speedBgRight:setPosition(posX - self.speedBgRight.width, posY)

    self.speedBgScale:setDimension(scaleWidth, nil)
    self.speedBgScale:setPosition(self.speedBgRight.x - self.speedBgScale.width, posY)

    self.speedBg:setPosition(self.speedBgScale.x - self.speedBg.width, posY)

    self.speedBg:render()
    self.speedBgScale:render()
    self.speedBgRight:render()

    self:drawSpeedMeter(self.speedBg.x + self.speedGaugeCenterOffsetX, self.speedBg.y + self.speedGaugeCenterOffsetY)

    if vehicle.getAIAutomaticSteeringState ~= nil then
        local selectedAIMode = vehicle:getAIModeSelection()

        local activeColor = HUD.COLOR.ACTIVE
        local startX = posX + self.aiSeperatorOffsetX
        local startY = posY + self.aiSeperatorOffsetY
        local endX = startX + self.aiSeperatorWidth
        local endY = startY
        drawLine2D(startX, startY, endX, endY, g_pixelSizeY, activeColor[1], activeColor[2], activeColor[3], activeColor[4])

        local timeSinceLastModeChange = g_time - vehicle.spec_aiModeSelection.lastModeChangeTime
        if timeSinceLastModeChange < 2500 then
            local modeName = g_i18n:getText(AIModeSelection.MODE_TEXTS[selectedAIMode])
            local alpha = math.sin(timeSinceLastModeChange / 2500 * math.pi * 3 - (math.pi * 0.5)) * 0.5 + 0.5

            setTextColor(HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], alpha)
            setTextAlignment(RenderText.ALIGN_CENTER)
            renderText(startX + self.aiSeperatorWidth * 0.5, posY + self.aiTextOffsetY, self.aiTextSize, modeName)
        else
            local aiIcon = self.aiWorkerIcon
            local text = self.aiInactiveText
            local r, g, b, a = 1, 1, 1, 1

            if selectedAIMode == AIModeSelection.MODE.STEERING_ASSIST then
                aiIcon = self.aiSteeringIcon

                local steeringState = vehicle:getAIAutomaticSteeringState()
                if steeringState == AIAutomaticSteering.STATE.AVAILABLE then
                    r, g, b, a = HUD.COLOR.AVAILABLE[1], HUD.COLOR.AVAILABLE[2], HUD.COLOR.AVAILABLE[3], HUD.COLOR.AVAILABLE[4]
                    text = self.aiReadyText
                elseif steeringState == AIAutomaticSteering.STATE.ACTIVE then
                    r, g, b, a = HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], HUD.COLOR.ACTIVE[4]
                    text = self.aiActiveText
                end
            else
                if vehicle:getIsAIActive() then
                    r, g, b, a = HUD.COLOR.ACTIVE[1], HUD.COLOR.ACTIVE[2], HUD.COLOR.ACTIVE[3], HUD.COLOR.ACTIVE[4]
                    text = self.aiActiveText
                end
            end

            local gpsTextPosX = posX + self.aiTextOffsetX
            local gpsTextPosY = posY + self.aiTextOffsetY
            setTextColor(1, 1, 1, 1)
            setTextAlignment(RenderText.ALIGN_CENTER)
            renderText(gpsTextPosX, gpsTextPosY, self.aiTextSize, text)

            aiIcon:setColor(r, g, b, a)
            aiIcon:setPosition(posX + self.aiIconOffsetX, posY + self.aiIconOffsetY)
            aiIcon:render()
        end

        setTextBold(false)
        setTextColor(1, 1, 1, 1)
        setTextAlignment(RenderText.ALIGN_LEFT)
    end

    local sectionPosX = posX + self.sectionOffsetX
    local sectionPosY = posY + self.sectionOffsetY

    if hasFuel then
        sectionPosX = sectionPosX + self.fuelOffsetX
        local fuelSectionPosY = sectionPosY + self.fuelOffsetY

        self.fuelIcon:setPosition(sectionPosX + self.fuelIconOffsetX, fuelSectionPosY + self.fuelIconOffsetY)
        self.fuelIcon:render()

        self.bar:setColor(0, 0, 0, 1)
        self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
        self.bar:setPosition(sectionPosX + self.fuelBarOffsetX, fuelSectionPosY + self.fuelBarOffsetY)
        self.bar:render()

        local fuelPercentage = fuelLevel / fuelCapacity
        if fuelPercentage > 0 then
            if fuelPercentage > 0.1 then
                self.bar:setColor(1, 0.4287, 0.0006, 1)
            else
                self.bar:setColor(1, 0.1233, 0, math.abs(math.cos(g_time / 300)))
            end

            local barScale = math.clamp(self.barMaxScaleWidth * fuelPercentage, 0, self.barMaxScaleWidth)
            self.bar:setMiddlePart(nil, barScale, nil)
            self.bar:setPosition(sectionPosX + self.fuelBarOffsetX, fuelSectionPosY + self.fuelBarOffsetY)
            self.bar:render()
        end
    end

    if hasRepair then
        sectionPosX = sectionPosX + self.repairOffsetX
        local repairSectionPosY = sectionPosY + self.repairOffsetY
        self.repairIcon:setPosition(sectionPosX + self.repairIconOffsetX, repairSectionPosY + self.repairIconOffsetY)
        self.repairIcon:render()

        self.bar:setColor(0, 0, 0, 1)
        self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
        self.bar:setPosition(sectionPosX + self.repairBarOffsetX, repairSectionPosY + self.repairBarOffsetY)
        self.bar:render()

        local damageValue = 1
        -- Show the most damage any item in the vehicle has
        local vehicles = vehicle.rootVehicle.childVehicles
        for _, subVehicle in ipairs(vehicles) do
            if subVehicle.getDamageShowOnHud ~= nil and subVehicle:getDamageShowOnHud() then
                damageValue = math.min(damageValue, 1 - subVehicle:getDamageAmount())
            end
        end

        if damageValue > 0 then
            if damageValue > 0.2 then
                self.bar:setColor(0.0097, 0.4287, 0.6445, 1)
            else
                self.bar:setColor(1, 0.1233, 0, 1)
            end

            local barScale = math.clamp(self.barMaxScaleWidth * damageValue, 0, self.barMaxScaleWidth)
            self.bar:setMiddlePart(nil, barScale, nil)
            self.bar:setPosition(sectionPosX + self.repairBarOffsetX, repairSectionPosY + self.repairBarOffsetY)
            self.bar:render()
        end
    end

    if hasGear then
        sectionPosX = sectionPosX + self.gearOffsetX
        local gearSectionPosY = sectionPosY + self.gearOffsetY
        self.gearIcon:setPosition(sectionPosX + self.gearIconOffsetX, gearSectionPosY + self.gearIconOffsetY)
        self.gearIcon:render()

        self:drawGearText(sectionPosX, gearSectionPosY)
    end
end








































































































































































































---Draw vehicle gear
-- @param table vehicle Current vehicle
function SpeedMeterDisplay:drawGearText(x, y)
    if self.vehicle == nil then
        return
    end

    local gearName, gearGroupName, _gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning = self.vehicle:getGearInfoToDisplay()
    local gearSelectedIndex = 1
    local gearGroupText = ""

    -- With gears (with or without group) and not automatic, set up the texts
    if gearName ~= nil and not isAutomatic then
        gearGroupText = gearGroupName or ""

        if nextGearName == nil and prevGearName == nil then
            self.gearTexts[1] = ""
            self.gearTexts[2] = gearName -- probably N
            self.gearTexts[3] = ""
            gearSelectedIndex = 2
        elseif nextGearName == nil then -- If there is no Next, this gear is the last gear
            if prevPrevGearName ~= nil then
                self.gearTexts[1] = prevPrevGearName
                self.gearTexts[2] = prevGearName
                self.gearTexts[3] = gearName
                gearSelectedIndex = 3
            else
                self.gearTexts[1] = prevGearName
                self.gearTexts[2] = gearName
                self.gearTexts[3] = ""
                gearSelectedIndex = 2
            end
        elseif prevGearName == nil then -- if there is no Prev, this gear is the first gear
            self.gearTexts[1] = gearName
            self.gearTexts[2] = nextGearName
            self.gearTexts[3] = nextNextGearName or ""
            gearSelectedIndex = 1
        else -- Otherwise, we show it in the middle
            self.gearTexts[1] = prevGearName
            self.gearTexts[2] = gearName
            self.gearTexts[3] = nextGearName
            gearSelectedIndex = 2
        end
    elseif gearName ~= nil and isAutomatic then
        -- Order is D N R so that when switching from D to R we move over N
        self.gearTexts[1] = "R"
        self.gearTexts[2] = "N"
        self.gearTexts[3] = "D"

        if gearName == "N" then
            gearSelectedIndex = 2
        elseif gearName == "D" then
            gearSelectedIndex = 3
        elseif gearName == "R" then
            gearSelectedIndex = 1
        end
    end

    if showNeutralWarning then
        self.gearWarningTime = self.gearWarningTime + g_currentDt
    else
        self.gearWarningTime = 0
    end

    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_CENTER)
    setTextBold(true)

    -- If there is a gear group, draw it
    if gearGroupText ~= nil then
        renderText(x, y + self.gearGroupTextOffsetY, self.gearTextSize, gearGroupText)
    end

    -- Draw all the gear texts, always 3. Values can be empty strings though
    for i = 1, 3 do
        local alpha = 1
        local renderBg = false
        if i == 2 then
            alpha = math.abs(math.cos(self.gearWarningTime / 200))
        end

        if gearSelectedIndex == i then
            if isGearChanging then
                alpha = alpha * 0.5
            end
            renderBg = true
        end

        if renderBg then
            self.gearBg:setColor(nil, nil, nil, alpha)
            self.gearBg:setPosition(x + self.gearBgOffsetX, y + self.gearBgOffsetY[i])
            self.gearBg:render()
        end

        renderText(x, y + self.gearTextOffsetY[i], self.gearTextSize, self.gearTexts[i])
    end

    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
end


---Set the current vehicle which provides the data for the speed meter.
-- @param table vehicle Vehicle reference
function SpeedMeterDisplay:setVehicle(vehicle)
    self.vehicle = nil

    local hasVehicle = vehicle ~= nil
    local isMotorized = hasVehicle and vehicle.spec_motorized ~= nil
    if hasVehicle and isMotorized then
        self.vehicle = vehicle
        local _, capacity, fuelType = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
        local needFuelGauge = capacity ~= nil

        if needFuelGauge then
            local fuelGaugeIconSliceId = "gui.icon_fuel"
            if fuelType == FillType.ELECTRICCHARGE then
                fuelGaugeIconSliceId = "gui.icon_electricCharge"
            elseif fuelType == FillType.METHANE then
                fuelGaugeIconSliceId = "gui.icon_methane"
            end
            self.fuelIcon:setSliceId(fuelGaugeIconSliceId)
        end
    end

    self:setVisible(self.vehicle ~= nil)

    self.isVehicleDrawSafe = false -- use a safety flag here because setVehicle() can be called inbetween update and draw
end


---Get fuel level and capacity of a vehicle.
function SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
    local fuelType = FillType.DIESEL
    local fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)

    if fillUnitIndex == nil then
        fuelType = FillType.ELECTRICCHARGE
        fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)

        if fillUnitIndex == nil then
            fuelType = FillType.METHANE
            fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
        end
    end

    local level = vehicle:getFillUnitFillLevel(fillUnitIndex)
    local capacity = vehicle:getFillUnitCapacity(fillUnitIndex)

    return level, capacity, fuelType
end
