









---Visual part of the wheel (tire, inner rim, outer rim, additionals)
local WheelVisualPart_mt = Class(WheelVisualPart)


---
function WheelVisualPart.new(name, visualWheel, linkNode, customMt)
    local self = setmetatable({}, customMt or WheelVisualPart_mt)

    self.name = name
    self.visualWheel = visualWheel
    self.linkNode = linkNode

    return self
end


---
function WheelVisualPart:delete()
    if self.sharedLoadRequestId ~= nil then
        g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)
    end
end


---
function WheelVisualPart:loadFromXML(xmlObject, key)
    self.filename = xmlObject:getValue(key .. "#filename")
    if self.filename ~= nil then
        self.filename = Utils.getFilename(self.filename, self.visualWheel.baseDirectory)
        if self.filename:contains(".xml") then
            local visualPartXMLFile = XMLFile.load("visualPartXML", self.filename)
            if visualPartXMLFile ~= nil then
                local rootName = visualPartXMLFile:getRootName()

                self.filename = visualPartXMLFile:getString(rootName .. ".file#name")
                if self.filename ~= nil then
                    self.filename = Utils.getFilename(self.filename, self.visualWheel.baseDirectory)
                    if self.filename == nil then
                        Logging.xmlError(visualPartXMLFile, "Unable to load visual wheel part from xml file. Unknown i3d file.")
                        return false
                    end
                else
                    Logging.xmlError(visualPartXMLFile, "Unable to load visual wheel part from xml file. Missing file definition.")
                    return false
                end

                if self.visualWheel.isLeft then
                    self.indexPath = visualPartXMLFile:getString(rootName .. ".file#leftNode")
                else
                    self.indexPath = visualPartXMLFile:getString(rootName .. ".file#rightNode")
                end

                if self.indexPath == nil then
                    Logging.xmlError(visualPartXMLFile, "Unable to load visual wheel part from xml file. Missing node definition.")
                    return false
                end

                visualPartXMLFile:delete()
            else
                xmlObject:xmlWarning(key .. "#filename", "Unable to load visual wheel part from xml file '%s'!", self.filename)
                return false
            end
        end

        if self.visualWheel.isLeft then
            self.indexPath = xmlObject:getValueAlternative(key .. "#nodeLeft", key .. "#node", self.indexPath)
        else
            self.indexPath = xmlObject:getValueAlternative(key .. "#nodeRight", key .. "#node", self.indexPath)
        end

        self.widthAndDiam = xmlObject:getValue(key .. "#widthAndDiam", nil, true)
        self.offset = xmlObject:getValue(key .. "#offset", 0)
        self.scale = xmlObject:getValue(key .. "#scale", nil, true)

        self.mass = xmlObject:getValue(key .. "#mass")
        self.isInverted = xmlObject:getValue(key .. "#isInverted", false)

        self.materials = {}
        local i = 0
        while true do
            local materialKey = string.format("%s.material(%d)", key, i)
            local materialXMLFile, _ = xmlObject:getXMLFileAndPropertyKey(materialKey)
            if materialXMLFile == nil then
                break
            end

            local material = VehicleMaterial.new(self.visualWheel.baseDirectory)
            if material:loadFromXML(xmlObject, materialKey, self.visualWheel.vehicle.customEnvironment) then
                table.insert(self.materials, material)
            end

            i = i + 1
        end

        local material = VehicleMaterial.new(self.visualWheel.baseDirectory)
        if material:loadShortFromXML(xmlObject, key, self.visualWheel.vehicle.customEnvironment) then
            material.targetMaterialSlotName = material.targetMaterialSlotName or self:getDefaultMaterialSlotName()
            table.insert(self.materials, material)
        end

        self.sharedLoadRequestId = self.visualWheel.vehicle:loadSubSharedI3DFile(self.filename, false, false, self.onPartI3DLoaded, self)

        return true
    end

    return false
end


---
function WheelVisualPart:postLoad()
    for _, material in ipairs(self.materials) do
        material:apply(self.node)
    end
