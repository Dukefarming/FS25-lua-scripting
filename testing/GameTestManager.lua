


































---
local GameTestManager_mt = Class(GameTestManager, AbstractManager)


---Creating manager
-- @return table instance instance of object
function GameTestManager.new(customMt)
    local self = AbstractManager.new(customMt or GameTestManager_mt)

    self:initDataStructures()

    GameTestManager.xmlSchema = XMLSchema.new("testing")
    GameTestManager.registerXMLPaths(GameTestManager.xmlSchema)

    addConsoleCommand("gsGameTestPrintVehicleSetups", "Prints all vehicle setups on the map to be used inside a test config file", "consoleCommandPrintVehicleSetups", self)

    return self
end


---Initialize data structures
function GameTestManager:initDataStructures()
    self.configXMLFilesToLoad = {}

    self.currentTestCase = nil

    self.totalNumTestCases = 0
    self.clientNumTestCases = 0
    self.clientNumTestCasesSuccess = 0
    self.clientNumTestCasesFailed = 0
    self.clientNumTestCasesInPool = 0
    self.clientNumTestCasesSession = 0

    self.testCasesLoaded = false

    self.numTestClients = tonumber(StartParams.getValue("gameTestNumClients") or "1")
    self.testClientIndex = tonumber(StartParams.getValue("gameTestClientIndex") or "1")
    self.createGameTestConfigs = StartParams.getIsSet("createGameTestConfigs")

    self.svnRevision = tonumber(StartParams.getValue("gameTestSVNRevision") or "-1")
    self.disableTrafficSystem = StartParams.getValue("gameTestDisableTraffic") ~= "false"
    local limitedCaseClassNamesStr = StartParams.getValue("gameTestLimitedCaseClassNames")
    if limitedCaseClassNamesStr ~= nil and limitedCaseClassNamesStr ~= "" then
        local limitedCaseClassNames = string.split(limitedCaseClassNamesStr, ";")

        self.limitedCaseClassNames = {}
        for _, v in ipairs(limitedCaseClassNames) do
            self.limitedCaseClassNames[v] = true
        end
    end

    self.testCaseConfigFile = StartParams.getValue("gameTestCaseConfigFile")
    if self.testCaseConfigFile ~= nil then
        if not fileExists(self.testCaseConfigFile) then
            self.testCaseConfigFile = nil
            Logging.warning("Unknown game test config file '%s'", self.testCaseConfigFile)
        else
            self.createGameTestConfigs = true
        end
    end

    self.gameTestsFolder = getUserProfileAppPath() .. "gameTests/"
    createFolder(self.gameTestsFolder)

    self.currentTestFolder = StartParams.getValue("gameTestDirectory")
    if self.currentTestFolder == nil then
        self.currentTestFolder = self.gameTestsFolder .. getDate("%Y_%m_%d_%H_%M_%S") .. "/"
        createFolder(self.currentTestFolder)
    else
        self.currentTestFolder = self.currentTestFolder:gsub("\\", "/") .. "/"
    end

    self.currentCaseConfigFolder = self.currentTestFolder .. "configs/"
    createFolder(self.currentCaseConfigFolder)

    if self.testCaseConfigFile == nil then
        setFileLogName(string.format("%sstartLog_client%d.txt", self.currentTestFolder, self.testClientIndex))
    end

    -- disable overwrite of our frame rate
    Platform.hasAdjustableFrameLimit = false
end


---Load data on map load
-- @return boolean true if loading was successful else false
function GameTestManager:loadMapData(xmlFile, missionInfo, baseDirectory)
    GameTestManager:superClass().loadMapData(self)

    for _, class in ipairs(GameTestManager.registeredTestCases) do
        if class.overwriteFunctions ~= nil then
            class.overwriteFunctions()
        end
    end

    local filename = Utils.getFilename(missionInfo.mapXMLFilename, baseDirectory)
    local directory = Utils.getDirectory(filename)
    directory = directory .. "/gameTests"

    if self.testCaseConfigFile == nil then
        local files = Files.new(directory)
        for _, file in pairs(files.files) do
            if not file.isDirectory and file.filename:contains(".xml") then
                table.insert(self.configXMLFilesToLoad, directory .. "/" .. file.filename)
            end
        end

        if #self.configXMLFilesToLoad > 0 then
            g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GameTestManager.onMissionStarted, self)
        else
            self:print("No test case config files found in '%s'", directory)
        end
    else
        g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GameTestManager.onMissionStarted, self)
    end

    if self.disableTrafficSystem then
        missionInfo.trafficEnabled = false
    end

    setCaption(string.format("Game Test Client %d of %d (rev %d)", self.testClientIndex, self.numTestClients, self.svnRevision))

    toggleShowFPS()
    setFramerateLimiter(true, 30)

    -- increase lod distance coeff since it's likely that we removed the lod0 with 'removeVisualsRec', so we want to have lod1+ visible (e.g. trees)
    setLODDistanceCoeff(3)

    -- save some VRAM with using the lowest MIP levels so we can run multiple clients
    setTextureStreamingMemoryBudget(5)

    -- disable seasonal growth, so we can plant right after the start
    missionInfo.growthMode = GrowthMode.DISABLED

    g_currentMission.growthSystem:setGrowthEnabled(false)

    -- disable wheel collision with terrain displacement
    WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
