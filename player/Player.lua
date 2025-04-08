




















---A player, either local or replicated from the server.
local Player_mt = Class(Player, Object)














































































































































































---Creates a player instance for use on the server. Automatically calls the load function.
-- @param boolean isClient Is true if this player exists on the client.
-- @param boolean isOwner Is true if this player is the controlling player.
-- @param Connection connection The connection of this player to the target client.
-- @param integer userId The id of the player's user.
-- @param integer farmId The id of the player's farm.
-- @param UserManager userManager The user manager of the world.
-- @return Player instance The created instance.
function Player.createServerInstance(isClient, isOwner, connection, userId, farmId, userManager)

    -- Create the player.
    local self = Player.new(true, isClient)

    -- Set the farm and user ids.
    self.farmId = farmId
    self.userId = userId
    self:setUniqueUserId(userManager:getUniqueUserIdByUserId(userId))

    self.walkDistance = 0
    self.animUpdateTime = 0

    self.allowPlayerPickUp = Platform.allowPlayerPickUp

    self.debugFlightMode = false
    self.debugFlightCoolDown = 0

    self.requestedFieldData = false

    -- Load, setting up the player in the scene.
    self:initialise(connection, isOwner)

    -- Get the player data for this player, and load using it.
    local mission = g_currentMission
    local playerData = mission.playerSystem:getPlayerDataByUniqueId(self.uniqueUserId)

    self:load(playerData)

    local style
    local isDefaultStyle = false
    if playerData ~= nil then
        style = playerData.style
    end

    if style == nil then
        local lastPlayerStyle = g_gameSettings.lastPlayerStyle
        if isOwner and lastPlayerStyle ~= nil and lastPlayerStyle:isValid() then
            style = PlayerStyle.defaultStyle()
            style:copyFrom(lastPlayerStyle)
        end

        if style == nil then
            style = PlayerStyle.defaultStyle()
            isDefaultStyle = true
        end
    end

    self:setStyleAsync(style, isDefaultStyle, nil, true)

    -- Register the player, syncing it to the clients.
    self:register(false)

    -- Return the created instance.
    return self
end


---Creates a player object. This is not called explicitly, but rather dynamically via the base Object.new().
-- @param boolean isServer Is true if this player exists on the server.
-- @param boolean isClient Is true if this player exists on the client.
-- @return Player self The created instance.
function Player.new(isServer, isClient)

    -- Create the instance.
    local self = Object.new(isServer, isClient, Player_mt)

    --#debug self:debugLog(Player.DEBUG_DISPLAY_FLAG.INITIALISATION, "new(isServer: %s isClient: %s)", isServer, isClient)

    -- The id of this player's associated user.
    self.userId = nil

    self.isDefaultStyle = true

    -- The filename of the player's data configuration xml file.
    self.filename = nil

    -- The connection to the server/client. This starts as nil, but will be initialised in load().
    self.connection = nil

    -- The network component. Just like the connection, this starts as nil but may be created in load().
    self.networkComponent = nil

    self.positionalInterpolator = nil

    -- The vehicle in which the player will spawn.
    self.spawnVehicle = nil

    -- The position at which the player should spawn. If this is nil, the player will spawn at the spawn point of the map.
    self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ = nil, nil, nil

    -- The yaw (rotation around the y axis) that the player should have when the spawn.
    self.spawnYaw = nil

    -- The base player dirty flag.
    self.dirtyFlag = self:getNextDirtyFlag()

    -- If this player is the player who is being controlled by the client.
    -- On a dedicated server, this will be false on every player.
    -- In all other cases, it will be true on exactly one player.
    -- On a locally hosted server, this will be true on the host.
    self.isOwner = false

    -- If this player is currently able to control themselves.
    self.isControlled = false

    -- If this server is ignoring what the server is saying, and keeping itself hidden or shown.
    -- There are limits to what the client can do in this state, it's mainly used to hide the player locally while in the wardrobe, and have them still be shown to other players.
    self.isLocallyControlled = nil

    -- The farm id, starting as a spectator.
    self.farmId = FarmManager.SPECTATOR_FARM_ID

    self.stateEvents = {}
    self:registerStateEvents()

    self.stateFunctions = {}
    self:registerStateFunctions()

    -- The player's hotspot, used to display them on the map.
    self.playerHotspot = PlayerHotspot.new()

    -- The player's hands. These are technically a tool that cannot be changed and save no data.
    self.hands = nil

    self.carriedHandTools = {}
    self.currentHandTool = nil
    self.currentHandToolIndex = 0

    self.lastHandToolIndex = 0

    -- The maximum weight of hand tools that the player can carry.
    self.maximumHandToolCarryMass = Player.MAX_HAND_TOOL_CARRY_MASS

    -- Create the input component.
    self.inputComponent = nil

    -- The player's camera. Only exists on the owning player.
    self.camera = nil

    -- The player's targeter. Only exists on the owning player.
    self.targeter = nil

    -- Create the graphics component.
    self.graphicsComponent = HumanGraphicsComponent.new()
    self.graphicsState = PlayerGraphicsState.new()

    -- Create the CCT.
    self.capsuleController = PlayerCCT.new()

    -- Create the mover.
    self.mover = PlayerMover.new(self)

    -- Create the state machine.
    self.stateMachine = PlayerStateMachine.new(self)
    self.stateMachine:createStateIndexNameMapping()

    self.hudUpdater = PlayerHUDUpdater.new()

    self.debugFunctionId = nil

    self.isFirstPerson = true
    self.isHoldingChainsaw = false
    self.isCutting = false
    self.isVerticalCut = true

    self.toggleFlightModeCommand = nil
    self.toggleSuperSpeedCommand = nil

    self.isStrafeWalkMode = false
    self.forceHandToolFirstPerson = false

    self.isFlashlightActive = false

    -- Return the created instance.
    return self
