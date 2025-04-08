











---The hand tool class, representing a hand tool instance.
local HandTool_mt = Class(HandTool, Object)










---Initialises the hand tool class.
function HandTool.init()

    -- Call the init function for all specialisations that have the function.
    for name, spec in pairs(g_handToolSpecializationManager:getSpecializations()) do
        local classObj = ClassUtil.getClassObject(spec.className)
        if classObj == nil or rawget(classObj, "init") == nil then
            continue
        end

        classObj.init()
    end
end


---Post-initialises the hand tool class.
function HandTool.postInit()
end


---Registers xml paths within the hand tool schema.
function HandTool.registerXMLPaths()

    -- Create the schema.
    local xmlSchema = XMLSchema.new("handTool")
    HandTool.xmlSchema = xmlSchema

    g_storeManager:addSpeciesXMLSchema(StoreSpecies.HANDTOOL, HandTool.xmlSchema)
    g_handToolTypeManager:setXMLSchema(HandTool.xmlSchema)

    HandTool.xmlSchemaSounds = XMLSchema.new("handTool_sounds")
    HandTool.xmlSchemaSounds:setRootNodeName("sounds")
    HandTool.xmlSchema:addSubSchema(HandTool.xmlSchemaSounds, "sounds")

    -- Register store paths.
    StoreManager.registerStoreDataXMLPaths(xmlSchema, "handTool")
    I3DUtil.registerI3dMappingXMLPaths(xmlSchema, "handTool")

    xmlSchema:register(XMLValueType.STRING, "handTool.annotation", "Annotation", nil, true)

    -- Register base node.
    xmlSchema:register(XMLValueType.BOOL,       "handTool.base#canCrouch", "If the player can crouch while holding this tool", true, false)
    xmlSchema:register(XMLValueType.BOOL,       "handTool.base#mustBeHeld", "True if this tool must be held, and cannot be put away; false otherwise", false, false)
    xmlSchema:register(XMLValueType.BOOL,       "handTool.base#canBeSaved", "True if this tool can be saved; false otherwise", "Defaults to true, so that the tool will be saved", false)
    xmlSchema:register(XMLValueType.BOOL,       "handTool.base#canBeDropped", "True if this tool can be dropped to inventory", "Defaults to true, so that the tool will be dropped", false)
    xmlSchema:register(XMLValueType.FLOAT,      "handTool.base#runMultiplier", "The amount of run speed the player gains while running with this tool", true, false)
    xmlSchema:register(XMLValueType.FLOAT,      "handTool.base#walkMultiplier", "The amount of walk speed the player gains while walking with this tool", true, false)
    xmlSchema:register(XMLValueType.L10N_STRING,"handTool.base.actions#activate", "The text displayed for activating the tool", nil, false)
    xmlSchema:register(XMLValueType.STRING,     "handTool.base.filename", "Hand tool i3d file", nil, false)
    xmlSchema:register(XMLValueType.L10N_STRING,"handTool.base.typeDesc", "Hand tool name localization string", nil, false)
    xmlSchema:register(XMLValueType.STRING,     "handTool.base.sounds#filename", "The filename of the xml file defining the sounds of the tool", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.graphics#node", "The node containing all the graphical nodes of the tool", nil, false)
    xmlSchema:register(XMLValueType.BOOL,       "handTool.base.graphics#lockFirstPerson", "True if first person mode should be forced, false for third person. A lack of this attribute does not lock the perspective at all", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.handNode#node", "The node used to position the hand tool when held in third person", nil, false)
    xmlSchema:register(XMLValueType.BOOL,       "handTool.base.handNode#useLeftHand", "If the handtool should be attached to player left hand", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.firstPersonNode#node", "The node used to position the hand tool when held in first person", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.carried#targetNode", "The node of the player character that the tool is attached to when not held", nil, false)
    xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.base.carried#node", "The node used to position the hand tool when not held", nil, false)
    xmlSchema:register(XMLValueType.FLOAT, "handTool.base#mass", "Mass in kilograms", nil, false)

    -- Register root node attributes.
    xmlSchema:register(XMLValueType.STRING, "handTool#type", "The specialisation type of the hand tool", nil, true)
    xmlSchema:registerAutoCompletionDataSource("handTool#type", "$dataS/handToolTypes.xml", "handToolTypes.type#name")

    -- Register all loaded specialisations.
    for _, specialisation in pairs(g_handToolSpecializationManager:getSpecializations()) do
        local specialisationClass = ClassUtil.getClassObject(specialisation.className)
        if specialisationClass.registerXMLPaths then
            specialisationClass.registerXMLPaths(xmlSchema)
            xmlSchema:setXMLSpecializationType()
        end
    end
end


---Registers all node paths used for the savegame xml file.
-- @param XMLSchema savegameXMLSchema The schema used for the savegame hand tools.
function HandTool.registerSavegameXMLPaths(savegameXMLSchema)
    local handToolBaseKey = "handTools.handTool(?)"

    savegameXMLSchema:register(XMLValueType.STRING, handToolBaseKey .. "#filename", "The filename of the tool xml file", nil, true)
    savegameXMLSchema:register(XMLValueType.STRING, handToolBaseKey .. "#modName", "Name of mod")
    savegameXMLSchema:register(XMLValueType.STRING, handToolBaseKey .. "#uniqueId", "The unique id of the hand tool within the savegame", nil, true)
    savegameXMLSchema:register(XMLValueType.INT, handToolBaseKey .. "#farmId", "The id of the farm owning the tool", nil, true)
    savegameXMLSchema:register(XMLValueType.FLOAT, handToolBaseKey .. "#age", "The age of the hand tool", nil, true)
    savegameXMLSchema:register(XMLValueType.FLOAT, handToolBaseKey .. "#price", "The price of the hand tool", nil, true)
    savegameXMLSchema:register(XMLValueType.STRING, handToolBaseKey .. ".holder#uniqueId", "Last holder", nil, true)

    -- Register all loaded specialisations.
    for _, specialisation in pairs(g_handToolSpecializationManager:getSpecializations()) do
        local specialisationClass = ClassUtil.getClassObject(specialisation.className)
        if specialisationClass.registerSavegameXMLPaths then
            specialisationClass.registerSavegameXMLPaths(savegameXMLSchema, handToolBaseKey)
        end
    end
end































---Registers all specialization events to the given hand tool type.
-- @param table handToolType The specialisation type to which the functions are registered.
function HandTool.registerEvents(handToolType)
    SpecializationUtil.registerEvent(handToolType, "onPreLoad")
    SpecializationUtil.registerEvent(handToolType, "onLoad")
    SpecializationUtil.registerEvent(handToolType, "onPostLoad")
    SpecializationUtil.registerEvent(handToolType, "onLoadFinished")
    SpecializationUtil.registerEvent(handToolType, "onDelete")
    SpecializationUtil.registerEvent(handToolType, "onSave")
    SpecializationUtil.registerEvent(handToolType, "onRegistered")
    SpecializationUtil.registerEvent(handToolType, "onWriteStream")
    SpecializationUtil.registerEvent(handToolType, "onReadStream")
    SpecializationUtil.registerEvent(handToolType, "onWriteUpdateStream")
    SpecializationUtil.registerEvent(handToolType, "onReadUpdateStream")
    SpecializationUtil.registerEvent(handToolType, "onPreUpdate")
    SpecializationUtil.registerEvent(handToolType, "onUpdate")
    SpecializationUtil.registerEvent(handToolType, "onPostUpdate")
    SpecializationUtil.registerEvent(handToolType, "onUpdateTick")
    SpecializationUtil.registerEvent(handToolType, "onDraw")

    SpecializationUtil.registerEvent(handToolType, "onRegisterActionEvents")
    SpecializationUtil.registerEvent(handToolType, "onHandToolHolderChanged")
    SpecializationUtil.registerEvent(handToolType, "onHeldStart")
    SpecializationUtil.registerEvent(handToolType, "onHeldEnd")

    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerStyleChanged")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerShown")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerHidden")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerEnteredVehicle")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerExitedVehicle")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerChanged")
    SpecializationUtil.registerEvent(handToolType, "onCarryingPlayerPerspectiveSwitched")

    SpecializationUtil.registerEvent(handToolType, "onDebugDraw")
