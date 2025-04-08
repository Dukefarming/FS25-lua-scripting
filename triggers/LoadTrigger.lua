










---
local LoadTrigger_mt = Class(LoadTrigger, Object)




---
function LoadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.FLOAT, basePath .. "#fillLitersPerSecond", "Fill liters per second")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#dischargeNode", "Discharge node")
    schema:register(XMLValueType.FLOAT, basePath .. "#dischargeWidth", "Discharge width", 0.5)
    schema:register(XMLValueType.FLOAT, basePath .. "#dischargeLength", "Discharge length", 0.5)

    schema:register(XMLValueType.STRING, basePath .. "#fillSoundIdentifier", "Fill sound identifier in map sound xml")
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#fillSoundNode", "Fill sound link node")

    EffectManager.registerEffectXMLPaths(schema, basePath)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "loading")

    schema:register(XMLValueType.NODE_INDEX, basePath .. "#scrollerNode", "Scroller node")
    schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Scroller shader parameter name", "uvScrollSpeed")
    schema:register(XMLValueType.VECTOR_2, basePath .. "#scrollerScrollSpeed", "Scroller speed scale", "0 -0.75")

    schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported fill type categories")
    schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported fill types")

    schema:register(XMLValueType.BOOL, basePath .. "#autoStart", "Auto start loading", false)
    schema:register(XMLValueType.BOOL, basePath .. "#infiniteCapacity", "Has infinite capacity", false)
    schema:register(XMLValueType.BOOL, basePath .. "#requiresExactFillRootNode", "Only checks for exactfillrootnode", true)  -- TODO: remove? does not seem to be used anywhere
    schema:register(XMLValueType.STRING, basePath .. "#startFillText", "Start fill text")
    schema:register(XMLValueType.STRING, basePath .. "#stopFillText", "Stop fill text")

    schema:register(XMLValueType.NODE_INDEX, basePath .. "#aiNode", "AI target node, required for the station to support AI. AI drives to the node in positive Z direction. Height is not relevant.")
end


---
function LoadTrigger.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or LoadTrigger_mt)

    self.fillableObjects = {}

    return self
end