end


---
function WheelVisualPart:getDefaultMaterialSlotName()
    if self.name == "innerRim" then
        return "rim_inner_mat"
    elseif self.name == "outerRim" then
        return "rim_outer_mat"
    elseif self.name == "additional" then
        return "rim_additional_mat"
    elseif self.name == "connector" then
        return "rim_bolt_mat"
    end
end


---
function WheelVisualPart:onPartI3DLoaded(i3dNode, failedReason, args)
    if i3dNode ~= 0 then
        local node = I3DUtil.indexToObject(i3dNode, self.indexPath)
        if node ~= nil then
            self:setNode(node)
        end

        delete(i3dNode)
    end
end


---
function WheelVisualPart:setNode(node)
    self.node = node

    link(self.linkNode, self.node)

    local direction = self.visualWheel.isLeft and 1 or -1
    setTranslation(self.node, self.offset * direction, 0, 0)

    if self.scale ~= nil then
        setScale(self.node, self.scale[1], self.scale[2], self.scale[3])
    end

    if self.widthAndDiam ~= nil then
        if self:getHasShaderParameterRec(self.node, "widthAndDiam") then
            self:setShaderParameterRec(self.node, "widthAndDiam", self.widthAndDiam[1], self.widthAndDiam[2], 0, 0)
        else
            -- convert width and diam to scale (mesh is normalized to 1 meter)
            local scaleX = MathUtil.inchToM(self.widthAndDiam[1])
            local scaleZY = MathUtil.inchToM(self.widthAndDiam[2])
            setScale(self.node, scaleX, scaleZY, scaleZY)
        end
    end

    if self.isInverted then
        setRotation(self.node, 0, 0, math.pi)
    end
end


---
function WheelVisualPart:setShaderParameterRec(node, shaderParameterName, x, y, z, w)
    if getHasClassId(node, ClassIds.SHAPE) then
        setShaderParameter(node, shaderParameterName, x, y, z, w, false, -1)
    end

    local numChildren = getNumOfChildren(node)
    for i=1, numChildren do
        self:setShaderParameterRec(getChildAt(node, i - 1), shaderParameterName, x, y, z, w)
    end
end


---
function WheelVisualPart:getHasShaderParameterRec(node, shaderParameterName)
    if getHasClassId(node, ClassIds.SHAPE) then
        if getHasShaderParameter(node, "widthAndDiam") then
            return true
        end
    end

    local numChildren = getNumOfChildren(node)
    for i=1, numChildren do
        if self:getHasShaderParameterRec(getChildAt(node, i - 1), shaderParameterName) then
            return true
        end
    end

    return false
end


---
function WheelVisualPart:getMass()
    return self.mass or 0
end


---
function WheelVisualPart.registerXMLPaths(schema, key, name)
    schema:register(XMLValueType.STRING, key .. "#filename", name .. " - Path to i3d file")
    schema:register(XMLValueType.STRING, key .. "#node", name .. " - Index in i3d file", "0|0")
    schema:register(XMLValueType.STRING, key .. "#nodeLeft", name .. " - Left index in i3d file", "0|0")
    schema:register(XMLValueType.STRING, key .. "#nodeRight", name .. " - Right index in i3d file", "0|0")
    schema:register(XMLValueType.VECTOR_2, key .. "#widthAndDiam", name .. " - Width and diameter")
    schema:register(XMLValueType.VECTOR_SCALE, key .. "#scale", name .. " - Scale")
    schema:register(XMLValueType.FLOAT, key .. "#offset", name .. " - Offset", false)
    schema:register(XMLValueType.FLOAT, key .. "#mass", name .. " - Mass")
    schema:register(XMLValueType.BOOL, key .. "#isInverted", name .. " - Node is inverted", false)

    VehicleMaterial.registerXMLPaths(schema, key .. ".material(?)")
    VehicleMaterial.registerShortXMLPaths(schema, key)
end