end


---Loads and sets up the player in the scene.
-- @param Connection connection The connection to the server or client.
-- @param boolean isOwner True if this player is being controlled by the client; otherwise false.
function Player:initialise(connection, isOwner)

    --#debug self:debugLog(Player.DEBUG_DISPLAY_FLAG.INITIALISATION, "initialise(isOwner: %s)", isOwner)

    -- Set the connection.
    self.connection = connection

    -- Set the owner status.
    self.isOwner = isOwner == true

    if self.isOwner or self.isClient then
        g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_LOADED, Player.onStartMission, self)
    end

    if self.isServer then
        g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, Player.playerFarmChanged, self)
    end

    -- Remote players (not on the server, and not being controlled by the player) are fully driven by the network, so their state machine is passive.
    self.stateMachine.states.onFoot:setIsPassive(not self.isOwner)

    -- Create the root node and place it into the scene.
    self.rootNode = createTransformGroup("Player Root")
    link(getRootNode(), self.rootNode)

    -- Initialise the CCT.
    self.capsuleController:setMass(self.graphicsComponent.model:getMass())
    self.capsuleController:setRootNode(self.rootNode)
    self.capsuleController:rebuild()

    g_currentMission:addNodeObject(self.rootNode, self)

    -- If the player is the owner, set up their camera, input, and targeter.
    if self.isOwner then
        -- Create the components.
        self.inputComponent = PlayerInputComponent.new(self)
        self.camera = PlayerCamera.new(self)
        self.targeter = PlayerTargeter.new(self)

        -- Initialise the input.
        self.inputComponent:registerActionEvents()

        -- Initialise the camera.
        self.camera:initialise()

        -- Add the hand tool holder as a target.
        HandToolUtil.addHandToolHolderTarget(self.targeter)
    else
        if self.isServer then
            self.positionalInterpolator = PlayerPositionalInterpolator.new(self, PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE)
        else
            self.positionalInterpolator = PlayerPositionalInterpolator.new(self, PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE)
        end
    end

    -- Set up hand tool events.
    self:addStateEvent(function(...)
        for i, handTool in ipairs(self.carriedHandTools) do
            handTool:setCarryingPlayerEnteredVehicle()
        end
    end, nil, "onEnterVehicle")

    self:addStateEvent(function(...)
        for i, handTool in ipairs(self.carriedHandTools) do
            handTool:setCarryingPlayerExitedVehicle()
        end
    end, nil, "onLeaveVehicle")

    -- Initialise the graphics.
    self.graphicsComponent:initialize()

    -- Initialise the mover.
    self.mover:initialise()

    -- Create the network component depending on if this player is the server or client.
    -- If this player is on the server, it uses a server component. Even if the player is also a client (locally hosting) they do not need a client component as they already see the world as it is.
    if self.isServer then
        self.networkComponent = PlayerServerNetworkComponent.new(self)
    -- Otherwise; the player uses a client networking component.
    else
        -- If the player is the owner, they require networking to reconcile their position.
        if isOwner then
            self.networkComponent = PlayerLocalNetworkComponent.new(self)
        -- Otherwise; they require a component to smoothly position the player in the world. This is for the other players that a player will see on a server.
        else
            self.networkComponent = PlayerRemoteNetworkComponent.new(self)
        end
    end

    self.isStrafeWalkMode = not self.isOwner
    self.forceHandToolFirstPerson = self.isOwner

    -- Position the player away from everything.
    self.mover:setPosition(0, -200, 0, true)

    -- If this player is controlled by the user, register their console commands.
    if self.isOwner then
        if g_addTestCommands then
            addConsoleCommand("gsTipToTrigger", "Tips a fillType into a trigger", "consoleCommandTipToTrigger", self, "fillTypeName; amount")
            addConsoleCommand("gsPlayerToggleStrafeWalkMode", "Toggles strafe walk mode", "consoleCommandToggleStrafeWalkMode", self)
            addConsoleCommand("gsPlayerToggleForceHandToolFirstPerson", "Toggle the force handtool mode", "consoleCommandToggleForceHandToolFirstPerson", self)
