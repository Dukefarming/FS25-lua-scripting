


















---The class responsible for managing hand tools in the world.
local HandToolSystem_mt = Class(HandToolSystem, AbstractManager)


























---Creates a new HandToolSystem with the current global specializations and types.
-- @return HandToolSystem self The created instance.
function HandToolSystem.new()
    local self = setmetatable({}, HandToolSystem_mt)

    self.version = 1
    self.handTools = {}
    self.handToolsByUniqueId = {}
    self.pendingHandTools = {}
    self.startingPlayerHandTools = {}
    self.handToolsToDelete = {}

    self.handToolHolders = {}
    self.handToolHoldersByUniqueId = {}
    self.handToolHoldersByClickBox = {}

    return self
end














































---
function HandToolSystem:addHandTool(handTool)
    if handTool == nil or handTool:isa(HandTool) == nil then
        Logging.error("Given object is not a handtool")
        return false
    end

    -- Ensure the handTool has not already been added.
    if handTool:getUniqueId() ~= nil and self.handToolsByUniqueId[handTool:getUniqueId()] ~= nil then
        Logging.warning("Tried to add existing handTool with unique id of %s! Existing: %s, new: %s", handTool:getUniqueId(), tostring(self.handToolsByUniqueId[handTool:getUniqueId()]), tostring(handTool))
        return false
    end

    -- If the handTool has no unique id, give it one.
    if handTool:getUniqueId() == nil then
        handTool:setUniqueId(Utils.getUniqueId(handTool, self.handToolsByUniqueId, HandToolSystem.UNIQUE_ID_PREFIX))
    end

    table.addElement(self.handTools, handTool)
    self.handToolsByUniqueId[handTool:getUniqueId()] = handTool

    g_messageCenter:publish(MessageType.HANDTOOL_ADDED)

    return true
end


---
function HandToolSystem:removeHandTool(handTool)
    if handTool == nil then
        return
    end

    -- Remove the hand tool from the collections.
    table.removeElement(self.handTools, handTool)
    local uniqueId = handTool:getUniqueId()
    if uniqueId ~= nil then
        if self.handToolsByUniqueId[uniqueId] == handTool then
            self.handToolsByUniqueId[uniqueId] = nil
        end
    end

    g_messageCenter:publish(MessageType.HANDTOOL_REMOVED)
end


---
function HandToolSystem:getHandToolByUniqueId(uniqueId)
    return self.handToolsByUniqueId[uniqueId]
end














---
function HandToolSystem:addHandToolHolder(handToolHolder)
    if handToolHolder == nil or handToolHolder:isa(HandToolHolder) == nil then
        Logging.error("Given object is not a HandToolHolder")
        return false
    end

    -- Add the holder to the collections.
    table.addElement(self.handToolHolders, handToolHolder)

    local uniqueId = handToolHolder:getUniqueId()
    -- Ensure the handTool has not already been added.
    if uniqueId ~= nil and self.handToolHoldersByUniqueId[uniqueId] ~= nil then
        Logging.warning("Tried to add existing handToolHolder (%s) but uniqueId is already in use! Existing: %s, new: %s", uniqueId, tostring(self.handToolHoldersByUniqueId[uniqueId]), tostring(handToolHolder))
        return false
    end

    -- If the handTool has no unique id, give it one.
    if uniqueId == nil then
        uniqueId = Utils.getUniqueId(handToolHolder, self.handToolHoldersByUniqueId, HandToolSystem.UNIQUE_ID_HOLDER_PREFIX)
        handToolHolder:setUniqueId(uniqueId)
    end

    self.handToolHoldersByUniqueId[uniqueId] = handToolHolder
    Logging.devInfo("Added handtool holder %q (%s)", handToolHolder, uniqueId)

    for _, clickBoxNode in ipairs(handToolHolder.clickBoxes) do
        --#debug Assert.hasNoKey(self.handToolHoldersByClickBox, clickBoxNode, "Cannot add clickBox node to two different hand tool holders!")
        self.handToolHoldersByClickBox[clickBoxNode] = handToolHolder
    end

    return true
end


