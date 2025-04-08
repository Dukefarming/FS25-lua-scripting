








---
local Bale_mt = Class(Bale, MountableObject)
































---Creating bale object
-- @param boolean isServer is server
-- @param boolean isClient is client
-- @param table? customMt customMt
-- @return table instance Instance of object
function Bale.new(isServer, isClient, customMt)
    local self = MountableObject.new(isServer, isClient, customMt or Bale_mt)

    self.forcedClipDistance = 300
    registerObjectClassName(self, "Bale")

    self.fillType = FillType.STRAW
    self.fillLevel = 0
    self.needsSaving = true

    self.variationIndex = 1

    self.supportsWrapping = false
    self.wrappingState = 0
    self.wrappingColor = {1, 1, 1}

    self.defaultMass = 0.25

    self.isFermenting = false
    self.fermentingPercentage = 0

    self.canBeSold = true
    self.allowPickup = true

    self.isMissionBale = false

    self.activatable = BaleActivatable.new(self)

    self.fillTypeDirtyFlag = self:getNextDirtyFlag()
    self.fillLevelDirtyFlag = self:getNextDirtyFlag()

    self.variationDirtyFlag = self:getNextDirtyFlag()

    self.texturesDirtyFlag = self:getNextDirtyFlag()

    self.wrapStateDirtyFlag = self:getNextDirtyFlag()
    self.wrapColorDirtyFlag = self:getNextDirtyFlag()

    self.fermentingDirtyFlag = self:getNextDirtyFlag()

    self.obstacleNodeId = nil
    self.sharedLoadRequestId = nil

    self.uniqueId = nil

    g_currentMission.slotSystem:addLimitedObject(SlotSystem.LIMITED_OBJECT_BALE, self)

    return self
end


---Deleting bale object
function Bale:delete()
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
        self.sharedLoadRequestId = nil
    end

    self.meshes = {}
    self.tensionBeltMeshes = {}

    g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)

    if self.isFermenting then
        g_baleManager:removeFermentation(self)
    end

    self:setBaleAIObstacle(false)

    g_currentMission.slotSystem:removeLimitedObject(SlotSystem.LIMITED_OBJECT_BALE, self)

    unregisterObjectClassName(self)
    g_currentMission.itemSystem:removeItem(self)
    Bale:superClass().delete(self)
end


---Called on client side on update
-- @param integer streamId stream ID
-- @param integer timestamp timestamp
-- @param table connection connection
function Bale:readUpdateStream(streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
            self:setFillType(fillType)
        end

        if streamReadBool(streamId) then
            self:setFillLevel(streamReadFloat32(streamId))
        end

        if streamReadBool(streamId) then
            self:setVariationIndex(streamReadUIntN(streamId, Bale.NUM_BITS_VARIATION) + 1)
        end

        if streamReadBool(streamId) then
            if streamReadBool(streamId) then
                local wrapDiffuse = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
                self:setWrapTextures(wrapDiffuse, nil)
            end

            if streamReadBool(streamId) then
                local wrapNormal = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
                self:setWrapTextures(nil, wrapNormal)
            end
        end

        if streamReadBool(streamId) then
            self:setWrappingState(streamReadUInt8(streamId) / 255, false)
        end

        if streamReadBool(streamId) then
            local r, g, b = Color.readStreamRGB(streamId)
            self:setColor(r, g, b)
        end

        if streamReadBool(streamId) then
            self.isFermenting = streamReadBool(streamId)
            self.fermentingPercentage = streamReadUInt8(streamId) / 255
        end
    end

    Bale:superClass().readUpdateStream(self, streamId, timestamp, connection)
end


---Called on server side on update
-- @param integer streamId stream ID
-- @param table connection connection
-- @param integer dirtyMask dirty mask
function Bale:writeUpdateStream(streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.fillTypeDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.fillLevelDirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.fillLevel)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.variationDirtyFlag) ~= 0) then
            streamWriteUIntN(streamId, self.variationIndex - 1, Bale.NUM_BITS_VARIATION)
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.texturesDirtyFlag) ~= 0) then
            if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
                streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
            end

            if streamWriteBool(streamId, self.wrapNormal ~= nil) then
                streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
            end
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.wrapStateDirtyFlag) ~= 0) then
            streamWriteUInt8(streamId, math.clamp(self.wrappingState*255, 0, 255))
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.wrapColorDirtyFlag) ~= 0) then
            Color.writeStreamRGB(streamId, self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])
        end

        if streamWriteBool(streamId, bitAND(dirtyMask, self.fermentingDirtyFlag) ~= 0) then
            streamWriteBool(streamId, self.isFermenting)
            streamWriteUInt8(streamId, math.clamp(self.fermentingPercentage * 255, 0, 255))
        end
    end

    Bale:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
end


---Called on client side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Bale:readStream(streamId, connection)
    local baleTypeIndex = streamReadUIntN(streamId, BaleManager.SEND_NUM_BITS)
    local xmlFilename = g_baleManager:getBaleXMLFilenameByIndex(baleTypeIndex)
    if self.nodeId == 0 then
        self:loadFromConfigXML(xmlFilename)
    end

    local fillLevel = streamReadFloat32(streamId)
    self:setFillLevel(fillLevel)

    local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
    self:setFillType(fillType)

    local variationIndex = streamReadUIntN(streamId, Bale.NUM_BITS_VARIATION) + 1
    self:setVariationIndex(variationIndex)

    if streamReadBool(streamId) then
        local wrapDiffuse = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
        self:setWrapTextures(wrapDiffuse, nil)
    end

    if streamReadBool(streamId) then
        local wrapNormal = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
        self:setWrapTextures(nil, wrapNormal)
    end

    Bale:superClass().readStream(self, streamId, connection)
    g_currentMission.itemSystem:addItem(self)

    self:setWrappingState(streamReadUInt8(streamId) / 255, false)

    local r, g, b = Color.readStreamRGB(streamId)
    self:setColor(r, g, b)

    self.isFermenting = streamReadBool(streamId)
    if self.isFermenting then
        self.fermentingPercentage = streamReadUInt8(streamId) / 255
    else
        self.fermentingPercentage = 0
    end
end