---
function LoadTrigger:load(components, xmlFile, xmlNode, i3dMappings, rootNode)
    self.rootNode = rootNode or xmlFile:getValue(xmlNode .. "#node", nil, components, i3dMappings)
    if self.rootNode == nil then
        Logging.xmlError(xmlFile, "Missing node '%s#node'", xmlNode)
        return false
    end

    -- load triggers
    self.objectsInTriggers = {}

    XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlNode .. "#scrollerIndex", xmlNode .. "#scrollerNode")

    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "triggerNode", xmlFile, xmlNode .. "#triggerNode")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "triggerIndex", xmlFile, xmlNode .. "#triggerNode")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillLitersPerSecond", xmlFile, xmlNode .. "#fillLitersPerSecond")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "dischargeNode", xmlFile, xmlNode .. "#dischargeNode")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillSoundIdentifier", xmlFile, xmlNode .. "#fillSoundIdentifier")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillSoundNode", xmlFile, xmlNode .. "#fillSoundNode")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "scrollerIndex", xmlFile, xmlNode .. "#scrollerNode")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "shaderParameterName", xmlFile, xmlNode .. "#shaderParameterName")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "scrollerScrollSpeed", xmlFile, xmlNode .. "#scrollerScrollSpeed")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillTypeCategories", xmlFile, xmlNode .. "#fillTypeCategories")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "fillTypes", xmlFile, xmlNode .. "#fillTypes")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "autoStart", xmlFile, xmlNode .. "#autoStart")
    XMLUtil.checkDeprecatedUserAttribute(self.rootNode, "infiniteCapacity", xmlFile, xmlNode .. "#infiniteCapacity")

    local triggerNode = xmlFile:getValue(xmlNode .. "#triggerNode", nil, components, i3dMappings)
    if triggerNode == nil then
        Logging.xmlError(xmlFile, "Missing triggerNode defined in '%s'", xmlNode)
        return false
    end

    self.triggerNode = triggerNode
    addTrigger(triggerNode, "loadTriggerCallback", self)
    g_currentMission:addNodeObject(triggerNode, self)

    self.fillLitersPerMS = xmlFile:getValue(xmlNode .. "#fillLitersPerSecond", 1000) / 1000


    self.aiNode = xmlFile:getValue(xmlNode .. "#aiNode", nil, components, i3dMappings)
    self.supportsAILoading = self.aiNode ~= nil

    local dischargeNode = xmlFile:getValue(xmlNode .. "#dischargeNode", nil, components, i3dMappings)
    if dischargeNode ~= nil then
        XMLUtil.checkDeprecatedUserAttribute(dischargeNode, "width", xmlFile, xmlNode .. "#dischargeWidth")
        XMLUtil.checkDeprecatedUserAttribute(dischargeNode, "length", xmlFile, xmlNode .. "#dischargeLength")

        self.dischargeInfo = {}
        self.dischargeInfo.name = "fillVolumeDischargeInfo"
        self.dischargeInfo.nodes = {}
        local width = xmlFile:getValue(xmlNode .. "#dischargeWidth", 0.5)
        local length = xmlFile:getValue(xmlNode .. "#dischargeLength", 0.5)
        table.insert(self.dischargeInfo.nodes, {node=dischargeNode, width=width, length=length, priority=1})
    end

    -- place sound at the same position as the trigger or the discharge node
    self.soundNode = createTransformGroup("loadTriggerSoundNode")
    link(dischargeNode or self.triggerNode, self.soundNode)

    if self.isClient then
        self.effects = g_effectManager:loadEffect(xmlFile, xmlNode, components, self, i3dMappings)

        local directory = g_currentMission.baseDirectory
        local modName, baseDirectory = Utils.getModNameAndBaseDirectory(g_currentMission.missionInfo.mapSoundXmlFilename)
        if modName ~= nil then
            directory = baseDirectory .. modName
        end

        self.samples = {}
        self.samples.loading = g_soundManager:loadSampleFromXML(xmlFile, xmlNode .. ".sounds", "loading", directory, components, 1, AudioGroup.VEHICLE, i3dMappings, self)

        local fillSoundIdentifier = xmlFile:getValue(xmlNode .. "#fillSoundIdentifier")
        local fillSoundNode = xmlFile:getValue(xmlNode .. "#fillSoundNode", nil, components, i3dMappings)

        if fillSoundNode == nil then
            fillSoundNode = self.rootNode
        end

        local xmlSoundFile = loadXMLFile("mapXML", g_currentMission.missionInfo.mapSoundXmlFilename)
        if xmlSoundFile ~= nil and xmlSoundFile ~= 0 then

            if fillSoundIdentifier ~= nil then
                self.samples.load = g_soundManager:loadSampleFromXML(xmlSoundFile, "sound.object", fillSoundIdentifier, directory, getRootNode(), 0, AudioGroup.ENVIRONMENT, nil, nil)
                if self.samples.load ~= nil then
                    link(fillSoundNode, self.samples.load.soundNode)
                    setTranslation(self.samples.load.soundNode, 0,0,0)
                end
            end
            delete(xmlSoundFile)
        end

        self.scroller = xmlFile:getValue(xmlNode .. "#scrollerNode", nil, components, i3dMappings)
        if self.scroller ~= nil then
            self.scrollerShaderParameterName = xmlFile:getValue(xmlNode .. "#shaderParameterName", "uvScrollSpeed")
            self.scrollerSpeedX, self.scrollerSpeedY = xmlFile:getValue(xmlNode .. "#scrollerScrollSpeed", "0 -0.75")

            setShaderParameter(self.scroller, self.scrollerShaderParameterName, 0, 0, 0, 0, false)
        end
    end

    self.fillTypes = {}
    local fillTypeCategories = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypeCategories", self.rootNode)
    local fillTypeNames = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, xmlNode, "fillTypes", self.rootNode)

    local fillTypes = nil
    if fillTypeCategories ~= nil and fillTypeNames == nil then
        fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: UnloadTrigger has invalid fillTypeCategory '%s'.")
    elseif fillTypeCategories == nil and fillTypeNames ~= nil then
        fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: UnloadTrigger has invalid fillType '%s'.")
    end
    if fillTypes ~= nil then
        for _,fillType in pairs(fillTypes) do
            self.fillTypes[fillType] = true
        end
    else
        self.fillTypes = nil
    end

    self.autoStart = xmlFile:getValue(xmlNode .. "#autoStart", false)
    self.hasInfiniteCapacity = xmlFile:getValue(xmlNode .. "#infiniteCapacity", false)
    self.requiresExactFillRootNode = xmlFile:getValue(xmlNode .. "#requiresExactFillRootNode", true)

    self.startFillText = g_i18n:convertText(xmlFile:getValue(xmlNode .. "#startFillText", "$l10n_action_siloStartFilling"))
    self.stopFillText = g_i18n:convertText(xmlFile:getValue(xmlNode .. "#stopFillText", "$l10n_action_siloStopFilling" ))

    self.activatable = LoadTriggerActivatable.new(self)
    self.activatable:setText(self.startFillText)

    self.isLoading = false
    self.selectedFillType = FillType.UNKNOWN

    self.automaticFilling = Platform.gameplay.automaticFilling
    self.requiresActiveVehicle = not self.automaticFilling
    self.automaticFillingTimer = 0

    return true
