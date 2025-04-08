









---Class for animated objects
local AnimatedObject_mt = Class(AnimatedObject, Object)




---Creating new instance of animated object class
-- @param boolean isServer is server
-- @param boolean isClient is client
-- @param table? customMt custom metatable
-- @return table self new instance of object
function AnimatedObject.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or AnimatedObject_mt)
    self.nodeId = 0
    self.isMoving = false

    -- input controls fields:
    self.controls = {}
    self.controls.wasPressed = false
    self.controls.posAction = nil
    self.controls.negAction = nil
    self.controls.posText = nil
    self.controls.negText = nil
    self.controls.posActionEventId = nil
    self.controls.negActionEventId = nil

    self.networkTimeInterpolator = InterpolationTime.new(1.2)
    self.networkAnimTimeInterpolator = InterpolatorValue.new(0)

    self.activatable = AnimatedObjectActivatable.new(self)

    return self
end


---Load animated object from object with given configuration file
-- @param entityId rootNode id of object
-- @param XMLFile xmlFile
-- @param string key
-- @param string xmlFilename Path of the xml configuration
-- @param table? i3dMappings
-- @return boolean success success
function AnimatedObject:load(rootNode, xmlFile, key, xmlFilename, i3dMappings)
    self.xmlFilename = xmlFilename

    local modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
    self.baseDirectory = baseDirectory
    self.customEnvironment = modName

    self.nodeId = rootNode
    if type(rootNode) == "table" then
        self.nodeId = rootNode[1].node
    end

    local success = true
    self.saveId = xmlFile:getValue(key.."#saveId") or "AnimatedObject_"..getName(self.nodeId)

    local animKey = key .. ".animation"

    self.animation = {}
    self.animation.parts = {}
    self.animation.shaderAnims = nil
    self.animation.clipRootNode = nil
    self.animation.clipName = nil
    self.animation.clipTrack = nil
    self.animation.duration = xmlFile:getValue(animKey.."#duration")
    self.animation.time = 0
    self.animation.direction = 0
    self.animation.maxTime = 0

    for _, partKey in xmlFile:iterator(animKey .. ".part") do
        local node = xmlFile:getValue(partKey.."#node", nil, rootNode, i3dMappings)
        if node ~= nil then
            local checkStaticCol = function(nodeToCheck)
                if getRigidBodyType(nodeToCheck) == RigidBodyType.STATIC and getHasClassId(nodeToCheck, ClassIds.SHAPE) then  -- check for classId as transformGroups can be static as well
                    Logging.xmlWarning(xmlFile, "Animated node %q at %q is a static rigid body, ignoring", I3DUtil.getNodePath(nodeToCheck, self.nodeId), partKey)
                    return false
                end
                return
            end
            if I3DUtil.iterateRecursively(node, checkStaticCol, true) == false then
                continue  -- do not add as animated part if check failed
            end

            local part = {}
            part.node = node
            part.frames = {}

            for _, frameKey in xmlFile:iterator(partKey .. ".keyFrame") do
                local keyframe = {self:loadFrameValues(xmlFile, frameKey, node)}
                keyframe.time = xmlFile:getValue(frameKey.."#time")
                self.animation.maxTime = math.max(keyframe.time, self.animation.maxTime)

                table.insert(part.frames, keyframe)
            end

            if #part.frames > 0 then
                table.insert(self.animation.parts, part)
            end
        end
    end

    for _, shaderKey in xmlFile:iterator(animKey .. ".shader") do
        local node = xmlFile:getValue(shaderKey.."#node", nil, rootNode, i3dMappings)
        if node ~= nil then
            local parameterName = xmlFile:getValue(shaderKey.."#parameterName")
            if parameterName ~= nil and getHasShaderParameter(node, parameterName) then
                local shader = {}

                shader.node = node
                shader.parameterName = parameterName
                shader.frames = {}

                for _, frameKey in xmlFile:iterator(shaderKey .. ".keyFrame") do
                    local keyTime = xmlFile:getValue(frameKey.."#time")

                    local shaderValuesStr = xmlFile:getValue(frameKey.."#values", nil)
                    if shaderValuesStr ~= nil then
                        local values = string.split(shaderValuesStr, " ")
                        if #values > 4 then
                            Logging.xmlWarning(xmlFile, "More than 4 values (%q) given for shader parameters at %q", shaderValuesStr, frameKey.."#values")
                        end
                        for i=1, 4 do  -- x,y,z,w
                            values[i] = tonumber(values[i])
                        end

                        local keyframe = values
                        keyframe.time = keyTime
                        table.insert(shader.frames, keyframe)
                    end
                end

                if #shader.frames > 0 then
                    self.animation.shaderAnims = self.animation.shaderAnims or {}
                    table.insert(self.animation.shaderAnims, shader)
                end
            end
        end
    end

    -- convert loaded parts to anim curve
    for _, part in ipairs(self.animation.parts) do
        part.animCurve = AnimCurve.new(linearInterpolatorN)

        for _, frame in ipairs(part.frames) do
            frame.time = frame.time / self.animation.maxTime  -- normalize frame timtes 0..1

            part.animCurve:addKeyframe(frame)
        end

        part.frames = nil
    end

    if self.animation.shaderAnims ~= nil then
        for _, shader in ipairs(self.animation.shaderAnims) do
            shader.animCurve = AnimCurve.new(linearInterpolatorN)

            for _, frame in ipairs(shader.frames) do
                frame.time = frame.time / self.animation.maxTime  -- normalize frame timtes 0..1

                shader.animCurve:addKeyframe(frame)
            end

            shader.frames = nil
        end
    end

    local clipRootNode = xmlFile:getValue(animKey .. ".clip#rootNode", nil, rootNode, i3dMappings)
    local clipName = xmlFile:getValue(animKey .. ".clip#name")

    if clipRootNode ~= nil and clipName ~= nil then
        local clipFilename = xmlFile:getValue(animKey .. ".clip#filename")

        self.animation.clipRootNode = clipRootNode
        self.animation.clipName = clipName
        self.animation.clipTrack = 0

        if clipFilename ~= nil then
            clipFilename = Utils.getFilename(clipFilename, self.baseDirectory)
            self.animation.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(clipFilename, false, false, self.onSharedAnimationFileLoaded, self, nil)
            self.animation.clipFilename = clipFilename
        else
            self:applyAnimation()
        end
    end

    if self.animation.duration == nil then
        self.animation.duration = self.animation.maxTime
    end
    self.animation.duration = self.animation.duration * 1000


    local initialTime = xmlFile:getValue(animKey.."#initialTime", 0)*1000
    self:setAnimTime(initialTime / self.animation.duration, true)

    local startTime = xmlFile:getValue(key..".openingHours#startTime")
    local endTime = xmlFile:getValue(key..".openingHours#endTime")
    if startTime ~= nil and endTime ~= nil then
        local disableIfClosed = xmlFile:getValue(key..".openingHours#disableIfClosed", false)
        local closedText = xmlFile:getValue(key..".openingHours#closedText", nil, self.customEnvironment)
        self.openingHours = {startTime=startTime, endTime=endTime, disableIfClosed=disableIfClosed, closedText=closedText}
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
    end

    self.isEnabled = true


    local triggerId = xmlFile:getValue(key..".controls#triggerNode", nil, rootNode, i3dMappings)
    if triggerId ~= nil then
        self.triggerNode = triggerId

        addTrigger(self.triggerNode, "triggerCallback", self)
        for i=0, getNumOfChildren(self.triggerNode)-1 do
            addTrigger(getChildAt(self.triggerNode, i), "triggerCallback", self)
        end

        if InputAction ~= nil then
            local posAction = xmlFile:getValue(key..".controls#posAction")
            if posAction ~= nil then
                if InputAction[posAction] then
                    self.controls.posAction = posAction

                    local posText = xmlFile:getValue(key..".controls#posText")
                    if posText ~= nil then
                        if g_i18n:hasText(posText, self.customEnvironment) then
                            posText = g_i18n:getText(posText, self.customEnvironment)
                        end
                        self.controls.posActionText = posText
                    end

                    local negText = xmlFile:getValue(key..".controls#negText")
                    if negText ~= nil then
                        if g_i18n:hasText(negText, self.customEnvironment) then
                            negText = g_i18n:getText(negText, self.customEnvironment)
                        end
                        self.controls.negActionText = negText
                    end

                    local negAction = xmlFile:getValue(key..".controls#negAction")
                    if negAction ~= nil then
                        if InputAction[negAction] then
                            self.controls.negAction = negAction
                        else
                            printWarning("Warning: Negative direction action '"..negAction.."' not defined!")
                        end
                    end
                else
                    printWarning("Warning: Positive direction action '"..posAction.."' not defined!")
                end
            end
        end
    end

    if g_client ~= nil then
        local soundsKey = key .. ".sounds"
        self.samplesMoving = g_soundManager:loadSamplesFromXML(xmlFile, soundsKey, "moving", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.samplePosEnd = g_soundManager:loadSampleFromXML(xmlFile, soundsKey, "posEnd", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.sampleNegEnd = g_soundManager:loadSampleFromXML(xmlFile, soundsKey, "negEnd", self.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
    end

    self.animatedObjectDirtyFlag = self:getNextDirtyFlag()

    return success
end






---Load frame values from xml
-- @param XMLFile xmlFile XMLFile instance
-- @param string key key
-- @param integer node node id
-- @return float x x translation
-- @return float y y translation
-- @return float z z translation
-- @return float rx x rotation
-- @return float ry y rotation
-- @return float rz z rotation
-- @return float sx x scale
-- @return float sy y scale
-- @return float sz z scale
-- @return integer visibility visibility
function AnimatedObject:loadFrameValues(xmlFile, key, node)
    local rx, ry, rz = xmlFile:getValue(key.."#rotation")
    if rx == nil then
        rx, ry, rz = getRotation(node)
    end
    local x, y, z = xmlFile:getValue(key.."#translation")
    if x == nil then
        x, y, z = getTranslation(node)
    end
    local sx, sy, sz = xmlFile:getValue(key.."#scale")
    if sx == nil then
        sx, sy, sz = getScale(node)
    end
    local isVisible = xmlFile:getValue(key.."#visibility", true)

    local visibility = 1
    if not isVisible then
        visibility = 0
    end

    return x, y, z, rx, ry, rz, sx, sy, sz, visibility
end









































---Delete animated object
function AnimatedObject:delete()

    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
        for i=0, getNumOfChildren(self.triggerNode)-1 do
            removeTrigger(getChildAt(self.triggerNode, i))
        end
        self.triggerNode = nil
    end

    if self.samplesMoving ~= nil then
        g_soundManager:deleteSamples(self.samplesMoving)
        self.samplesMoving = nil
    end
    if self.samplePosEnd ~= nil then
        g_soundManager:deleteSample(self.samplePosEnd)
        self.samplePosEnd = nil
    end
    if self.sampleNegEnd ~= nil then
        g_soundManager:deleteSample(self.sampleNegEnd)
        self.sampleNegEnd = nil
    end

    if self.animation ~= nil and self.animation.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.animation.sharedLoadRequestId)
        self.animation.sharedLoadRequestId = nil
    end

    if g_currentMission ~= nil then
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end

    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end

    self.isDeleted = true

    AnimatedObject:superClass().delete(self)
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function AnimatedObject:readStream(streamId, connection)
    AnimatedObject:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        local animTime = streamReadFloat32(streamId)
        self:setAnimTime(animTime, true)
        local direction = streamReadUIntN(streamId, 2) - 1
        self.animation.direction = direction

        self.networkAnimTimeInterpolator:setValue(animTime)

        self.networkTimeInterpolator:reset()
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function AnimatedObject:writeStream(streamId, connection)
    AnimatedObject:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteFloat32(streamId, self.animation.time)
        streamWriteUIntN(streamId, self.animation.direction + 1, 2)
    end
end


---Called on client side on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function AnimatedObject:readUpdateStream(streamId, timestamp, connection)
    AnimatedObject:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self.networkTimeInterpolator:startNewPhaseNetwork()
            local animTime = streamReadFloat32(streamId)
            self.networkAnimTimeInterpolator:setTargetValue(animTime)
            local direction = streamReadUIntN(streamId, 2) - 1
            self.animation.direction = direction
        end
    end
end


---Called on server side on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function AnimatedObject:writeUpdateStream(streamId, connection, dirtyMask)
    AnimatedObject:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.animatedObjectDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.animation.timeSend)
            streamWriteUIntN(streamId, self.animation.direction + 1, 2)
        end
    end
end


---Loading from attributes and nodes
-- @param integer xmlFile id of xml object
-- @param string key key
-- @return boolean success success
function AnimatedObject:loadFromXMLFile(xmlFile, key)
    local animTime = xmlFile:getValue(key .. "#time")
    if animTime ~= nil then
        self.animation.direction = xmlFile:getValue(key.."#direction", 0)
        self:setAnimTime(animTime, true)
    end

    AnimatedObject.hourChanged(self)

    return true
end




























---Called on update
-- @param float dt time since last call in ms
function AnimatedObject:update(dt)
    AnimatedObject:superClass().update(self, dt)

    local finishedAnimation = false

    -- former updateTick()
    if self.isServer then
        if self.animation.direction ~= 0 then
            local newAnimTime = math.clamp(self.animation.time + (self.animation.direction*dt)/self.animation.duration, 0, 1)

            self:setAnimTime(newAnimTime)
            if newAnimTime == 0 or newAnimTime == 1 then
                self.animation.direction = 0
                finishedAnimation = true
            end
        end

        if self.animation.time ~= self.animation.timeSend then
            self.animation.timeSend = self.animation.time
            self:raiseDirtyFlags(self.animatedObjectDirtyFlag)
        end
    else
        self.networkTimeInterpolator:update(dt)
        local interpolationAlpha = self.networkTimeInterpolator:getAlpha()
        local animTime = self.networkAnimTimeInterpolator:getInterpolatedValue(interpolationAlpha)
        local newAnimTime = self:setAnimTime(animTime)

        if self.animation.direction ~= 0 then
            if self.animation.direction > 0 then
                if newAnimTime == 1 then
                    self.animation.direction = 0
                    finishedAnimation = true
                end
            else
                if newAnimTime == 0 then
                    self.animation.direction = 0
                    finishedAnimation = true
                end
            end
        end

        if self.networkTimeInterpolator:isInterpolating() then
            self:raiseActive()
        end
    end

    if self.samplesMoving ~= nil then
        if self.isMoving and self.animation.direction ~= 0 then
            if not self.samplesMovingArePlaying then
                g_soundManager:playSamples(self.samplesMoving)
                self.samplesMovingArePlaying = true
            end
        else
            if self.samplesMovingArePlaying then
                g_soundManager:stopSamples(self.samplesMoving)
                self.samplesMovingArePlaying = false
            end
        end
    end

    if finishedAnimation and self.animation.direction == 0 then
        if self.samplePosEnd ~= nil and self.animation.time == 1 then
            g_soundManager:playSample(self.samplePosEnd)
        elseif self.sampleNegEnd ~= nil and self.animation.time == 0 then
            g_soundManager:playSample(self.sampleNegEnd)
        end
    end

    self.isMoving = false

    if self.animation.direction ~= 0 then
        self:raiseActive()
    end
end






---Set animation time
-- @param float t time
function AnimatedObject:setAnimTime(t, omitSound)
    t = math.clamp(t, 0, 1)

    for _, part in pairs(self.animation.parts) do
        local x, y, z, rx, ry, rz, sx, sy, sz, vis = part.animCurve:get(t)

        setTranslation(part.node, x, y, z)
        setRotation(part.node, rx, ry, rz)
        setScale(part.node, sx, sy, sz)
        setVisibility(part.node, vis == 1)
    end

    if self.animation.shaderAnims ~= nil then
        for _, shader in pairs(self.animation.shaderAnims) do
            local x, y, z, w = shader.animCurve:get(t)
            local parameterName = shader.parameterName

            setShaderParameter(shader.node, parameterName, x, y, z, w, false)
        end
    end

    local characterSet = self.animation.clipCharacterSet
    if characterSet ~= nil then
        enableAnimTrack(characterSet, self.animation.clipTrack)
        setAnimTrackTime(characterSet, self.animation.clipTrack, t * self.animation.clipDuration, true)
        disableAnimTrack(characterSet, self.animation.clipTrack)
    end

    self.animation.time = t
    self.isMoving = true

    return t
end


---Set frame values
-- @param integer node node id
-- @param table v values
function AnimatedObject:setFrameValues(node, v)
    setTranslation(node, v[1], v[2], v[3])
    setRotation(node, v[4], v[5], v[6])
    setScale(node, v[7], v[8], v[9])
    setVisibility(node, v[10] == 1)
end


---Called on hour change
function AnimatedObject:hourChanged()
    if not self.isServer then
        return
    end

    if g_currentMission == nil or g_currentMission.environment == nil then
        return
    end

    if self.openingHours ~= nil then
        local currentHour = g_currentMission.environment.currentHour

        if currentHour >= self.openingHours.startTime and currentHour < self.openingHours.endTime then
            if not self.openingHours.isOpen then
                if self.isServer then
                    self.animation.direction = 1
                    self:raiseActive()
                end
                self.openingHours.isOpen = true
            end
            if self.openingHours.disableIfClosed then
                self.isEnabled = true
            end
        else
            if self.openingHours.isOpen then
                if self.isServer then
                    self.animation.direction = -1
                    self:raiseActive()
                end
                self.openingHours.isOpen = false
            end
            if self.openingHours.disableIfClosed then
                self.isEnabled = false
            end
        end
    end
end


---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherId id of object that calls callback
-- @param boolean onEnter called on enter
-- @param boolean onLeave called on leave
-- @param boolean onStay called on stay
function AnimatedObject:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if g_currentMission.missionInfo:isa(FSCareerMissionInfo) then
        if onEnter or onLeave then
            if g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
                if onEnter then
                    g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
                else
                    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
                end

                self:raiseActive()
            end
        end
    end
end



---
function AnimatedObject.registerXMLPaths(schema, basePath)
    schema:setXMLSharedRegistration("AnimatedObject", basePath)

    basePath = basePath .. ".animatedObject(?)"
    schema:register(XMLValueType.STRING, basePath .. "#saveId", "Save identifier", "AnimatedObject_[nodeName]")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation#duration", "Animation duration (sec.)", 3)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".animation.part(?)#node", "Part node")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation.part(?).keyFrame(?)#time", "Key time")
    schema:register(XMLValueType.VECTOR_ROT, basePath .. ".animation.part(?).keyFrame(?)#rotation", "Key rotation", "values read from i3d node")
    schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".animation.part(?).keyFrame(?)#translation", "Key translation", "values read from i3d node")
    schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".animation.part(?).keyFrame(?)#scale", "Key scale", "values read from i3d node")
    schema:register(XMLValueType.BOOL, basePath .. ".animation.part(?).keyFrame(?)#visibility", "Key visibility", true)

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".animation.shader(?)#node", "Shader node")
    schema:register(XMLValueType.STRING, basePath .. ".animation.shader(?)#parameterName", "Shader parameter name")
    schema:register(XMLValueType.FLOAT, basePath .. ".animation.shader(?).keyFrame(?)#time", "Key time")
    schema:register(XMLValueType.STRING, basePath .. ".animation.shader(?).keyFrame(?)#values", "Key shader parameter values. Use '-' to force using existing shader parameter value")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".animation.clip#rootNode", "I3d animation rootnode")
    schema:register(XMLValueType.STRING, basePath .. ".animation.clip#name", "I3d animation clipName")
    schema:register(XMLValueType.STRING, basePath .. ".animation.clip#filename", "I3d animation external animation")

    schema:register(XMLValueType.FLOAT, basePath .. ".animation#initialTime", "Animation time after loading", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".openingHours#startTime", "Start day time")
    schema:register(XMLValueType.FLOAT, basePath .. ".openingHours#endTime", "End day time")
    schema:register(XMLValueType.BOOL, basePath .. ".openingHours#disableIfClosed", "Disabled if closed")
    schema:register(XMLValueType.L10N_STRING, basePath .. ".openingHours#closedText", "Closed text")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".controls#triggerNode", "Player trigger node")

    schema:register(XMLValueType.STRING, basePath .. ".controls#posAction", "Positive direction action event name")
    schema:registerAutoCompletionDataSource(basePath .. ".controls#posAction", "$dataS/inputActions.xml", "actions.action#name")
    schema:register(XMLValueType.STRING, basePath .. ".controls#posText", "Positive direction text")
    schema:register(XMLValueType.STRING, basePath .. ".controls#negText", "Negative direction text")
    schema:register(XMLValueType.STRING, basePath .. ".controls#negAction", "Negative direction action event name")
    schema:registerAutoCompletionDataSource(basePath .. ".controls#negAction", "$dataS/inputActions.xml", "actions.action#name")

    if SoundManager ~= nil then
        SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "moving(?)")
        SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "posEnd")
        SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "negEnd")
    end

    schema:resetXMLSharedRegistration("AnimatedObject", basePath)
