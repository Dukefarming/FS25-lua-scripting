












---
function VehicleConfigurationDataMaterial.registerXMLPaths(schema, rootPath, configPath)
    schema:setXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)

    local materialKey = configPath .. ".material(?)"
    VehicleMaterial.registerXMLPaths(schema, materialKey)
    schema:register(XMLValueType.BOOL, materialKey .. "#ignoreWarning", "If set to 'true' there is no warning if the material is not found.", false)

    schema:register(XMLValueType.NODE_INDEX, materialKey .. "#node", "If defined, the 'targetMaterialSlotName' is only replaced for this node")
    schema:register(XMLValueType.STRING, materialKey .. "#sourceMaterialSlotName", "Material with this slot name replaces the material defined with 'targetMaterialSlotName'")
    schema:register(XMLValueType.STRING, materialKey .. "#targetMaterialSlotName", "Material with this slot name is replaced the material defined with 'sourceMaterialSlotName'")

    schema:resetXMLSharedRegistration("VehicleConfigurationDataMaterial", configPath)
end


---
function VehicleConfigurationDataMaterial.onLoadFinished(vehicle, configItem, configId, ...)
    if configItem.configKey == "" then
        return
    end

    local color
    if configItem:isa(VehicleConfigurationItemColor) then
        color = configItem:getColor()
    end

    vehicle.xmlFile:iterate(configItem.configKey.. ".material", function(index, materialKey)
        XMLUtil.checkDeprecatedXMLElements(vehicle.xmlFile, materialKey .. "#refNode", materialKey .. "#sourceMaterialSlotName") --FS22 to FS25

        if vehicle.xmlFile:getValue(materialKey .. "#materialSlotName") ~= nil then
            local material = VehicleMaterial.new(vehicle.baseDirectory)
            material:setColor(color)
            material:loadFromXML(vehicle.xmlFile, materialKey, vehicle.customEnvironment)
            if material.targetMaterialSlotName ~= nil then
                if not material:applyToVehicle(vehicle) then
                    if not vehicle.xmlFile:getValue(materialKey .. "#ignoreWarning", false) then
                        Logging.xmlWarning(vehicle.xmlFile, "Failed to find material by material slot name '%s' in '%s'", material.targetMaterialSlotName, materialKey)
                    end
                end
            end
        else
            local node = vehicle.xmlFile:getValue(materialKey.."#node", nil, vehicle.components, vehicle.i3dMappings)
            local sourceMaterialSlotName = vehicle.xmlFile:getValue(materialKey.."#sourceMaterialSlotName")
            local targetMaterialSlotName = vehicle.xmlFile:getValue(materialKey.."#targetMaterialSlotName")
            if sourceMaterialSlotName ~= nil and targetMaterialSlotName ~= nil then
                local oldMaterial
                for _, component in pairs(vehicle.components) do
                    oldMaterial = MaterialUtil.getMaterialBySlotName(component.node, targetMaterialSlotName)
                    if oldMaterial ~= nil then
                        break
                    end
                end

                local newMaterial
                for _, component in pairs(vehicle.components) do
                    newMaterial = MaterialUtil.getMaterialBySlotName(component.node, sourceMaterialSlotName)
                    if newMaterial ~= nil then
                        break
                    end
                end

                if oldMaterial ~= nil then
                    if newMaterial ~= nil then
                        if node ~= nil then
                            MaterialUtil.replaceMaterialRec(node, oldMaterial, newMaterial)
                        else
                            for _, component in pairs(vehicle.components) do
                                MaterialUtil.replaceMaterialRec(component.node, oldMaterial, newMaterial)
                            end
                        end
                    else
                        Logging.xmlWarning(vehicle.xmlFile, "Unable to find sourceMaterialSlotName '%s' in '%s'", sourceMaterialSlotName, configItem.configKey)
                    end
                else
                    Logging.xmlWarning(vehicle.xmlFile, "Unable to find targetMaterialSlotName '%s' in '%s'", targetMaterialSlotName, configItem.configKey)
                end
            elseif sourceMaterialSlotName ~= nil or targetMaterialSlotName ~= nil then
                Logging.xmlWarning(vehicle.xmlFile, "Both 'sourceMaterialSlotName' and 'targetMaterialSlotName' need to be defined in '%s'", materialKey)
            end
        end
    end)
end