end


---
function LoadTrigger:delete()
    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
        g_currentMission:removeNodeObject(self.triggerNode)
    end
    if self.isClient then
        g_soundManager:deleteSamples(self.samples)
        g_effectManager:deleteEffects(self.effects)
    end

    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

    LoadTrigger:superClass().delete(self)
end


---
function LoadTrigger:setSource(object)
    assert(object.getSupportedFillTypes ~= nil)
    assert(object.getAllFillLevels ~= nil)
    assert(object.addFillLevelToFillableObject ~= nil)
    assert(object.getIsFillAllowedToFarm ~= nil)

    self.source = object
end


---
function LoadTrigger:raiseActive()
    LoadTrigger:superClass().raiseActive(self)

    if self.source ~= nil and self.source.raiseActive ~= nil then
        self.source:raiseActive()
    end
end


---
function LoadTrigger:loadTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    local fillableObject = g_currentMission:getNodeObject(otherId)
    if fillableObject == nil then
        return
    end

    if not entityExists(otherId) then
        return
    end

    if self.requiresExactFillRootNode and not CollisionFlag.getHasGroupFlagSet(otherId, CollisionFlag.FILLABLE) then
        return
    end

    if fillableObject == self.source then
        return
    end

    if fillableObject.getRootVehicle ~= nil and fillableObject.getFillUnitIndexFromNode ~= nil then
        local fillTypes = self.source:getSupportedFillTypes()

        if fillTypes ~= nil then
            local foundFillUnitIndex = fillableObject:getFillUnitIndexFromNode(otherId)

            if foundFillUnitIndex ~= nil then
                local found = false
                for fillTypeIndex, state in pairs(fillTypes) do
                    if state and (self.fillTypes == nil or self.fillTypes[fillTypeIndex]) then
                        if fillableObject:getFillUnitSupportsFillType(foundFillUnitIndex, fillTypeIndex) then
                            if fillableObject:getFillUnitAllowsFillType(foundFillUnitIndex, fillTypeIndex) then
                                found = true
                                break
                            end
                        end
                    end
                end

                -- ignore fillUnitIndex if does not support or allow one of the provided filltypes
                if not found then
                    foundFillUnitIndex = nil
                end
            end

            if foundFillUnitIndex == nil then
                for fillTypeIndex, state in pairs(fillTypes) do
                    if state and (self.fillTypes == nil or self.fillTypes[fillTypeIndex]) then
                        local fillUnits = fillableObject:getFillUnits()
                        for fillUnitIndex, fillUnit in ipairs(fillUnits) do
                            -- only check fill units without exactFillRootNodes
                            if fillUnit.exactFillRootNode == nil then
                                if fillableObject:getFillUnitSupportsFillType(fillUnitIndex, fillTypeIndex) then
                                    if fillableObject:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex) then
                                        foundFillUnitIndex = fillUnitIndex
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end

            if foundFillUnitIndex ~= nil then
                if onEnter then
                    self.fillableObjects[otherId] = {object=fillableObject, fillUnitIndex=foundFillUnitIndex}
                    fillableObject:addDeleteListener(self)
                    fillableObject:setFillUnitInTriggerRange(foundFillUnitIndex, true)

                    self:raiseActive()
                elseif onLeave then
                    self.fillableObjects[otherId] = nil
                    fillableObject:removeDeleteListener(self)
                    fillableObject:setFillUnitInTriggerRange(foundFillUnitIndex, false)

                    if self.isLoading and self.currentFillableObject == fillableObject then
                        self:setIsLoading(false)
                    end

                    if fillableObject == self.validFillableObject then
                        self.validFillableObject = nil
                        self.validFillableFillUnitIndex = nil
                    end
                end

                if self.automaticFilling then
                    if not self.isLoading then
                        if next(self.fillableObjects) ~= nil then
                            if self:getIsFillableObjectAvailable() then
                                self:toggleLoading()
                            end
                        end
                    end
                else
                    if next(self.fillableObjects) ~= nil then
                        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
                    else
                        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
                    end
                end
            end
        end
    end
