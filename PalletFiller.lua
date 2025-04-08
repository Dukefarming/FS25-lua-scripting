

















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PalletFiller.prerequisitesPresent(specializations)
    return true
end


---
function PalletFiller.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("PalletFiller")

    local basePath = "vehicle.palletFiller"

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".pickupTrigger#node", "Pickup pallet trigger")

    schema:register(XMLValueType.STRING, basePath .. ".pallet#filename", "Filename to supported pallet xml file")
    schema:register(XMLValueType.FLOAT, basePath .. ".pallet#spacing", "Spacing between the pallets while they are loaded", 0.5)

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".palletRow#node", "Pallet row node")
    schema:register(XMLValueType.INT, basePath .. ".palletRow#maxNumPallets", "Max. number of pallets that can be picked up", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".palletRow#minTransZ", "Min. translation of the row (drop off point)", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".palletRow#maxTransZ", "Max. translation of the row (pick up point)", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".palletRow#moveSpeed", "Move speed of pallet on the row (m/sec)", 1)
    schema:register(XMLValueType.TIME, basePath .. ".palletRow#pickupTime", "Time until the pallet is fully picked up (sec)", 2)

    schema:register(XMLValueType.TIME, basePath .. ".palletRow#loadingDelay", "Loading delay used for combine", 0)

    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".palletRow.rotLimit#startLimit", "Start rotation limit after pickup", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".palletRow.rotLimit#endLimit", "End rotation limit while fully mounted", "0 0 0")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".palletRow.rotLimit#unloadLimit", "Rotation limit while unloading", "0 0 25")

    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".palletRow.transLimit#startLimit", "Start translation limit after pickup", "0.25 2 0.25")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".palletRow.transLimit#endLimit", "End translation limit while fully mounted", "0.05 2 0")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".palletRow.transLimit#unloadLimit", "Translation limit while unloading", "0.25 2 0")

    schema:register(XMLValueType.FLOAT, basePath .. ".palletRow.fillStep(?)#transZ", "Target Z translation of the pickup of pallet while filling this pallet index", 0)
    schema:register(XMLValueType.INT, basePath .. ".palletRow.fillStep(?)#palletIndex", "Pallet index to fill", 1)
    schema:register(XMLValueType.INT, basePath .. ".palletRow.fillStep(?)#dischargeNodeIndex", "Discharge Node Index (defines which discharge node is used while the defined pallet index is available & not full)", 1)

    schema:register(XMLValueType.STRING, basePath .. ".fillDeflectorAnimation#name", "Name of fill deflector animation (animation is played before the pallets are moving and revered after they are in the new position)")
    schema:register(XMLValueType.FLOAT, basePath .. ".fillDeflectorAnimation#speed", "Animation speed scale", 1)

    schema:register(XMLValueType.STRING, basePath .. ".platformAnimation#name", "Name of platform animation (animation to lower the tool for pallet pickup and drop -> 0=pickup, #middleTime=idle, 1=drop)")
    schema:register(XMLValueType.FLOAT, basePath .. ".platformAnimation#speed", "Animation speed scale", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".platformAnimation#middleTime", "Animation middle time", 0.5)
    schema:register(XMLValueType.BOOL, basePath .. ".platformAnimation#automaticLift", "Automatically lift platform after dropping or pickup", false)
    schema:register(XMLValueType.BOOL, basePath .. ".platformAnimation#lowerToUnload", "Tool needs to be lowered first to be unloaded", false)

    schema:register(XMLValueType.FLOAT, basePath .. ".foldable#minLimit", "Min. folding time for platform state change [0-1]", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".foldable#maxLimit", "Max. folding time for platform state change [0-1]", 1)

    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "move")
    AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    local key = "vehicles.vehicle(?).palletFiller"
    PalletFillerState.registerXMLPath(schemaSavegame, key .. "#state", "Current vehicle state", nil, false)
    schemaSavegame:register(XMLValueType.BOOL, key .. "#deflectorState", "Current deflector state")
    schemaSavegame:register(XMLValueType.INT, key .. ".palletSlot(?)#slotIndex", "Index of slot")
    schemaSavegame:register(XMLValueType.STRING, key .. ".palletSlot(?)#objectUniqueId", "Unique id of the object that is loaded on this slot")
    schemaSavegame:register(XMLValueType.VECTOR_TRANS, key .. ".palletSlot(?)#translation", "Translation of the joint")
    schemaSavegame:register(XMLValueType.VECTOR_ROT, key .. ".palletSlot(?)#rotation", "Rotation of the joint")
end


---
function PalletFiller.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadPalletFillerPallet", PalletFiller.loadPalletFillerPallet)
    SpecializationUtil.registerFunction(vehicleType, "unloadPalletFillerPallet", PalletFiller.unloadPalletFillerPallet)
    SpecializationUtil.registerFunction(vehicleType, "buyPalletFillerPallets", PalletFiller.buyPalletFillerPallets)
    SpecializationUtil.registerFunction(vehicleType, "getCanChangePalletFillerState", PalletFiller.getCanChangePalletFillerState)
    SpecializationUtil.registerFunction(vehicleType, "getCanBuyPalletFillerPallets", PalletFiller.getCanBuyPalletFillerPallets)
    SpecializationUtil.registerFunction(vehicleType, "setPalletFillerState", PalletFiller.setPalletFillerState)
    SpecializationUtil.registerFunction(vehicleType, "setPalletFillerDeflectorState", PalletFiller.setPalletFillerDeflectorState)
    SpecializationUtil.registerFunction(vehicleType, "getPalletFillerFillStep", PalletFiller.getPalletFillerFillStep)
    SpecializationUtil.registerFunction(vehicleType, "getPalletFillerMovementDirection", PalletFiller.getPalletFillerMovementDirection)
end


---
function PalletFiller.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToObject", PalletFiller.getCanToggleDischargeToObject)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToGround", PalletFiller.getCanToggleDischargeToGround)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", PalletFiller.removeFromPhysics)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", PalletFiller.getIsFoldAllowed)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", PalletFiller.getFillLevelInformation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", PalletFiller.getCanAIImplementContinueWork)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "verifyCombine", PalletFiller.verifyCombine)
end