end


---Creates a new hand tool instance.
-- @param boolean isServer True if this instance is being created on the server.
-- @param boolean isClient True if this instance is being created on the client.
-- @param table? customMt
-- @return HandTool self The created instance.
function HandTool.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or HandTool_mt)

    self.finishedLoading = false
    self.isDeleted = false
    self.updateLoopIndex = -1
    self.sharedLoadRequestId = nil
    self.loadingState = HandToolLoadingState.OK
    self.loadingStep = SpecializationLoadStep.CREATED

    self.loadingTasks = {}
    self.readyForFinishLoading = false

    self.uniqueId = nil

    self.rootNode = nil
    self.graphicalNode = nil
    self.handNode = nil
    self.useLeftHand = false
    self.firstPersonNode = nil

    self.mass = 0

    self.actionEvents = {}

    self.carryingPlayer = nil
    self.isHeld = false

    self.holder = nil

    return self
end


---
function HandTool:setFilename(filename)
    self.configFileName = filename
    self.configFileNameClean = Utils.getFilenameInfo(filename, true)

    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(filename)
end


---
function HandTool:setType(typeDef)
    SpecializationUtil.initSpecializationsIntoTypeClass(g_handToolTypeManager, typeDef, self)
end


---
function HandTool:setLoadCallback(loadCallbackFunction, loadCallbackFunctionTarget, loadCallbackFunctionArguments)
    self.loadCallbackFunction = loadCallbackFunction
    self.loadCallbackFunctionTarget = loadCallbackFunctionTarget
    self.loadCallbackFunctionArguments = loadCallbackFunctionArguments
