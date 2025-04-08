














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableWeighingStation.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableWeighingStation.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "onWeighingTriggerCallback", PlaceableWeighingStation.onWeighingTriggerCallback)
    SpecializationUtil.registerFunction(placeableType, "updateWeightDisplay", PlaceableWeighingStation.updateWeightDisplay)
    SpecializationUtil.registerFunction(placeableType, "setWeightDisplay", PlaceableWeighingStation.setWeightDisplay)
end


---
function PlaceableWeighingStation.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWeighingStation)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWeighingStation)
end


---
function PlaceableWeighingStation.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("WeighingStation")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".weighingStation#triggerNode", "Vehicle trigger")

    schema:register(XMLValueType.NODE_INDEX, basePath .. ".weighingStation.display(?)#node", "Display start node")
    schema:register(XMLValueType.STRING,     basePath .. ".weighingStation.display(?)#font", "Display font name")
    schema:register(XMLValueType.STRING, basePath .. ".weighingStation.display(?)#alignment", "Display text alignment")
    schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#size", "Display text size")
    schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#scaleX", "Display text x scale")
    schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#scaleY", "Display text y scale")
    schema:register(XMLValueType.STRING, basePath .. ".weighingStation.display(?)#mask", "Display text mask")
    schema:register(XMLValueType.FLOAT, basePath .. ".weighingStation.display(?)#emissiveScale", "Display emissive scale")
    schema:register(XMLValueType.COLOR, basePath .. ".weighingStation.display(?)#color", "Display text color")
    schema:register(XMLValueType.COLOR, basePath .. ".weighingStation.display(?)#hiddenColor", "Display text hidden color")

    schema:setXMLSpecializationType()
end


---Called on loading
-- @param table savegame savegame
function PlaceableWeighingStation:onLoad(savegame)
    local spec = self.spec_weighingStation

    local key = "placeable.weighingStation"

    spec.trigger = self.xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings)
    if spec.trigger == nil then
        Logging.xmlError(self.xmlFile, "Missing vehicle triggerNode for weighing station")
        return
    end

    addTrigger(spec.trigger, "onWeighingTriggerCallback", self)
    spec.triggerVehicleNodes = {}
    spec.vehicles = {}

    spec.displays = {}
    self.xmlFile:iterate(key .. ".display", function(_, displayKey)
        local displayNode = self.xmlFile:getValue(displayKey .. "#node", nil, self.components, self.i3dMappings)
        if displayNode ~= nil then
            local fontName = self.xmlFile:getValue(displayKey .. "#font", "DIGIT"):upper()
            local fontMaterial = g_materialManager:getFontMaterial(fontName, self.customEnvironment)

            if fontMaterial ~= nil then
                local display = {}

                local alignmentStr = self.xmlFile:getValue(displayKey .. "#alignment", "RIGHT")
                local alignment = RenderText["ALIGN_" .. alignmentStr:upper()] or RenderText.ALIGN_RIGHT

                local size = self.xmlFile:getValue(displayKey .. "#size", 0.03)
                local scaleX = self.xmlFile:getValue(displayKey .. "#scaleX", 1)
                local scaleY = self.xmlFile:getValue(displayKey .. "#scaleY", 1)
                local mask = self.xmlFile:getValue(displayKey .. "#mask", "00.0")
                local emissiveScale = self.xmlFile:getValue(displayKey .. "#emissiveScale", 0.2)
                local color = self.xmlFile:getValue(displayKey .. "#color", {0.9, 0.9, 0.9, 1}, true)
                local hiddenColor = self.xmlFile:getValue(displayKey .. "#hiddenColor", nil, true)

                display.displayNode = displayNode
                display.formatStr, display.formatPrecision = Utils.maskToFormat(mask)

                display.characterLine = CharacterLine.new(displayNode, fontMaterial, mask:len())
                display.characterLine:setSizeAndScale(size, scaleX, scaleY)
                display.characterLine:setTextAlignment(alignment)
                display.characterLine:setColor(color, hiddenColor, emissiveScale)

                table.insert(spec.displays, display)
            end
        end
    end)

    self:setWeightDisplay(0)
end


---
function PlaceableWeighingStation:onDelete()
    local spec = self.spec_weighingStation

    if spec.trigger ~= nil then
        removeTrigger(spec.trigger)
        spec.trigger = nil
    end
end


---
function PlaceableWeighingStation:updateWeightDisplay()
    local spec = self.spec_weighingStation

    -- resolve nodes to vehicles, add to table to eliminate duplicates
    for node, _ in pairs(spec.triggerVehicleNodes) do
        if entityExists(node) then
            local vehicle = g_currentMission:getNodeObject(node)
            if vehicle ~= nil and vehicle.getTotalMass ~= nil then
                spec.vehicles[vehicle] = true
            end
        else
            -- vehicle does not exist anymore
            spec.triggerVehicleNodes[node] = nil
        end
    end

    local mass = 0
    for vehicle in pairs(spec.vehicles) do
        mass = mass + vehicle:getTotalMass(true)
    end
    table.clear(spec.vehicles)

    self:setWeightDisplay(mass*1000)
end


---
function PlaceableWeighingStation:setWeightDisplay(mass)
    local spec = self.spec_weighingStation
    for _, display in ipairs(spec.displays) do
        local int, floatPart = math.modf(mass)

        local value = string.format(display.formatStr, int, math.abs(math.floor(floatPart * (10 ^ display.formatPrecision))))
        display.characterLine:setText(value)
    end
end


---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherId id of actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
function PlaceableWeighingStation:onWeighingTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if onEnter or onLeave then
        local spec = self.spec_weighingStation
        if onEnter then
            spec.triggerVehicleNodes[otherId] = true
        else
            -- on leave
            spec.triggerVehicleNodes[otherId] = nil
        end

        self:updateWeightDisplay()
    end
end
