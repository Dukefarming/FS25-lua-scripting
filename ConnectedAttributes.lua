





















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function ConnectedAttributes.prerequisitesPresent(specializations)
    return true
end


---
function ConnectedAttributes.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("ConnectedAttributes")

    local attributePath = "vehicle.connectedAttributes.attribute(?)"

    schema:register(XMLValueType.BOOL, attributePath .. "#isActiveDirty", "Attribute is permanently updated", false)
    schema:register(XMLValueType.FLOAT, attributePath .. "#maxUpdateDistance", "If the player is within this distance to the vehicle, the attribute is updated", "always")

    schema:register(XMLValueType.STRING, attributePath .. ".updateByAnimation(?)#name", "Name of animation that triggers a update of the connected value")
    schema:register(XMLValueType.BOOL, attributePath .. ".updateByAnimation(?)#onStart", "Update is triggered on start of the animation", false)
    schema:register(XMLValueType.BOOL, attributePath .. ".updateByAnimation(?)#onRun", "Update is triggered while the animation is running", false)
    schema:register(XMLValueType.BOOL, attributePath .. ".updateByAnimation(?)#onStop", "Update is triggered while the animation is stopped", false)

    schema:register(XMLValueType.STRING, attributePath .. ".prerequisites.animation(?)#name", "Name of animation that needs to be in the defined target range")
    schema:register(XMLValueType.FLOAT, attributePath .. ".prerequisites.animation(?)#minTime", "Min. time of animation", 0)
    schema:register(XMLValueType.FLOAT, attributePath .. ".prerequisites.animation(?)#maxTime", "Max. time of animation", 1)

    schema:register(XMLValueType.NODE_INDEX, attributePath .. ".source(?)#node", "Source reference node")
    schema:register(XMLValueType.STRING, attributePath .. ".source(?)#type", "Source type (" .. ConnectedAttributes.TYPES_STRING .. ")", nil, nil, table.toList(ConnectedAttributes.TYPES_BY_NAME))
    schema:register(XMLValueType.STRING, attributePath .. ".source(?)#values", "Value definition from the source")

    for i=1, #ConnectedAttributes.TYPES do
        local typeClass = ConnectedAttributes.TYPES[i]
        typeClass.registerSourceXMLPaths(schema, attributePath .. ".source(?)")
    end

    schema:register(XMLValueType.STRING, attributePath .. ".combine(?)#value", "New value id of the combined value")
    schema:register(XMLValueType.STRING, attributePath .. ".combine(?)#operation", "Operation to be executed on the values (AVERAGE, SUM, SUBTRACT, MULTIPLY, DIVIDE)")
    schema:register(XMLValueType.STRING, attributePath .. ".combine(?)#values", "Values to combine")

    schema:register(XMLValueType.NODE_INDEX, attributePath .. ".target(?)#node", "Target reference node")
    schema:register(XMLValueType.STRING, attributePath .. ".target(?)#type", "Target type (" .. ConnectedAttributes.TYPES_STRING .. ")", nil, nil, table.toList(ConnectedAttributes.TYPES_BY_NAME))
    schema:register(XMLValueType.STRING, attributePath .. ".target(?)#values", "Value definition how the source values are applied to the target")

    for i=1, #ConnectedAttributes.TYPES do
        local typeClass = ConnectedAttributes.TYPES[i]
        typeClass.registerTargetXMLPaths(schema, attributePath .. ".target(?)")
    end

    schema:addDelayedRegistrationFunc("Cylindered:movingTool", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#connectedAttributeIndices", "Connected attributes to update")
    end)

    schema:addDelayedRegistrationFunc("Cylindered:movingPart", function(cSchema, cKey)
        cSchema:register(XMLValueType.VECTOR_N, cKey .. "#connectedAttributeIndices", "Connected attributes to update")
    end)

    schema:setXMLSpecializationType()
end


---
function ConnectedAttributes.registerFunctions(vehicleType)
end


---
function ConnectedAttributes.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ConnectedAttributes.loadExtraDependentParts)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ConnectedAttributes.updateExtraDependentParts)
end


---
function ConnectedAttributes.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onPlayAnimation", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateAnimation", ConnectedAttributes)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", ConnectedAttributes)
end