end





































































---
function HandTool:i3dFileLoaded(i3dNode, failedReason, arguments, i3dLoadingId)
    if i3dNode == 0 then
        self:setLoadingState(HandToolLoadingState.ERROR)
        Logging.xmlError(self.xmlFile, "Handtool i3d loading failed!")
        self:loadCallback()
        return
    end

    self.i3dNode = i3dNode
    setVisibility(i3dNode, false)

    self:loadFinished()
end


---
function HandTool:loadFinished()
    self:setLoadingState(HandToolLoadingState.OK)
    self:setLoadingStep(SpecializationLoadStep.LOAD)

    self.age = 0
    self:setOwnerFarmId(self.handToolLoadingData.ownerFarmId, true)
    self.mass = self.xmlFile:getValue("handTool.base#mass", 0)

    local savegame = self.savegame
    if savegame ~= nil then
        local uniqueId = savegame.xmlFile:getValue(savegame.key .. "#uniqueId", nil)
        if uniqueId ~= nil then
            self:setUniqueId(uniqueId)
        end

        -- Load this early: it used by the handtool load functions already
        local farmId = savegame.xmlFile:getValue(savegame.key .. "#farmId", AccessHandler.EVERYONE)
        if g_farmManager.mergedFarms ~= nil and g_farmManager.mergedFarms[farmId] ~= nil then
            farmId = g_farmManager.mergedFarms[farmId]
        end

        self:setOwnerFarmId(farmId, true)
    end

    self.price = self.handToolLoadingData.price
    if self.price == 0 or self.price == nil then
        local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
        self.price = StoreItemUtil.getDefaultPrice(storeItem, self.configurations)
    end

    self.typeDesc = self.xmlFile:getValue("handTool.base.typeDesc", "TypeDescription", self.customEnvironment, true)
    self.activateText = self.xmlFile:getValue("handTool.base.actions#activate", "Activate", self.customEnvironment, true)

    if self.i3dNode ~= nil then
        self.rootNode = getChildAt(self.i3dNode, 0)

        self.components = {}
        I3DUtil.loadI3DComponents(self.i3dNode, self.components)

        self.i3dMappings = {}
        I3DUtil.loadI3DMapping(self.xmlFile, "handTool", self.rootLevelNodes, self.i3dMappings)

        for _, component in ipairs(self.components) do
            link(getRootNode(), component.node)
        end

        delete(self.i3dNode)
        self.i3dNode = nil

        self.graphicalNode = self.xmlFile:getValue("handTool.base.graphics#node", nil, self.components, self.i3dMappings)

        if self.graphicalNode == nil then
            Logging.xmlError(self.xmlFile, "Handtool is missing graphical node! Graphics will not work as intended!")
            self:setLoadingState(HandToolLoadingState.ERROR)
            self:loadCallback()
            return
        end

        self.graphicalNodeParent = getParent(self.graphicalNode)
        self.handNode = self.xmlFile:getValue("handTool.base.handNode#node", nil, self.components, self.i3dMappings)
        self.useLeftHand = self.xmlFile:getValue("handTool.base.handNode#useLeftHand", self.useLeftHand)
        self.firstPersonNode = self.xmlFile:getValue("handTool.base.firstPersonNode#node", nil, self.components, self.i3dMappings)
    end

    self.shouldLockFirstPerson = self.xmlFile:getValue("handTool.base.graphics#lockFirstPerson", nil)
    self.runMultiplier = self.xmlFile:getValue("handTool.base#runMultiplier", 1.0)
    self.walkMultiplier = self.xmlFile:getValue("handTool.base#walkMultiplier", 1.0)
    self.canCrouch = self.xmlFile:getValue("handTool.base#canCrouch", true)
    self.mustBeHeld = self.xmlFile:getValue("handTool.base#mustBeHeld", false)
    self.canBeSaved = self.xmlFile:getValue("handTool.base#canBeSaved", true)
    if not self.handToolLoadingData.isSaved then
        self.canBeSaved = false
    end

    self.canBeDropped = self.xmlFile:getValue("handTool.base#canBeDropped", true)
    if not self.handToolLoadingData.canBeDropped then
        self.canBeDropped = false
    end

    -- Load the sound properties.
    local soundsXMLFilename = self.xmlFile:getValue("handTool.base.sounds#filename", nil)
    soundsXMLFilename = Utils.getFilename(soundsXMLFilename, self.baseDirectory)
    self.externalSoundsFile = XMLFile.loadIfExists("TempExternalSounds", soundsXMLFilename, HandTool.xmlSchemaSounds)

    SpecializationUtil.raiseEvent(self, "onLoad", self.xmlFile, self.baseDirectory)
    if self.loadingState ~= HandToolLoadingState.OK then
        Logging.xmlError(self.xmlFile, "HandTool loading failed!")
        self:loadCallback()
        return
    end

    self:setLoadingStep(SpecializationLoadStep.POST_LOAD)

    SpecializationUtil.raiseEvent(self, "onPostLoad", self.savegame)

    if self.loadingState ~= HandToolLoadingState.OK then
        Logging.xmlError(self.xmlFile, "HandTool post-loading failed!")
        self:loadCallback()
        return
    end

    if savegame ~= nil then
        self.age = savegame.xmlFile:getValue(savegame.key.."#age", 0)
        self.price = savegame.xmlFile:getValue(savegame.key.."#price", self.price)
    end

    local mission = g_currentMission
    if mission ~= nil and mission.environment ~= nil then
        g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
    end

    if #self.loadingTasks == 0 then
        self:onFinishedLoading()
    else
        self.readyForFinishLoading = true
        self:setLoadingStep(SpecializationLoadStep.AWAIT_SUB_I3D)
    end