end


---Get the farm id for given object. If none can be found, SPECTATOR is used.
function LoadTrigger:farmIdForFillableObject(fillableObject)
    local objectFarmId = fillableObject:getOwnerFarmId()
    if fillableObject.getActiveFarm ~= nil then
        objectFarmId = fillableObject:getActiveFarm()
    end

    if objectFarmId == nil then
        objectFarmId = FarmManager.SPECTATOR_FARM_ID
    end

    return objectFarmId
end


---
function LoadTrigger:getIsFillableObjectAvailable()
    if next(self.fillableObjects) == nil then
        return false
    else
        if self.isLoading then
            if self.currentFillableObject ~= nil and self:getAllowsActivation(self.currentFillableObject) then
                return true
            end
        else
            self.validFillableObject = nil
            self.validFillableFillUnitIndex = nil

            -- last object that was filled has lower prio than the other objects in the trigger
            -- so we can guarantee that all objects will be filled
            local hasLowPrioObject = false
            local numOfObjects = 0
            for _, fillableObject in pairs(self.fillableObjects) do
                if fillableObject.lastWasFilled then
                    hasLowPrioObject = true
                end
                numOfObjects = numOfObjects + 1
            end
            hasLowPrioObject = hasLowPrioObject and (numOfObjects > 1)

            for _, fillableObject in pairs(self.fillableObjects) do
                if not fillableObject.lastWasFilled or not hasLowPrioObject then
                    if self:getAllowsActivation(fillableObject.object) then
                        if fillableObject.object:getFillUnitSupportsToolType(fillableObject.fillUnitIndex, ToolType.TRIGGER) then
                            if fillableObject.object:getFillUnitFreeCapacity(fillableObject.fillUnitIndex, nil, nil) > 0 then
                                if self.source:getIsFillAllowedToFarm(self:farmIdForFillableObject(fillableObject.object)) then
                                    self.validFillableObject = fillableObject.object
                                    self.validFillableFillUnitIndex = fillableObject.fillUnitIndex

                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end


