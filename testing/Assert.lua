
















































---Asserts that the given expected and actual objects are equal (==). If they are not, throws an error and prints the given message along with the given values.
-- @param any actual The actual value to check.
-- @param any expected The expected value that the object should have.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.areEqual(actual, expected, message, ...)
    Assert.assert(expected == actual, string.format("expected: %s, actual: %s", tostring(expected), tostring(actual)), message, ...)
end


---Asserts that the given expected and actual objects are not equal (~=). If they are, throws an error and prints the given message along with the given values.
-- @param any actual The actual value to check.
-- @param any expected The expected value that the object should not have.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.areNotEqual(actual, expected, message, ...)
    Assert.assert(expected ~= actual, string.format("expected: %s, actual: %s", tostring(expected), tostring(actual)), message, ...)
end


---Asserts that the given and actual objects are roughly equal taking into account an epsilon value, used to check float values. If they are not, throws an error and prints the given message along with the given values.
-- @param number actual The actual value to check.
-- @param number expected The expected value that the object should roughly have.
-- @param float? epsilon Optional epsilon value, 0.001 by default. The two values are subtracted from each other and compared to this epsilon value.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.areRoughlyEqual(actual, expected, epsilon, message, ...)
    epsilon = epsilon or 0.001

    -- adjust precision of output based on epislon
    local floatFormatStr = string.format("%%.%df", MathUtil.getIndexOfFirstNonZeroFractionDigit(epsilon) + 1)
    local outputFormatStr = string.format("expected: %s, actual: %s, difference: %s, allowed difference: %s", floatFormatStr, floatFormatStr, floatFormatStr, floatFormatStr)

    Assert.assert(math.abs(actual - expected) <= epsilon, string.format(outputFormatStr, tostring(expected), tostring(actual), math.abs(actual - expected), epsilon), message, ...)
end