end


---Called after all specializations have finished loading, and handles finalising the load state and cleaning up any loading variables.
function HandTool:onFinishedLoading()
    self:setLoadingStep(SpecializationLoadStep.FINISHED)
    SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)

    -- if we are the server or in single player we don't need to be synchronized
    if self.isServer then
        self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
    end

    self.finishedLoading = true

    local mission = g_currentMission
    local handToolSystem = mission.handToolSystem
    if not handToolSystem:addHandTool(self) then
        Logging.xmlError(self.xmlFile, "Failed to register handTool!")
        self:setLoadingState(HandToolLoadingState.ERROR)
        self:loadCallback()
        return
    end

    if self.handToolLoadingData.isRegistered then
        self:register()
    end

    local holder = self.handToolLoadingData.holder
    if holder ~= nil then
        if holder:getCanPickupHandTool(self) then
            self.pendingHolder = holder
        end
    else
        local savegame = self.savegame
        if savegame ~= nil then
            self.pendingHolderUniqueId = savegame.xmlFile:getValue(savegame.key .. ".holder#uniqueId", nil)
        end
    end

    g_currentMission:addOwnedItem(self)

    self.savegame = nil
    self.handToolLoadingData = nil

    self.xmlFile:delete()
    self.xmlFile = nil

    -- Clean up the sounds file.
    if self.externalSoundsFile ~= nil then
        self.externalSoundsFile:delete()
        self.externalSoundsFile = nil
    end

    self:loadCallback()
