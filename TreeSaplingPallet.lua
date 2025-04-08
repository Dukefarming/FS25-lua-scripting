













---
function TreeSaplingPallet.prerequisitesPresent(specializations)
    return true
end


---Called on specialization initializing
function TreeSaplingPallet.initSpecialization()
    g_vehicleConfigurationManager:addConfigurationType("treeSaplingType", g_i18n:getText("configuration_treeType"), "treeSaplingPallet", VehicleConfigurationItemTreeSapling)

    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("TreeSaplingPallet")

    schema:register(XMLValueType.INT, "vehicle.treeSaplingPallet#fillUnitIndex", "Index of the saplings fill unit", 1)
    schema:register(XMLValueType.STRING, "vehicle.treeSaplingPallet#treeType", "Tree Type Name", "spruce1")
    schema:register(XMLValueType.STRING, "vehicle.treeSaplingPallet#variationName", "Stage variation name to use", "DEFAULT")
    schema:register(XMLValueType.FILENAME, "vehicle.treeSaplingPallet#filename", "Custom tree sapling i3d file")

    schema:register(XMLValueType.NODE_INDEX, "vehicle.treeSaplingPallet.saplingNodes.saplingNode(?)#node", "Sapling link node")
    schema:register(XMLValueType.BOOL, "vehicle.treeSaplingPallet.saplingNodes.saplingNode(?)#randomize", "Randomize rotation and scale of saplings", true)
    schema:register(XMLValueType.NODE_INDEX, "vehicle.treeSaplingPallet.treeSaplingTypeConfigurations.treeSaplingTypeConfiguration(?).saplingNodes.saplingNode(?)#node", "Sapling link node")
    schema:register(XMLValueType.BOOL, "vehicle.treeSaplingPallet.treeSaplingTypeConfigurations.treeSaplingTypeConfiguration(?).saplingNodes.saplingNode(?)#randomize", "Randomize rotation and scale of saplings", true)

    schema:setXMLSpecializationType()

    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).treeSaplingPallet#treeTypeName", "Name of currently loaded tree type")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).treeSaplingPallet#variationName", "Name of currently loaded tree stage variation")
end


---
function TreeSaplingPallet.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "onTreeSaplingLoaded", TreeSaplingPallet.onTreeSaplingLoaded)
    SpecializationUtil.registerFunction(vehicleType, "getTreeSaplingPalletType", TreeSaplingPallet.getTreeSaplingPalletType)
    SpecializationUtil.registerFunction(vehicleType, "setTreeSaplingPalletType", TreeSaplingPallet.setTreeSaplingPalletType)
    SpecializationUtil.registerFunction(vehicleType, "updateTreeSaplingVisuals", TreeSaplingPallet.updateTreeSaplingVisuals)
    SpecializationUtil.registerFunction(vehicleType, "updateTreeSaplingPalletNodes", TreeSaplingPallet.updateTreeSaplingPalletNodes)
end


---
function TreeSaplingPallet.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", TreeSaplingPallet.showInfo)
end


---
function TreeSaplingPallet.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", TreeSaplingPallet)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TreeSaplingPallet)
    SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", TreeSaplingPallet)
end


---
function TreeSaplingPallet:onLoad(savegame)
    local spec = self.spec_treeSaplingPallet

    local treeSaplingTypeConfigurationId = self.configurations["treeSaplingType"] or 1
    local baseKey = string.format("vehicle.treeSaplingPallet.treeSaplingTypeConfigurations.treeSaplingTypeConfiguration(%d)", treeSaplingTypeConfigurationId - 1)
    if not self.xmlFile:hasProperty(baseKey) then
        baseKey = "vehicle.treeSaplingPallet"
    end

    spec.saplingNodes = {}

    spec.fillUnitIndex = self.xmlFile:getValue("vehicle.treeSaplingPallet#fillUnitIndex", 1)
    spec.treeTypeName = self.xmlFile:getValue("vehicle.treeSaplingPallet#treeType", "spruce")
    spec.variationName = self.xmlFile:getValue("vehicle.treeSaplingPallet#variationName")
    spec.treeTypeFilename = self.xmlFile:getValue("vehicle.treeSaplingPallet#filename", nil, self.baseDirectory)

    local configItem = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "treeSaplingType", treeSaplingTypeConfigurationId)
    if configItem ~= nil then
        spec.fillUnitIndex = configItem.fillUnitIndex or spec.fillUnitIndex
        spec.treeTypeName = configItem.treeTypeName or spec.treeTypeName
        spec.variationName = configItem.variationName or spec.variationName
        spec.treeTypeFilename = configItem.treeTypeFilename or spec.treeTypeFilename
    end

    if savegame ~= nil then
        spec.treeTypeName = savegame.xmlFile:getValue(savegame.key .. ".treeSaplingPallet#treeTypeName", spec.treeTypeName)
        spec.variationName = savegame.xmlFile:getValue(savegame.key .. ".treeSaplingPallet#variationName", spec.variationName)
    end

    if spec.treeTypeFilename == nil then
        local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromName(spec.treeTypeName)
        if treeTypeDesc ~= nil then
            local variations = treeTypeDesc.stages[1]
            if variations ~= nil then
                local variation
                for _, _variation in ipairs(variations) do
                    if string.lower(_variation.name or "DEFAULT") == string.lower(spec.variationName or "DEFAULT") then
                        variation = _variation
                        break
                    end
                end

                if variation ~= nil then
                    spec.treeTypeFilename = variation.palletFilename or variation.filename
                end
            end
        end
    end

    if spec.treeTypeFilename ~= nil then
        local nodeKey = baseKey .. ".saplingNodes.saplingNode"
        if not self.xmlFile:hasProperty(nodeKey) then
            nodeKey = "vehicle.treeSaplingPallet.saplingNodes.saplingNode"
        end

        self.xmlFile:iterate(nodeKey, function(_, key)
            local entry = {}
            entry.node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

            if entry.node ~= nil then
                if self.xmlFile:getValue(key .. "#randomize", true) then
                    setRotation(entry.node, 0, math.random(0, math.pi * 2), 0)
                    setScale(entry.node, 1, math.random(90, 110) / 100, 1)
                end

                table.insert(spec.saplingNodes, entry)
            end
        end)
    end

    if spec.treeTypeFilename ~= nil then
        spec.infoBoxLineTitle = g_i18n:getText("configuration_treeType", self.customEnvironment)
        spec.infoBoxLineValue = self.spec_treeSaplingPallet.title
    end

    self:updateTreeSaplingVisuals()