--             addConsoleCommand("gsPlayerIKChainsReload", "Reloads player IKChains", "Player.consoleCommandReloadIKChains", nil)
--             addConsoleCommand("gsPlayerRaycastDebug", "Enables/disables player pickup raycast debug information", "consoleCommandTogglePickupRaycastDebug", self)
        end
    end
end


---Loads the player's model, sets up their style, and performs any other setup that requires the player's data.
-- @param table? playerData The save data of the player, or nil if they are new. Only used when loading via createServerInstance on the server.
function Player:load(playerData)
    local mission = g_currentMission

    --#debug self:debugLog(Player.DEBUG_DISPLAY_FLAG.INITIALISATION, "load(playerData: %s)", playerData)

    -- Load any console commands.
    self:createConsoleCommands()

    if self.isServer then
        -- Handle the spawn data of the player, loading it from the player data.
        if playerData ~= nil then
            self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ = playerData.spawnPositionX, playerData.spawnPositionY, playerData.spawnPositionZ
            self.spawnYaw = playerData.spawnYaw
            self.spawnVehicle = self:resolveSpawnVehicle(playerData.spawnVehicleUniqueId)

            self.pendingHandToolUniqueIds = {}
            for _, handToolUniqueId in ipairs(playerData.handToolUniqueIds) do
                table.insert(self.pendingHandToolUniqueIds, handToolUniqueId)
            end
        end

        self.pendingStartHandTools = {}
        local handData = HandToolLoadingData.new()
        handData:setFilename("data/handTools/hands.xml")
        handData:setOwnerFarmId(self.farmId)
        handData:setIsSaved(false)
        handData:setCanBeDropped(false)
        self.pendingStartHandTools[handData] = true
        handData.areHands = true
        handData:load(self.onStartHandToolLoaded, self, handData)

        local flashlightData = HandToolLoadingData.new()
        flashlightData:setFilename("data/handTools/brandless/flashlight/flashlight.xml")
        flashlightData:setOwnerFarmId(self.farmId)
        flashlightData:setIsSaved(false)
        flashlightData:setCanBeDropped(false)
        flashlightData:setHolder(self)
        self.pendingStartHandTools[flashlightData] = true
        flashlightData:load(self.onStartHandToolLoaded, self, flashlightData)

        local startHandTools = mission.handToolSystem:getStartingHandTools()
        for _, xmlFilename in ipairs(startHandTools) do
            local data = HandToolLoadingData.new()
            data:setFilename(xmlFilename)
            data:setOwnerFarmId(self.farmId)
            data:setHolder(self)
            data:setIsSaved(false)
            data:setCanBeDropped(false)
            self.pendingStartHandTools[data] = true
            data:load(self.onStartHandToolLoaded, self, data)
        end

        self.mover:teleportToSpawnPoint()
    end

    -- Rebuild the CCT after setting the style, as it may have changed.
    self.capsuleController:rebuild()

    -- Load the mover.
    self.mover:onPlayerLoad()

    -- Allow the player's input component to set up anything after the player has loaded.
    if self.isOwner then

        mission:addDrawable(self)

        self.inputComponent:onPlayerLoad()
        self.capsuleController:onPlayerLoad(self)
        self.camera:onPlayerLoad()
    else
        self.mover:disablePhysics()
    end

    -- Now that the player has been loaded, add them to the player system. This deletes their unloaded data, as it now exists via this instance.
    mission.playerSystem:addPlayer(self)

    -- As other players can only join once the mission has already started, the start mission function must be called manually, after everything else has loaded.
    if self.isServer and not self.isOwner then
        self:onStartMission()
    end
end