---Asserts that the given value is between the given upper and lower, inclusive by default. This means that (1,#array) limits will check in the range of a table. If the value is not between the limits, throws an error and prints the given message along with the given values.
-- @param any actual The actual value to check.
-- @param float lowerLimit The lower limit to check against.
-- @param float upperLimit The upper limit to check against.
-- @param boolean? lowerInclusive If the value can be equal to the lower limit. True by default.
-- @param boolean? upperInclusive If the value can be equal to the upper limit. True by default.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isBetween(actual, lowerLimit, upperLimit, lowerInclusive, upperInclusive, message, ...)

    -- Handle setting the default values for the inclusiveness of the lower and upper limits, if they were not given.
    -- Default to both being inclusive for easy array range checking. (1 to #array)
    if lowerInclusive == nil then
        lowerInclusive = true
    end
    if upperInclusive == nil then
        upperInclusive = true
    end

    -- Check the lower and upper limits.
    if lowerInclusive then
        Assert.greaterThanOrEqualTo(actual, lowerLimit, message, ...)
    else
        Assert.greaterThan(actual, lowerLimit, message, ...)
    end
    if upperInclusive then
        Assert.lessThanOrEqualTo(actual, upperLimit, message, ...)
    else
        Assert.lessThan(actual, upperLimit, message, ...)
    end
end


---Check that the given value is greater than the given limit.
-- @param any actual The actual value to check.
-- @param float lowerLimit The limit to check against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.greaterThan(actual, lowerLimit, message, ...)
    Assert.assert(actual > lowerLimit, string.format("lower limit: %s, actual: %s", tostring(lowerLimit), tostring(actual)), message, ...)
end


---Check that the given value is greater than or equal to the given limit.
-- @param any actual The actual value to check.
-- @param float lowerLimit The limit to check against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ...
function Assert.greaterThanOrEqualTo(actual, lowerLimit, message, ...)
    Assert.assert(actual >= lowerLimit, string.format("lower limit: %s, actual: %s", tostring(lowerLimit), tostring(actual)), message, ...)
end


---Check that the given value is less than the given limit.
-- @param any actual The actual value to check.
-- @param float upperLimit The limit to check against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.lessThan(actual, upperLimit, message, ...)
    Assert.assert(actual < upperLimit, string.format("upper limit: %s, actual: %s", tostring(upperLimit), tostring(actual)), message, ...)
end


---Check that the given value is less than or equal to the given limit.
-- @param any actual The actual value to check.
-- @param float upperLimit The limit to check against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.lessThanOrEqualTo(actual, upperLimit, message, ...)
    Assert.assert(actual <= upperLimit, string.format("upper limit: %s, actual: %s", tostring(upperLimit), tostring(actual)), message, ...)
end


---Asserts that the given table is or derives from the given class.
-- @param table actual The table value to check the class of.
-- @param table expectedClass The class table to check the actual table against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isClass(actual, expectedClass, message, ...)

    Assert.isType(expectedClass, "table", "Tried to assert a non-table value as the expected class", ...)
    Assert.isType(actual, "table", message, ...)
    Assert.isNotNil(actual.isa, message, ...)
    Assert.assert(actual:isa(expectedClass), "table is not of the given class", message, ...)
end


---Asserts that the given table is either nil, or is or dervies from the given class.
-- @param table actual The table value to check the class of.
-- @param table expectedClass The class table to check the actual table against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isNilOrClass(actual, expectedClass, message, ...)

    -- If the given value is nil, do nothing more.
    if actual == nil then
        return
    end

    -- Assert the class of the given value.
    Assert.isClass(actual, expectedClass, message, ...)
end


---Asserts that the given value's type matches the given type.
-- @param any object object whose type to check.
-- @param string expectedType The type to check the given value against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isType(object, expectedType, message, ...)
    Assert.assert(type(object) == expectedType, string.format("expected: %s, actual: %s", expectedType, object and type(object) or "nil"), message, ...)
end


---Asserts that the given value is either nil or whose type matches the given type.
-- @param any object object whose type to check.
-- @param string expectedType The type to check the given value against.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isNilOrType(object, expectedType, message, ...)
    Assert.assert(object == nil or type(object) == expectedType, string.format("or nil expected: %s, actual: %s", expectedType, object and type(object) or "nil"), message, ...)
end


---Asserts that the given object is nil.
-- @param any actual The actual value to check.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isNil(actual, message, ...)
    Assert.assert(actual == nil, "value was not nil", message, ...)
end


---Asserts that the given object is not nil.
-- @param any actual The actual value to check.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isNotNil(actual, message, ...)
    Assert.assert(actual ~= nil, "value was nil", message, ...)
end


---Asserts that the given object is a string that is not nil or whitespace.
-- @param any actual The actual value to check.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isStringNotNilOrEmpty(actual, message, ...)
    Assert.assert(actual == nil or type(actual) == "string", string.format("object %s was not nil or a string", tostring(actual)), message, ...)
    Assert.assert(not string.isNilOrWhitespace(actual), string.format("string %q was nil or whitespace", tostring(actual)), message, ...)
end


---Asserts that the given value is not nil and an integer, where value == math.floor(value)
-- @param any actual The actual value to check.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isInteger(actual, message, ...)
    Assert.assert(type(actual) == "number" and actual == math.floor(actual), string.format("value %s is not an integer", tostring(actual)), message, ...)
end


---Asserts that the given node id is not nil, is a number greater than 0, and exists using entityExists().
-- @param integer node The node id to check.
-- @param string? message The optional string message to be appended to the default assert message.
-- @param any ... arguments passed into the message using string.format
function Assert.entityExists(node, message, ...)
    Assert.isNotNil(node, message, ...)
    Assert.isType(node, "number", ...)
    Assert.greaterThan(node, 0, message, ...)
    Assert.isTrue(entityExists(node), message, ...)
end


---Asserts that the given boolean is true.
-- @param boolean actual The actual value to check.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isTrue(actual, message, ...)

    -- Explicitly test against true to ensure the object is also a boolean.
    Assert.assert(actual == true, "value was not true", message, ...)
end


---Asserts that the given boolean is false.
-- @param boolean actual The actual value to check.
-- @param string? message The optional string message to be appended to the default assert message. Note that the default message includes the expected and actual values.
-- @param any ... arguments passed into the message using string.format
function Assert.isFalse(actual, message, ...)

    -- Explicitly test against false to ensure the object is also a boolean.
    Assert.assert(actual == false, "value was not false", message, ...)
end


---Asserts that the given function fails a pcall test
-- @param function testFunction The function to run.
-- @param string? message The optional string message to be used as an error message.
-- @param any ... arguments passed into the message using string.format
function Assert.throwsError(testFunction, message, ...)

    -- Run the function in protected mode.
    local status = pcall(testFunction)

    -- Ensure the status is false (the function failed).
    Assert.assert(not status, "function threw no error", message, ...)
end


---Asserts that the given table contains an element with the given key.
-- @param table actualTable The table whose contents to check.
-- @param any key The key to use on the table.
-- @param string? message The optional string message to be used as an error message.
-- @param any ... arguments passed into the message using string.format
function Assert.hasKey(actualTable, key, message, ...)
    Assert.isType(actualTable, "table", message)
    Assert.isNotNil(key, message)
    Assert.assert(actualTable[key] ~= nil, string.format("table was missing element with key %s", tostring(key)), message, ...)
end


---Asserts that the given table does not contain an element with the given key.
-- @param table actualTable The table whose contents to check.
-- @param any key The key to use on the table.
-- @param string? message The optional string message to be used as an error message.
-- @param any ... arguments passed into the message using string.format
function Assert.hasNoKey(actualTable, key, message, ...)
    Assert.isType(actualTable, "table", message)
    Assert.isNotNil(key, message)
    Assert.assert(actualTable[key] == nil, string.format("table has element with key %s", tostring(key)), message, ...)
end


---Immediately fails assertion and prints the given message as an error.
-- @param string? message The optional string message to be appended to the default assert message.
-- @param any ... arguments passed into the message using string.format
function Assert.fail(message, ...)
    Assert.assert(false, "force failed", message, ...)
end