end


---Creates a loading task in the loadingTasks table with the given target and returns it.
-- @param any target The id or reference used to track the loading task.
-- @return table task The created loading task.
function HandTool:createLoadingTask(target)
    return SpecializationUtil.createLoadingTask(self, target)
end


---Marks the given task as done, and calls onFinishedLoading, if readyForFinishLoading is true.
-- @param table task The task to mark as complete. Should be obtained from createLoadingTask.
function HandTool:finishLoadingTask(task)
    SpecializationUtil.finishLoadingTask(self, task)
end


---
function HandTool:setLoadingState(loadingState)
    if HandToolLoadingState.getName(loadingState) ~= nil then
        self.loadingState = loadingState
    else
        printCallstack()
        Logging.error("Invalid loading state '%s'!", loadingState)
    end
end


---Sets the loadingStep value of this handtool, logging an error if the given step is invalid.
-- @param SpecializationLoadStep loadingStep The loading step to set.
function HandTool:setLoadingStep(loadingStep)
    SpecializationUtil.setLoadingStep(self, loadingStep)
end


---Cleans up any resources the hand tool uses.
function HandTool:delete()
    if self.isDeleted then
        return
    end

    g_currentMission:removeOwnedItem(self)

    g_messageCenter:unsubscribeAll(self)

    local mission = g_currentMission
    local handToolSystem = mission.handToolSystem

    if self.holder ~= nil then
        self:setHolder(nil, true)
    end

    -- If an i3d file was loaded, release the id.
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end

    SpecializationUtil.raiseEvent(self, "onDelete")

    if self.rootNode ~= nil and entityExists(self.rootNode) then
        delete(self.rootNode)
        self.rootNode = nil
    end

    handToolSystem:removeHandTool(self)

    if self.externalSoundsFile ~= nil then
        self.externalSoundsFile:delete()
        self.externalSoundsFile = nil
    end

    HandTool:superClass().delete(self)

    self.isDeleted = true
end


---Writes the state of this tool to the network stream.
-- @param integer streamId The id of the stream to which to write.
-- @param Connection connection The connection to the specific client who will receive this tool data.
function HandTool:writeStream(streamId, connection)
    HandTool:superClass().writeStream(self, streamId, connection)

    streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
    streamWriteBool(streamId, self.canBeDropped)
end


---Reads the initial tool state from the server.
-- @param integer streamId The id of the stream from which to read.
-- @param Connection connection The connection to the server.
-- @param integer objectId The id of the tool object.
function HandTool:readStream(streamId, connection, objectId)
    HandTool:superClass().readStream(self, streamId, connection, objectId)

    local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
    local canBeDropped = streamReadBool(streamId)

    local data = HandToolLoadingData.new()
    data:setFilename(filename)
    data:setOwnerFarmId(self.ownerFarmId)
    data:setCanBeDropped(canBeDropped)

    local asyncCallbackFunction = function(_, handTool, loadingState)
        if loadingState == HandToolLoadingState.OK then
            g_client:onObjectFinishedAsyncLoading(handTool)
        else
            Logging.error("Failed to load handtool on client")
            printCallstack()
        end
    end

    data:loadHandToolOnClient(self, asyncCallbackFunction, nil)
end


---Called on server side when handTool is fully loaded on client side
-- @param integer streamId stream ID
-- @param table connection connection
function HandTool:postWriteStream(streamId, connection)
    local holder = self:getHolder()
    if streamWriteBool(streamId, holder ~= nil) then
        NetworkUtil.writeNodeObject(streamId, holder)
        streamWriteBool(streamId, self:getIsHeld())
    end

    SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