---Handles the deletion of the player.
function Player:delete()
    local currentVehicle = self:getCurrentVehicle()
    if currentVehicle ~= nil and not currentVehicle:getIsBeingDeleted() then
        local seatIndex
        if currentVehicle.getPassengerSeatIndexByPlayer ~= nil then
            seatIndex = currentVehicle:getPassengerSeatIndexByPlayer(self.userId)
        end

        if seatIndex == nil then
            currentVehicle:onPlayerLeaveVehicle()
        else
            currentVehicle:leavePassengerSeat(self.isOwner, seatIndex)
        end
    end

    local mission = g_currentMission

    if self.pendingStartHandTools ~= nil then
        for loadingData in pairs(self.pendingStartHandTools) do
            loadingData:cancelLoading()
        end
    end

    if self.swsObstacle ~= nil then
        mission.shallowWaterSimulation:removeObstacle(self.swsObstacle)
        self.swsObstacle = nil
    end

    if mission.aiSystem ~= nil then
        mission.aiSystem:removeObstacle(self.rootNode)
    end

    -- Unbind all message listeners.
    g_messageCenter:unsubscribeAll(self)

    if self.hudUpdater ~= nil then
        self.hudUpdater:delete()
        self.hudUpdater = nil
    end

    -- If this player is the client's player, unbind the controls and remove the console commands.
    if self.isOwner then
        mission:removeDrawable(self)
        self.inputComponent:unregisterActionEvents()
        self.inputComponent:stopListeningForBindingChanges()

        removeConsoleCommand("gsPlayerDebugFlagToggle")
        removeConsoleCommand("gsPlayerDebugFlagVerbosityToggle")
        removeConsoleCommand("gsPlayerFlightToggle")
    end

    mission:removeMapHotspot(self.playerHotspot)
    self.playerHotspot:delete()

    self.stateMachine:delete()

    -- Delete the hands tool.
    if self.hands ~= nil then
        self.hands:delete()
    end

    for i = #self.carriedHandTools, 1, -1 do
        local handTool = self.carriedHandTools[i]
        if handTool.isPlayerStartHandTool then
            handTool:delete()
        else
            handTool:setHolder(nil, true)
        end
    end

    -- Delete the components.
    self.graphicsComponent:delete()
    self.mover:delete()
    self.capsuleController:delete()
    if self.camera ~= nil then
        self.camera:delete()
    end

    g_currentMission:removeNodeObject(self.rootNode)

    -- Delete the root node.
    delete(self.rootNode)

    self.isDeleted = true

    -- Call the base object delete function.
    Player:superClass().delete(self)
end


---Writes the state of this player to the network stream.
-- @param integer streamId The id of the stream to which to write.
-- @param Connection connection The connection to the specific client who will receive this player data.
function Player:writeStream(streamId, connection)
    --#debug Assert.isTrue(self.isServer, "Non-server should never writeStream for the player!")
    Player:superClass().writeStream(self, streamId, connection)

    local isOwner = connection == self.connection
    streamWriteBool(streamId, isOwner)

    local x, y, z = self.capsuleController:getPosition()
    streamWriteFloat32(streamId, x)
    streamWriteFloat32(streamId, y)
    streamWriteFloat32(streamId, z)

    streamWriteBool(streamId, self.isControlled)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    User.streamWriteUserId(streamId, self.userId)

    if streamWriteBool(streamId, not self.isDefaultStyle) then
        local currentStyle = self.graphicsComponent:getStyle()
        currentStyle:writeStream(streamId, connection)
    end

    if streamWriteBool(streamId, self.hands ~= nil) then
        NetworkUtil.writeNodeObject(streamId, self.hands)
    end
end


---Reads the initial player state from the server.
-- @param integer streamId The id of the stream from which to read.
-- @param Connection connection The connection to the server.
-- @param integer objectId The id of the player object.
function Player:readStream(streamId, connection, objectId)
    --#debug Assert.isFalse(self.isServer, "Server should never readStream for the player!")
    Player:superClass().readStream(self, streamId, connection)

    local isOwner = streamReadBool(streamId)
    local x = streamReadFloat32(streamId)
    local y = streamReadFloat32(streamId)
    local z = streamReadFloat32(streamId)
    local isControlled = streamReadBool(streamId)

    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.userId = User.streamReadUserId(streamId)

    self:initialise(connection, isOwner)

    local style
    if streamReadBool(streamId) then
        style = self.graphicsComponent:getStyle()
        style:readStream(streamId, connection)
    else
        style = PlayerStyle.defaultStyle()
    end

    if streamReadBool(streamId) then
        self.pendingHandsId = NetworkUtil.readNodeObjectId(streamId)
    end

    self:load(nil)
    self:setStyleAsync(style, false, nil, true)

    self:teleportTo(x, y, z, true, true)

    -- By default, self.isControlled is false. If the server says that this player is controlled, then call the show function so that it may fully initialise.
    if isControlled then
        self:show()
    else
        self:hide()
    end
end


---Writes to the outgoing update stream.
-- @param integer streamId The id of the stream to which to write.
-- @param Connection connection The connection to the client or server receiving the data.
-- @param integer dirtyMask The current dirty mask.
function Player:writeUpdateStream(streamId, connection, dirtyMask)

    -- If this player has a network component, allow it to write to the stream.
    if self.networkComponent then
        self.networkComponent:writeUpdateStream(streamId, connection, dirtyMask)
    end
end


---Reads the incoming update stream.
-- @param integer streamId The id of the stream from which to read.
-- @param integer timestamp The current timestamp for synchronisation purposes.
-- @param Connection connection The connection to the client or server sending the data.
function Player:readUpdateStream(streamId, timestamp, connection)

    -- If this player has a network component, allow it to read from the stream.
    if self.networkComponent then
        self.networkComponent:readUpdateStream(streamId, connection, timestamp)
    end
end




