---
function PalletFiller.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", PalletFiller)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PalletFiller)
end


---
function PalletFiller:onLoad(savegame)
    local spec = self.spec_palletFiller

    local basePath = "vehicle.palletFiller"

    spec.state = PalletFillerState.IDLE

    spec.pickupTrigger = {}
    spec.pickupTrigger.node = self.xmlFile:getValue(basePath .. ".pickupTrigger#node", nil, self.components, self.i3dMappings)
    if spec.pickupTrigger.node ~= nil then
        spec.pickupTrigger.triggeredObjects = {}

        spec.pickupTrigger.pickupTriggerCallback = function(_, triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
            local object = g_currentMission:getNodeObject(otherActorId)
            if object ~= nil then
                if object:isa(Vehicle) then
                    if onEnter then
                        -- skip already mounted pallets
                        for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
                            if palletSlot.object == object then
                                return
                            end
                        end

                        if object.configFileName == spec.pallet.filename then
                            spec.pickupTrigger.triggeredObjects[otherActorId] = (spec.pickupTrigger.triggeredObjects[otherActorId] or 0) + 1

                            object:addDeleteListener(self, PalletFiller.onObjectDeleted)
                            self:raiseActive()
                        end
                    elseif onLeave then
                        spec.pickupTrigger.triggeredObjects[otherActorId] = (spec.pickupTrigger.triggeredObjects[otherActorId] or 0) - 1
                        if spec.pickupTrigger.triggeredObjects[otherActorId] <= 0 then
                            spec.pickupTrigger.triggeredObjects[otherActorId] = nil
                            object:removeDeleteListener(self, PalletFiller.onObjectDeleted)
                        end
                    end
                end
            end
        end

        addTrigger(spec.pickupTrigger.node, "pickupTriggerCallback", spec.pickupTrigger)
    end

    spec.pallet = {}
    spec.pallet.filename = self.xmlFile:getValue(basePath .. ".pallet#filename")
    if spec.pallet.filename ~= nil then
        spec.pallet.filename = Utils.getFilename(spec.pallet.filename, self.baseDirectory)
        spec.pallet.storeItem = g_storeManager:getItemByXMLFilename(spec.pallet.filename)
        if spec.pallet.storeItem == nil then
            Logging.xmlWarning(self.xmlFile, "Invalid pallet filename defined for '%s' (%s)", basePath, spec.pallet.filename)
            spec.pallet.filename = nil
        end
    else
        Logging.xmlWarning(self.xmlFile, "No pallet filename defined for '%s'", basePath)
    end
    spec.pallet.spacing = self.xmlFile:getValue(basePath .. ".pallet#spacing", 0.5)

    spec.palletRow = {}
    spec.palletRow.node = self.xmlFile:getValue(basePath .. ".palletRow#node", nil, self.components, self.i3dMappings)
    spec.palletRow.maxNumPallets = self.xmlFile:getValue(basePath .. ".palletRow#maxNumPallets", 1)
    spec.palletRow.minTransZ = self.xmlFile:getValue(basePath .. ".palletRow#minTransZ", 0)
    spec.palletRow.maxTransZ = self.xmlFile:getValue(basePath .. ".palletRow#maxTransZ", 0)
    spec.palletRow.moveSpeed = self.xmlFile:getValue(basePath .. ".palletRow#moveSpeed", 1) / 1000
    spec.palletRow.pickupTime = self.xmlFile:getValue(basePath .. ".palletRow#pickupTime", 2)
    spec.palletRow.loadingDelay = self.xmlFile:getValue(basePath .. ".palletRow#loadingDelay", 0)

    spec.palletRow.fillSteps = {}
    self.xmlFile:iterate(basePath .. ".palletRow.fillStep", function(index, key)
        local fillStep = {}
        fillStep.transZ = self.xmlFile:getValue(key .. "#transZ", 0)
        fillStep.palletIndex = self.xmlFile:getValue(key .. "#palletIndex", 1)
        fillStep.dischargeNodeIndex = self.xmlFile:getValue(key .. "#dischargeNodeIndex", 1)
        fillStep.index = #spec.palletRow.fillSteps + 1

        table.insert(spec.palletRow.fillSteps, fillStep)
    end)

    spec.palletRow.startRotLimit = self.xmlFile:getValue(basePath .. ".palletRow.rotLimit#startLimit", "0 0 0", true)
    spec.palletRow.endRotLimit = self.xmlFile:getValue(basePath .. ".palletRow.rotLimit#endLimit", "0 0 0", true)
    spec.palletRow.unloadRotLimit = self.xmlFile:getValue(basePath .. ".palletRow.rotLimit#unloadLimit", "0 0 25", true)

    spec.palletRow.startTransLimit = self.xmlFile:getValue(basePath .. ".palletRow.transLimit#startLimit", "0.25 2 0.25", true)
    spec.palletRow.endTransLimit = self.xmlFile:getValue(basePath .. ".palletRow.transLimit#endLimit", "0 2 0", true)
    spec.palletRow.unloadTransLimit = self.xmlFile:getValue(basePath .. ".palletRow.transLimit#unloadLimit", "0.25 2 0", true)

    spec.palletRow.palletSlots = {}
    for i=1, spec.palletRow.maxNumPallets do
        local palletSlot = {}

        palletSlot.jointNode = createTransformGroup("jointNode" .. i)
        link(spec.palletRow.node, palletSlot.jointNode)
        setTranslation(palletSlot.jointNode, 0, 0, 0)
        setRotation(palletSlot.jointNode, 0, 0, 0)

        palletSlot.object = nil
        palletSlot.interpolationTimer = 0
        palletSlot.index = #spec.palletRow.palletSlots + 1

        table.insert(spec.palletRow.palletSlots, palletSlot)
    end

    spec.palletRow.currentTransZ = 0
    spec.palletRow.currentDischargeNodeIndex = 1
    spec.palletRow.isMoving = false

    spec.fillDeflectorAnimation = {}
    spec.fillDeflectorAnimation.name = self.xmlFile:getValue(basePath .. ".fillDeflectorAnimation#name")
    spec.fillDeflectorAnimation.speed = self.xmlFile:getValue(basePath .. ".fillDeflectorAnimation#speed", 1)
    spec.fillDeflectorAnimation.state = false

    spec.platformAnimation = {}
    spec.platformAnimation.name = self.xmlFile:getValue(basePath .. ".platformAnimation#name")
    spec.platformAnimation.speed = self.xmlFile:getValue(basePath .. ".platformAnimation#speed", 1)
    spec.platformAnimation.middleTime = self.xmlFile:getValue(basePath .. ".platformAnimation#middleTime", 0.5)
    spec.platformAnimation.automaticLift = self.xmlFile:getValue(basePath .. ".platformAnimation#automaticLift", false)
    spec.platformAnimation.lowerToUnload = self.xmlFile:getValue(basePath .. ".platformAnimation#lowerToUnload", false)

    spec.foldable = {}
    spec.foldable.minLimit = self.xmlFile:getValue(basePath .. ".foldable#minLimit", 0)
    spec.foldable.maxLimit = self.xmlFile:getValue(basePath .. ".foldable#maxLimit", 1)

    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, basePath .. ".animationNodes", self.components, self, self.i3dMappings)

        spec.samples = {}
        spec.samples.move = g_soundManager:loadSampleFromXML(self.xmlFile, basePath .. ".sounds", "move", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    spec.texts = {}
    spec.texts.warningPalletFillerNoPalletAvailable = g_i18n:getText("warning_palletFillerNoPalletAvailable", PalletFiller.MOD_NAME)

    spec.dirtyFlag = self:getNextDirtyFlag()

    if not self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdate", PalletFiller)
    end

    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", PalletFiller)
    end
end


---
function PalletFiller:onLoadFinished(savegame)
    local spec = self.spec_palletFiller

    -- overwriting of combine loadingDelay as we dont have combine configurations yet
    if spec.palletRow.loadingDelay > 0 then
        local spec_combine = self.spec_combine
        if self.spec_combine ~= nil then
            spec_combine.loadingDelay = spec.palletRow.loadingDelay
            spec_combine.unloadingDelay = spec.palletRow.loadingDelay
            spec_combine.loadingDelaySlotsDelayedInsert = false

            spec_combine.loadingDelaySlots = {}
            for i=1, spec_combine.loadingDelay / 1000 * 60 + 1 do -- max if we fill at 60FPS every frame
                spec_combine.loadingDelaySlots[i] = {time=-math.huge, fillLevelDelta=0, fillType=0, valid=false}
            end
        end
    end

    self:setAnimationTime(spec.platformAnimation.name, 1, true, false)
    self:setAnimationTime(spec.platformAnimation.name, 0, true, false)

    if savegame ~= nil then
        local key = savegame.key .. ".palletFiller"

        local state = PalletFillerState.loadFromXMLFile(savegame.xmlFile, key .. "#state")
        if state ~= nil then
            self:setPalletFillerState(state, true, true)
        end

        local deflectorState = savegame.xmlFile:getValue(key .. "#deflectorState", spec.fillDeflectorAnimation.state)
        self:setPalletFillerDeflectorState(deflectorState, true)

        spec.objectsToLoad = {}

        savegame.xmlFile:iterate(key .. ".palletSlot", function(index, slotKey)
            local objectToLoad = {}
            objectToLoad.slotIndex = savegame.xmlFile:getValue(slotKey .. "#slotIndex")
            objectToLoad.objectUniqueId = savegame.xmlFile:getValue(slotKey .. "#objectUniqueId")
            if objectToLoad.slotIndex ~= nil and objectToLoad.objectUniqueId ~= nil then
                objectToLoad.translation = savegame.xmlFile:getValue(slotKey .. "#translation", nil, true)
                objectToLoad.rotation = savegame.xmlFile:getValue(slotKey .. "#rotation", nil, true)

                table.insert(spec.objectsToLoad, objectToLoad)
            end
        end)
    else
        self:setPalletFillerState(spec.state, true, true)
    end
end


---
function PalletFiller:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_palletFiller

    PalletFillerState.saveToXMLFile(xmlFile, key .. "#state", spec.state)
    xmlFile:setValue(key .. "#deflectorState", spec.fillDeflectorAnimation.state)

    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object ~= nil then
            local slotKey = string.format("%s.palletSlot(%d)", key, i - 1)
            xmlFile:setValue(slotKey .. "#slotIndex", i)
            xmlFile:setValue(slotKey .. "#objectUniqueId", palletSlot.object:getUniqueId())

            xmlFile:setValue(slotKey .. "#translation", getTranslation(palletSlot.jointNode))
            xmlFile:setValue(slotKey .. "#rotation", getRotation(palletSlot.jointNode))
        end
    end
end


---Called on deleting
function PalletFiller:onDelete()
    local spec = self.spec_palletFiller
    if spec.pickupTrigger ~= nil and spec.pickupTrigger.node ~= nil then
        removeTrigger(spec.pickupTrigger.node)
    end

    if spec.samples ~= nil then
        g_soundManager:deleteSamples(spec.samples)
    end

    if spec.palletRow ~= nil then
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object ~= nil then
                self:unloadPalletFillerPallet(palletSlot.object)
            end
        end
    end
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PalletFiller:onReadStream(streamId, connection)
    local spec = self.spec_palletFiller

    local state = PalletFillerState.readStream(streamId)
    self:setPalletFillerState(state, true, true)

    local deflectorState = streamReadBool(streamId)
    self:setPalletFillerDeflectorState(deflectorState, true)

    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if streamReadBool(streamId) then
            palletSlot.object = NetworkUtil.readNodeObject(streamId)
        else
            palletSlot.object = nil
        end

        palletSlot.pendingObjectLoading = false
    end
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PalletFiller:onWriteStream(streamId, connection)
    local spec = self.spec_palletFiller

    PalletFillerState.writeStream(streamId, spec.state)
    streamWriteBool(streamId, spec.fillDeflectorAnimation.state)

    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if streamWriteBool(streamId, palletSlot.object ~= nil) then
            NetworkUtil.writeNodeObject(streamId, palletSlot.object)
        end
    end
end


---Called on on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function PalletFiller:onReadUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local spec = self.spec_palletFiller
            spec.palletRow.isMoving = streamReadBool(streamId)

            if spec.palletRow.isMoving then
                g_animationManager:startAnimations(spec.animationNodes)
                g_soundManager:playSample(spec.samples.move)
            else
                g_animationManager:stopAnimations(spec.animationNodes)
                g_soundManager:stopSample(spec.samples.move)
            end

            for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
                if streamReadBool(streamId) then
                    palletSlot.objectId = NetworkUtil.readNodeObjectId(streamId)
                    palletSlot.object = NetworkUtil.getObject(palletSlot.objectId)
                    if palletSlot.object ~= nil then
                        palletSlot.objectId = nil
                        palletSlot.pendingObjectLoading = false
                    else
                        self:raiseActive()
                    end
                else
                    palletSlot.object = nil
                    palletSlot.pendingObjectLoading = false
                end
            end

            PalletFiller.updatePalletFillerDeflectorState(self)
            PalletFiller.updateActionEventTexts(self)
        end
    end
end


---Called on on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function PalletFiller:onWriteUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        local spec = self.spec_palletFiller
        if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
            streamWriteBool(streamId, spec.palletRow.isMoving)

            for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
                if streamWriteBool(streamId, palletSlot.object ~= nil) then
                    NetworkUtil.writeNodeObject(streamId, palletSlot.object)
                end
            end
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function PalletFiller:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_palletFiller

    if spec.objectsToLoad ~= nil and #spec.objectsToLoad > 0 then
        for i=#spec.objectsToLoad, 1, -1 do
            local objectToLoad = spec.objectsToLoad[i]
            local vehicle = g_currentMission.vehicleSystem:getVehicleByUniqueId(objectToLoad.objectUniqueId)
            if vehicle ~= nil then
                if not self:loadPalletFillerPallet(vehicle, objectToLoad) then
                    Logging.warning("Failed to load pallet object from savegame. UniqueId: %d SlotIndex: %d", objectToLoad.objectUniqueId, objectToLoad.slotIndex)
                end
                spec.objectsToLoad[i] = nil
            end
        end
    end

    if spec.state == PalletFillerState.LOADING then
        if not self:getIsAnimationPlaying(spec.platformAnimation.name) then
            for otherActorId, v in pairs(spec.pickupTrigger.triggeredObjects) do
                local object = g_currentMission:getNodeObject(otherActorId)
                if object ~= nil then
                    if object:isa(Vehicle) and self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
                        local allowPickup = true
                        for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
                            if palletSlot.object == object then
                                allowPickup = false
                                break
                            end

                            -- only mount one pallet at the time
                            if palletSlot.interpolationTimer ~= 0 then
                                allowPickup = false
                                break
                            end
                        end

                        if allowPickup then
                            self:loadPalletFillerPallet(object)
                            break
                        end
                    end
                end

                self:raiseActive()
            end
        end
    end

    local fillStep = self:getPalletFillerFillStep()
    if fillStep ~= nil then
        spec.palletRow.currentTransZ = fillStep.transZ
        spec.palletRow.currentDischargeNodeIndex = fillStep.dischargeNodeIndex

        if self:getCurrentDischargeNodeIndex() ~= fillStep.dischargeNodeIndex then
            self:setCurrentDischargeNodeIndex(fillStep.dischargeNodeIndex)
        end
    end

    local palletsMoving = false
    local palletSlotOffset = 0
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.interpolationTimer ~= 0 then
            if palletSlot.object ~= nil then
                palletSlot.interpolationTimer = math.max(palletSlot.interpolationTimer - dt, 0)

                local alpha = 1 - (palletSlot.interpolationTimer / spec.palletRow.pickupTime)

                local qStart = palletSlot.startQuaternion
                local qEnd = palletSlot.endQuaternion

                local qx, qy, qz, qw = MathUtil.slerpQuaternionShortestPath(qStart[1], qStart[2], qStart[3], qStart[4], qEnd[1], qEnd[2], qEnd[3], qEnd[4], alpha)
                setQuaternion(palletSlot.jointNode, qx, qy, qz, qw)

                local tx, ty, tz = MathUtil.vector3ArrayLerp(palletSlot.startTranslation, palletSlot.endTranslation, alpha)
                setTranslation(palletSlot.jointNode, tx, ty, tz)

                if palletSlot.jointIndex ~= nil then
                    local rlx, rly, rlz = MathUtil.vector3ArrayLerp(spec.palletRow.startRotLimit, spec.palletRow.endRotLimit, alpha)
                    setJointRotationLimit(palletSlot.jointIndex, 0, true, -rlx, rlx)
                    setJointRotationLimit(palletSlot.jointIndex, 1, true, -rly, rly)
                    setJointRotationLimit(palletSlot.jointIndex, 2, true, -rlz, rlz)

                    local tlx, tly, tlz = MathUtil.vector3ArrayLerp(spec.palletRow.startTransLimit, spec.palletRow.endTransLimit, alpha)
                    setJointTranslationLimit(palletSlot.jointIndex, 0, true, -tlx, tlx)
                    setJointTranslationLimit(palletSlot.jointIndex, 1, true, 0, tly)
                    setJointTranslationLimit(palletSlot.jointIndex, 2, true, -tlz, tlz)

                    setJointFrame(palletSlot.jointIndex, 0, palletSlot.jointNode)
                end

                palletsMoving = true
            else
                palletSlot.interpolationTimer = 0
            end
        elseif palletSlot.object ~= nil then
            local targetTrans = spec.palletRow.currentTransZ + palletSlotOffset
            if spec.state == PalletFillerState.UNLOADING then
                if spec.palletRow.minTransZ ~= spec.palletRow.maxTransZ then
                    targetTrans = spec.palletRow.minTransZ - 0.1
                end
            end

            local _, _, currentTrans = getTranslation(palletSlot.jointNode)
            local offset = targetTrans - currentTrans
            local limit = offset > 0 and math.min or math.max
            currentTrans = limit(currentTrans + math.sign(offset) * spec.palletRow.moveSpeed * dt, targetTrans)

            local rotLimit, transLimit = spec.palletRow.endRotLimit, spec.palletRow.endTransLimit
            if spec.state == PalletFillerState.UNLOADING then
                rotLimit, transLimit = spec.palletRow.unloadRotLimit, spec.palletRow.unloadTransLimit
            end

            setTranslation(palletSlot.jointNode, 0, 0, currentTrans)
            if palletSlot.jointIndex ~= nil then
                local rlx, rly, rlz = rotLimit[1], rotLimit[2], rotLimit[3]
                setJointRotationLimit(palletSlot.jointIndex, 0, true, -rlx, rlx)
                setJointRotationLimit(palletSlot.jointIndex, 1, true, -rly, rly)
                setJointRotationLimit(palletSlot.jointIndex, 2, true, -rlz, rlz)

                local tlx, tly, tlz = transLimit[1], transLimit[2], transLimit[3]
                setJointTranslationLimit(palletSlot.jointIndex, 0, true, -tlx, tlx)
                setJointTranslationLimit(palletSlot.jointIndex, 1, true, 0, tly)
                setJointTranslationLimit(palletSlot.jointIndex, 2, true, -tlz, tlz)

                setJointFrame(palletSlot.jointIndex, 0, palletSlot.jointNode)
            end

            palletSlotOffset = palletSlotOffset + spec.pallet.spacing

            palletsMoving = palletsMoving or math.abs(offset) > 0.01

            if spec.state == PalletFillerState.UNLOADING then
                if spec.palletRow.minTransZ == spec.palletRow.maxTransZ then
                    if not self:getIsAnimationPlaying(spec.platformAnimation.name) then
                        self:unloadPalletFillerPallet(palletSlot.object)
                    end
                else
                    if currentTrans < spec.palletRow.minTransZ then
                        self:unloadPalletFillerPallet(palletSlot.object)
                    end
                end
            end
        end
    end

    if spec.platformAnimation.automaticLift then
        local numPallets = 0
        for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.interpolationTimer == 0 and palletSlot.object ~= nil then
                numPallets = numPallets + 1
            end
        end

        if spec.state == PalletFillerState.LOADING then
            if numPallets == #spec.palletRow.palletSlots then
                self:setPalletFillerState(PalletFillerState.IDLE)
            end
        elseif spec.state == PalletFillerState.UNLOADING then
            if numPallets == 0 and next(spec.pickupTrigger.triggeredObjects) == nil then
                self:setPalletFillerState(PalletFillerState.IDLE)
            end
        end
    end

    if palletsMoving ~= spec.palletRow.isMoving then
        spec.palletRow.isMoving = palletsMoving
        self:raiseDirtyFlags(spec.dirtyFlag)

        PalletFiller.updatePalletFillerDeflectorState(self)

        if self.isClient then
            if palletsMoving then
                g_animationManager:startAnimations(spec.animationNodes)
                g_soundManager:playSample(spec.samples.move)
            else
                g_animationManager:stopAnimations(spec.animationNodes)
                g_soundManager:stopSample(spec.samples.move)
            end
        end
    end
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function PalletFiller:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_palletFiller
    if isActiveForInputIgnoreSelection then
        if self:getIsTurnedOn() then
            if spec.state == PalletFillerState.IDLE then
                local freeCapacity = 0
                for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
                    if palletSlot.object ~= nil and palletSlot.object.getFillUnitFreeCapacity ~= nil then
                        freeCapacity = freeCapacity + palletSlot.object:getFillUnitFreeCapacity(1)
                    end
                end

                if freeCapacity == 0 then
                    g_currentMission:showBlinkingWarning(spec.texts.warningPalletFillerNoPalletAvailable, 250)
                end
            end
        end
    end

    -- on client side we resolve the object ids delayed in case the object was not yet synced
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.objectId ~= nil then
            local object = NetworkUtil.getObject(palletSlot.objectId)
            if object ~= nil and object:getIsSynchronized() then
                palletSlot.object = object
                palletSlot.objectId = nil
                palletSlot.pendingObjectLoading = false

                PalletFiller.updateActionEventTexts(self)
            else
                self:raiseActive()
            end
        end
    end
end


---
function PalletFiller:onFinishAnimation(name)
    local spec = self.spec_palletFiller
    if name == spec.platformAnimation.name then
        PalletFiller.updatePalletFillerDeflectorState(self)
    end
end


---
function PalletFiller:onFoldTimeChanged(name)
    PalletFiller.updateActionEventTexts(self)
end


---
function PalletFiller:loadPalletFillerPallet(object, data)
    local spec = self.spec_palletFiller

    for slotIndex, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if (data == nil and palletSlot.object == nil)
        or (data ~= nil and data.slotIndex == slotIndex) then
            palletSlot.object = object

            if data ~= nil and data.translation ~= nil then
                setTranslation(palletSlot.jointNode, data.translation[1], data.translation[2], data.translation[3])
                setRotation(palletSlot.jointNode, data.rotation[1], data.rotation[2], data.rotation[3])
            else
                setWorldTranslation(palletSlot.jointNode, getWorldTranslation(object.rootNode))
                setWorldRotation(palletSlot.jointNode, getWorldRotation(object.rootNode))
            end

            local distance = calcDistanceFrom(palletSlot.jointNode, object.rootNode)

            local constr = JointConstructor.new()
            constr:setActors(self.rootNode, object.rootNode)

            constr:setJointTransforms(palletSlot.jointNode, object.rootNode)
            constr:setEnableCollision(true)

            local rlx, rly, rlz = spec.palletRow.startRotLimit[1], spec.palletRow.startRotLimit[2], spec.palletRow.startRotLimit[3]
            constr:setRotationLimit(0, -rlx, rlx)
            constr:setRotationLimit(1, -rly, rly)
            constr:setRotationLimit(2, -rlz, rlz)

            local tlx, tly, tlz = spec.palletRow.startTransLimit[1], spec.palletRow.startTransLimit[2], spec.palletRow.startTransLimit[3]
            constr:setTranslationLimit(0, true, -tlx, tlx)
            constr:setTranslationLimit(1, true, 0, tly)
            constr:setTranslationLimit(2, true, -tlz, tlz)

            if data ~= nil then
                palletSlot.interpolationDistance = distance
                palletSlot.interpolationTimer = 0
            else
                palletSlot.startQuaternion = {getQuaternion(palletSlot.jointNode)}

                local dx, _, dz = worldDirectionToLocal(getParent(palletSlot.jointNode), localDirectionToWorld(object.rootNode, 0, 0, 1))
                local yRot = MathUtil.vector2Normalize(dx, dz)
                if math.abs(yRot) < math.pi * 0.5 then
                    palletSlot.endQuaternion = {mathEulerToQuaternion(0, 0, 0)}
                else
                    palletSlot.endQuaternion = {mathEulerToQuaternion(0, math.pi, 0)}
                end

                palletSlot.startTranslation = {getTranslation(palletSlot.jointNode)}
                palletSlot.endTranslation = {0, 0, spec.palletRow.maxTransZ}

                palletSlot.interpolationDistance = distance
                palletSlot.interpolationTimer = spec.palletRow.pickupTime
            end

            palletSlot.jointIndex = constr:finalize()

            object:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC)
            self:raiseDirtyFlags(spec.dirtyFlag)
            PalletFiller.updateActionEventTexts(self)

            return true
        end
    end

    return false
