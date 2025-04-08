









---Holds a function and an optional target object to make event functions simpler.
local TargetedFunction_mt = Class(TargetedFunction)


---Creates a new listener function with the given function and target object.
-- @param function targetFunction The function that is called.
-- @param table? targetObject The optional object used to call the function.
-- @param any ... optional arguments for the function
-- @return TargetedFunction instance The created instance.
function TargetedFunction.new(targetFunction, targetObject, ...)

    --#debug assert(type(targetFunction) == "function", "Given listener function was not a function.")
    --#debugif targetObject ~= nil then
    --#debug    assert(type(targetObject) == "table", "Given target object was not a table.")
    --#debug end

    -- Create the instance.
    local self = setmetatable({}, TargetedFunction_mt)

    -- Set the values.
    self.targetFunction = targetFunction
    self.targetObject = targetObject

    -- The arguments of the function.
    self.arguments = table.pack(...)

    -- Return the created instance.
    return self
end


---Unbinds the function and target.
function TargetedFunction:delete()
    self.targetFunction = nil
    self.targetObject = nil
end


---Takes a listener function and an optional target object. If the listener function is a TargetedFunction, returns it as-is. Otherwise; wraps the function and optional target object in a TargetedFunction and returns it.
-- @param function targetFunction The function or TargetedFunction to wrap or return.
-- @param table? targetObject The optional target object, used to wrap the function.
-- @return TargetedFunction targetFunction The wrapped or returned TargetedFunction.
function TargetedFunction.resolveListener(targetFunction, targetObject)

    -- If the target function is a function, wrap it in a TargetedFunction and return it.
    if type(targetFunction) == "function" then
        return TargetedFunction.new(targetFunction, targetObject)
    -- Otherwise; assume it's already a TargetedFunction and return it as-is.
    else
        return targetFunction
    end
end


---Combines this function's arguments with the given arguments, returning each value separately.
-- @param any ... The arguments to pack.
-- @return any ... Multiple values, starting with each element in this function's arguments, then each element in the given arguments.
function TargetedFunction:unpackCombinedArguments(...)
    return table.unpack(table.getListUnion(self.arguments, table.pack(...)))
end


---Calls the function with the given arguments.
-- @param any ... The collection of arguments to pass to the function.
-- @return any value The return value of the function.
function TargetedFunction:invoke(...)

    -- Call the function with the optional object.
    if self.targetObject then
        if self.arguments.n == 0 then
            return self.targetFunction(self.targetObject, ...)
        else
            return self.targetFunction(self.targetObject, self:unpackCombinedArguments(...))
        end
    else
        if self.arguments.n == 0 then
            return self.targetFunction(...)
        else
            return self.targetFunction(self:unpackCombinedArguments(...))
        end
    end
end


---Metamethod so the table itself can be called as a shortcut for :invoke().
-- @param TargetedFunction instance The instance of the listener function.
-- @param any ... The collection of arguments to pass to the function.
-- @return any value The return value of the function.
function TargetedFunction_mt.__call(instance, ...)
    return instance:invoke(...)
end