---Updates the player and their components every frame.
-- @param float dt delta time in ms
function Player:update(dt)
    if self.pendingHandsId ~= nil then
        local hands = NetworkUtil.getObject(self.pendingHandsId)
        if hands ~= nil then
            self.hands = hands
            self.pendingHandsId = nil
        end
    end

    if self.pendingHandToolUniqueIds ~= nil then
        local mission = g_currentMission
        local handToolSystem = mission.handToolSystem
        for _, handToolUniqueId in ipairs(self.pendingHandToolUniqueIds) do
            local handTool = handToolSystem:getHandToolByUniqueId(handToolUniqueId)
            if handTool ~= nil and handTool:getHolder() == nil then
                handTool:setHolder(self, false)
            end
        end
        self.pendingHandToolUniqueIds = nil
    end

--#profile     RemoteProfiler.zoneBeginN("Player-HudUpdater")
    -- Always raise the player as active so they can always update.
    if self.isControlled then
        self:raiseActive()

        if self.isOwner and self.hudUpdater ~= nil then
            local x,y,z = self:getPosition()
            self.hudUpdater:update(dt, x,y,z, self:getYaw())
        end
    end
--#profile     RemoteProfiler.zoneEnd()

--#profile     RemoteProfiler.zoneBeginN("Player-StateMachine")
    -- Update the state machine.
    self.stateMachine:update(dt)
--#profile     RemoteProfiler.zoneEnd()
end


---Network tick update.
-- @param float dt Delta time in ms.
function Player:updateTick(dt)

    if self.stateMachine.currentState.updateTick ~= nil then
        self.stateMachine.currentState:updateTick(dt)
    end
end









































































































































---Gets this player's unique user id.
-- @return string? uniqueUserId The unique user id of the player, or nil if it has not yet been set.
function Player:getUniqueUserId()
    return self.uniqueUserId
end






---Sets this player's unique user id. This should only be done once.
-- @param string uniqueUserId The unique user id of the player.
function Player:setUniqueUserId(uniqueUserId)
    --#debug Assert.isType(uniqueUserId, "string")
    --#debug Assert.isStringNotNilOrEmpty(uniqueUserId)

    -- Ensure the unique id will not be changed once it is no longer nil.
    if not string.isNilOrWhitespace(self.uniqueUserId) and uniqueUserId ~= self.uniqueUserId then
        Logging.error("Cannot change a player's unique id after it has been set!")
        return
    end

    -- Set the unique id.
    self.uniqueUserId = uniqueUserId
    --#debug self:debugLog(Player.DEBUG_DISPLAY_FLAG.INITIALISATION, "Set unique user id to %q", uniqueUserId)
end

























































---
function Player:onPickupHandTool(handTool)
    if handTool == nil then
        return false
    end

    table.addElement(self.carriedHandTools, handTool)
    handTool:setCarryingPlayer(self)

    return true
end


---
function Player:onDropHandTool(handTool)
    Logging.devInfo("Player.onDropHandTool: try dropping hand tool %q (%s) from player", handTool.configFileName, handTool.uniqueId)
    if handTool == nil then
        return
    end

    -- If the player is currently holding the given hand tool, stop holding it.
    if self.currentHandTool == handTool then
        self:setCurrentHandTool(nil, true)
    end

    self:setFlashlightIsActive(self.isFlashlightActive, true)

    local success = table.removeElement(self.carriedHandTools, handTool)
    if not success then
        Logging.error("Player.onDropHandTool: Could not remove hand tool %q (%s) from player, as it was not carried by the player!", handTool.configFileName, handTool.uniqueId)
        printCallstack()
        return
    end

    handTool:setCarryingPlayer(nil)
end


---
function Player:getCanPickupHandTool(handTool)
    if handTool == nil then
        return false
    end

    if handTool:getOwnerFarmId() ~= self.farmId then
        Logging.warning("Player.getCanPickupHandTool failed for handTool '%s'. OwnerFarm: '%s' - Player: '%s'", handTool.configFileName, handTool:getOwnerFarmId(), self.farmId)
        return false
    end

    -- If the given tool would over-encumber the player, return false.
    if self:getReachedHandToolLimit(handTool) then
        return false
    end

    return true
end



























































































































---Gets the value repesenting whether or not the player is currently holding a hand tool in their hands.
-- @return boolean isHoldingHandTool True if the player has a currentHandTool; otherwise false.
function Player:getIsHoldingHandTool()
    local handTool = self:getHeldHandTool()
    return handTool ~= nil
end

















---Gets the value representing whether or not the player is carrying the given tool, either in their hands or in their backpack.
-- @param HandTool handTool The hand tool to check.
-- @return boolean isCarryingHandTool True if the player is carrying the given tool; otherwise false.
function Player:getIsCarryingHandTool(handTool)
    return handTool ~= nil and table.find(self.carriedHandTools, handTool) ~= nil
end


---Calculates and returns the total combined weight for all hand tools that this player is carrying.
-- @return float summedWeight The combined weight of all carried hand tools.
function Player:getCarriedHandToolMass()
    local summedWeight = 0

    for _, handTool in ipairs(self.carriedHandTools) do
        summedWeight = summedWeight + handTool.mass
    end

    return summedWeight