end


---
function PalletFiller:unloadPalletFillerPallet(object)
    local spec = self.spec_palletFiller

    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object == object then
            palletSlot.object = nil
            palletSlot.interpolationTimer = 0

            if palletSlot.jointIndex ~= nil then
                removeJoint(palletSlot.jointIndex)
                palletSlot.jointIndex = nil
            end

            object:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)

            break
        end
    end

    self:raiseDirtyFlags(spec.dirtyFlag)
    PalletFiller.updateActionEventTexts(self)
end


---
function PalletFiller:buyPalletFillerPallets(noEventSend)
    local spec = self.spec_palletFiller

    if self.isServer then
        local palletSlotOffset = 0
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            local targetTrans = spec.palletRow.currentTransZ + palletSlotOffset
            setTranslation(palletSlot.jointNode, 0, 0, targetTrans)

            if palletSlot.object == nil then
                palletSlot.pendingObjectLoading = true

                local data = VehicleLoadingData.new()
                data:setFilename(spec.pallet.filename)
                data:setSpawnNode(palletSlot.jointNode)
                data:setIgnoreShopOffset(true)
                data:setPropertyState(VehiclePropertyState.OWNED)
                data:setOwnerFarmId(self:getOwnerFarmId())

                data:load(PalletFiller.onCreatePalletFinished, self, {palletSlot=palletSlot})

            else
                if palletSlot.jointIndex ~= nil then
                    setJointFrame(palletSlot.jointIndex, 0, palletSlot.jointNode)
                end
            end

            palletSlotOffset = palletSlotOffset + spec.pallet.spacing
        end
    else
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object == nil then
                palletSlot.pendingObjectLoading = true
            end
        end

        if noEventSend ~= true then
            g_client:getServerConnection():sendEvent(PalletFillerBuyPalletEvent.new(self))
        end
    end