end


---
function AnimatedObject.registerSavegameXMLPaths(schema, basePath)
    schema:register(XMLValueType.FLOAT, basePath .. "#time", "Animated object time")
    schema:register(XMLValueType.INT, basePath .. "#direction", "Animated object direction", 0)
end



---
local AnimatedObjectBuilder_mt = Class(AnimatedObjectBuilder)


---
function AnimatedObjectBuilder.registerXMLPaths(schema, basePath)
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "moving(?)")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "posEnd")
    SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "negEnd")
end


---
function AnimatedObjectBuilder.new(animatedObject, xmlFilename, saveId)
    local self = setmetatable({}, AnimatedObjectBuilder_mt)

    self.animatedObject = animatedObject

    local modName, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
    animatedObject.baseDirectory = baseDirectory
    animatedObject.customEnvironment = modName

    animatedObject.saveId = saveId

    animatedObject.animation = {}
    animatedObject.animation.parts = {}
    animatedObject.animation.time = 0
    animatedObject.animation.direction = 0
    animatedObject.animation.duration = 1000
    animatedObject.animation.shaderAnims = {}

    animatedObject.isEnabled = true

    return self
end


---Finalize construction of the object
function AnimatedObjectBuilder:build(rootNodeId)
    local ao = self.animatedObject

    -- Finalize parts
    ao:setAnimTime(0, true)

    if ao.openingHours ~= nil then
        g_messageCenter:subscribe(MessageType.HOUR_CHANGED, ao.hourChanged, ao)
    end

    if ao.triggerNode ~= nil then
        local node = ao.triggerNode

        addTrigger(node, "triggerCallback", ao)
        for i = 0, getNumOfChildren(node) - 1 do
            addTrigger(getChildAt(node, i), "triggerCallback", ao)
        end

    end

    ao.animatedObjectDirtyFlag = ao:getNextDirtyFlag()

    return true