end


---Called on client side on join when the handTool was fully loaded
-- @param integer streamId stream ID
-- @param table connection connection
function HandTool:postReadStream(streamId, connection)
    if streamReadBool(streamId) then
        self.pendingHolderObjectId = NetworkUtil.readNodeObjectId(streamId)
        self.isHoldingPending = streamReadBool(streamId)
        self:raiseActive()
    end

    SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)

    self:setLoadingStep(SpecializationLoadStep.SYNCHRONIZED)
end


---Called on server side on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function HandTool:writeUpdateStream(streamId, connection, dirtyMask)
    SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
end


---Called on client side on update
-- @param integer streamId stream ID
-- @param table connection connection
function HandTool:readUpdateStream(streamId, timestamp, connection)
    SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
end


---
function HandTool:getNeedsSaving()
    return self.canBeSaved
end






---Saves this hand tool to the given savegame xml file under the given key.
-- @param XMLFile xmlFile The savegame xml file to save to (Handtools.xml).
-- @param string key The base key under which to create the hand tool node.
-- @param table usedModNames The collection of currently used mod names in the current game.
function HandTool:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key .. "#uniqueId", self.uniqueId)
    xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId() or -1)
    xmlFile:setValue(key .. "#age", self.age)

    if self.holder ~= nil then
        xmlFile:setValue(key .. ".holder#uniqueId", self.holder:getUniqueId())
    end

    for id, spec in pairs(self.specializations) do
        local name = self.specializationNames[id]

        if spec.saveToXMLFile ~= nil then
            spec.saveToXMLFile(self, xmlFile, key.."."..name, usedModNames)
        end
    end
end


---Gets this tool's unique id.
-- @return string uniqueId This tool's unique id.
function HandTool:getUniqueId()
    return self.uniqueId
end


---Sets this tool's unique id. Note that a hand tool's id should not be changed once it has been first set.
-- @param string uniqueId The unique id to use.
function HandTool:setUniqueId(uniqueId)
    --#debug Assert.isType(uniqueId, "string", "Hand tool unique id must be a string!")
    --#debug Assert.isNil(self.uniqueId, "Should not change a hand tool's unique id!")
    self.uniqueId = uniqueId
end


---
function HandTool:register(alreadySent)
    HandTool:superClass().register(self, alreadySent)

    SpecializationUtil.raiseEvent(self, "onRegistered", alreadySent)
end


---Gets the value representing the load state of this tool, where true means the tool has fully loaded and synchronised.
-- @return boolean hasLoaded True if the tool has fully loaded and synchronised; otherwise false.
function HandTool:getIsSynchronized()
    return self.loadingStep == SpecializationLoadStep.SYNCHRONIZED
end


































---Updates this hand tool as it is being held in the player's hands.
-- @param float dt Delta time in ms.
function HandTool:update(dt)
    if self.pendingHolder ~= nil then
        self:setHolder(self.pendingHolder)
        self.pendingHolder = nil
    end

    if self.pendingHolderObjectId ~= nil then
        local holder = NetworkUtil.getObject(self.pendingHolderObjectId)
        if holder ~= nil then
            if holder:getCanPickupHandTool(self) then
                self:setHolder(holder, true)

                if self.isHoldingPending and self.carryingPlayer ~= nil then
                    self.carryingPlayer:setCurrentHandTool(self, true)
                end
            end
            self.pendingHolderObjectId = nil
            self.isHoldingPending = nil
        end
        self:raiseActive()
    end

    if self.pendingHolderUniqueId ~= nil then
        local mission = g_currentMission
        local holder = mission:getObjectByUniqueId(self.pendingHolderUniqueId)
        if holder ~= nil then
            self:setHolder(holder)
            self.pendingHolderUniqueId = nil
        end
        self:raiseActive()
    end

    SpecializationUtil.raiseEvent(self, "onPreUpdate", dt)

    SpecializationUtil.raiseEvent(self, "onUpdate", dt)

    SpecializationUtil.raiseEvent(self, "onPostUpdate", dt)

    if self:getIsHeld() then
        local carryingPlayer = self:getCarryingPlayer()
        if carryingPlayer ~= nil and carryingPlayer:getIsControlled() then
            self:raiseActive()
        end
    end