end


---
function PalletFiller.onCreatePalletFinished(self, vehicles, vehicleLoadState, arguments)
    local spec = self.spec_palletFiller
    arguments.palletSlot.pendingObjectLoading = false

    if vehicleLoadState == VehicleLoadingState.OK and #vehicles >= 1 then
        local vehicle = vehicles[1]
        vehicle:removeFromPhysics()
        vehicle:addToPhysics()

        local data = {}
        data.slotIndex = arguments.palletSlot.index
        data.translation = {getTranslation(arguments.palletSlot.jointNode)}
        data.rotation = {getRotation(arguments.palletSlot.jointNode)}

        if not self:loadPalletFillerPallet(vehicle, data) then
            vehicle:delete()
        else
            g_currentMission:addMoney(-spec.pallet.storeItem.price, self:getOwnerFarmId(), MoneyType.PURCHASE_PALLETS)
            g_currentMission:addMoneyChange(-spec.pallet.storeItem.price, self:getOwnerFarmId(), MoneyType.PURCHASE_PALLETS, false)

            local hasFreeSlots = false
            for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
                hasFreeSlots = hasFreeSlots or palletSlot.object == nil
            end

            if not hasFreeSlots then
                g_currentMission:showMoneyChange(MoneyType.PURCHASE_PALLETS)
            end
        end
    end