end

































































































---
function GameTestManager:loadXMLConfigFile(testCases, xmlFile)
    xmlFile:iterate("testing.testCases", function(index, caseKey)
        local className = xmlFile:getValue(caseKey .. "#className")
        if self.limitedCaseClassNames == nil or self.limitedCaseClassNames[className] == true then
            local class = ClassUtil.getClassObject(className)
            if class ~= nil then
                class.generateTestCases(testCases, xmlFile, caseKey)
            end
        end
    end)
end


---Load data on map load
-- @return boolean true if loading was successful else false
function GameTestManager:unloadMapData()
    if self.currentTestCase ~= nil then
        self.currentTestCase:delete()
        self.currentTestCase = nil
    end

    GameTestManager:superClass().unloadMapData(self)
end


---
function GameTestManager:onMissionStarted(isNewSavegame)
    -- test client 1 will generate all test cases and create individual config files for them
    -- all clients will load from this config pool and perform the tests
    if self.createGameTestConfigs then
        self:print("Create test configs..")

        local testCases = {}

        for i=1, #self.configXMLFilesToLoad do
            local testCaseConfigFilename = self.configXMLFilesToLoad[i]

            self:print("Loading test cases from config file '%s'", testCaseConfigFilename)

            local testXMLFile = XMLFile.load("TempTesting", testCaseConfigFilename, GameTestManager.xmlSchema)
            if testXMLFile ~= nil then
                self:loadXMLConfigFile(testCases, testXMLFile)
                testXMLFile:delete()
            end
        end

        if self.testCaseConfigFile ~= nil then
            self:print("Loading test cases from config file '%s'", self.testCaseConfigFile)

            local testCaseConfigFile = XMLFile.load("testCaseConfigFile", self.testCaseConfigFile, GameTestManager.xmlSchema)
            if testCaseConfigFile ~= nil then
                local className = testCaseConfigFile:getString("testCaseReport.config#className")
                if className ~= nil then
                    local class = ClassUtil.getClassObject(className)
                    if class ~= nil then
                        local testCase = class.generateTestCaseFromConfig(testCaseConfigFile, "testCaseReport.config")
                        if testCase ~= nil then
                            table.insert(testCases, testCase)
                        end
                    end
                end
                testCaseConfigFile:delete()
            end
        end

        self.totalNumTestCases = #testCases

        for i, testCase in ipairs(testCases) do
            local filename = string.format("%stestCase%04d.xml", self.currentCaseConfigFolder, i)
            local xmlFile = XMLFile.create("testConfig", filename, "testConfig", nil)

            testCase:saveToXMLFile(xmlFile, "testConfig")

            xmlFile:save()
            xmlFile:delete()
        end


        self:print("Found %d test cases.", self.totalNumTestCases)
    end

    -- load meta data again in case we are restarting the test client
    --self:loadMetaData()

    self:writeMetaData()

    for _, class in ipairs(GameTestManager.registeredTestCases) do
        if class.onMissionStarted ~= nil then
            class.onMissionStarted(isNewSavegame)
        end
    end

    self.testCasesLoaded = true
end


---
function GameTestManager:update(dt)
    if self.testCasesLoaded and not g_pendingExit then
        if self.currentTestCase == nil then
            local files = Files.new(self.currentCaseConfigFolder).files
            self.clientNumTestCasesInPool = #files

            local testCaseToUse = nil

            for k, file in pairs(files) do
                if not file.isDirectory then
                    local filename = self.currentCaseConfigFolder .. file.filename
                    local xmlFile = XMLFile.load("testConfig", filename, nil)
                    if xmlFile ~= nil then
                        local className = xmlFile:getString("testConfig#className")
                        if className ~= nil then
                            local class = ClassUtil.getClassObject(className)
                            if class ~= nil then
                                local testCase = class.generateTestCaseFromConfig(xmlFile, "testConfig")
                                if testCase ~= nil then
                                    testCase.index = tonumber(file.filename:sub(9, 12))

                                    testCaseToUse = testCase
                                end
                            end
                        end

                        self:print("Loaded test case from config file '%s'", filename)

                        xmlFile:delete()
                        deleteFile(filename)
                        break
                    else
                        self:print("Failed to load test case from config file '%s'", filename)
                    end
                end
            end

            if testCaseToUse ~= nil then
                self.currentTestCase = testCaseToUse
                testCaseToUse:start(function(result)
                    self.clientNumTestCases = self.clientNumTestCases + 1
                    self.clientNumTestCasesSession = self.clientNumTestCasesSession + 1

                    if result == GameTestCase.RESULT.SUCCESS then
                        self.clientNumTestCasesSuccess = self.clientNumTestCasesSuccess + 1
                    else
                        self.clientNumTestCasesFailed = self.clientNumTestCasesFailed + 1
                    end

                    self:onTestCaseFinished()
                end)
            elseif self.testCaseConfigFile == nil and (g_time > 1000 * 60 * 2 or self.clientNumTestCases ~= 0) then
                -- only close game for regular test runs
                -- while retesting we keep the game open for testing purpose

                self:print("No test cases found. Closing.")
                doExit()
            end
        else
            self.currentTestCase:update(dt)
        end
    end
