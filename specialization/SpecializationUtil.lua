













---Raises a specialization event async
-- 
-- @param table object an object that supports specializations
-- @param string eventName the event name
-- @param any ... the parameters
function SpecializationUtil.raiseAsyncEvent(object, eventName, ...)
    if object.eventListeners[eventName] == nil then
        local typeName = object.type and object.type.name or "<unknown>"
        printError(string.format("Error: Event %q is not registered for type %q!", eventName, typeName))
        printCallstack()
        return
    end

    local args = {...}
    for _, spec in ipairs(object.eventListeners[eventName]) do
        object:addAsyncTask(function()
            --#profile local doProfiling, profileName = Vehicle.PROFILE_EVENTS[eventName], spec.className .. ":" .. eventName
            --#profile if doProfiling then RemoteProfiler.zoneBeginN(profileName) end
            spec[eventName](object, unpack(args))
            --#profile if doProfiling then RemoteProfiler.zoneEnd() end
        end, spec.className, false)
    end
end



---Raises a specialization event
-- 
-- @param table object an object that supports specializations
-- @param string eventName the event name
-- @param any ... the parameters
function SpecializationUtil.raiseEvent(object, eventName, ...)
    if object.eventListeners[eventName] == nil then
        local typeName = object.type and object.type.name or "<unknown>"
        printError(string.format("Error: Event %q is not registered for type %q!", eventName, typeName))
        printCallstack()
        return
    end

    for _, spec in ipairs(object.eventListeners[eventName]) do
        --#profile local doProfiling, profileName = Vehicle.PROFILE_EVENTS[eventName], spec.className .. ":" .. eventName
        --#profile if doProfiling then RemoteProfiler.zoneBeginN(profileName) end
        spec[eventName](object, ...)
        --#profile if doProfiling then RemoteProfiler.zoneEnd() end
    end
end



---Registers a function to a given object type
-- 
-- @param table objectType the object type
-- @param string funcName the function name
-- @param function func the function pointer
function SpecializationUtil.registerFunction(objectType, funcName, func)
    if string.isNilOrWhitespace(funcName) then
        Logging.error("Given function name is is 'nil' or empty!")
        printCallstack()
        return
    end

    if func == nil then
        Logging.error("Given reference for Function '%s' is 'nil'!", funcName)
        printCallstack()
        return
    end

    if objectType.functions[funcName] ~= nil then
        Logging.error("Function '%s' already registered as function in type '%s'!", funcName, objectType.name)
        printCallstack()
        return
    end

    if objectType.events[funcName] ~= nil then
        Logging.error("Function '%s' already registered as event in type '%s'!", funcName, objectType.name)
        printCallstack()
        return
    end

    objectType.functions[funcName] = func
end



---Overwrites a function of an object type
-- 
-- @param table objectType the object type
-- @param string funcName the function name
-- @param function func the function pointer
function SpecializationUtil.registerOverwrittenFunction(objectType, funcName, func)
    if string.isNilOrWhitespace(funcName) then
        Logging.error("Given function name is is 'nil' or empty!")
        printCallstack()
        return
    end

    if func == nil then
        Logging.error("Given reference for OverwrittenFunction '%s' is 'nil'!", funcName)
        printCallstack()
        return
    end

    -- if function does not exist, we don't need to overwrite anything
    if objectType.functions[funcName] ~= nil then
        objectType.functions[funcName] = Utils.overwrittenFunction(objectType.functions[funcName], func)
    end
end



---Registers an event to a given object type
-- 
-- @param table objectType the object type
-- @param string eventName the event name
function SpecializationUtil.registerEvent(objectType, eventName)
    if string.isNilOrWhitespace(eventName) then
        Logging.error("Given name for event is 'nil' or empty!")
        printCallstack()
        return
    end

    if objectType.functions[eventName] ~= nil then
        Logging.error("Event '%s' already registered as function in type '%s'!", eventName, objectType.name)
        printCallstack()
        return
    end

    if objectType.events[eventName] ~= nil then
        Logging.error("Event '%s' already registered as event in type '%s'!", eventName, objectType.name)
        printCallstack()
        return
    end

    objectType.events[eventName] = eventName
    objectType.eventListeners[eventName] = {}
end



---Registers an event listener to an object type
-- 
-- @param table objectType the object type
-- @param string eventName the event name
-- @param table specClass the specialization class
function SpecializationUtil.registerEventListener(objectType, eventName, specClass)
    if string.isNilOrWhitespace(eventName) then
        Logging.error("Given event name is is 'nil' or empty!")
        printCallstack()
        return
    end

    local className = specClass.className

    if objectType.eventListeners == nil then
        Logging.error("Invalid type for specialization '%s'!", className)
        printCallstack()
        return
    end

    if specClass[eventName] == nil then
        Logging.error("Event listener function '%s' not defined in specialization '%s'!", eventName, className)
        printCallstack()
        return
    end

    if objectType.eventListeners[eventName] == nil then
        return
    end

    local found = false
    for _, registeredSpec in pairs(objectType.eventListeners[eventName]) do
        if registeredSpec == specClass then
            found = true
            break
        end
    end

    if found then
        Logging.error("Event listener for '%s' already registered in specialization '%s'!", eventName, className)
        printCallstack()
        return
    end

    table.insert(objectType.eventListeners[eventName], specClass)