end


---
function PalletFiller:getCanChangePalletFillerState(newState)
    local spec = self.spec_palletFiller

    if spec.platformAnimation.automaticLift then
        if spec.state == PalletFillerState.UNLOADING then
            return false
        end
    end

    local hasPalletsLoaded, hasFreeSlots = false, false
    for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object ~= nil then
            hasPalletsLoaded = true
        else
            hasFreeSlots = true
        end
    end

    if spec.state == PalletFillerState.UNLOADING then
        if hasPalletsLoaded then
            return false
        end
    end

    if spec.state == PalletFillerState.IDLE and newState == PalletFillerState.UNLOADING then
        if not hasPalletsLoaded then
            return false
        end

        if spec.platformAnimation.lowerToUnload then
            if not self:getIsLowered(true) then
                return false, string.format(g_i18n:getText("warning_lowerImplementFirst"), self:getName())
            end
        end
    end

    if spec.state == PalletFillerState.IDLE and newState == PalletFillerState.LOADING then
        if not hasFreeSlots then
            return false
        end
    end

    if newState ~= PalletFillerState.IDLE then
        local foldAnimTime = self:getFoldAnimTime()
        if foldAnimTime < spec.foldable.minLimit or foldAnimTime > spec.foldable.maxLimit then
            return false
        end
    end

    return true