end


---
function GameTestManager:onTestCaseFinished()
    self.currentTestCase = nil

    -- save the meta data after every test in case of crashes etc
    self:writeMetaData()

    -- restart the client after 10 test cases to avoid performance issues
    if self.numTestClients > 1 then
        if self.clientNumTestCasesSession > 10 then
            self:print("Forcing restart after 10 test cases")
            doExit()
        end
    end
end


---
function GameTestManager:loadMetaData()
    local filename = self.currentTestFolder .. "meta.xml"

    if fileExists(filename) then
        local xmlFile = XMLFile.load("meta", filename, nil)
        if xmlFile ~= nil then
            local clientKey = string.format("meta.clients.client(%d)", self.testClientIndex - 1)

            self.clientNumTestCases = xmlFile:getInt(clientKey .. "#numCases", self.clientNumTestCases)
            self.clientNumTestCasesSuccess = xmlFile:getInt(clientKey .. "#numCasesSuccess", self.clientNumTestCasesSuccess)
            self.clientNumTestCasesFailed = xmlFile:getInt(clientKey .. "#numCasesFailed", self.clientNumTestCasesFailed)

            xmlFile:delete()
        end
    end
end


---
function GameTestManager:writeMetaData()
    local filename = self.currentTestFolder .. "meta.xml"

    local xmlFile
    if fileExists(filename) then
        xmlFile = XMLFile.load("meta", filename, nil)
    end

    if xmlFile == nil then
        xmlFile = XMLFile.create("meta", filename, "meta", nil)
    end

    local clientKey = string.format("meta.clients.client(%d)", self.testClientIndex - 1)
    xmlFile:setInt(clientKey .. "#clientIndex", self.testClientIndex)
    xmlFile:setFloat(clientKey .. "#duration", g_time / 1000 / 60)

    xmlFile:setInt(clientKey .. "#numCases", self.clientNumTestCases)
    xmlFile:setInt(clientKey .. "#numCasesSuccess", self.clientNumTestCasesSuccess)
    xmlFile:setInt(clientKey .. "#numCasesFailed", self.clientNumTestCasesFailed)
    xmlFile:setInt(clientKey .. "#luaMemory", collectgarbage("count"))

    -- the general test data is only saved by client 1
    if self.testClientIndex == 1 then
        xmlFile:setInt("meta#totalTestCases", self.totalNumTestCases)
        xmlFile:setString("meta#gameVersion", g_gameVersionDisplay)
        xmlFile:setString("meta#gameTitle", g_gameTitle)
        xmlFile:setString("meta#gameDirectory", getAppBasePath())
        xmlFile:setInt("meta#svnRevision", self.svnRevision)

        xmlFile:setInt("meta.clients#numClients", self.numTestClients)

        for _, class in ipairs(GameTestManager.registeredTestCases) do
            if class.fillMetaData ~= nil then
                class.fillMetaData(xmlFile, "meta")
            end
        end
    end

    xmlFile:save()
    xmlFile:delete()

    self:print("Saved meta data to '%s'", filename)
end


---
function GameTestManager:draw(dt)
    if self.currentTestCase ~= nil then
        local minutes = g_time / 1000 / 60
        local hours = math.floor(minutes / 60)
        local durationStr = string.format("%02d:%02dh", hours, minutes - hours * 60)

        setTextAlignment(RenderText.ALIGN_CENTER)
        setTextBold(true)
        setTextColor(1, 1, 1, 1)
        renderText(0.5, 0.200, 0.025, string.format("Test Client %d/%d (%d failed - %d success - %d waiting - %s)", self.testClientIndex, self.numTestClients, self.clientNumTestCasesFailed, self.clientNumTestCasesSuccess, self.clientNumTestCasesInPool, durationStr))
        renderText(0.5, 0.175, 0.025, self.currentTestCase:getFullName())
        renderText(0.5, 0.150, 0.025, self.currentTestCase:getDescription())

        setTextAlignment(RenderText.ALIGN_LEFT)
    end
end


---
function GameTestManager:print(text, ...)
    print("   GameTestManager: " .. string.format(text, ...))
end








































































































---
function GameTestManager.registerXMLPaths(schema)
    schema:register(XMLValueType.STRING, "testing.testCases(?)#className", "LUA class name of the test")

    for _, class in ipairs(GameTestManager.registeredTestCases) do
        if class.registerXMLPaths ~= nil then
            class.registerXMLPaths(schema, "testing.testCases(?)")
        end
    end
end
