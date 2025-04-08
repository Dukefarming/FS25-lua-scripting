













---
local WoodUnloadTrigger_mt = Class(WoodUnloadTrigger, UnloadTrigger)






---
function WoodUnloadTrigger.registerXMLPaths(schema, basePath)
    UnloadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#activationTriggerNode", "Activation trigger node for the player")
    schema:register(XMLValueType.BOOL,       basePath .. "#autoUnload", "Wood is automatically unloaded", false)
    schema:register(XMLValueType.STRING,     basePath .. "#trainSystemId", "Money will be added to the account of the current rental farm id of the train. This attribute is the unique id of the corresponding train system.")
end


---Creates a new instance of the class
-- @param boolean isServer true if we are server
-- @param boolean isClient true if we are client
-- @param table? customMt meta table
-- @return table self returns the instance
function WoodUnloadTrigger.new(isServer, isClient, customMt)
    local self = UnloadTrigger.new(isServer, isClient, customMt or WoodUnloadTrigger_mt)

    self.triggerNode = nil
    self.woodInTrigger = {}
    self.vehiclesInTrigger = {}

    self.lastSplitShapeVolume = 0
    self.lastSplitType = nil
    self.lastSplitShapeStats = {sizeX=0, sizeY=0, sizeZ=0, numConvexes=0, numAttachments=0}

    self.extraAttributes = {price = 1}
    return self
end


---Loads elements of the class
-- @param table components components
-- @param table xmlFile xml file object
-- @param string xmlNode xml key
-- @param table target target object
-- @param table i3dMappings i3dMappings
-- @return boolean success success
function WoodUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
    if not WoodUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
        return false
    end

    local triggerNodeKey = xmlNode .. "#triggerNode"
    self.triggerNode = xmlFile:getValue(triggerNodeKey, nil, components, i3dMappings)
    if self.triggerNode ~= nil then
        local colMask = getCollisionFilterMask(self.triggerNode)
        if bitAND(CollisionFlag.TREE, colMask) == 0 then
            Logging.xmlWarning(xmlFile, "Invalid collision filter mask for wood trigger '%s'. %s needs to be set!", triggerNodeKey, CollisionFlag.getBitAndName(CollisionFlag.TREE))
            return false
        end
        addTrigger(self.triggerNode, "woodTriggerCallback", self)
    else
        return false
    end


    local activationTrigger = xmlFile:getValue(xmlNode .. "#activationTriggerNode", nil, components, i3dMappings)
    if activationTrigger ~= nil then
        if not CollisionFlag.getHasMaskFlagSet(activationTrigger, CollisionFlag.PLAYER) then
            Logging.xmlWarning(xmlFile, "Missing collision filter mask '%s'. Please add this bit to sell trigger node '%s' in 'placeable.woodSellingStation#sellTrigger'.", CollisionFlag.getBitAndName(CollisionFlag.PLAYER), getName(activationTrigger))
            return false
        end

        self.activationTrigger = activationTrigger
        if self.activationTrigger ~= nil then
            addTrigger(self.activationTrigger, "woodSellTriggerCallback", self)
        end
    end

    self.autoUnload = xmlFile:getValue(xmlNode .. "#autoUnload", false)

    self.isManualSellingActive = true
    self.trainSystemId = xmlFile:getValue(xmlNode .. "#trainSystemId")
    self.trainSystem = nil

    self.activatable = WoodUnloadTriggerActivatable.new(self)

    return true
end


---Delete instance
function WoodUnloadTrigger:delete()
    if self.triggerNode ~= nil and self.triggerNode ~= 0 then
        removeTrigger(self.triggerNode)
        self.triggerNode = 0
    end

    if self.activationTrigger ~= nil then
        local mission = g_currentMission
        mission.activatableObjectsSystem:removeActivatable(self.activatable)
        removeTrigger(self.activationTrigger)
        self.activationTrigger = nil
    end

    WoodUnloadTrigger:superClass().delete(self)
end


---
function WoodUnloadTrigger:processWood(farmId, noEventSend)
    if not self.isServer then
        g_client:getServerConnection():sendEvent(WoodUnloadTriggerEvent.new(self, farmId))
        return
    end

    local soldWood = false
    local totalMass = 0
    local isFull = false

    local mission = g_currentMission
    local isServer = mission:getIsServer()
    for _, nodeId in pairs(self.woodInTrigger) do
        if self:getCanProcessWood() then
            if entityExists(nodeId) then
                soldWood = true

                local volume, qualityScale, maxSize = self:calculateWoodBaseValue(nodeId)
                self.extraAttributes.price = qualityScale  -- override price and use actual values from splitTypes
                self.extraAttributes.maxSize = maxSize  -- override price and use actual values from splitTypes

                if isServer then
                    -- Do not sell if capacity is constrained (e.g. production points)
                    local fillType = self:getTargetFillType(maxSize, volume)
                    if self.getFillUnitFreeCapacity == nil or self:getFillUnitFreeCapacity(nil, fillType, farmId) > volume * 0.9 then
                        self:addFillUnitFillLevel(farmId, nil, volume, fillType, ToolType.undefined, nil, self.extraAttributes)
                        -- object will be deleted on client automatically
                        self:onProcessedWood(nodeId, volume, fillType)

                        local treeObject = mission:getNodeObject(nodeId)
                        if treeObject ~= nil then
                            treeObject:delete()
                        else
                            delete(nodeId)
                        end
                    else
                        isFull = true
                    end
                end
            end

            if isFull then
                break
            else
                self.woodInTrigger[nodeId] = nil
            end
        end
    end

    if soldWood then
        if isServer then
            g_farmManager:updateFarmStats(g_localPlayer.farmId, "woodTonsSold", totalMass)
        end
    end