end


---Gets the x and z position of the player, as well as the yaw (y rotation) of their current camera.
-- @return float x The x position.
-- @return float z The z position.
-- @return float cameraYaw The yaw (y rotation) of the player's current camera.
function Player:getMapPositionAndLookYaw()

    -- Get the yaw of the current camera node.
    local currentCameraNode = self:getCurrentCameraNode()
    local cameraDirectionX, _, cameraDirectionZ = localDirectionToWorld(currentCameraNode, 0, 0, -1)
    local cameraYaw = MathUtil.getYRotationFromDirection(cameraDirectionX, cameraDirectionZ)

    -- Get the current position of the player.
    local x, _, z = self:getPosition()

    -- Return the x, z, and camera yaw.
    return x, z, cameraYaw
end



































































































































































































































































































































































































---Uses the given boolean value to determine if the player has entered or exited a vehicle or the world.
-- @param boolean isControlled Is true if the player is now able to control themselves; otherwise false.
function Player:updateControlledState(isControlled, skipModel, skipMover)

    if isControlled == self.isControlled then
        return
    end

    -- Handle entering or leaving depending on the given boolean.
    if isControlled then
        self:show(skipModel, skipMover)
    else
        self:hide(skipModel, skipMover)
    end
end














---Finds the most valid spawn position and yaw for the player to use. Starting with the player's saved spawn position, then the auto load parameters, then the mission start point, then 0, 0, 0.
-- @return float spawnPositionX The x position of the player's spawn.
-- @return float spawnPositionY The y position of the player's spawn.
-- @return float spawnPositionZ The z position of the player's spawn.
-- @return float spawnYaw The yaw of the player's spawn.
function Player:findSpawnPositionAndYaw()

    -- Always use whatever spawn data the player has saved, as long as it exists.
    local spawnYaw = self:getHasSpawnYaw() and self:getSpawnYaw() or 0
    if self:getHasSpawnPosition() then
        return self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ, spawnYaw
    end

    -- If any auto-loading parameters were given, use those.
    if AutoLoadParams.enable == true and AutoLoadParams.x ~= nil and AutoLoadParams.z ~= nil then
        local y = getTerrainHeightAtWorldPos(g_terrainNode, AutoLoadParams.x, 0, AutoLoadParams.z) + 0.2
        return AutoLoadParams.x, y, AutoLoadParams.z, spawnYaw
    end

    local spawnPoint = g_farmManager:getSpawnPoint(self.farmId)
    local mission = g_currentMission
    if spawnPoint == nil or (mission ~= nil and mission:getIsServer() and not mission.missionInfo.isValid) then
        spawnPoint = g_mission00StartPoint
    end

    -- If there is a mission start point, use it.
    if spawnPoint ~= nil then

        -- Get the spawn position and yaw from the start node.
        local startPositionX, startPositionY, startPositionZ = getWorldTranslation(spawnPoint)
        local dx, _, dz = localDirectionToWorld(spawnPoint, 0, 0, 1)

        -- Return the position and yaw.
        return startPositionX, startPositionY, startPositionZ, MathUtil.getYRotationFromDirection(dx, dz)
    end

    -- Finally, since there's absolutely no valid spawn for the player, return 0, 0, 0 with no yaw, and log an error.
    Logging.error("Player could not find any valid spawn position!")
    return 0, 0, 0, spawnYaw
end


---Finds the closest position around the given position that is clear.
-- @param float x The x of the position to check around.
-- @param float y The y of the position to check around.
-- @param float z The z of the position to check around.
-- @return float spawnPositionX The closest clear x position.
-- @return float spawnPositionY The closest clear y position.
-- @return float spawnPositionZ The closest clear z position.
function Player:findEmptyAreaAroundPosition(x, y, z)
    -- TODO: Check around the position, using overlaps with the CCT size until an empty position is found.
    --#debug Logging.warning("findEmptyAreaAroundPosition has not yet been implemented, returning given position")
    return x, y, z
end






























---Finds if this player has a spawn position set.
-- @return boolean hasSpawnPosition True if the player has a spawn position; otherwise false.
function Player:getHasSpawnPosition()
    return self.spawnPositionX ~= nil and self.spawnPositionY ~= nil and self.spawnPositionZ ~= nil
end


---Gets the spawn position of this player.
-- @return float? spawnPositionX The x position of the player's spawn, or nil if there is no spawn position.
-- @return float? spawnPositionY The y position of the player's spawn, or nil if there is no spawn position.
-- @return float? spawnPositionZ The z position of the player's spawn, or nil if there is no spawn position.
function Player:getSpawnPosition()
    return self.spawnPositionX, self.spawnPositionY, self.spawnPositionZ
end














---Finds if this player has a spawn yaw set.
-- @return boolean hasSpawnYaw True if the player has a spawn yaw set; otherwise false.
function Player:getHasSpawnYaw()
    return self.spawnYaw ~= nil
end