---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function Bale:writeStream(streamId, connection)
    local baleTypeIndex = g_baleManager:getBaleTypeIndexByXMLFilename(self.xmlFilename) or 1
    streamWriteUIntN(streamId, baleTypeIndex, BaleManager.SEND_NUM_BITS)

    streamWriteFloat32(streamId, self.fillLevel)
    streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)

    streamWriteUIntN(streamId, self.variationIndex - 1, Bale.NUM_BITS_VARIATION)

    if streamWriteBool(streamId, self.wrapDiffuse ~= nil) then
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapDiffuse))
    end

    if streamWriteBool(streamId, self.wrapNormal ~= nil) then
        streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.wrapNormal))
    end

    Bale:superClass().writeStream(self, streamId, connection)

    streamWriteUInt8(streamId, math.clamp(self.wrappingState*255, 0, 255))

    Color.writeStreamRGB(streamId, self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])

    if streamWriteBool(streamId, self.isFermenting) then
        streamWriteUInt8(streamId, math.clamp(self.fermentingPercentage * 255, 0, 255))
    end
end


---Mount bale to object
-- @param table object target object
-- @param integer node target node id
-- @param float x x position
-- @param float y z position
-- @param float z z position
-- @param float rx rx rotation
-- @param float ry ry rotation
-- @param float rz rz rotation
function Bale:mount(object, node, x,y,z, rx,ry,rz)
    Bale:superClass().mount(self, object, node, x,y,z, rx,ry,rz)
    self:setBaleAIObstacle(false)
end


---Unmount bale
function Bale:unmount()
    if Bale:superClass().unmount(self) then
        self:setReducedComponentMass(false)
        self:setBaleAIObstacle(true)
        return true
    end
    return false
end


---Mount bale to object kinematic
-- @param table object target object
-- @param integer node target node id
-- @param float x x position
-- @param float y z position
-- @param float z z position
-- @param float rx rx rotation
-- @param float ry ry rotation
-- @param float rz rz rotation
function Bale:mountKinematic(object, node, x,y,z, rx,ry,rz)
    Bale:superClass().mountKinematic(self, object, node, x,y,z, rx,ry,rz)
    self:setBaleAIObstacle(false)
end


---Unmount bale kinematic
function Bale:unmountKinematic()
    if Bale:superClass().unmountKinematic(self) then
        self:setReducedComponentMass(false)
        self:setBaleAIObstacle(true)
        return true
    end
    return false
end


---
function Bale:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
    if not Bale:superClass().mountDynamic(self, object, objectActorId, jointNode, mountType, forceAcceleration) then
        return false
    end

    self:setBaleAIObstacle(false)
    return true
end


---
function Bale:unmountDynamic(isDelete)
    Bale:superClass().unmountDynamic(self, isDelete)
    self:setReducedComponentMass(false)
    self:setBaleAIObstacle(true)
end


---
function Bale:setBaleAIObstacle(isActive)
    if isActive and self.obstacleNodeId == nil then
        g_currentMission.aiSystem:addObstacle(self.nodeId, nil, nil, nil, nil, nil, nil, nil)
        self.obstacleNodeId = self.nodeId
    elseif not isActive and self.obstacleNodeId ~= nil then
        g_currentMission.aiSystem:removeObstacle(self.obstacleNodeId)
        self.obstacleNodeId = nil
    end
end


---Load node from i3d file
-- @param string i3dFilename i3d file name
function Bale:createNode(i3dFilename)
    self.i3dFilename = i3dFilename
    local baleRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
    self.sharedLoadRequestId = sharedLoadRequestId

    local baleId = getChildAt(baleRoot, 0)
    link(getRootNode(), baleId)
    delete(baleRoot)

    self:setNodeId(baleId)
end


---Load bale from bale XML
-- @param string xmlFilename xml file name
-- @param float x x world position
-- @param float y z world position
-- @param float z z world position
-- @param float rx rx world rotation
-- @param float ry ry world rotation
-- @param float rz rz world rotation
function Bale:loadFromConfigXML(xmlFilename, x, y, z, rx, ry, rz, uniqueId)
    if xmlFilename == nil or not fileExists(xmlFilename) then
        Logging.error("Failed to load bale. XML file could not be found! (%s)", xmlFilename)
        return false
    end

    if g_baleManager:getBaleTypeIndexByXMLFilename(xmlFilename) == nil and g_iconGenerator == nil then
        Logging.error("Failed to load bale. Bale not correctly registered! (%s)", xmlFilename)
        return false
    end

    local xmlFile = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)

    self.xmlFilename = xmlFilename
    self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(self.xmlFilename)

    self.i3dFilename = xmlFile:getValue("bale.filename")
    if self.i3dFilename ~= nil then
        self.i3dFilename = Utils.getFilename(self.i3dFilename, self.baseDirectory)

        self:createNode(self.i3dFilename)

        if x ~= nil and y ~= nil and z ~= nil and rx ~= nil and ry ~= nil and rz ~= nil then
            setTranslation(self.nodeId, x, y, z)
            setRotation(self.nodeId, rx, ry, rz)
        end

        if not self:loadBaleAttributesFromXML(xmlFile) then
            Logging.error("Failed to load bale. Attributes could not be loaded. (%s)", xmlFilename)
            return false
        end
    end

    xmlFile:delete()

    if uniqueId ~= nil then
        self:setUniqueId(uniqueId)
    end

    g_currentMission.itemSystem:addItem(self)

    self:setBaleAIObstacle(true)

    return true
end


---Loads bale attributes from xml file
-- @param table xmlFile xml file object
function Bale:loadBaleAttributesFromXML(xmlFile)
    local triggerId = xmlFile:getValue("bale.mountableObject#triggerNode", nil, self.nodeId)
    local forceAcceleration = xmlFile:getValue("bale.mountableObject#forceAcceleration", 4)
    local forceLimitScale = xmlFile:getValue("bale.mountableObject#forceLimitScale", 1)
    local axisFreeY = xmlFile:getValue("bale.mountableObject#axisFreeY", false)
    local axisFreeX = xmlFile:getValue("bale.mountableObject#axisFreeX", false)
    self:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)

    self.fillTypes = {}
    Bale.loadFillTypesFromXML(self.fillTypes, xmlFile, self.baseDirectory)

    self.variations = {}
    Bale.loadVariationsFromXML(self.variations, xmlFile, self.baseDirectory)

    self.isRoundbale = xmlFile:getValue("bale.size#isRoundbale", true)
    self.width = MathUtil.round(xmlFile:getValue("bale.size#width", 0), 2)
    self.height = MathUtil.round(xmlFile:getValue("bale.size#height", 0), 2)
    self.length = MathUtil.round(xmlFile:getValue("bale.size#length", 0), 2)
    self.diameter = MathUtil.round(xmlFile:getValue("bale.size#diameter", 0), 2)

    self.centerOffsetX, self.centerOffsetY, self.centerOffsetZ = 0, 0, 0

    self.uvId = xmlFile:getValue("bale.uvId", "DEFAULT")

    self.meshes, self.tensionBeltMeshes = Bale.loadVisualMeshesFromXML(self.nodeId, xmlFile, self.baseDirectory)

    return true