end






---Fired when the player starts holding this hand tool in their hands.
function HandTool:startHolding()
    --#debug Logging.devInfo("HandTool:startHolding for hand tool %q (%s)", self.configFileName, self.uniqueId)

    self:raiseActive()

    -- Begin getting the tool out.
    self.isHoldStarting = true

    local player = self.carryingPlayer

    -- Handle locking the player's perspective if needed.
    if player ~= nil and player:getForceHandToolFirstPerson() and self.shouldLockFirstPerson ~= nil then
        self.wasInFirstPerson = player.camera.isFirstPerson
        if self.shouldLockFirstPerson then
            player.camera:lockFirstPersonMode()
        else
            player.camera:lockThirdPersonMode()
        end
    end

    self.isHeld = true

    -- Attach the tool to the player.
    self:attachTool()

    -- Raise the held start event.
    SpecializationUtil.raiseEvent(self, "onHeldStart", player)

    self:clearActionEvents()
    if player ~= nil and player.isOwner then
        self:registerActionEvents()
    end

    -- Finish getting the tool out.
    self.isHoldStarting = false
end


---Fired when the player stops holding this hand tool in their hands.
-- @param Player player The player who was holding this tool.
function HandTool:stopHolding()
    --#debug Logging.devInfo("HandTool:stopHolding for hand tool %q (%s)", self.configFileName, self.uniqueId)

    -- Begin putting the tool away.
    self.isHoldEnding = true

    local carryingPlayer = self:getCarryingPlayer()

    -- Handle unlocking and resetting the perspective, if needed.
    if carryingPlayer ~= nil and carryingPlayer:getForceHandToolFirstPerson() and self.shouldLockFirstPerson ~= nil then
        carryingPlayer.camera:unlockSwitching()
        carryingPlayer.camera:switchToPerspective(self.wasInFirstPerson)
    end

    self.isHeld = false

    -- Detach the tool from the player.
    self:detachTool()

    -- Raise the held end event.
    SpecializationUtil.raiseEvent(self, "onHeldEnd")

    -- Unbind any bound controls.
    self:clearActionEvents()
    if carryingPlayer.isOwner then
        self:registerActionEvents()
    end

    -- Stop putting the tool away.
    self.isHoldEnding = false
end


---Gets the value representing if this tool is currently carried by a player.
-- @return boolean isCarried True if this tool is in a player's inventory; otherwise false. Note that getIsHeld can also be true; this value is just for if the player has the tool on them.
function HandTool:getIsCarried()
    return self.carryingPlayer ~= nil
end


---Sets the player who is currently carrying this hand tool.
-- @param Player player the player
function HandTool:setCarryingPlayer(player)
    --#debug Logging.devInfo("HandTool:setCarryingPlayer '%s' for hand tool %q (%s)", player, self.configFileName, self.uniqueId)
    local lastCarryingPlayer = self.carryingPlayer
    self.carryingPlayer = player

    SpecializationUtil.raiseEvent(self, "onCarryingPlayerChanged", player, lastCarryingPlayer)

    self:clearActionEvents()
    if player ~= nil and player.isOwner then
        self:registerActionEvents()
    end
end


---Gets the player who is currently carrying this hand tool.
-- @return Player player The player who has this hand tool in their inventory.
function HandTool:getCarryingPlayer()
    return self.carryingPlayer
end


---Called if period changed
function HandTool:periodChanged()
    self.age = self.age + 1
end


---Returns price
-- @param float price price
function HandTool:getPrice()
    return self.price
end


---Get sell price
-- @return float sellPrice sell price
function HandTool:getSellPrice()
    local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
    return HandTool.calculateSellPrice(storeItem, self.age, self:getPrice())
end






---Calculate price of vehicle given a bunch of parameters
function HandTool.calculateSellPrice(storeItem, age, price)
    local ageInYears = age / Environment.PERIODS_IN_YEAR
    local ageFactor = math.min(-0.1 * math.log(ageInYears) + 0.75, 0.8)

    return math.max(price * ageFactor, price * 0.03)