end


---
function PalletFiller:getCanBuyPalletFillerPallets()
    local spec = self.spec_palletFiller
    local foldAnimTime = self:getFoldAnimTime()
    if foldAnimTime < spec.foldable.minLimit or foldAnimTime > spec.foldable.maxLimit then
        return false, string.format(g_i18n:getText("warning_firstUnfoldTheTool"), self:getFullName())
    end

    return true
end


---
function PalletFiller:setPalletFillerState(state, updateAnimations, noEventSend)
    local spec = self.spec_palletFiller

    spec.state = state

    local animationTime = self:getAnimationTime(spec.platformAnimation.name)
    local targetTime = spec.platformAnimation.middleTime
    if spec.state == PalletFillerState.LOADING then
        targetTime = 0
    elseif spec.state == PalletFillerState.UNLOADING then
        targetTime = 1
    end

    if targetTime ~= animationTime then
        self:setAnimationStopTime(spec.platformAnimation.name, targetTime)
        self:playAnimation(spec.platformAnimation.name, spec.platformAnimation.speed * math.sign(targetTime - animationTime), animationTime, true)

        if updateAnimations == true then
            AnimatedVehicle.updateAnimationByName(self, spec.platformAnimation.name, 99999, true)
        end
    end

    PalletFiller.updateActionEventTexts(self)

    PalletFillerStateEvent.sendEvent(self, state, noEventSend)