end


---Returns if the bale matches the given size
-- @param float diameter diameter
-- @param float width width
-- @param float height height
-- @param float length length
-- @return boolean match matches the size
function Bale:getBaleMatchesSize(diameter, width, height, length)
    if self.isRoundbale then
        return diameter == self.diameter and width == self.width
    else
        return width == self.width and height == self.height and length == self.length
    end
end


---Returns if the bale can be wrapped
-- @return boolean canBeWrapped bale can be wrapped
function Bale:getSupportsWrapping()
    return self.supportsWrapping
end


---Loading from attributes and nodes
-- @param integer xmlFile id of xml object
-- @param string key key
-- @param boolean resetVehicles reset vehicles
-- @return boolean success success
function Bale:loadFromXMLFile(xmlFile, key, resetVehicles)
    local x, y, z = xmlFile:getValue(key.."#position")
    local rx, ry, rz = xmlFile:getValue(key.."#rotation")
    if x == nil or y == nil or z == nil or rx == nil or ry == nil or rz == nil then
        return false
    end

    local xmlFilename = xmlFile:getValue(key.."#filename")
    if xmlFilename == nil then
        return false
    end

    xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFilename)
    if not fileExists(xmlFilename) then
        return false
    end

    local attributes = {}
    Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)

    if not self:loadFromConfigXML(xmlFilename, x, y, z, rx, ry, rz, attributes.uniqueId) then
        return false
    end


    self:applyBaleAttributes(attributes)

    return true
end


---
function Bale.loadBaleAttributesFromXMLFile(attributes, xmlFile, key, resetVehicles)
    attributes.xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFile:getValue(key .. "#filename"))
    attributes.farmId = xmlFile:getValue(key .. "#farmId", AccessHandler.EVERYONE)
    attributes.fillLevel = xmlFile:getValue(key.."#fillLevel")
    attributes.fillTypeName = xmlFile:getValue(key.."#fillType")
    attributes.variationIndex = xmlFile:getValue(key.."#variationIndex")
    attributes.fillType = g_fillTypeManager:getFillTypeIndexByName(attributes.fillTypeName)

    local wrapDiffuse = xmlFile:getValue(key..".textures#wrapDiffuse")
    if wrapDiffuse ~= nil then
        attributes.wrapDiffuse = NetworkUtil.convertFromNetworkFilename(wrapDiffuse)
    end

    local wrapNormal = xmlFile:getValue(key..".textures#wrapNormal")
    if wrapNormal ~= nil then
        attributes.wrapNormal = NetworkUtil.convertFromNetworkFilename(wrapNormal)
    end

    attributes.isFermenting = xmlFile:getValue(key..".fermentation#isFermenting", false)
    attributes.fermentationTime = xmlFile:getValue(key..".fermentation#time", 0)

    attributes.wrappingState = xmlFile:getValue(key.."#wrappingState", 0)
    attributes.wrappingColor = xmlFile:getValue(key.."#wrappingColor", nil, true) or {1, 1, 1}

    attributes.isMissionBale = xmlFile:getValue(key.."#isMissionBale", false)

    attributes.uniqueId = xmlFile:getValue(key.."#uniqueId", nil)

    return true
end


---
function Bale:getBaleAttributes()
    local attributes = {}

    attributes.xmlFilename = self.xmlFilename
    attributes.farmId = self:getOwnerFarmId()
    attributes.fillLevel = self.fillLevel
    attributes.fillType = self.fillType
    attributes.variationIndex = self.variationIndex
    attributes.wrapDiffuse = self.wrapDiffuse
    attributes.wrapNormal = self.wrapNormal
    attributes.supportsWrapping = self.supportsWrapping
    attributes.wrappingState = self.wrappingState
    attributes.wrappingColor = self.wrappingColor
    attributes.isMissionBale = self.isMissionBale

    attributes.isFermenting = self.isFermenting
    if self.isFermenting then
        attributes.fermentationTime = g_baleManager:getFermentationTime(self) or 0
    end

    return attributes
end


---
function Bale.saveBaleAttributesToXMLFile(attributes, xmlFile, key)
    xmlFile:setValue(key.."#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.xmlFilename)))

    xmlFile:setValue(key.."#fillLevel", attributes.fillLevel)
    xmlFile:setValue(key.."#fillType", g_fillTypeManager:getFillTypeNameByIndex(attributes.fillType))
    xmlFile:setValue(key.."#variationIndex", attributes.variationIndex)
    xmlFile:setValue(key.."#farmId", attributes.farmId)
    xmlFile:setValue(key.."#isMissionBale", attributes.isMissionBale)

    xmlFile:setValue(key.."#wrappingState", attributes.wrappingState)
    xmlFile:setValue(key.."#wrappingColor", attributes.wrappingColor[1], attributes.wrappingColor[2], attributes.wrappingColor[3])

    if attributes.wrapDiffuse ~= nil then
        xmlFile:setValue(key..".textures#wrapDiffuse", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.wrapDiffuse)))
    end
    if attributes.wrapNormal ~= nil then
        xmlFile:setValue(key..".textures#wrapNormal", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(attributes.wrapNormal)))
    end

    if attributes.isFermenting then
        xmlFile:setValue(key..".fermentation#isFermenting", true)
        xmlFile:setValue(key..".fermentation#time", attributes.fermentationTime)
    end
end