end


---Called on deleting
function TreeSaplingPallet:onDelete()
    local spec = self.spec_treeSaplingPallet

    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
        spec.sharedLoadRequestId = nil
    end

    if spec.saplingNodes ~= nil then
        for _, saplingNode in ipairs(spec.saplingNodes) do
            if saplingNode.saplingShape ~= nil then
                delete(saplingNode.saplingShape)
                saplingNode.saplingShape = nil
            end
        end
    end
end


---
function TreeSaplingPallet:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self.spec_treeSaplingPallet

    if spec.treeTypeName ~= nil then
        xmlFile:setValue(key.."#treeTypeName", spec.treeTypeName)
    end
    if spec.variationName ~= nil then
        xmlFile:setValue(key.."#variationName", spec.variationName)
    end
end


---Returns current tree type
-- @return string name tree type name
function TreeSaplingPallet:getTreeSaplingPalletType()
    local spec = self.spec_treeSaplingPallet
    return spec.treeTypeName, spec.variationName
end


---Sets the current tree type
-- @return string name tree type name
function TreeSaplingPallet:setTreeSaplingPalletType(treeTypeName, variationName)
    local spec = self.spec_treeSaplingPallet
    if treeTypeName ~= spec.treeTypeName or spec.variationName ~= variationName then
        spec.treeTypeName, spec.variationName = treeTypeName, variationName
        self:updateTreeSaplingVisuals()
    end
end


---Sets the current tree type
-- @return string name tree type name
function TreeSaplingPallet:updateTreeSaplingVisuals()
    local spec = self.spec_treeSaplingPallet

    if spec.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
        spec.sharedLoadRequestId = nil
    end

    if spec.treeTypeFilename ~= nil then
        if self.finishedLoading then
            spec.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(spec.treeTypeFilename, false, false, self.onTreeSaplingLoaded, self)
        else
            spec.sharedLoadRequestId = self:loadSubSharedI3DFile(spec.treeTypeFilename, false, false, self.onTreeSaplingLoaded, self)
        end
    end
end


---Called after the sapling has been loaded
-- @return integer i3dNode i3d node id
-- @return table args arguments
function TreeSaplingPallet:onTreeSaplingLoaded(i3dNode, failedReason, args)
    if i3dNode ~= 0 then
        local shape = getChildAt(i3dNode, 0)

        local spec = self.spec_treeSaplingPallet
        for _, saplingNode in ipairs(spec.saplingNodes) do
            if saplingNode.saplingShape ~= nil then
                delete(saplingNode.saplingShape)
            end

            saplingNode.saplingShape = clone(shape, false, false, false)
            link(saplingNode.node, saplingNode.saplingShape)
        end

        delete(i3dNode)

        self:updateTreeSaplingPalletNodes()
    end
end


---
function TreeSaplingPallet:updateTreeSaplingPalletNodes()
    local spec = self.spec_treeSaplingPallet

    local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
    local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)
    for i=1, #spec.saplingNodes do
        local saplingNode = spec.saplingNodes[i]
        setVisibility(saplingNode.node, i <= MathUtil.round(fillLevel))

        I3DUtil.setShaderParameterRec(saplingNode.node, "hideByIndex", capacity-fillLevel, 0, 0, 0)
    end
end


---
function TreeSaplingPallet:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
    self:updateTreeSaplingPalletNodes()
end


---
function TreeSaplingPallet:showInfo(superFunc, box)
    local spec = self.spec_treeSaplingPallet
    if spec.infoBoxLineTitle ~= nil then
        box:addLine(spec.infoBoxLineTitle, spec.infoBoxLineValue)
    end

    superFunc(self, box)
end
