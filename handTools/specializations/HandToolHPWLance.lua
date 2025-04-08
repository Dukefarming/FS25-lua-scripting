












---
function HandToolHPWLance.registerXMLPaths(xmlSchema)
    xmlSchema:setXMLSpecializationType("HandToolHPWLance")
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.highPressureWasherLance.lance#raycastNode", "The range in metres that the lance can wash things", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#washDistance", "The range in metres that the lance can wash things", "10 metres", false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#washMultiplier", "The multiplier applied to the wash amount", "1x", false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#pricePerMinute", "The cost of using this tool for a minute", "10", false)
    EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.highPressureWasherLance.effects")
    SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.highPressureWasherLance.sounds", "washing")
end


---
function HandToolHPWLance.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "onWashAction", HandToolHPWLance.onWashAction)
    SpecializationUtil.registerFunction(handToolType, "setIsActivated", HandToolHPWLance.setIsActivated)
    SpecializationUtil.registerFunction(handToolType, "onLanceCallback", HandToolHPWLance.onLanceCallback)
end


---
function HandToolHPWLance.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeDropped", HandToolHPWLance.getCanBeDropped)
end


---
function HandToolHPWLance.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolHPWLance)
    SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolHPWLance)
end


---
function HandToolHPWLance.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(HandToolTethered, specializations)
end


---
function HandToolHPWLance:onLoad(xmlFile, baseDirectory)
    local spec = self.spec_highPressureWasherLance

    spec.raycastNode = xmlFile:getValue("handTool.highPressureWasherLance.lance#raycastNode", nil, self.components, self.i3dMappings)
    spec.washDistance = xmlFile:getValue("handTool.highPressureWasherLance.lance#washDistance", 10)
    spec.washMultiplier = xmlFile:getValue("handTool.highPressureWasherLance.lance#washMultiplier", 1)
    spec.pricePerSecond = xmlFile:getValue("handTool.highPressureWasherLance.lance#pricePerMinute", 10) / 60

    if self.isClient then
        spec.effects = g_effectManager:loadEffect(xmlFile, "handTool.highPressureWasherLance.effects", self.components, self, self.i3dMappings)
        g_effectManager:setEffectTypeInfo(spec.effects, FillType.WATER)
        spec.washingSample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.highPressureWasherLance.sounds", "washing", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    spec.isActivated = false
    spec.targetedVehicleId = nil
    spec.activateActionEventId = nil

    spec.isActivatedSent = false
    spec.targetedVehicleIdSent = nil

    spec.dirtyFlag = self:getNextDirtyFlag()
end


---Deleting
function HandToolHPWLance:onDelete()
    local spec = self.spec_highPressureWasherLance
    g_effectManager:deleteEffects(spec.effects)
    g_soundManager:deleteSample(spec.washingSample)
end


---
function HandToolHPWLance:onWriteUpdateStream(streamId, connection, dirtyMask)
    local spec = self.spec_highPressureWasherLance

    if streamWriteBool(streamId, spec.isActivatedSent) then
        if connection:getIsServer() then
            if streamWriteBool(streamId, spec.targetedVehicleIdSent ~= nil) then
                NetworkUtil.writeNodeObjectId(streamId, spec.targetedVehicleIdSent)
            end
        end
    end
end


---
function HandToolHPWLance:onReadUpdateStream(streamId, timestamp, connection)
    local spec = self.spec_highPressureWasherLance

    local isActivated = streamReadBool(streamId)
    spec.targetedVehicleId = nil

    if isActivated then
        if not connection:getIsServer() then
            if streamReadBool(streamId) then
                local targetedVehicleId = NetworkUtil.readNodeObjectId(streamId)
                local carryingPlayer = self:getCarryingPlayer()
                if not carryingPlayer.isOwner then
                    spec.targetedVehicleId = targetedVehicleId
                end
            end
        end
    end

    self:setIsActivated(isActivated)
end