---
function Bale:applyBaleAttributes(attributes)
    self:setOwnerFarmId(attributes.farmId or AccessHandler.EVERYONE)

    self:setFillLevel(attributes.fillLevel or self.fillLevel)
    if attributes.fillTypeName ~= nil then
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(attributes.fillTypeName)
        self:setFillType(fillTypeIndex or self.fillType)
    elseif attributes.fillType ~= nil then
        self:setFillType(attributes.fillType)
    end

    self:setVariationIndex(attributes.variationIndex or self.variationIndex)

    self:setWrapTextures(attributes.wrapDiffuse, attributes.wrapNormal)

    self:setWrappingState(attributes.wrappingState, false)
    self:setColor(unpack(attributes.wrappingColor))

    self.isMissionBale = Utils.getNoNil(attributes.isMissionBale, self.isMissionBale)

    if self.isServer then
        if attributes.isFermenting then
            local fillTypeInfo = self:getFillTypeInfo(self.fillType)
            if fillTypeInfo ~= nil and fillTypeInfo.fermenting ~= nil then
                local maxTime = fillTypeInfo.fermenting.time * (24 * 60 * 60 * 1000) -- days / months

                -- while bale is produced from a mission field we ferment instantly so it can be sold directly
                if self.isMissionBale then
                    maxTime = 0
                end

                g_baleManager:registerFermentation(self, attributes.fermentationTime, maxTime)
                self.isFermenting = true
                self:raiseDirtyFlags(self.fermentingDirtyFlag)
            end
        end
    end

    return true
end


---
function Bale:saveToXMLFile(xmlFile, key)
    local x, y, z = getTranslation(self.nodeId)
    local xRot, yRot, zRot = getRotation(self.nodeId)

    xmlFile:setValue(key.."#uniqueId", self.uniqueId)
    xmlFile:setValue(key.."#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.xmlFilename)))
    xmlFile:setValue(key.."#position", x, y, z)
    xmlFile:setValue(key.."#rotation", xRot, yRot, zRot)
    xmlFile:setValue(key.."#fillLevel", self.fillLevel)
    xmlFile:setValue(key.."#fillType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
    xmlFile:setValue(key.."#variationIndex", self.variationIndex)
    xmlFile:setValue(key.."#farmId", self:getOwnerFarmId())
    xmlFile:setValue(key.."#isMissionBale", self.isMissionBale)

    xmlFile:setValue(key.."#wrappingState", self.wrappingState)
    xmlFile:setValue(key.."#wrappingColor", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3])

    if self.wrapDiffuse ~= nil then
        xmlFile:setValue(key..".textures#wrapDiffuse", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapDiffuse)))
    end
    if self.wrapNormal ~= nil then
        xmlFile:setValue(key..".textures#wrapNormal", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.wrapNormal)))
    end

    if self.isFermenting then
        xmlFile:setValue(key..".fermentation#isFermenting", true)
        xmlFile:setValue(key..".fermentation#time", g_baleManager:getFermentationTime(self))
    end
end






---
function Bale:getNeedsSaving()
    if not self.needsSaving then
        return false
    end

    -- Only save when the bale is at a valid position. The shop is at -100 and is thus the limit.
    local _, y, _ = getTranslation(self.nodeId)
    return y > -90
end


---
function Bale:getAutoLoadIsSupported()
    return true
end


---
function Bale:getAutoLoadIsAllowed()
    return self:getAllowPickup()
end


---
function Bale:getAutoLoadSize()
    local sizeX = self.width
    local sizeY = self.isRoundbale and self.diameter or self.height
    local sizeZ = self.isRoundbale and self.diameter or self.length

    return sizeX, sizeY, sizeZ
end


---
function Bale:autoLoad(autoLoader, node, posX, posZ, sizeX, sizeZ)
    local mountPosX = posX + sizeX*0.5
    local mountPosY = self.isRoundbale and self.diameter*0.5 or self.height*0.5
    local mountPosZ = posZ + sizeZ*0.5
    local mountRotX = 0
    local mountRotY = self.isRoundbale and math.pi*0.5 or 0
    local mountRotZ = 0

    if self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
        self:unmountKinematic()
    end

    self:mountKinematic(autoLoader, node, mountPosX, mountPosY, mountPosZ, mountRotX, mountRotY, mountRotZ)

    return true
end













---Get price value of bale
function Bale:getValue()
    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(self.fillType)
    return self.fillLevel * pricePerLiter
end


---Get mass of bale
function Bale:getMass()
    return (entityExists(self.nodeId or 0) and getMass(self.nodeId)) or 0
end


---Get mass of bale
function Bale:getDefaultMass()
    return self.defaultMass
end


---Get fill type of bale
-- @return integer fillType current fill type id
function Bale:getFillType()
    return self.fillType
end


---Get mass of bale
function Bale:setReducedComponentMass(state)
    if state then
        setMass(self.nodeId, 0.1)
    else
        setMass(self.nodeId, self.defaultMass)
    end
end


---Returns if component mass reduction is allowed
function Bale:getAllowComponentMassReduction()
    return self.defaultMass > 0.1
end


---
function Bale:setFillType(fillTypeIndex, fillBale)
    Bale.setFillTypeTextures(self.meshes, self.fillTypes, fillTypeIndex)
    self.fillType = fillTypeIndex

    self.supportsWrapping = false

    local fillTypeInfo = self:getFillTypeInfo(self.fillType)
    if fillTypeInfo ~= nil then
        self.supportsWrapping = fillTypeInfo.supportsWrapping
        setMass(self.nodeId, fillTypeInfo.mass)
        self.defaultMass = fillTypeInfo.mass

        if self.isServer then
            if fillTypeInfo.forceAcceleration ~= nil then
                self:setMountableObjectAttributes(nil, fillTypeInfo.forceAcceleration, self.dynamicMountForceLimitScale, self.dynamicMountSingleAxisFreeY, self.dynamicMountSingleAxisFreeX)
            end

            if fillTypeInfo.fermenting ~= nil then
                if not fillTypeInfo.fermenting.requiresWrapping then
                    if self.isFermenting then
                        g_baleManager:removeFermentation(self)
                    end

                    local maxTime = fillTypeInfo.fermenting.time * (24 * 60 * 60 * 1000) -- days / months
                    g_baleManager:registerFermentation(self, 0, maxTime)
                    self.isFermenting = true
                    self:raiseDirtyFlags(self.fermentingDirtyFlag)
                end
            end
        end

        if fillBale == true then
            self:setFillLevel(fillTypeInfo.capacity)
        end
    end

    -- reapply wrapping state in case material has changed
    Bale.updateVisualMeshVisibility(self.meshes, self.fillType, self.wrappingState ~= 0)
    Bale.updateVisualMeshWrappingState(self.meshes, self.wrappingState, self.wrappingColor)

    if self.isServer then
        self:raiseDirtyFlags(self.fillTypeDirtyFlag)
    end