---
function LoadTrigger:toggleLoading()
    if not self.isLoading then
        local fillLevels = self.source:getAllFillLevels(g_currentMission:getFarmId())

        local fillableObject = self.validFillableObject
        local fillUnitIndex = self.validFillableFillUnitIndex

        local firstFillType = nil
        local validFillLevels = {}
        local numFillTypes = 0
        for fillTypeIndex, fillLevel in pairs(fillLevels) do
            if self.fillTypes == nil or self.fillTypes[fillTypeIndex] then
                if fillableObject:getFillUnitAllowsFillType(fillUnitIndex, fillTypeIndex) then
                    validFillLevels[fillTypeIndex] = fillLevel

                    if firstFillType == nil then
                        firstFillType = fillTypeIndex
                    end

                    numFillTypes = numFillTypes + 1
                end
            end
        end

        if not self.autoStart and numFillTypes > 0 then
            local startAllowed = true
            local controlledVehicle = g_localPlayer:getCurrentVehicle()
            if controlledVehicle.getIsActiveForInput ~= nil then
                startAllowed = controlledVehicle:getIsActiveForInput(true)
            end

            -- allow popup only for the vehicle that controlled by the player
            if startAllowed then
                local title = string.format("%s", self.source:getName())

                SiloDialog.show(self.onFillTypeSelection, self, title, validFillLevels, self.hasInfiniteCapacity)

                if self.automaticFilling then
                    local rootVehicle = fillableObject.rootVehicle
                    if rootVehicle.brakeToStop ~= nil then
                        rootVehicle:brakeToStop()
                    end
                end
            end
        else
            self:onFillTypeSelection(firstFillType)
        end
    else
        self:setIsLoading(false)
    end
end


---
function LoadTrigger:onFillTypeSelection(fillType)
    if fillType ~= nil and fillType ~= FillType.UNKNOWN then
        local validFillableObject = self.validFillableObject
        if validFillableObject ~= nil and self:getAllowsActivation(validFillableObject) then
            local fillUnitIndex = self.validFillableFillUnitIndex
            self:setIsLoading(true, validFillableObject, fillUnitIndex, fillType)
        end
    end
end


---
function LoadTrigger:setIsLoading(isLoading, targetObject, fillUnitIndex, fillType, noEventSend)
    LoadTriggerSetIsLoadingEvent.sendEvent(self, isLoading, targetObject, fillUnitIndex, fillType, noEventSend)
    if isLoading then
        self:startLoading(fillType, targetObject, fillUnitIndex)
    else
        self:stopLoading()
    end

    self:setFillSoundIsPlaying(isLoading)

    if self.currentFillableObject ~= nil then
        if self.currentFillableObject.setFillSoundIsPlaying ~= nil then
            self.currentFillableObject:setFillSoundIsPlaying(isLoading)
        end
    end
end


---
function LoadTrigger:getAllowsActivation(fillableObject)
    if not self.requiresActiveVehicle then
        return true
    end

    if fillableObject.getAllowLoadTriggerActivation ~= nil and fillableObject:getAllowLoadTriggerActivation(fillableObject) then
        return true
    end

    return false
end


---
function LoadTrigger:startLoading(fillType, fillableObject, fillUnitIndex)
    if not self.isLoading then
        self:raiseActive()
        self.isLoading = true
        self.selectedFillType = fillType
        self.currentFillableObject = fillableObject
        self.fillUnitIndex = fillUnitIndex
        self.activatable:setText(self.stopFillText)

        if self.isClient then
            g_effectManager:setEffectTypeInfo(self.effects, self.selectedFillType)
            g_effectManager:startEffects(self.effects)
            g_soundManager:playSample(self.samples.load)
            g_soundManager:playSample(self.samples.loading)

            if self.scroller ~= nil then
                setShaderParameter(self.scroller, self.scrollerShaderParameterName, self.scrollerSpeedX, self.scrollerSpeedY, 0, 0, false)
            end
        end
    end
end


---
function LoadTrigger:stopLoading()
    if self.isLoading then
        self:raiseActive()
        self.isLoading = false
        self.selectedFillType = FillType.UNKNOWN
        self.activatable:setText(self.startFillText)
        if self.currentFillableObject.aiStoppedLoadingFromTrigger ~= nil then
            self.currentFillableObject:aiStoppedLoadingFromTrigger()
        end

        for _, fillableObject in pairs(self.fillableObjects) do
            fillableObject.lastWasFilled = fillableObject.object == self.validFillableObject and fillableObject.fillUnitIndex == self.fillUnitIndex
        end

        if self.isClient then
            g_effectManager:stopEffects(self.effects)
            g_soundManager:stopSample(self.samples.load)
            g_soundManager:stopSample(self.samples.loading)

            if self.scroller ~= nil then
                setShaderParameter(self.scroller, self.scrollerShaderParameterName, 0, 0, 0, 0, false)
            end
        end
    end