---Gets the player's current spawn yaw.
-- @return float? spawnYaw The player's current spawn yaw, or nil if it does not exist.
function Player:getSpawnYaw()
    return self.spawnYaw
end


---Sets the player's current spawn yaw to the given value.
-- @param float? spawnYaw The spawn yaw to use.
function Player:setSpawnYaw(spawnYaw)
    --#debug Assert.isNilOrType(spawnYaw, "number", "Spawn yaw should be nil or a number!")
    self.spawnYaw = spawnYaw
end





























---Gets the yaw (y rotation) of the player's movement direction. This is more or less the actual yaw that the player has, and the graphical node's yaw smoothly follows it.
-- @return float currentForceYaw The movement yaw of the player.
function Player:getMovementYaw()
    return self.mover:getMovementYaw()
end







































































































---Fired when the player enters a mission. Sets up some state.
function Player:show(skipShowingModel, skipEnablingMover, ignoreLocalCheck)
    if self.isDeleted then
        return
    end

    if not ignoreLocalCheck and self.isLocallyControlled ~= nil then
        return
    end

    local mission = g_currentMission

    --#debug self:debugLog(Player.DEBUG_DISPLAY_FLAG.GRAPHICS, "show()")

    -- TODO: check over this whole function and see if it really should work like this.
    -- It may also need to be renamed, because the entire idea is that the player is moved somewhere underground and hidden, which is different to their model being hidden.
    -- Things like setOwner and raiseActive also need to be double checked.

    -- Raise the player as active so they begin receiving updates.
    self:raiseActive()

    -- If this player exists on the server, set the owning connection.
    if self.isServer then

        self.networkComponent:setShowHideParameters(skipShowingModel, skipEnablingMover)

        self:setOwnerConnection(self.connection)

        -- If the player exists on the server or is able to be controlled, raise the dirty flag to ensure they are synced.
        self:raiseDefaultDirtyFlag()
    end

    -- Set the controlled flag to true, as the player can now control their character.
    self.isControlled = true

    -- Broadcast that the player has entered the mission.
    g_messageCenter:publish(MessageType.OWN_PLAYER_ENTERED)

    if self.isOwner then

        -- Add the player to the environment system.
        if mission ~= nil then
            mission.environmentAreaSystem:setReferenceNode(self.camera.cameraRootNode)
        end

        -- Make the player's camera current.
        self.camera:makeCurrent()

        -- Start listening for the player's bindings to be changed.
        self.inputComponent:listenForBindingChanges()

        -- Set up any input functionality.
        self.inputComponent:addPauseListeners()

        -- Since this is the player who is playing, they should only see their player model in third person.
        if not skipShowingModel then
            local isFirstPerson = self.camera ~= nil and self.camera.isFirstPerson
            local isVisible = not isFirstPerson
            self.graphicsComponent:setModelVisibility(isVisible, true)
        end
    else
        -- Since this is another player, their model should always be visible.
        if not skipShowingModel then
            self.graphicsComponent:setModelVisibility(true)
        end
    end

    if mission ~= nil then
        if mission.shallowWaterSimulation ~= nil and self.swsObstacle == nil then
            local getXZVelocityAndRotYFunc = function()
                local vx, _, vz = self.mover:getVelocity()

                -- add fake velocity when jumping without moving so it splashes
                if vx == 0 and vz == 0 and self.stateMachine.currentState == self.stateMachine.states.onFoot then
                    local state = self.stateMachine.currentState.currentState
                    if state == self.stateMachine.currentState.states.falling or state == self.stateMachine.currentState.states.jumping then
                        return math.random(5),  math.random(5), 0
                    end
                end

                return vx, vz, self.mover:getMovementYaw()
            end

            local width = self.capsuleController:getRadius() * 1.5 -- make obstacle a bit smaller than CCT so it matches the visual mesh better
            local yOffset = self.capsuleController:getHeight() / 2  -- pivot of self.rootNode is at the end of the half sphere so only the cylinder part of the CCT needs to be offset
            self.swsObstacle = mission.shallowWaterSimulation:addObstacle(self.rootNode, width, self.capsuleController:getTotalHeight(), width, getXZVelocityAndRotYFunc, nil, {[2] = yOffset})
        end

        if mission.aiSystem ~= nil then
            mission.aiSystem:addObstacle(self.rootNode, nil, nil, nil, 0.8, 2, 0.8, nil, false)
        end
    end

    -- Set up the player's hotspot.
    self.playerHotspot:setPlayer(self)
    self.playerHotspot:setOwnerFarmId(self.farmId)
    if mission ~= nil then
        mission:addMapHotspot(self.playerHotspot)
    end

    -- Add the player to the traffic system.
    if self.isServer and mission ~= nil and mission.trafficSystem ~= nil and mission.trafficSystem.trafficSystemId ~= 0 then
        addTrafficSystemPlayer(mission.trafficSystem.trafficSystemId, self.graphicsComponent.graphicsRootNode)
    end

    self:setCurrentHandTool(nil, true)

    for i, handTool in ipairs(self.carriedHandTools) do
        handTool:setCarryingPlayerShown()
    end

    if self.isOwner and not skipEnablingMover then
        self.mover:enablePhysics()
    end