end


---
function Bale:setVariationIndex(variationIndex)
    local variation = self.variations[variationIndex or 1]
    if variation ~= nil then
        self.variationIndex = variationIndex

        Bale.setVariationTextures(self.meshes, self.variations, variation.id)

        if self.isServer then
            self:raiseDirtyFlags(self.variationDirtyFlag)
        end
    end
end


---
function Bale:setVariationId(variationId)
    if variationId == nil then
        self:setVariationIndex(1)
        return true
    end

    for variationIndex, variation in ipairs(self.variations) do
        if string.lower(variation.id) == string.lower(variationId) then
            self:setVariationIndex(variationIndex)
            return true
        end
    end

    return false
end


---
function Bale:getVariationId()
    if #self.variations == 0 then
        return "NONE"
    end

    local variation = self.variations[self.variationIndex]
    if variation ~= nil then
        return variation.id
    end

    return "NONE"
end


---Get max capacity of bale
-- @return integer capacity capacity
function Bale:getCapacity()
    local fillTypeInfo = self:getFillTypeInfo(self.fillType)
    if fillTypeInfo ~= nil then
        return fillTypeInfo.capacity
    end

    return 0
end



---Get fill level of bale
-- @return integer fillLevel current fill level
function Bale:getFillLevel()
    return self.fillLevel
end


---Set fill level of bale
-- @param integer fillLevel fill level
function Bale:setFillLevel(fillLevel)
    self.fillLevel = fillLevel

    if self.isServer then
        self:raiseDirtyFlags(self.fillLevelDirtyFlag)
    end
end


---Return fill type info by given fill type index
-- @param integer fillTypeIndex fill type index
-- @return table fillTypeInfo fill type info
function Bale:getFillTypeInfo(fillTypeIndex)
    for i=1, #self.fillTypes do
        if self.fillTypes[i].fillTypeIndex == self.fillType then
            return self.fillTypes[i]
        end
    end

    return nil
end


---Set if bale can be sold
-- @param boolean canBeSold bale can be sold
function Bale:setCanBeSold(canBeSold)
    self.canBeSold = canBeSold
end


---Returns if bale can be sold
-- @return boolean canBeSold bale can be sold
function Bale:getCanBeSold()
    return self.canBeSold
end