end


---Set trigger
function AnimatedObjectBuilder:setTrigger(node)
    self.animatedObject.triggerNode = node
end


---
function AnimatedObjectBuilder:setActions(posAction, posText, negAction, negText)
    if posAction ~= nil then
        local ao = self.animatedObject
        if InputAction[posAction] then
            ao.controls.posAction = posAction

            if posText ~= nil then
                if g_i18n:hasText(posText, ao.customEnvironment) then
                    posText = g_i18n:getText(posText, ao.customEnvironment)
                end
                ao.controls.posActionText = posText
            end

            if negText ~= nil then
                if g_i18n:hasText(negText, ao.customEnvironment) then
                    negText = g_i18n:getText(negText, ao.customEnvironment)
                end
                ao.controls.negActionText = negText
            end

            if negAction ~= nil then
                if InputAction[negAction] then
                    ao.controls.negAction = negAction
                else
                    printWarning("Warning: Negative direction action '"..negAction.."' not defined!")
                end
            end
        else
            printWarning("Warning: Positive direction action '"..posAction.."' not defined!")
        end
    end
end


---Add a part that has the original position as start, and given rot/translation as end of animation
function AnimatedObjectBuilder:addSimplePart(node, openRotation, openTranslation)
    local part = {}
    part.node = node
    part.animCurve = AnimCurve.new(linearInterpolatorN)

    --#debug if getRigidBodyType(node) ~= RigidBodyType.KINEMATIC then
    --#debug     Logging.error("animated part '%s' has to be a kinematic rigid body", I3DUtil.getNodePath(node))
    --#debug end

    local x, y, z = getTranslation(node)
    local rx, ry, rz = getRotation(node)
    local sx, sy, sz = getScale(node)

    part.animCurve:addKeyframe({
        x, y, z,
        rx, ry, rz,
        sx, sy, sz,
        1, -- visibility
        time = 0
    })

    if openTranslation ~= nil then
        x, y, z = unpack(openTranslation)
    end
    if openRotation ~= nil then
        rx, ry, rz = unpack(openRotation)
    end

    part.animCurve:addKeyframe({
        x, y, z,
        rx, ry, rz,
        sx, sy, sz,
        1, -- visibility
        time = 1
    })

    table.insert(self.animatedObject.animation.parts, part)
end


---
function AnimatedObjectBuilder:setDuration(duration)
    self.animatedObject.animation.duration = duration
end


---Set sounds from some XML, using rootNode as root for binding sounds
function AnimatedObjectBuilder:setSounds(xmlFile, key, rootNode)
    if g_client ~= nil then
        local i3dMappings = nil -- unsupported
        self.animatedObject.samplesMoving = g_soundManager:loadSamplesFromXML(xmlFile, key, "moving", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.animatedObject.samplePosEnd = g_soundManager:loadSampleFromXML(xmlFile, key, "posEnd", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
        self.animatedObject.sampleNegEnd = g_soundManager:loadSampleFromXML(xmlFile, key, "negEnd", self.animatedObject.baseDirectory, rootNode, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
    end
end


---Set opening hours. If unused the animations is always activatable.
function AnimatedObjectBuilder:setOpeningTimes(startTime, endTime, disableIfClosed, closedText)
    if startTime ~= nil and endTime ~= nil then
        self.animatedObject.openingHours = {startTime=startTime, endTime=endTime, disableIfClosed=disableIfClosed, closedText=closedText}
    end
end