end




















































































































































































































































































































































---Displays the debug information.
-- @param float x The x position on the screen to begin drawing the values.
-- @param float y The y position on the screen to begin drawing the values.
-- @param float textSize The height of the text.
-- @return float y The y position on the screen after the entire debug info was drawn.
function Player:debugDraw(x, y, textSize)

    -- Display the currently active debug flags.
    if self.isOwner then
        local flagTextY = textSize * (table.size(Player.DEBUG_DISPLAY_FLAG) + 1)
        flagTextY = DebugUtil.renderTextLine(0.9, flagTextY, textSize, "Enabled debug views:", nil, true)
        for flagName, flagValue in pairs(Player.DEBUG_DISPLAY_FLAG) do
            if flagValue ~= 0 and bitAND(flagValue, Player.currentDebugFlag) == flagValue then
                flagTextY = DebugUtil.renderTextLine(0.9, flagTextY, textSize, flagName, nil, true)
            end
        end
    end

    if self.userId == nil then
        return
    end

    -- Draw the root node for all players.
    DebugUtil.drawDebugNode(self.rootNode, "Root", false, 0)

    -- Render the header.
    y = DebugUtil.renderTextLine(x, y, textSize * 2, string.format("Player %d (farm: %d)", self.userId, self.farmId), nil, true, self.isOwner and Color.PRESETS.DARKGREEN or Color.PRESETS.WHITE)
    y = DebugUtil.renderTextLine(x, y, textSize, string.format("Controlled (server, local): %s, %s", tostring(self.isControlled), tostring(self.isLocallyControlled)), nil, true)

    if bitAND(Player.DEBUG_DISPLAY_FLAG.STATE, Player.currentDebugFlag) ~= 0 then
        y = DebugUtil.renderTextLine(x, y, textSize * 2, self.stateMachine.states.onFoot:getCurrentStateName(), nil, true)

        y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "State functions", nil, true)
        for functionName in pairs(self.stateFunctions) do
            y = DebugUtil.renderTextLine(x, y, textSize, functionName, nil, true)
        end

        y = DebugUtil.renderNewLine(y, textSize)
    end

    if self.stateMachine.currentState ~= self.stateMachine.states.onFoot then
        return
    end

    -- Draw the debug info for each component.
    if bitAND(Player.DEBUG_DISPLAY_FLAG.MOVEMENT, Player.currentDebugFlag) ~= 0 then
        y = self.mover:debugDraw(x, y, textSize)
        y = self.capsuleController:debugDraw(x, y, textSize)
        y = DebugUtil.renderNewLine(y, textSize)
    end

    if self.inputComponent ~= nil and bitAND(Player.DEBUG_DISPLAY_FLAG.INPUT, Player.currentDebugFlag) ~= 0 then
        y = self.inputComponent:debugDraw(x, y, textSize)
    end

    if bitAND(Player.DEBUG_DISPLAY_FLAG.GRAPHICS, Player.currentDebugFlag) ~= 0 then

        if self.isOwner then
            self.graphicsComponent:debugDrawAnimator(0.75, 0.5, 0.25, 0.3, 0.01)
            if self.camera ~= nil then
                y = self.camera:debugDraw(x, y, textSize)
            end
        end

        y = self.graphicsComponent:debugDraw(x, y, textSize, self.camera == nil or not self.camera.isFirstPerson)
        y = DebugUtil.renderNewLine(y, textSize)
    end

    if bitAND(Player.DEBUG_DISPLAY_FLAG.HANDTOOLS, Player.currentDebugFlag) ~= 0 then

        if self.targeter ~= nil then
            y = self.targeter:debugDraw(x, y, textSize)
            y = DebugUtil.renderNewLine(y, textSize)
        end

        y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Tools", nil, true)
        for i, handTool in ipairs(self.carriedHandTools) do
            if handTool == self.currentHandTool then
                y = DebugUtil.renderTextLine(x, y, textSize, string.format("%d: %s", i, handTool.typeName), nil, true)
            else
                y = DebugUtil.renderTextLine(x, y, textSize, string.format("%d: %s", i, handTool.typeName))
            end
        end

        if self:getIsHoldingHandTool() then
            y = self.currentHandTool:debugDraw(x, y, textSize)
        end
        y = DebugUtil.renderNewLine(y, textSize)
    end

    -- Draw the network component if it exists.
    if self.networkComponent ~= nil and bitAND(Player.DEBUG_DISPLAY_FLAG.NETWORK, Player.currentDebugFlag) ~= 0 then
        y = self.networkComponent:debugDraw(x, y, textSize)

        y = DebugUtil.renderNewLine(y, textSize)
    end

    -- Return the final y value.
    return y
end