---
function ConnectedAttributes:onLoad(savegame)
    local spec = self.spec_connectedAttributes

    spec.attributes = {}
    spec.dirtyAttributes = {}

    local hasOnStart, hasOnRun, hasOnStop = false, false, false

    self.xmlFile:iterate("vehicle.connectedAttributes.attribute", function(index, attributeKey)
        local attribute = {}

        attribute.isActive = false

        attribute.isActiveDirty = self.xmlFile:getValue(attributeKey .. "#isActiveDirty", false)
        attribute.maxUpdateDistance = self.xmlFile:getValue(attributeKey .. "#maxUpdateDistance")
        attribute.values = {}

        attribute.updateByAnimations = {}
        self.xmlFile:iterate(attributeKey .. ".updateByAnimation", function(_, animationKey)
            local updateByAnimationData = {}
            updateByAnimationData.animationName = self.xmlFile:getValue(animationKey .. "#name")
            if updateByAnimationData.animationName ~= nil then
                updateByAnimationData.onStart = self.xmlFile:getValue(animationKey .. "#onStart", false)
                updateByAnimationData.onRun = self.xmlFile:getValue(animationKey .. "#onRun", false)
                updateByAnimationData.onStop = self.xmlFile:getValue(animationKey .. "#onStop", false)

                if updateByAnimationData.onStart or updateByAnimationData.onRun or updateByAnimationData.onStop then
                    table.insert(attribute.updateByAnimations, updateByAnimationData)

                    hasOnStart = hasOnStart or updateByAnimationData.onStart
                    hasOnRun = hasOnRun or updateByAnimationData.onRun
                    hasOnStop = hasOnStop or updateByAnimationData.onStop
                end
            end
        end)

        attribute.prerequisites = {}
        self.xmlFile:iterate(attributeKey .. ".prerequisites.animation", function(index, animationKey)
            local animationName = self.xmlFile:getValue(animationKey .. "#name")
            local minTime = self.xmlFile:getValue(animationKey .. "#minTime", 0)
            local maxTime = self.xmlFile:getValue(animationKey .. "#maxTime", 1)
            if animationName ~= nil and (minTime > 0 or maxTime < 1) then
                table.insert(attribute.prerequisites, function()
                    local t = self:getAnimationTime(animationName)
                    return t >= minTime and t <= maxTime
                end)
            end
        end)

        attribute.sources = {}
        self.xmlFile:iterate(attributeKey .. ".source", function(_, sourceKey)
            local source = {}
            source.node = self.xmlFile:getValue(sourceKey .. "#node", nil, self.components, self.i3dMappings)
            if source.node == nil then
                Logging.xmlWarning(self.xmlFile, "Missing node in '%s'", sourceKey)
                return
            end

            local typeString = self.xmlFile:getValue(sourceKey .. "#type")
            if typeString == nil then
                Logging.xmlWarning(self.xmlFile, "Missing type in '%s'", sourceKey)
                return
            end

            source.typeClass = ConnectedAttributes.TYPES_BY_NAME[typeString:upper()]
            if source.typeClass == nil then
                Logging.xmlWarning(self.xmlFile, "Invalid type '%s' in '%s'", typeString, sourceKey)
                return
            end

            if source.typeClass.isAvailable ~= nil and not source.typeClass.isAvailable(self) then
                return
            end

            source.object = source.typeClass.new(self, source.node, self.xmlFile, sourceKey, self.components, self.i3dMappings)
            if source.object == nil then
                Logging.xmlWarning(self.xmlFile, "Failed to load source '%s'", sourceKey)
                return
            end

            source.values = {}
            local valuesStr = self.xmlFile:getValue(sourceKey .. "#values")
            if valuesStr ~= nil then
                local valueParts = valuesStr:split(" ")
                for i=1, math.min(#valueParts, source.typeClass.NUM_VALUES) do
                    if valueParts[i] ~= "-" then
                        source.values[i] = valueParts[i]
                        attribute.values[valueParts[i]] = 0
                    end
                end
            end

            table.insert(attribute.sources, source)
        end)

        attribute.combinations = {}
        self.xmlFile:iterate(attributeKey .. ".combine", function(_, combineKey)
            local combination = {}
            combination.value = self.xmlFile:getValue(combineKey .. "#value")
            if combination.value == nil then
                Logging.xmlWarning(self.xmlFile, "Missing value for '%s'", combineKey)
                return
            end

            local operationStr = self.xmlFile:getValue(combineKey .. "#operation")
            if operationStr ~= nil then
                combination.operation = ConnectedAttributes.COMBINE_OPERATION[operationStr:upper()]
            end

            if combination.operation == nil then
                Logging.xmlWarning(self.xmlFile, "Invalid operation for '%s'", combineKey)
                return
            end

            combination.values = {}
            local valuesStr = self.xmlFile:getValue(combineKey .. "#values")
            if valuesStr ~= nil then
                local valueParts = valuesStr:split(" ")
                for i=1, #valueParts do
                    local valueId = valueParts[i]
                    if valueId ~= "" and attribute.values[valueId] ~= nil then
                        table.insert(combination.values, valueId)
                    end
                end
            end

            combination.numValues = #combination.values
            if combination.numValues == 0 then
                Logging.xmlWarning(self.xmlFile, "Missing values for '%s'", combineKey)
                return
            end

            attribute.values[combination.value] = 0

            table.insert(attribute.combinations, combination)
        end)

        attribute.targets = {}
        self.xmlFile:iterate(attributeKey .. ".target", function(_, targetKey)
            local target = {}

            target.node = self.xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)
            if target.node == nil then
                Logging.xmlWarning(self.xmlFile, "Missing node in '%s'", targetKey)
                return
            end

            local typeString = self.xmlFile:getValue(targetKey .. "#type")
            if typeString == nil then
                Logging.xmlWarning(self.xmlFile, "Missing type in '%s'", targetKey)
                return
            end

            target.typeClass = ConnectedAttributes.TYPES_BY_NAME[typeString:upper()]
            if target.typeClass == nil then
                Logging.xmlWarning(self.xmlFile, "Invalid type '%s' in '%s'", typeString, targetKey)
                return
            end

            if target.typeClass.isAvailable ~= nil and not target.typeClass.isAvailable(self) then
                return
            end

            target.object = target.typeClass.new(self, target.node, self.xmlFile, targetKey, self.components, self.i3dMappings)
            if target.object == nil then
                Logging.xmlWarning(self.xmlFile, "Failed to load target '%s'", targetKey)
                return
            else
                -- update the data to the default values if it's a target in case we do not set all values
                target.object:get()
            end

            target.values = {}
            target.factors = {}
            target.additionals = {}
            target.toSourceValue = {}
            local valuesStr = self.xmlFile:getValue(targetKey .. "#values")
            if valuesStr ~= nil then
                local valueParts = valuesStr:split(" ")
                for i=1, math.min(#valueParts, target.typeClass.NUM_VALUES) do
                    if valueParts[i] ~= "-" then
                        if valueParts[i]:contains("*") then
                            local singleValueParts = valueParts[i]:split("*")
                            target.values[i] = singleValueParts[1]
                            target.factors[i] = tonumber(singleValueParts[2]) or 1
                            target.additionals[i] = 0
                        elseif valueParts[i]:contains("/") then
                            local singleValueParts = valueParts[i]:split("/")
                            target.values[i] = singleValueParts[1]
                            target.factors[i] = 1 / (tonumber(singleValueParts[2]) or 1)
                            target.additionals[i] = 0
                        elseif valueParts[i]:contains("+") then
                            local singleValueParts = valueParts[i]:split("+")
                            target.values[i] = singleValueParts[1]
                            target.factors[i] = 1
                            target.additionals[i] = tonumber(singleValueParts[2]) or 0
                        elseif valueParts[i]:contains("-") then
                            local singleValueParts = valueParts[i]:split("-")
                            if singleValueParts[1] == "" then
                                if attribute.values[singleValueParts[2]] == nil then
                                    target.values[i] = next(attribute.values)
                                    target.factors[i] = 0
                                    target.additionals[i] = tonumber(valueParts[i])
                                else
                                    target.values[i] = singleValueParts[2]
                                    target.factors[i] = -1
                                    target.additionals[i] = 0
                                end
                            else
                                target.values[i] = singleValueParts[1]
                                target.factors[i] = 1
                                target.additionals[i] = -(tonumber(singleValueParts[2]) or 0)
                            end
                        else
                            if attribute.values[valueParts[i]] ~= nil then
                                target.values[i] = valueParts[i]
                                target.factors[i] = 1
                                target.additionals[i] = 0
                            else
                                local number = tonumber(valueParts[i])
                                if number ~= nil then
                                    target.values[i] = next(attribute.values)
                                    target.factors[i] = 0
                                    target.additionals[i] = tonumber(valueParts[i])
                                end
                            end
                        end

                        if target.values[i] == nil or target.values[i] == "" or attribute.values[target.values[i]] == nil then
                            target.values[i] = nil
                            target.factors[i] = nil
                            target.additionals[i] = nil

                            Logging.xmlWarning(self.xmlFile, "Failed to validate target value '%s' of '%s' in '%s'", valueParts[i], valuesStr, targetKey)
                        else
                            target.toSourceValue[i] = attribute.values[target.values[i]]
                        end
                    end
                end
            end

            table.insert(attribute.targets, target)
        end)

        if #attribute.sources >= 1 and #attribute.targets >= 1 then
            table.insert(spec.attributes, attribute)

            if attribute.isActiveDirty then
                table.insert(spec.dirtyAttributes, attribute)
            end
        end
    end)

    if #spec.attributes == 0 then
        SpecializationUtil.removeEventListener(self, "onLoadFinished", ConnectedAttributes)
        SpecializationUtil.removeEventListener(self, "onUpdate", ConnectedAttributes)
    else
        if #spec.dirtyAttributes == 0 then
            SpecializationUtil.removeEventListener(self, "onUpdate", ConnectedAttributes)
        end
    end

    if not hasOnStart then
        SpecializationUtil.removeEventListener(self, "onPlayAnimation", ConnectedAttributes)
    end
    if not hasOnRun then
        SpecializationUtil.removeEventListener(self, "onUpdateAnimation", ConnectedAttributes)
    end
    if not hasOnStop then
        SpecializationUtil.removeEventListener(self, "onFinishAnimation", ConnectedAttributes)
    end
end


---
function ConnectedAttributes:onLoadFinished(savegame)
    local spec = self.spec_connectedAttributes
    for _, attribute in ipairs(spec.attributes) do
        ConnectedAttributes.updateAttribute(attribute, true)
    end
end


---
function ConnectedAttributes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_connectedAttributes
    for i=1, #spec.dirtyAttributes do
        local attribute = spec.dirtyAttributes[i]
        if attribute.maxUpdateDistance == nil or self.currentUpdateDistance < attribute.maxUpdateDistance then
            ConnectedAttributes.updateAttribute(attribute)
        end
    end
end


---
function ConnectedAttributes:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    -- force update of all attributes independent of camera distance right before vehicles starts to sleep
    -- so if we get into the moving part update distance again we are already in the right state without waking up the vehicle
    ConnectedAttributes.onUpdate(self, 99999, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end


---
function ConnectedAttributes:onPlayAnimation(animationName)
    local spec = self.spec_connectedAttributes
    for _, attribute in ipairs(spec.attributes) do
        for _, updateByAnimationData in ipairs(attribute.updateByAnimations) do
            if updateByAnimationData.onStart then
                if updateByAnimationData.animationName == animationName then
                    ConnectedAttributes.updateAttribute(attribute, true)
                    break
                end
            end
        end
    end
end


---
function ConnectedAttributes:onUpdateAnimation(animationName)
    local spec = self.spec_connectedAttributes
    for _, attribute in ipairs(spec.attributes) do
        for _, updateByAnimationData in ipairs(attribute.updateByAnimations) do
            if updateByAnimationData.onRun then
                if updateByAnimationData.animationName == animationName then
                    ConnectedAttributes.updateAttribute(attribute, true)
                    break
                end
            end
        end
    end
end


---
function ConnectedAttributes:onFinishAnimation(animationName)
    local spec = self.spec_connectedAttributes
    for _, attribute in ipairs(spec.attributes) do
        for _, updateByAnimationData in ipairs(attribute.updateByAnimations) do
            if updateByAnimationData.onStop then
                if updateByAnimationData.animationName == animationName then
                    ConnectedAttributes.updateAttribute(attribute, true)
                    break
                end
            end
        end
    end
end


---
function ConnectedAttributes.updateAttribute(attribute, forceUpdate)
    local isActive = true
    for i=1, #attribute.prerequisites do
        if not attribute.prerequisites[i]() then
            isActive = false
            break
        end
    end

    if isActive then
        local values = attribute.values

        local hasChanged = attribute.isActive ~= isActive or forceUpdate
        for sourceIndex=1, #attribute.sources do
            local source = attribute.sources[sourceIndex]
            local object = source.object

            object:get()

            for index, name in pairs(source.values) do
                local value = object.data[index]
                if value ~= values[name] then
                    values[name] = value
                    hasChanged = true
                end
            end
        end

        for i=1, #attribute.combinations do
            local combination = attribute.combinations[i]
            if combination.operation == ConnectedAttributes.COMBINE_OPERATION.AVERAGE then
                local sum = 0
                for j=1, combination.numValues do
                    sum = sum + values[combination.values[j]]
                end
                values[combination.value] = sum / combination.numValues
            elseif combination.operation == ConnectedAttributes.COMBINE_OPERATION.SUM then
                local sum = 0
                for j=1, combination.numValues do
                    sum = sum + values[combination.values[j]]
                end
                values[combination.value] = sum
            elseif combination.operation == ConnectedAttributes.COMBINE_OPERATION.SUBTRACT then
                local value = values[combination.values[1]]
                for j=2, combination.numValues do
                    value = value - values[combination.values[j]]
                end
                values[combination.value] = value
            elseif combination.operation == ConnectedAttributes.COMBINE_OPERATION.MULTIPLY then
                local value = values[combination.values[1]]
                for j=2, combination.numValues do
                    value = value * values[combination.values[j]]
                end
                values[combination.value] = value
            elseif combination.operation == ConnectedAttributes.COMBINE_OPERATION.DIVIDE then
                local value = values[combination.values[1]]
                for j=2, combination.numValues do
                    value = value / values[combination.values[j]]
                end
                values[combination.value] = value
            end
        end

        if hasChanged then
            for targetIndex=1, #attribute.targets do
                local target = attribute.targets[targetIndex]
                local object = target.object
                local data, factors, additionals = object.data, target.factors, target.additionals

                for index, name in pairs(target.values) do
                    data[index] = values[name] * factors[index] + additionals[index]
                end

                object:set()
            end
        end
    end

    attribute.isActive = isActive
end


---
function ConnectedAttributes:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
    if not superFunc(self, xmlFile, baseName, entry) then
        return false
    end

    local connectedAttributeIndices = xmlFile:getValue(baseName.. "#connectedAttributeIndices", nil, true)
    if connectedAttributeIndices ~= nil and #connectedAttributeIndices > 0 then
        entry.connectedAttributeIndices = connectedAttributeIndices
    end

    return true
end


---
function ConnectedAttributes:updateExtraDependentParts(superFunc, part, dt)
    superFunc(self, part, dt)

    if part.connectedAttributeIndices ~= nil then
        local spec = self.spec_connectedAttributes
        for i=1, #part.connectedAttributeIndices do
            local index = part.connectedAttributeIndices[i]
            if spec.attributes[index] ~= nil then
                ConnectedAttributes.updateAttribute(spec.attributes[index])
            end
        end
    end
end


---
function ConnectedAttributes:updateDebugValues(values)
    local spec = self.spec_connectedAttributes
    for i=1, #spec.attributes do
        local attribute = spec.attributes[i]

        if i > 1 then
            table.insert(values, {name="-", value="-"})
        end

        for i=1, #attribute.prerequisites do
            table.insert(values, {name=string.format("prerequisite %d", i), value=string.format("%s", attribute.prerequisites[i]())})
        end

        for sourceIndex=1, #attribute.sources do
            local source = attribute.sources[sourceIndex]
            local object = source.object

            local valueStr = ""
            for _, value in pairs(object.data) do
                valueStr = string.format("%s %.2f", valueStr,  MathUtil.round(value, 2))
            end

            table.insert(values, {name=string.format("source %d (%s)", sourceIndex, object.NAME), value=valueStr})
        end

        local valuesStr = ""
        for name, value in pairs(attribute.values) do
            valuesStr = string.format("%s (%s: %.2f)", valuesStr, name, MathUtil.round(value, 2))
        end
        table.insert(values, {name="current values", value=valuesStr})

        for targetIndex=1, #attribute.targets do
            local target = attribute.targets[targetIndex]
            local object = target.object

            local valueStr = ""
            for _, value in pairs(object.data) do
                valueStr = string.format("%s %.2f", valueStr,  MathUtil.round(value, 2))
            end

            table.insert(values, {name=string.format("target %d (%s)", targetIndex, object.NAME), value=valueStr})
        end
    end
end