end















---Gets the value representing if this tool is currently equipped (held) by a player.
-- @return boolean isHeld True if this tool is carried and currently used by the player; otherwise false.
function HandTool:getIsHeld()

    -- If the tool is not carried at all, it cannot be held, so return false.
    if not self:getIsCarried() then
        return false
    end

    return self.isHeld
end



































































---Attaches the tool to its carrying player, based on the player's camera perspective.
function HandTool:attachTool()

    -- Do nothing if the tool is not being held. A player is needed to attach to.
    if not self:getIsHeld() then
        return
    end

    -- Handle attaching the tool to the player or to their camera, based on the perspective.
    -- Note that only the client player can hold a tool in first person, the tool is always in the hand when viewed from another player's perspective.
    if self.carryingPlayer:getForceHandToolFirstPerson() and self.carryingPlayer.camera.isFirstPerson then
        self:attachToolToCamera()
    else
        self:attachToolToHand()
    end
end


---Detaches the tool from its carrying player, leaving it unlinked.
function HandTool:detachTool()
    -- If there is no root node to detach, do nothing.
    if self.rootNode == nil then
        return
    end

    -- Unlink the root node completely.
    unlink(self.rootNode)
end


---Attaches the tool to the player's hand, using the hand node as an offset.
function HandTool:attachToolToHand()

    -- If the tool is not held, or the graphics of the player are invalid, do nothing.
    if not self:getIsHeld() or self.carryingPlayer.graphicsComponent == nil or self.carryingPlayer.graphicsComponent.model == nil then
        Logging.error("Invalid player configuration or tool is not held, cannot equip hand tool")
        return false
    end

    -- If there is no root node, do nothing.
    if self.rootNode == nil then
        return false
    end

    -- Get the player's model.
    local playerModel = self.carryingPlayer.graphicsComponent.model

    -- If there is no hand node, log a warning, zero the offset, and return.
    if self.handNode == nil then
        Logging.warning("Handtool %s is missing hand node, using no offset!", self.typeName)
        link(playerModel.thirdPersonRightHandNode, self.rootNode)
        setTranslation(self.rootNode, 0, 0, 0)
        setRotation(self.rootNode, 0, 0, 0)
        return false
    end

    local handNode = playerModel.thirdPersonRightHandNode
    if self.useLeftHand then
        handNode = playerModel.thirdPersonLeftHandNode
    end

    -- Link the tool to the hand and transform it so that the tool's hand node matches the transform of the player's hand node.
    HandToolUtil.linkAndTransformRelativeToParent(self.rootNode, self.handNode, handNode)

    return true
end


---Attaches the tool directly to the player's camera, using the first person node as an offset.
function HandTool:attachToolToCamera()

    -- If the tool is not held or has no root node, do nothing.
    if not self:getIsHeld() or self.rootNode == nil then
        return
    end

    -- If there is no first person node, attach the root node directly to the camera with no offset, log a warning, and do nothing more.
    if self.firstPersonNode == nil then
        Logging.warning("Handtool %s is missing first person node, using no offset!", self.typeName)
        link(self:getCarryingPlayer().camera.pitchNode, self.rootNode)
        setTranslation(self.rootNode, 0, 0, 0)
        setRotation(self.rootNode, 0, 0, 0)
        return
    end

    -- Link the root node to the camera's pitch node, so that the first person node is centred on it.
    HandToolUtil.linkAndTransformRelativeToParent(self.rootNode, self.firstPersonNode, self:getCarryingPlayer().camera.pitchNode)
end













---Unbinds and removes all action events related to this tool.
-- @param boolean? clearCarriedActionEvents If this is true, the carried action events will be cleared instead.
function HandTool:clearActionEvents(clearCarriedActionEvents)
    g_inputBinding:beginActionEventsModification(PlayerInputComponent.INPUT_CONTEXT_NAME)
    for inputAction, actionEvent in pairs(self.actionEvents) do
        g_inputBinding:removeActionEvent(actionEvent.actionEventId)
        self.actionEvents[inputAction] = nil
    end
    g_inputBinding:endActionEventsModification()
end