---Set wrapping state of bale
-- @param boolean wrappingState new wrapping state
-- @param boolean updateFermentation update fermentation state
function Bale:setWrappingState(wrappingState, updateFermentation)
    if self.isServer then
        if self.wrappingState ~= wrappingState then
            self:raiseDirtyFlags(self.wrapStateDirtyFlag)
        end
    end

    self.wrappingState = wrappingState

    for i=1, #self.meshes do
        local meshData = self.meshes[i]
        local visibility = (meshData.supportsWrapping or wrappingState == 0) and meshData.fillTypeVisibility
        setVisibility(meshData.node, visibility)

        if visibility then
            setShaderParameter(meshData.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
        end
    end

    if self.isServer then
        if updateFermentation ~= false then
            if self.wrappingState >= 1 then
                local fillTypeInfo = self:getFillTypeInfo(self.fillType)
                if fillTypeInfo ~= nil and fillTypeInfo.fermenting ~= nil then
                    if fillTypeInfo.fermenting.requiresWrapping then
                        if not self.isFermenting then
                            local maxTime = fillTypeInfo.fermenting.time * (24 * 60 * 60 * 1000) -- days / months

                            -- while bale is produced from a mission field we ferment instantly so it can be sold directly
                            if self.isMissionBale then
                                maxTime = 0
                            end

                            g_baleManager:registerFermentation(self, 0, maxTime)
                            self.isFermenting = true
                            self:raiseDirtyFlags(self.fermentingDirtyFlag)
                        end
                    end
                end
            end
        end
    end

    if wrappingState > 0 then
        g_currentMission.activatableObjectsSystem:addActivatable(self.activatable)
    else
        g_currentMission.activatableObjectsSystem:removeActivatable(self.activatable)
    end
end


---Set bale wrapping textures
-- @param string diffuse path to diffuse map
-- @param string normal path to normal map
function Bale:setWrapTextures(diffuse, normal)
    self.wrapDiffuse = diffuse or self.wrapDiffuse
    self.wrapNormal = normal or self.wrapNormal

    for i=1, #self.meshes do
        local meshData = self.meshes[i]
        local materialId = getMaterial(meshData.node, 0)

        if self.wrapDiffuse ~= nil then
            if textureFileExists(self.wrapDiffuse) then
                materialId = setMaterialCustomMapFromFile(materialId, "wrapDiffuseMap", self.wrapDiffuse, false, true, false)
            else
                Logging.warning("Unknown bale wrapping texture '%s'. Using default texture.", self.wrapDiffuse)
            end
        end
        if self.wrapNormal ~= nil then
            if textureFileExists(self.wrapNormal) then
                materialId = setMaterialCustomMapFromFile(materialId, "wrapNormalMap", self.wrapNormal, false, false, false)
            else
                Logging.warning("Unknown bale wrapping texture '%s'. Using default texture.", self.wrapNormal)
            end
        end

        setMaterial(meshData.node, materialId, 0)

        setShaderParameter(meshData.node, "wrappingState", self.wrappingState, 0, 0, 0, false)
        setShaderParameter(meshData.node, "colorScale", self.wrappingColor[1], self.wrappingColor[2], self.wrappingColor[3], 1, false)
    end

    if self.isServer then
        if diffuse ~= nil or normal ~= nil then
            self:raiseDirtyFlags(self.texturesDirtyFlag)
        end
    end
end


---Set color of bale
-- @param float r red channel value
-- @param float g green channel value
-- @param float b blue channel value
-- @param float a alpha channel value
function Bale:setColor(r, g, b)
    r, g, b = r or 1, g or 1, b or 1

    if r ~= self.wrappingColor[1]
    or g ~= self.wrappingColor[2]
    or b ~= self.wrappingColor[3] then
        if self.isServer then
            self:raiseDirtyFlags(self.wrapColorDirtyFlag)
        end

        self.wrappingColor[1] = r
        self.wrappingColor[2] = g
        self.wrappingColor[3] = b

        for i=1, #self.meshes do
            local meshData = self.meshes[i]
            if getHasShaderParameter(meshData.node, "colorScale") then
                setShaderParameter(meshData.node, "colorScale", r, g, b, 1, false)
            end
        end
    end
end


---
function Bale:setIsMissionBale(state)
    self.isMissionBale = state
end


---
function Bale:getMeshNodes()
    return self.tensionBeltMeshes
end


---
function Bale:getSupportsTensionBelts()
    return true
end


---
function Bale:getTensionBeltNodeId()
    return self.nodeId
end


---
function Bale:getBaleSupportsBaleLoader()
    return true
end


---
function Bale:getAllowPickup()
    return self.allowPickup
end


---
function Bale:getAdditionalMountingDistance()
    if self.isRoundbale then
        return 0
    else
        return self.height * 0.5
    end
end


---
function Bale:getIsFermenting()
    return self.isFermenting
end


---Returns fermenting percentage [0..1]
function Bale:getFermentingPercentage()
    if self.isFermenting then
        return self.fermentingPercentage
    end

    return 0
end


---Called on fermentation update
function Bale:onFermentationUpdate(percentage)
    self.fermentingPercentage = percentage
    self:raiseDirtyFlags(self.fermentingDirtyFlag)
end


---Called on fermentation end
function Bale:onFermentationEnd()
    if self.isServer then
        if self.isFermenting then
            local fillTypeInfo = self:getFillTypeInfo(self.fillType)
            if fillTypeInfo ~= nil and fillTypeInfo.fermenting ~= nil then
                self:setFillType(fillTypeInfo.fermenting.outputFillTypeIndex)
            end

            self.isFermenting = false
            self:raiseDirtyFlags(self.fermentingDirtyFlag)
        end
    end
end


---
function Bale:getCanBeOpened()
    if self.wrappingState <= 0 then
        return false
    end

    if self.isFermenting then
        return false
    end

    if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_NONE then
        return false
    end

    return true
end


---
function Bale:getInteractionPosition()
    if g_localPlayer:getIsInVehicle() then
        return
    end

    return getWorldTranslation(g_localPlayer.rootNode)
end


---
function Bale:getCanInteract()
    if not g_currentMission.accessHandler:canPlayerAccess(self) then
        return false
    end

    local px, py, pz = self:getInteractionPosition()
    if px ~= nil then
        local x, y, z = getWorldTranslation(self.nodeId)
        local distance = MathUtil.vector3Length(x-px, y-py, z-pz)
        return distance <= Bale.INTERACTION_RADIUS
    end

    return false
end


---
function Bale:open()
    self:setWrappingState(0)
end


---
function Bale:resetDetailVisibilityCut()
    for i=1, #self.meshes do
        local meshData = self.meshes[i]
        if getHasShaderParameter(meshData.node, "visibilityXZ") then
            setShaderParameter(meshData.node, "visibilityXZ", 5, -5, 5, -5, false)
        end
    end
end


---
function Bale:setDetailVisibilityCutNode(node, axis, direction)
    for i=1, #self.meshes do
        Bale.setBaleMeshVisibilityCut(self.meshes[i].node, node, axis, direction, false)
    end
end


---
function Bale.setBaleMeshVisibilityCut(baleMesh, node, axis, direction, recursively)
    if getHasShaderParameter(baleMesh, "visibilityXZ") then
        local sx, sy, sz, sw
        local x, _, z = localToLocal(node, baleMesh, 0, 0, 0)

        if axis == 1 then
            if direction > 0 then
                sx = x
            else
                sy = x
            end
        else
            if direction > 0 then
                sz = z
            else
                sw = z
            end
        end

        setShaderParameter(baleMesh, "visibilityXZ", sx, sy, sz, sw, false)
    end

    if recursively then
        for i=1, getNumOfChildren(baleMesh) do
            Bale.setBaleMeshVisibilityCut(getChildAt(baleMesh, i-1), node, axis, direction, recursively)
        end
    end
end


---
function Bale:doDensityMapItemAreaUpdate(func, target, ...)
    local gridSize = 0.25
    if self.isRoundbale then
        local x, _, z = getWorldTranslation(self.nodeId)

        local sizeFactor = 0.4 -- using 40% since it's applied with rounding mode inclusive
        local x0, z0 = x + self.width * sizeFactor, z + self.width * sizeFactor
        local x1, z1 = x - self.width * sizeFactor, z + self.width * sizeFactor
        local x2, z2 = x + self.width * sizeFactor, z - self.width * sizeFactor

        func(target, x0 + gridSize, z0 + gridSize, x1 + gridSize, z1 + gridSize, x2 + gridSize, z2 + gridSize, ...)
    else
        local sizeFactor = 0.4 -- using 40% since it's applied with rounding mode inclusive
        local x0, _, z0 = localToWorld(self.nodeId, self.width * sizeFactor, self.height * sizeFactor, self.length * sizeFactor)
        local x1, _, z1 = localToWorld(self.nodeId, -self.width * sizeFactor, -self.height * sizeFactor, self.length * sizeFactor)
        local x2, _, z2 = localToWorld(self.nodeId, self.width * sizeFactor, self.height * sizeFactor, -self.length * sizeFactor)

        func(target, x0 + gridSize, z0 + gridSize, x1 + gridSize, z1 + gridSize, x2 + gridSize, z2 + gridSize, ...)
    end
end


---
function Bale:showInfo(box)
    local fillType = self:getFillType()
    local fillLevel = self:getFillLevel()
    local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
    box:addLine(fillTypeDesc.title, g_i18n:formatVolume(fillLevel, 0))
    if self:getIsFermenting() then
        box:addLine(g_i18n:getText("info_fermenting"), string.format("%d%%", self:getFermentingPercentage() * 100))
    end
    box:addLine(g_i18n:getText("infohud_mass"), g_i18n:formatMass(self:getMass()))
end












---Creating a dummy bale mesh for the given attributes
-- @param string xmlFilename xmlFilename
-- @param integer fillTypeIndex fill type index to apply
-- @param string variationId variation identifier
-- @param float? wrappingState current wrapping state progress, default 0
-- @param table? wrappingColor color table (r, g, b, a), default white
-- @return integer nodeId node id of dummy bale mesh
-- @return integer sharedLoadRequestId sharedLoadRequestId
function Bale.createDummyBale(xmlFilename, fillTypeIndex, variationId, wrappingState, wrappingColor)
    local xmlFile = XMLFile.load("TempBale", xmlFilename, BaleManager.baleXMLSchema)

    local baleId, baleRoot, sharedLoadRequestId
    local i3dFilename = xmlFile:getValue("bale.filename")
    if i3dFilename ~= nil then
        local _, baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
        i3dFilename = Utils.getFilename(i3dFilename, baseDirectory)

        baleRoot, sharedLoadRequestId = g_i3DManager:loadSharedI3DFile(i3dFilename, false, false)
        if baleRoot ~= 0 then
            baleId = getChildAt(baleRoot, 0)
            setRigidBodyType(baleId, RigidBodyType.NONE)
            unlink(baleId)

            wrappingState = wrappingState or 0

            local meshes = Bale.loadVisualMeshesFromXML(baleId, xmlFile, baseDirectory)

            local fillTypes = {}
            Bale.loadFillTypesFromXML(fillTypes, xmlFile, baseDirectory)
            Bale.setFillTypeTextures(meshes, fillTypes, fillTypeIndex)

            local variations = {}
            Bale.loadVariationsFromXML(variations, xmlFile, baseDirectory)
            Bale.setVariationTextures(meshes, variations, variationId)

            Bale.updateVisualMeshVisibility(meshes, fillTypeIndex, wrappingState > 0)
            Bale.updateVisualMeshWrappingState(meshes, wrappingState, wrappingColor)

            delete(baleRoot)
        end
    end

    xmlFile:delete()

    return baleId, sharedLoadRequestId
end
















---Load bale fill types from given xmlFile
-- @param table fillTypes target table
-- @param table xmlFile xmlFile object
-- @param string baseDirectory base directory
function Bale.loadFillTypesFromXML(fillTypes, xmlFile, baseDirectory)
    xmlFile:iterate("bale.fillTypes.fillType", function(index, key)
        local fillTypeName = xmlFile:getValue(key .. "#name")
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        if fillTypeIndex ~= nil then
            local fillTypeInfo = {}
            fillTypeInfo.fillTypeIndex = fillTypeIndex
            fillTypeInfo.capacity = xmlFile:getValue(key .. "#capacity", 1000)
            fillTypeInfo.mass = xmlFile:getValue(key .. "#mass", 500) / 1000
            fillTypeInfo.forceAcceleration = xmlFile:getValue(key .. "#forceAcceleration")
            fillTypeInfo.supportsWrapping = xmlFile:getValue(key .. "#supportsWrapping", false)
            fillTypeInfo.materialName = xmlFile:getValue(key .. "#materialName")
            fillTypeInfo.alphaMaterialName = xmlFile:getValue(key .. "#alphaMaterialName")

            Bale.loadTexturesFromXML(fillTypeInfo, xmlFile, key, baseDirectory)

            local outputFillTypeName = xmlFile:getValue(key .. ".fermenting#outputFillType")
            local outputFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeName)
            if outputFillTypeIndex ~= nil then
                fillTypeInfo.fermenting = {}
                fillTypeInfo.fermenting.outputFillTypeIndex = outputFillTypeIndex
                fillTypeInfo.fermenting.requiresWrapping = xmlFile:getValue(key .. ".fermenting#requiresWrapping", true)
                fillTypeInfo.fermenting.time = xmlFile:getValue(key .. ".fermenting#time", 0)
            end

            table.insert(fillTypes, fillTypeInfo)
        end
    end)