end


---
function LoadTrigger:update(dt)
    if self.isServer then
        if self.isLoading then
            if self.currentFillableObject ~= nil then
                local fillSpeed = self.fillLitersPerMS
                if self.currentFillableObject.getLoadTriggerMaxFillSpeed ~= nil then
                    fillSpeed = math.min(fillSpeed, self.currentFillableObject:getLoadTriggerMaxFillSpeed())
                end

                local fillDelta = self.source:addFillLevelToFillableObject(self.currentFillableObject, self.fillUnitIndex, self.selectedFillType, fillSpeed * dt, self.dischargeInfo, ToolType.TRIGGER)
                if fillDelta == nil or math.abs(fillDelta) < 0.001 then
                    self:setIsLoading(false)
                end
            elseif self.isLoading then
                self:setIsLoading(false)
            end
            self:raiseActive()
        else
            -- automatic fill every 10 seconds if a object is in trigger
            if self.automaticFilling then
                if next(self.fillableObjects) ~= nil then
                    self.automaticFillingTimer = math.max(self.automaticFillingTimer - dt, 0)
                    if self.automaticFillingTimer == 0 then
                        if self:getIsFillableObjectAvailable() then
                            self:toggleLoading()
                            self.automaticFillingTimer = 10000
                        end
                    end

                    self:raiseActive()
                end
            end
        end
    end
end


---
function LoadTrigger:getCurrentFillType()
    return self.selectedFillType
end


---
function LoadTrigger:getFillTargetNode()
    if self.currentFillableObject ~= nil then
        return self.currentFillableObject:getFillUnitRootNode(self.fillUnitIndex)
    end

    return nil
end


---
function LoadTrigger:setFillSoundIsPlaying(state)
    if self.dischargeInfo == nil and state then
        local target = self:getFillTargetNode()
        if target ~= nil then
            local x, y, z = getWorldTranslation(target)
            setWorldTranslation(self.soundNode, x, y, z)
        end
    end

    -- if we don't have a custom loading sample defined we play the fill trigger fillType based sound
    if self.samples.load == nil then
        FillTrigger.setFillSoundIsPlaying(self, state)
    end
end


---
function LoadTrigger:onDeleteObject(vehicle)
    for k, fillableObject in pairs(self.fillableObjects) do
        if fillableObject.object == vehicle then
            self.fillableObjects[k] = nil

            if self.isLoading then
                if self.currentFillableObject == vehicle then
                    self:stopLoading()
                    self.currentFillableObject = nil
                end
            end
        end
    end
end


---
function LoadTrigger:getIsFillTypeSupported(fillType)
    return self.fillTypes[fillType] ~= nil
end


---
function LoadTrigger:getSupportAILoading()
    return self.supportsAILoading
end


---
function LoadTrigger:getAITargetPositionAndDirection()
    local x, _, z = getWorldTranslation(self.aiNode)
    local xDir, _, zDir = localDirectionToWorld(self.aiNode, 0, 0, 1)
    return x, z, xDir, zDir
end




---
local LoadTriggerActivatable_mt = Class(LoadTriggerActivatable)


---
function LoadTriggerActivatable.new(loadTrigger)
    local self = setmetatable({}, LoadTriggerActivatable_mt)

    self.loadTrigger = loadTrigger
    self.activateText = ""

    return self
end


---
function LoadTriggerActivatable:setText(text)
    self.activateText = text
end


---
function LoadTriggerActivatable:getIsActivatable()
    return self.loadTrigger:getIsFillableObjectAvailable()
end


---
function LoadTriggerActivatable:run()
    self.loadTrigger:toggleLoading()
end
