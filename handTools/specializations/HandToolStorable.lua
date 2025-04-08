













---
function HandToolStorable.registerXMLPaths(xmlSchema)
    local basePath = "handTool.storable.holderType(?)"

    xmlSchema:setXMLSpecializationType("HandToolStorable")
    xmlSchema:register(XMLValueType.STRING, basePath .. "#type", "The type of holder that can be used", nil, true)
    xmlSchema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "The node used to orient the tool in the holder")
    xmlSchema:setXMLSpecializationType()
end


---
function HandToolStorable.registerFunctions(handToolType)
    SpecializationUtil.registerFunction(handToolType, "getHolsterNodeByType", HandToolStorable.getHolsterNodeByType)
end


---
function HandToolStorable.registerEventListeners(handToolType)
    SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolStorable)
end


---
function HandToolStorable.prerequisitesPresent(specializations)
    return true
end


---
function HandToolStorable:onLoad(xmlFile)
    local spec = self.spec_storable

    -- A collection of nodes keyed by holder type. If a holder's type is not a key in this table, then the tool cannot be stored in it.
    spec.holderHolsterNodes = {}

    for _, key in xmlFile:iterator("handTool.storable.holderType") do
        local holderType = xmlFile:getValue(key .. "#type", nil)
        if holderType == nil then
            Logging.xmlError(xmlFile, "HandToolStorable has a holder type with a missing type!")
            continue
        end

        local holderNode = xmlFile:getValue(key .. "#node", nil,  self.components, self.i3dMappings)
        if holderNode ~= nil then
            spec.holderHolsterNodes[holderType] = holderNode
        end
    end
end


---
function HandToolStorable:getHolsterNodeByType(typeName)
    local spec = self.spec_storable
    if spec.holderHolsterNodes == nil then
        return nil
    end

    return spec.holderHolsterNodes[typeName]
end