end



















---
function WoodUnloadTrigger:calculateWoodBaseValue(objectId)
    local volume = getVolume(objectId)
    local splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(objectId))
    local sizeX, sizeY, sizeZ, numConvexes, numAttachments = getSplitShapeStats(objectId)

    return self:calculateWoodBaseValueForData(volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments)
end


---
function WoodUnloadTrigger:calculateWoodBaseValueForData(volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments)
    local qualityScale = 1
    local lengthScale = 1
    local defoliageScale = 1
    local maxSize = 0
    if sizeX ~= nil and volume > 0 then
        local bvVolume = sizeX*sizeY*sizeZ
        local volumeRatio = bvVolume / volume
        local volumeQuality = 1-math.sqrt(math.clamp((volumeRatio-3)/7, 0,1)) * 0.95  --  ratio <= 3: 100%, ratio >= 10: 5%
        local convexityQuality = 1-math.clamp((numConvexes-2)/(6-2), 0,1) * 0.95  -- 0-2: 100%:, >= 6: 5%

        maxSize = math.max(sizeX, sizeY, sizeZ)
        -- 1m: 60%, 6-11m: 120%, 19m: 60%
        if maxSize < 11 then
            lengthScale = 0.6 + math.min(math.max((maxSize-1)/5, 0), 1)*0.6
        else
            lengthScale = 1.2 - math.min(math.max((maxSize-11)/8, 0), 1)*0.6
        end

        local minQuality = math.min(convexityQuality, volumeQuality)
        local maxQuality = math.max(convexityQuality, volumeQuality)
        qualityScale = minQuality + (maxQuality - minQuality) * 0.3  -- use 70% of min quality

        defoliageScale = 1-math.min(numAttachments/15, 1) * 0.8  -- #attachments 0: 100%, >=15: 20%
    end

     -- Only take 33% into account of the quality criteria on low
    local numDifficulties = #EconomicDifficulty.getAllOrdered()
    local mission = g_currentMission
    local missionInfo = mission.missionInfo
    qualityScale = MathUtil.lerp(1, qualityScale, missionInfo.economicDifficulty / numDifficulties)
    defoliageScale = MathUtil.lerp(1, defoliageScale, missionInfo.economicDifficulty / numDifficulties)

    return volume * splitType.volumeToLiter, splitType.pricePerLiter * qualityScale * defoliageScale * lengthScale, maxSize
end


---
function WoodUnloadTrigger:update(dt)
    WoodUnloadTrigger:superClass().update(self, dt)

    if self.isServer then
        local farmId = self.target:getOwnerFarmId()
        local mission = g_currentMission

        if self.trainSystemId ~= nil then
            if self.trainSystem == nil then
                local placeable = mission.placeableSystem:getPlaceableByUniqueId(self.trainSystemId)
                if placeable ~= nil and placeable.spec_trainSystem ~= nil then
                    self.trainSystem = placeable
                end
            end

            if self.trainSystem ~= nil then
                farmId = self.trainSystem.spec_trainSystem.lastRentFarmId
            end
        elseif self.autoUnload then
            local vehicleNodeId = next(self.vehiclesInTrigger)
            if vehicleNodeId ~= nil then
                local vehicle = mission:getNodeObject(vehicleNodeId)
                if vehicle ~= nil then
                    farmId = vehicle:getOwnerFarmId()
                else
                    self.vehiclesInTrigger[vehicleNodeId] = nil
                end
            end
        end

        if farmId ~= FarmManager.SPECTATOR_FARM_ID then
            self:processWood(farmId)
        end
    end
end



---Callback method for the wood trigger
-- @param integer triggerId
-- @param integer otherId
-- @param boolean onEnter
-- @param boolean onLeave
-- @param boolean onStay
-- @param integer otherShapeId
function WoodUnloadTrigger:woodTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    if otherId ~= 0 then
        local splitType
        if getHasClassId(otherId, ClassIds.MESH_SPLIT_SHAPE) then
            splitType = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherId))
        end

        if splitType ~= nil and splitType.pricePerLiter > 0 then
            if onEnter then
                self.woodInTrigger[otherId] = otherId
                if self:getNeedRaiseActive() then
                    self:raiseActive()  -- needed for train wood selling without trigger activation
                end
            else
                self.woodInTrigger[otherId] = nil
            end
        elseif self.autoUnload then
            local mission = g_currentMission
            local object = mission:getNodeObject(otherId)
            if object ~= nil and object:isa(Vehicle) then
                if onEnter then
                    self.vehiclesInTrigger[otherId] = (self.vehiclesInTrigger[otherId] or 0) + 1
                    self:raiseActive()
                else
                    self.vehiclesInTrigger[otherId] = (self.vehiclesInTrigger[otherId] or 0) - 1
                    if self.vehiclesInTrigger[otherId] <= 0 then
                        self.vehiclesInTrigger[otherId] = nil
                    end
                end
            end
        end
    end
end






---Get all wood logs currently in trigger as nodeId indexed table
function WoodUnloadTrigger:getWoodLogs()
    return self.woodInTrigger
end


---
function WoodUnloadTrigger:woodSellTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if onEnter or onLeave then
        if g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode then
            local mission = g_currentMission
            if onEnter then
                if self.isManualSellingActive then
                    mission.activatableObjectsSystem:addActivatable(self.activatable)
                end
            else
                mission.activatableObjectsSystem:removeActivatable(self.activatable)
            end
        end
    end
end
