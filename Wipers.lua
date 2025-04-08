














---
function Wipers.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Enterable, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end


---
function Wipers.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("Wipers")

    schema:register(XMLValueType.STRING, "vehicle.wipers.wiper(?)#animName", "Animation name")
    schema:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animSpeed", "Animation speed")
    schema:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animPause", "Animation pause time (sec.)")

    Dashboard.registerDashboardXMLPaths(schema, "vehicle.wipers.dashboards", {"state"})

    schema:setXMLSpecializationType()
end


---
function Wipers.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "loadWiperFromXML", Wipers.loadWiperFromXML)
    SpecializationUtil.registerFunction(vehicleType, "getIsActiveForWipers", Wipers.getIsActiveForWipers)
end


---
function Wipers.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wipers)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Wipers)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wipers)
    SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", Wipers)
end


---
function Wipers:onLoad(savegame)
    local spec = self.spec_wipers

    spec.wipers = {}

    local i = 0
    while true do
        local key = string.format("vehicle.wipers.wiper(%d)", i)
        if not self.xmlFile:hasProperty(key) then
            break
        end

        local wiper = {}
        if self:loadWiperFromXML(self.xmlFile, key, wiper) then
            wiper.lastValidState = 1
            wiper.lastState = 0
            table.insert(spec.wipers, wiper)
        end

        i = i + 1
    end

    spec.hasWipers = #spec.wipers > 0
    spec.lastRainScale = 0.0

    spec.maxStateWiper = nil
    local maxNumWiperStates = 0
    for _, wiper in ipairs(spec.wipers) do
        local numStates = #wiper.states
        if numStates > maxNumWiperStates then
            maxNumWiperStates = numStates
            spec.maxStateWiper = wiper
        end
    end

    if not spec.hasWipers then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", Wipers)
    end
end


---Called on post load to register dashboard value types
function Wipers:onRegisterDashboardValueTypes()
    local spec = self.spec_wipers

    if spec.maxStateWiper ~= nil then
        local state = DashboardValueType.new("wipers", "state")
        state:setValue(spec.maxStateWiper, "lastState")
        self:registerDashboardValueType(state)
    end
end


---
function Wipers:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_wipers

    if self:getIsControlled() then
        spec.lastRainScale = g_currentMission.environment.weather:getRainFallScale()

        for _, wiper in pairs(spec.wipers) do
            local stateIdToUse = 0
            if self:getIsActiveForWipers() then
                if spec.lastRainScale > 0.01 then -- small etha for the long tail
                    for stateIndex,state in ipairs(wiper.states) do
                        if spec.lastRainScale <= state.maxRainValue then
                            stateIdToUse = stateIndex
                            break
                        end
                    end
                end
            end

            if Wipers.forcedState ~= -1 then
                stateIdToUse = math.clamp(Wipers.forcedState, 0, #wiper.states)
            end

            if stateIdToUse > 0 then
                local currentState = wiper.states[stateIdToUse]

                if wiper.nextStartTime == nil or wiper.nextStartTime < g_currentMission.time then
                    if not self:getIsAnimationPlaying(wiper.animName) then
                        self:playAnimation(wiper.animName, currentState.animSpeed, 0, true)
                        wiper.nextStartTime = nil
                    end
                end

                if wiper.nextStartTime == nil then
                    wiper.nextStartTime = g_currentMission.time + (wiper.animDuration / currentState.animSpeed) * 2 + currentState.animPause
                end

                wiper.lastValidState = stateIdToUse
            end

            wiper.lastState = stateIdToUse
        end
    end
end


---
function Wipers:onFinishAnimation(name)
    local spec = self.spec_wipers
    for _, wiper in pairs(spec.wipers) do
        if wiper.animName == name and self:getAnimationTime(wiper.animName) == 1 then
            local lastValidState = wiper.states[wiper.lastValidState]
            self:playAnimation(wiper.animName, -lastValidState.animSpeed, 1, true)
        end
    end
end


---
function Wipers:loadWiperFromXML(xmlFile, key, wiper)
    local animName = xmlFile:getValue(key .. "#animName")
    if animName ~= nil then
        if self:getAnimationExists(animName) then
            wiper.animName = animName
            wiper.animDuration = self:getAnimationDuration(animName)
            wiper.states = {}
            local j = 0
            while true do
                local stateKey = string.format("%s.state(%d)", key, j)
                if not xmlFile:hasProperty(stateKey) then
                    break
                end

                local state = {}
                state.animSpeed = xmlFile:getValue(stateKey .. "#animSpeed")
                state.animPause = xmlFile:getValue(stateKey .. "#animPause")
                if state.animSpeed ~= nil and state.animPause ~= nil then
                    state.animPause = state.animPause * 1000
                    table.insert(wiper.states, state)
                end

                j = j + 1
            end
        else
            Logging.xmlWarning(self.xmlFile, "Animation '%s' not defined for wiper '%s'!", animName, key)
            return false
        end
    else
        Logging.xmlWarning(self.xmlFile, "Missing animation for wiper '%s'!", key)
        return false
    end

    local numStates = #wiper.states
    if numStates > 0 then
        local stepSize = 1.0 / numStates
        local curMax = stepSize

        for _,state in ipairs(wiper.states) do
            state.maxRainValue = curMax
            curMax = curMax + stepSize
        end

        wiper.nextStartTime = nil
    else
        Logging.xmlWarning(self.xmlFile, "No states defined for wiper '%s'!", key)
        return false
    end

    return true
end


---
function Wipers:getIsActiveForWipers()
    return true
end


---
function Wipers:consoleSetWiperState(state)
    local usage = "Usage: gsWiperStateSet <state> (-1 = use state from weather; 0..n = force specific wiper state)"
    if state == nil then
        return "Error: No arguments given! " .. usage
    end

    state = tonumber(state)
    if state == nil then
        return "Error: Argument is not a number! " .. usage
    end
    Wipers.forcedState = math.clamp(state, -1, 999)

    return(Wipers.forcedState == -1 and " Reset global wiper state, now using weather state") or string.format("Set global wiper states to %d.", Wipers.forcedState)
end