end


---Load bale variations from given xmlFile
-- @param table variations target table
-- @param table xmlFile xmlFile object
-- @param string baseDirectory base directory
function Bale.loadVariationsFromXML(variations, xmlFile, baseDirectory)
    for _, key in xmlFile:iterator("bale.variations.variation") do
        local id = xmlFile:getValue(key .. "#id")
        if id ~= nil then
            local variation = {}
            variation.id = id

            Bale.loadTexturesFromXML(variation, xmlFile, key, baseDirectory)

            table.insert(variations, variation)
        end
    end

    if #variations == 0 then
        table.insert(variations, {id = "DEFAULT"})
    end
end


---Apply fill type textures to all sub nodes of given nodeId
-- @param table meshes array of meshes
-- @param table fillTypes list with fill type data
-- @param integer fillTypeIndex target fill type
function Bale.setFillTypeTextures(meshes, fillTypes, fillTypeIndex)
    for i=1, #fillTypes do
        local fillTypeInfo = fillTypes[i]
        if fillTypeInfo.fillTypeIndex == fillTypeIndex then

            for _, meshData in ipairs(meshes) do
                local materialName = fillTypeInfo.materialName
                if meshData.isAlphaMesh then
                    materialName = fillTypeInfo.alphaMaterialName
                end

                if fillTypeInfo.materialName ~= nil then
                    local materialId = g_materialManager:getBaseMaterialByName(materialName)
                    if materialId ~= nil then
                        setMaterial(meshData.node, materialId, 0)
                    else
                        Logging.warning("Unable to find bale material '%s'", materialName)
                    end
                end

                Bale.setTexturesForNode(meshData.node, fillTypeInfo)

                if getHasShaderParameter(meshData.node, "fillTypeId") then
                    local textureArrayIndex = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillTypeInfo.fillTypeIndex)
                    if textureArrayIndex ~= nil then
                        setShaderParameter(meshData.node, "fillTypeId", textureArrayIndex - 1, 0, 0, 0, true)
                    end
                end
            end

            break
        end
    end
end