end


---
function PalletFiller.updatePalletFillerDeflectorState(self)
    local spec = self.spec_palletFiller

    local deflectorState = false
    if math.abs(self:getAnimationTime(spec.platformAnimation.name) - spec.platformAnimation.middleTime) > 0.01
    or spec.palletRow.isMoving then
        deflectorState = true
    end

    if deflectorState ~= spec.fillDeflectorAnimation.state then
        self:setPalletFillerDeflectorState(deflectorState)
    end
end


---
function PalletFiller:setPalletFillerDeflectorState(state, updateAnimations)
    local spec = self.spec_palletFiller
    spec.fillDeflectorAnimation.state = state

    local direction = spec.fillDeflectorAnimation.state and 1 or -1
    self:playAnimation(spec.fillDeflectorAnimation.name, spec.fillDeflectorAnimation.speed * direction, self:getAnimationTime(spec.fillDeflectorAnimation.name), true)

    if updateAnimations == true then
        AnimatedVehicle.updateAnimationByName(self, spec.fillDeflectorAnimation.name, 99999, true)
    end
end


---
function PalletFiller:getPalletFillerFillStep()
    local spec = self.spec_palletFiller

    -- use the first slot with a pallet that is not full yet
    for i, fillStep in ipairs(spec.palletRow.fillSteps) do
        local palletSlot = spec.palletRow.palletSlots[fillStep.palletIndex]
        if palletSlot.object ~= nil then
            if palletSlot.object:getFillUnitFreeCapacity(1) > 0 then
                return fillStep
            end
        end
    end

    -- if all loaded pallets are full already, we move to the first empty slot
    for i, fillStep in ipairs(spec.palletRow.fillSteps) do
        local palletSlot = spec.palletRow.palletSlots[fillStep.palletIndex]
        if palletSlot.object == nil then
            return fillStep
        end
    end

    -- if the whole tool is full we move to the first fill step
    return spec.palletRow.fillSteps[1]
end


---
function PalletFiller:getPalletFillerMovementDirection()
    local spec = self.spec_palletFiller
    if spec.state == PalletFillerState.LOADING then
        return 1
    elseif spec.state == PalletFillerState.UNLOADING then
        return -1
    end

    return 0
end


---
function PalletFiller:getCanToggleDischargeToObject(superFunc)
    return false
end


---
function PalletFiller:getCanToggleDischargeToGround(superFunc)
    return false
end


---
function PalletFiller:removeFromPhysics(superFunc)
    local spec = self.spec_palletFiller
    if spec.palletRow ~= nil then
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object ~= nil then
                self:unloadPalletFillerPallet(palletSlot.object)
            end
        end
    end

    return superFunc(self)
end


---
function PalletFiller:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
    local spec = self.spec_palletFiller
    if spec.state ~= PalletFillerState.IDLE then
        return false, g_i18n:getText("warning_palletFillerPlatformLowered")
    end

    if spec.palletRow ~= nil then
        for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object ~= nil or palletSlot.pendingObjectLoading then
                return false, g_i18n:getText("warning_palletFillerNoEmpty")
            end
        end
    end

    return superFunc(self, direction, onAiTurnOn)
end


---
function PalletFiller:getFillLevelInformation(superFunc, display)
    superFunc(self, display)

    local fillType, fillLevel, capacity = nil, 0, 0
    local spec = self.spec_palletFiller
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object ~= nil and palletSlot.object.getFillUnitFillLevel ~= nil then
            local objectFillType = palletSlot.object:getFillUnitFillType(1)
            if objectFillType ~= FillType.UNKNOWN then
                fillType = objectFillType
            end

            fillLevel = fillLevel + palletSlot.object:getFillUnitFillLevel(1)
            capacity = capacity + palletSlot.object:getFillUnitCapacity(1)
        end
    end

    if capacity > 0 then
        display:addFillLevel(fillType or FillType.UNKNOWN, fillLevel, capacity)
    end
end


