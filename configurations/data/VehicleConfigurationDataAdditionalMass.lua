












---
function VehicleConfigurationDataAdditionalMass.registerXMLPaths(schema, rootPath, configPath)
    schema:setXMLSharedRegistration("VehicleConfigurationDataAdditionalMass", configPath)

    schema:register(XMLValueType.NODE_INDEX, configPath .. ".component#node", "Component node")
    schema:register(XMLValueType.NODE_INDEX, configPath .. ".component#additionalMassNode", "At this position, the additional mass will be applied to the component")
    schema:register(XMLValueType.VECTOR_TRANS, configPath .. ".component#additionalMassOffset", "Offset to the component node to apply the mass there")
    schema:register(XMLValueType.FLOAT, configPath .. ".component#additionalMass", "Additional mass that is added to the component")
    schema:register(XMLValueType.BOOL, configPath .. ".component#useTotalMassReference", "Use total mass of vehicle as reference for center of mass adjustment. Otherwise just the mass of the component itself", true)

    schema:register(XMLValueType.INT, configPath .. ".component.dependentComponentJoint#index", "Index of the component joint to influence")
    schema:register(XMLValueType.FLOAT, configPath .. ".component.dependentComponentJoint#transSpringFactor", "Factor that is applied to the trans spring of the component joint")
    schema:register(XMLValueType.FLOAT, configPath .. ".component.dependentComponentJoint#transDampingFactor", "Factor that is applied to the trans damping of the component joint")

    schema:resetXMLSharedRegistration("VehicleConfigurationDataAdditionalMass", configPath)
end


---
function VehicleConfigurationDataAdditionalMass.onLoad(vehicle, configItem, configId)
    if configItem.configKey ~= "" then
        local componentNode = vehicle.xmlFile:getValue(configItem.configKey .. ".component#node", nil, vehicle.components, vehicle.i3dMappings)
        local additionalMass = vehicle.xmlFile:getValue(configItem.configKey .. ".component#additionalMass", 0) * 0.001
        if componentNode ~= nil and additionalMass ~= 0 then
            local additionalMassNode = vehicle.xmlFile:getValue(configItem.configKey .. ".component#additionalMassNode", nil, vehicle.components, vehicle.i3dMappings)
            local additionalMassOffset = vehicle.xmlFile:getValue(configItem.configKey .. ".component#additionalMassOffset", nil, true)
            local useTotalMassReference = vehicle.xmlFile:getValue(configItem.configKey .. ".component#useTotalMassReference", true)

            local componentJointIndex = vehicle.xmlFile:getValue(configItem.configKey .. ".component.dependentComponentJoint#index", nil)
            if componentJointIndex ~= nil then
                local transSpringFactor = vehicle.xmlFile:getValue(configItem.configKey .. ".component.dependentComponentJoint#transSpringFactor", 1)
                local transDampingFactor = vehicle.xmlFile:getValue(configItem.configKey .. ".component.dependentComponentJoint#transDampingFactor", 1)
                if vehicle.setDependentComponentJointBaseFactors ~= nil then
                    vehicle:setDependentComponentJointBaseFactors(componentJointIndex, transSpringFactor, transDampingFactor)
                end
            end

            -- use the total vehicle mass as reference, as we have a 50/50 distribution with the front axle
            local totalMass = 0
            for _, component in ipairs(vehicle.components) do
                totalMass = totalMass + component.defaultMass
            end

            for _, component in ipairs(vehicle.components) do
                if component.node == componentNode then
                    if additionalMassNode ~= nil or additionalMassOffset ~= nil then
                        local comX, comY, comZ = getCenterOfMass(componentNode)

                        local massX, massY, massZ
                        if additionalMassNode ~= nil then
                            massX, massY, massZ = localToLocal(additionalMassNode, componentNode, 0, 0, 0)
                        else
                            massX, massY, massZ = additionalMassOffset[1], additionalMassOffset[2], additionalMassOffset[3]
                        end

                        local alpha = additionalMass / (useTotalMassReference and totalMass or component.defaultMass)
                        local invAlpha = 1 - alpha
                        comX, comY, comZ = comX * invAlpha + massX * alpha, comY * invAlpha + massY * alpha, comZ * invAlpha + massZ * alpha
                        setCenterOfMass(componentNode, comX, comY, comZ)
                    end

                    component.defaultMass = component.defaultMass + additionalMass
                    break
                end
            end
        end
    end
end
