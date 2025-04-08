













---
function IKChains.prerequisitesPresent(specializations)
    return true
end


---Called on specialization initializing
function IKChains.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("IKChains")
    IKUtil.registerIKChainXMLPaths(schema, "vehicle.ikChains.ikChain(?)")
    schema:setXMLSpecializationType()
end


---
function IKChains.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", IKChains)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", IKChains)
end


---
function IKChains:onLoad(savegame)
    local spec = self.spec_ikChains

    spec.chains = {}
    local i = 0
    while true do
        local key = string.format("vehicle.ikChains.ikChain(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end
        IKUtil.loadIKChain(self.xmlFile, key, self.components, self.components, spec.chains)
        i = i + 1
    end

    if next(spec.chains) == nil then
        SpecializationUtil.removeEventListener(self, "onUpdate", IKChains)
    end
end


---
function IKChains:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    IKUtil.updateIKChains(self.spec_ikChains.chains)
end