---
function PalletFiller:getCanAIImplementContinueWork(superFunc, isTurning)
    local freeCapacity, numLoadedPallets = 0, 0
    local spec = self.spec_palletFiller
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object ~= nil and palletSlot.object.getFillUnitFillLevel ~= nil then
            freeCapacity = freeCapacity + palletSlot.object:getFillUnitFreeCapacity(1)
            numLoadedPallets = numLoadedPallets + 1
        end
    end

    if freeCapacity == 0 then
        if numLoadedPallets > 0 then
            return false, true, AIMessageErrorPalletsFull.new()
        else
            return false, true, AIMessageErrorNoPalletsLoaded.new()
        end
    end

    return superFunc(self, isTurning)
end


---
function PalletFiller:verifyCombine(superFunc, fruitType, outputFillType, ...)
    local spec = self.spec_palletFiller

    local freeCapacity = 0
    for i, palletSlot in ipairs(spec.palletRow.palletSlots) do
        if palletSlot.object ~= nil and palletSlot.object.getFillUnitFillType ~= nil then
            if outputFillType ~= FillType.UNKNOWN then
                if not palletSlot.object:getFillUnitAllowsFillType(1, outputFillType) then
                    return nil, self, palletSlot.object:getFillUnitFillType(1)
                end
            end

            freeCapacity = freeCapacity + palletSlot.object:getFillUnitFreeCapacity(1)
        end
    end

    if freeCapacity == 0 then
        return nil
    end

    return superFunc(self, fruitType, outputFillType, ...)
end


---
function PalletFiller:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if isActiveForInputIgnoreSelection then
        if self.isClient then
            local spec = self.spec_palletFiller
            self:clearActionEventsTable(spec.actionEvents)

            if spec.platformAnimation.name ~= nil then
                local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, PalletFiller.actionEventLowerPlatformLoad, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)

                _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, PalletFiller.actionEventLowerPlatformUnload, false, true, false, true, nil)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)

                if spec.pallet.storeItem ~= nil then
                    _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.PALLET_FILLER_BUY_PALLETS, self, PalletFiller.actionEventBuyPallets, false, true, false, true, nil)
                    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
                    g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_palletFillerBuyPallets"))
                end

                PalletFiller.updateActionEventTexts(self)
            end
        end
    end
end


---
function PalletFiller.updateActionEventTexts(self)
    local spec = self.spec_palletFiller
    local loadAction = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
    if loadAction ~= nil then
        local text
        if spec.state == PalletFillerState.IDLE then
            local isAllowed, warning = self:getCanChangePalletFillerState(PalletFillerState.LOADING)
            if isAllowed or warning ~= nil then
                text = g_i18n:getText("action_palletFillerLoad")
            end
        elseif spec.state == PalletFillerState.LOADING then
            local isAllowed, warning = self:getCanChangePalletFillerState(PalletFillerState.IDLE)
            if isAllowed or warning ~= nil then
                text = g_i18n:getText("action_palletFillerIdle")
            end
        end

        if text ~= nil then
            g_inputBinding:setActionEventText(loadAction.actionEventId, text)
            g_inputBinding:setActionEventActive(loadAction.actionEventId, true)
        else
            g_inputBinding:setActionEventActive(loadAction.actionEventId, false)
        end
    end

    local unloadAction = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]
    if unloadAction ~= nil then
        local text
        if spec.state == PalletFillerState.IDLE then
            local isAllowed, warning = self:getCanChangePalletFillerState(PalletFillerState.UNLOADING)
            if isAllowed or warning ~= nil then
                text = g_i18n:getText("action_palletFillerUnload")
            end
        elseif spec.state == PalletFillerState.UNLOADING then
            local isAllowed, warning = self:getCanChangePalletFillerState(PalletFillerState.IDLE)
            if isAllowed or warning ~= nil then
                text = g_i18n:getText("action_palletFillerIdle")
            end
        end

        if text ~= nil then
            g_inputBinding:setActionEventText(unloadAction.actionEventId, text)
            g_inputBinding:setActionEventActive(unloadAction.actionEventId, true)
        else
            g_inputBinding:setActionEventActive(unloadAction.actionEventId, false)
        end
    end

    local buyAction = spec.actionEvents[InputAction.PALLET_FILLER_BUY_PALLETS]
    if buyAction ~= nil then
        local numPallets = 0
        for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object == nil then
                numPallets = numPallets + 1
            end
        end

        g_inputBinding:setActionEventActive(buyAction.actionEventId, spec.state == PalletFillerState.IDLE and numPallets > 0)
    end
end


---
function PalletFiller.actionEventLowerPlatformLoad(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_palletFiller

    local newState = spec.state == PalletFillerState.IDLE and PalletFillerState.LOADING or PalletFillerState.IDLE
    local isAllowed, warning = self:getCanChangePalletFillerState(newState)
    if isAllowed then
        self:setPalletFillerState(newState)
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end


---
function PalletFiller.actionEventLowerPlatformUnload(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_palletFiller

    local newState = spec.state == PalletFillerState.IDLE and PalletFillerState.UNLOADING or PalletFillerState.IDLE
    local isAllowed, warning = self:getCanChangePalletFillerState(newState)
    if isAllowed then
        self:setPalletFillerState(newState)
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end


---
function PalletFiller.actionEventBuyPallets(self, actionName, inputValue, callbackState, isAnalog)
    local spec = self.spec_palletFiller
    local isAllowed, warning = self:getCanBuyPalletFillerPallets()
    if isAllowed then
        local numPallets = 0
        for _, palletSlot in ipairs(spec.palletRow.palletSlots) do
            if palletSlot.object == nil then
                numPallets = numPallets + 1
            end
        end
        local price = spec.pallet.storeItem.price * numPallets

        local callback = function(_, yes)
            if yes then
                self:buyPalletFillerPallets()
            end
        end

        YesNoDialog.show(callback, self, string.format(g_i18n:getText("ui_palletFillerBuyPalletsText"), numPallets, g_i18n:formatMoney(price)), self:getFullName())
    elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
    end
end


---
function PalletFiller.onObjectDeleted(self, object)
    local spec = self.spec_palletFiller
    spec.pickupTrigger.triggeredObjects[object.rootNode] = nil
end