---
function HandToolHPWLance:onUpdate(dt)
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer == nil then
        return
    end

    local spec = self.spec_highPressureWasherLance

    -- Do nothing more if the tool is not activated.
    if not spec.isActivated then
        spec.targetedVehicleId = nil
        return
    end

    -- Get the vehicle being aimed at.
    if carryingPlayer.isOwner then
        local x, y, z = getWorldTranslation(spec.raycastNode)
        local dirX, dirY, dirZ = localDirectionToWorld(spec.raycastNode, 0, 0, 1)
        raycastClosestAsync(x, y, z, dirX, dirY, dirZ, spec.washDistance, "onLanceCallback", self, CollisionFlag.VEHICLE)

        if spec.targetedVehicleId ~= spec.targetedVehicleIdSent then
            spec.targetedVehicleIdSent = spec.targetedVehicleId
            self:raiseDirtyFlags(spec.dirtyFlag)
        end

        if spec.targetedVehicleId == nil then
            g_inputBinding:setActionEventText(spec.activateActionEventId, string.format(self.activateText, ""))
        else
            local vehicle = NetworkUtil.getObject(spec.targetedVehicleId)
            g_inputBinding:setActionEventText(spec.activateActionEventId, string.format(self.activateText, vehicle.typeDesc))
        end
    end

    if self.isServer then
        if spec.targetedVehicleId ~= nil then
            local vehicle = NetworkUtil.getObject(spec.targetedVehicleId)
            if vehicle ~= nil then
                -- Remove the dirt from the vehicle.
                vehicle:cleanVehicle((spec.washMultiplier * dt) / vehicle:getWashDuration())
            end
        end

        -- Charge the price per second to the player.
        local farmId = carryingPlayer.farmId
        local price = spec.pricePerSecond * dt * 0.001
        g_farmManager:updateFarmStats(farmId, "expenses", price)
        local mission = g_currentMission
        mission:addMoney(-price, farmId, MoneyType.VEHICLE_RUNNING_COSTS)
    end
end


---
function HandToolHPWLance:onLanceCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
    local spec = self.spec_highPressureWasherLance

    spec.targetedVehicleId = nil

    if nodeId == 0 then
        return false
    end

    local vehicle = g_currentMission.vehicleSystem:getVehicleByNodeId(nodeId, shapeId)
    if vehicle ~= nil then
        -- If the vehicle is not washable by this machine, return nil.
        if vehicle.getAllowsWashingByType ~= nil and vehicle:getAllowsWashingByType(Washable.WASHTYPE_HIGH_PRESSURE_WASHER) then
            spec.targetedVehicleId = NetworkUtil.getObjectId(vehicle)
        end
    end

    local continueReporting = true

    return continueReporting
end


---
function HandToolHPWLance:setIsActivated(isActivated)
    local spec = self.spec_highPressureWasherLance

    if spec.isActivated == isActivated then
        return
    end

    -- If there is no player, do nothing.
    local carryingPlayer = self:getCarryingPlayer()
    if carryingPlayer == nil then
        return
    end

    spec.isActivated = isActivated

    if carryingPlayer.isOwner then
        spec.isActivatedSent = isActivated
        self:raiseDirtyFlags(spec.dirtyFlag)
    end

    if spec.isActivated then
        g_effectManager:startEffects(spec.effects)
        g_soundManager:playSample(spec.washingSample)
    else
        g_effectManager:stopEffects(spec.effects)

        g_soundManager:stopSample(spec.washingSample)
    end
end


---
function HandToolHPWLance:onRegisterActionEvents()
    if not self:getIsActiveForInput(true) then
        return
    end

    local spec = self.spec_highPressureWasherLance

    local _, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHPWLance.onWashAction, false, false, true, true, nil)
    spec.activateActionEventId = actionEventId
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventText(actionEventId, string.format(self.activateText, ""))
end


---
function HandToolHPWLance:onWashAction(_, inputValue)
    self:setIsActivated(inputValue > 0)
end


---
function HandToolHPWLance:getCanBeDropped(superFunc)
    return false
end


---
function HandToolHPWLance:onHeldEnd()
    self:setIsActivated(false)
    self:returnToHolder(true)
end


---
function HandToolHPWLance:onDebugDraw(x, y, textSize)
    local spec = self.spec_highPressureWasherLance

    y = DebugUtil.renderTextLine(x, y, textSize, string.format("isActivated: %s", tostring(spec.isActivated)))

    if spec.targetedVehicleId ~= nil then
        local vehicle = NetworkUtil.getObject(spec.targetedVehicleId)
        if vehicle ~= nil then
            y = DebugUtil.renderTextLine(x, y, textSize, string.format("Target: %q", vehicle.typeName))
        end
    end

    return y
end