---Apply variation textures to all sub nodes of given nodeId
-- @param table meshes array of meshes
-- @param table variations variation data
-- @param string id identifier of variation
function Bale.setVariationTextures(meshes, variations, id)
    for i=1, #variations do
        if variations[i].id == id then
            for _, meshData in ipairs(meshes) do
                Bale.setTexturesForNode(meshData.node, variations[i])
            end
            return
        end
    end

    -- use variation 1 by default
    if #variations > 0 then
        for _, meshData in ipairs(meshes) do
            Bale.setTexturesForNode(meshData.node, variations[1])
        end
    end
end


---Apply textures to the given node
-- @param integer nodeId node
-- @param table textureData texture information
function Bale.setTexturesForNode(nodeId, textureData)
    if getHasClassId(nodeId, ClassIds.SHAPE) then
        local materialId = getMaterial(nodeId, 0)
        if materialId ~= 0 then
            local shaderFilename = getMaterialCustomShaderFilename(materialId)
            if shaderFilename:contains("wrapBaleShader") then
                if textureData.diffuseFilename ~= nil then
                    materialId = setMaterialDiffuseMapFromFile(materialId, textureData.diffuseFilename, true, true, false)
                elseif textureData.diffuseUseFillTypeArray then
                    g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, g_terrainNode, true, false, false)
                    materialId = getMaterial(nodeId, 0)
                end

                if textureData.normalFilename ~= nil then
                    materialId = setMaterialNormalMapFromFile(materialId, textureData.normalFilename, true, false, false)
                elseif textureData.normalUseFillTypeArray then
                    g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, g_terrainNode, false, true, false)
                    materialId = getMaterial(nodeId, 0)
                end

                if textureData.alphaFilename ~= nil then
                    materialId = setMaterialCustomMapFromFile(materialId, "alphaMap", textureData.alphaFilename, true, false, false)
                end
                if textureData.baleNormalFilename ~= nil then
                    materialId = setMaterialCustomMapFromFile(materialId, "baleNormalMap", textureData.baleNormalFilename, true, false, false)
                end
                if textureData.netWrapDiffuseFilename ~= nil then
                    materialId = setMaterialCustomMapFromFile(materialId, "netWrapDiffuseMap", textureData.netWrapDiffuseFilename, true, true, false)
                end
                if textureData.netWrapNormalFilename ~= nil then
                    materialId = setMaterialCustomMapFromFile(materialId, "netWrapNormalMap", textureData.netWrapNormalFilename, true, false, false)
                end

                setMaterial(nodeId, materialId, 0)
            end
        end
    end
end


---Load visual bale meshes from XML
-- @param integer rootNode rootNode
-- @param table xmlFile xmlFile object
-- @param string baseDirectory base directory
-- @return table meshes meshes
-- @return table tensionBeltMeshes tensionBeltMeshes
function Bale.loadVisualMeshesFromXML(rootNode, xmlFile, baseDirectory)
    local meshes = {}
    local tensionBeltMeshes = {}
    xmlFile:iterate("bale.baleMeshes.baleMesh", function(index, key)
        local meshData = {}
        meshData.node = xmlFile:getValue(key .. "#node", nil, rootNode)
        meshData.supportsWrapping = xmlFile:getValue(key .. "#supportsWrapping", true)

        local fillTypeNames = xmlFile:getValue(key .. "#fillTypes")
        meshData.fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames)

        meshData.fillTypeVisibility = true

        meshData.isTensionBeltMesh = xmlFile:getValue(key .. "#isTensionBeltMesh", false)
        if meshData.isTensionBeltMesh then
            table.insert(tensionBeltMeshes, meshData.node)
        end

        meshData.isAlphaMesh = xmlFile:getValue(key .. "#isAlphaMesh", false)

        table.insert(meshes, meshData)
    end)

    return meshes, tensionBeltMeshes
end


---Update the visibility of the visual meshes depending on the fill type
-- @param table meshes list with mesh data
-- @param integer fillTypeIndex target fill type
-- @param boolean isWrapped is wrapped
function Bale.updateVisualMeshVisibility(meshes, fillTypeIndex, isWrapped)
    for i=1, #meshes do
        local meshData = meshes[i]
        if meshData.fillTypes ~= nil and #meshData.fillTypes > 0 then
            setVisibility(meshData.node, false)
            meshData.fillTypeVisibility = false
            for j=1, #meshData.fillTypes do
                if meshData.fillTypes[j] == fillTypeIndex then
                    if meshData.supportsWrapping or not isWrapped then
                        setVisibility(meshData.node, true)
                    end
                    meshData.fillTypeVisibility = true

                    break
                end
            end
        end
    end
end


---Update the wrapping state of the visual meshes
-- @param table meshes list with mesh data
-- @param float wrappingState wrappingState
-- @param table wrappingColor color table (r, g, b, a)
function Bale.updateVisualMeshWrappingState(meshes, wrappingState, wrappingColor)
    for i=1, #meshes do
        local node = meshes[i].node
        setShaderParameter(node, "wrappingState", wrappingState, 0, 0, 0, false)

        if wrappingState > 0 then
            if getHasShaderParameter(node, "colorScale") then
                if wrappingColor ~= nil and #wrappingColor == 3 then
                    setShaderParameter(node, "colorScale", wrappingColor[1], wrappingColor[2], wrappingColor[3], 1, false)
                else
                    setShaderParameter(node, "colorScale", 0.85, 0.85, 0.85, 1, false) -- white as default color
                end
            end
        end
    end
end




---Update the wrapping state of the visual meshes
local BaleActivatable_mt = Class(BaleActivatable)


---
function BaleActivatable.new(bale)
    local self = setmetatable({}, BaleActivatable_mt)

    self.bale = bale
    self.activateText = g_i18n:getText("action_cutBale")

    return self
end


---
function BaleActivatable:getIsActivatable()
    if self.bale:getCanInteract() then
        if self.bale:getCanBeOpened() then
            return true
        end
    end

    return false
end






---
function BaleActivatable:getDistance(posX, posY, posZ)
    if self.bale.nodeId ~= 0 then
        local x, _, z = getWorldTranslation(self.bale.nodeId)
        local distance = MathUtil.vector2Length(posX-x, posZ-z)
        return distance
    end

    return math.huge
end


---
function BaleActivatable:run()
    if g_server ~= nil then
        self.bale:open()
    else
        g_client:getServerConnection():sendEvent(BaleOpenEvent.new(self.bale))
    end
end