---
function HandToolSystem:removeHandToolHolder(handToolHolder)
    if handToolHolder == nil then
        return
    end

    -- Remove the holder from the collections.
    table.removeElement(self.handToolHolders, handToolHolder)

    local uniqueId = handToolHolder:getUniqueId()
    if uniqueId ~= nil then
        if self.handToolHoldersByUniqueId[uniqueId] == handToolHolder then
            self.handToolHoldersByUniqueId[uniqueId] = nil
        end
    end

    if handToolHolder.clickBoxes ~= nil then
        for _, clickBoxNode in ipairs(handToolHolder.clickBoxes) do
            self.handToolHoldersByClickBox[clickBoxNode] = nil
        end
    end
end



---
function HandToolSystem:getHandToolHolderByUniqueId(uniqueId)
    return self.handToolHoldersByUniqueId[uniqueId]
end









---
function HandToolSystem:save(xmlFilename, usedModNames)
    local xmlFile = XMLFile.create("handToolsXML", xmlFilename, "handTools", HandToolSystem.savegameXMLSchema)
    if xmlFile ~= nil then
        self:saveToXML(self.handTools, xmlFile, usedModNames)
        xmlFile:delete()
    end
end


---
function HandToolSystem:saveToXML(handTools, xmlFile, usedModNames)
    if xmlFile ~= nil then
        local xmlIndex = 0
        for i, handTool in ipairs(handTools) do
            if handTool:getNeedsSaving() then
                self:saveHandToolToXML(handTool, xmlFile, xmlIndex, i, usedModNames)

                xmlIndex = xmlIndex + 1
            end
        end

        xmlFile:save(false, true)
    end
end


---
function HandToolSystem:saveHandToolToXML(handTool, xmlFile, index, i, usedModNames)
    local handToolKey = string.format("handTools.handTool(%d)", index)

    local modName = handTool.customEnvironment
    if modName ~= nil then
        if usedModNames ~= nil then
            usedModNames[modName] = modName
        end
        xmlFile:setValue(handToolKey.."#modName", modName)
    end

    xmlFile:setValue(handToolKey.."#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(handTool.configFileName)))

    handTool:saveToXMLFile(xmlFile, handToolKey, usedModNames)
end













































---
function HandToolSystem:loadHandToolFromXML(xmlFile, key)
    local filename = xmlFile:getValue(key .. "#filename")

    local allowedToLoad = true

    if allowedToLoad then
        filename = NetworkUtil.convertFromNetworkFilename(filename)
        local savegame = {
            xmlFile = xmlFile,
            key = key
        }

        local storeItem = g_storeManager:getItemByXMLFilename(filename)

        if storeItem ~= nil then
            self.handToolsToLoad = self.handToolsToLoad + 1

            local data = HandToolLoadingData.new()
            data:setStoreItem(storeItem)
            data:setSavegameData(savegame)

            data:load(self.loadHandToolFinished, self)

            return true
        end
    else
        Logging.xmlInfo(xmlFile, "HandTool '%s' is not allowed to be loaded", filename)
    end

    return false
end


---
function HandToolSystem:loadHandToolFinished(handTool, loadingState)
    if loadingState == HandToolLoadingState.OK then
        table.insert(self.loadedHandTools, handTool)
    else
        self.handToolLoadingState = self.handToolLoadingState or loadingState
    end

    self.handToolsToLoad = self.handToolsToLoad - 1
    if self.handToolsToLoad <= 0 then
        if self.asyncCallbackFunction ~= nil then
            self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedHandTools, self.handToolLoadingState or HandToolLoadingState.OK, self.asyncCallbackArguments)

            self.asyncCallbackFunction = nil
            self.asyncCallbackObject = nil
            self.asyncCallbackArguments = nil

            self.loadedHandTools = nil
            self.handToolLoadingState = nil
        end
    end
end


---
function HandToolSystem:addPendingHandToolLoad(handTool)
    table.addElement(self.pendingHandTools, handTool)
end


---
function HandToolSystem:removePendingHandToolLoad(handTool)
    table.removeElement(self.pendingHandTools, handTool)
end







---
function HandToolSystem:canStartMission()
    for _, handTool in ipairs(self.handTools) do
        if not handTool:getIsSynchronized() then
            return false
        end
    end

    if #self.pendingHandTools > 0 then
        return false
    end

    return true
end