end



---Removes an event listener from an object
-- 
-- @param table object a object that supports specializations
-- @param string eventName the event name
-- @param table specClass a specialization class
function SpecializationUtil.removeEventListener(object, eventName, specClass)
    local listeners = object.eventListeners[eventName]
    if listeners ~= nil then
        for i=#listeners, 1, -1 do
            if listeners[i] == specClass then
                table.remove(listeners, i)
            end
        end
    end
end



---Checks if a specialzation is in a list of specializations
-- 
-- @param table spec a specialization class
-- @param table specializations list of specializations
-- @return boolean true if spec is in specialization list
function SpecializationUtil.hasSpecialization(spec, specializations)
    for _,v in pairs(specializations) do
        if v == spec then
            return true
        end
    end

    return false
end


---
-- @param any typeManager
-- @param any typeDef
-- @param table target
-- @return any typeDef
function SpecializationUtil.initSpecializationsIntoTypeClass(typeManager, typeDef, target)
    target.type = typeDef
    target.typeName = typeDef.name
    target.specializations = typeDef.specializations
    target.specializationNames = typeDef.specializationNames
    target.specializationsByName = typeDef.specializationsByName
    target.eventListeners = table.clone(typeDef.eventListeners, 2)

    return typeDef
end


---Copies the functions from the given type into the given target object.
-- @param table typeDef The type to copy from.
-- @param table target The target table to copy into.
function SpecializationUtil.copyTypeFunctionsInto(typeDef, target)
    for funcName, func in pairs(typeDef.functions) do
        target[funcName] = func
    end
end





































---Creates a loading task on the given typeClass's loadingTasks table with the given target and returns it.
-- @param table typeClass The class instance of the specialisation type.
-- @param any target The id or reference used to track the loading task.
-- @return table task The created loading task.
function SpecializationUtil.createLoadingTask(typeClass, target)

    --#debug Assert.isType(typeClass.loadingTasks, "table", "Type class is missing loadingTasks table!")

    -- Create, add, and return the task.
    local task = {
        target = target
    }

    table.insert(typeClass.loadingTasks, task)

    return task
end


---Marks the given task as done, and calls the onFinishedLoading function of the given typeClass, if its readyForFinishLoading value evaluates to true.
-- @param table typeClass The class instance of the specialisation type.
-- @param table task The task to mark as complete. Should be obtained from SpecializationUtil.createLoadingTask.
function SpecializationUtil.finishLoadingTask(typeClass, task)

    --#debug Assert.isType(typeClass.onFinishedLoading, "function", "Type class is missing onFinishedLoading function!")
    --#debug Assert.isType(typeClass.loadingTasks, "table", "Type class is missing loadingTasks table! This can be caused by a lack of calls to createLoadingTask, in such a way that the loading completes instantly")
    --#debug Assert.greaterThan(#typeClass.loadingTasks, 0, "Nothing was loading, yet a task was finished!")

    -- Remove the task from the list. If it does not get removed, log a warning but still continue like normal.
    if not table.removeElement(typeClass.loadingTasks, task) then
        Logging.warning("Loading task was marked as finished, but was never added in the first place. Ensure that every finishLoadingTask call uses a task given from the createLoadingTask function.")
    end

    -- If the type class is ready for the finish loading call, and all tasks have been completed, call the onFinishedLoading function.
    if typeClass.readyForFinishLoading and #typeClass.loadingTasks == 0 then
        typeClass:onFinishedLoading()
    end
end


---Sets the loadingStep value of the given specialisation type class, logging an error if the given step is invalid.
-- @param table typeClass The class instance of the specialisation type.
-- @param SpecializationLoadStep loadingStep The loading step to set.
function SpecializationUtil.setLoadingStep(typeClass, loadingStep)

    -- If the given step type is not a valid SpecializationLoadStep value, log the error and return.
    if not SpecializationUtil.getIsValidLoadingStep(loadingStep) then
        printCallstack()
        Logging.error("Invalid loading step '%s'!", loadingStep)
        return
    end

    -- Set the loading step.
    typeClass.loadingStep = loadingStep
end


---Checks if the given loading step is a valid enum value of SpecializationLoadStep.
-- @param SpecializationLoadStep loadingStep The loading step to check.
-- @return boolean isValid True if the given loadingStep is a valid enum value; otherwise false.
function SpecializationUtil.getIsValidLoadingStep(loadingStep)

    -- Check the given value against each value in the enum. If it matches any; return true.
    for _, value in pairs(SpecializationLoadStep) do
        if value == loadingStep then
            return true
        end
    end

    -- Otherwise; since no match was found, return false.
    return false
end
