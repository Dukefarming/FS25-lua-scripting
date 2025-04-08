









---A class holding 4 values representing a color, with functions for converting to and from multiple formats, and an indexer supporting numeric indexing and swizzling.
local Color_mt = Class(Color)


---Index metafunction that overrides the basic inheritence system with numeric indexing and swizzling as a final step.
-- @param Color color The color instance.
-- @param string key The key that is being used to index the color.
-- @return any value The indexed value.
function Color_mt.__index(color, key)

    -- Attempt to get the value from the actual instance table first.
    local value = rawget(color, key)
    if value ~= nil then
        return value
    end

    -- Next, try to get the value from the class table.
    value = Color[key]
    if value ~= nil then
        return value
    end

    -- Next, if the key is a number between 1 and 4, index as if it were an array.
    if type(key) == "number" and key > 0 and key <= 4 then
        if key == 1 then
            return color.r
        elseif key == 2 then
            return color.g
        elseif key == 3 then
            return color.b
        else
            return color.a
        end
    end

    -- Lastly, try to swizzle the key.
    return Color.swizzle(color, key)
end


---Metafunction allowing colors to be easily blended using multiplication with either a table, number, or another color.
-- @param (table|number|Color) left The left value to multiply.
-- @param (table|number|Color) right The right value to multiply.
-- @return Color color The multiplied color.
function Color_mt.__mul(left, right)

    -- Handle two tables. These can either be vector arrays or colors.
    if type(left) == "table" and type(right) == "table" then

        -- Ensure rgb exist.
        for i=1,3 do
            if left[i] == nil or right[i] == nil then
                Assert.fail("Cannot multiply between two tables that do not both have indices 1, 2, and 3!")
            end
        end

        -- Multiply the rgb.
        local r, g, b = math.clamp(left[1] * right[1], 0, 1), math.clamp(left[2] * right[2], 0, 1), math.clamp(left[3] * right[3], 0, 1)

        -- If both tables have alpha then multiply them. Otherwise, take the existing alpha, or default to 1.
        local a
        if left[4] ~= nil and right[4] ~= nil then
            a = math.clamp(left[4] * right[4], 0, 1)
        else
            a = left[4] or right[4] or 1
        end

        -- Return the multiplied color.
        return Color.new(r, g, b, a)
    end

    -- Handle multiplying by a number. This affects all values.
    if type(left) == "number" then
        return Color.new(math.clamp(right[1] * left, 0, 1), math.clamp(right[2] * left, 0, 1), math.clamp(right[3] * left, 0, 1), math.clamp((right[4] or 1) * left, 0, 1))
    elseif type(right) == "number" then
        return Color.new(math.clamp(left[1] * right, 0, 1), math.clamp(left[2] * right, 0, 1), math.clamp(left[3] * right, 0, 1), math.clamp((left[4] or 1) * right, 0, 1))
    end

    -- If no valid operation could be found, fail.
    Assert.fail("attempt to perform arithmetic (mul) on %s and %s", type(left), type(right))
    return nil
end


---Creates a new color from the given channels, from 0 to 1.
-- @param float r The red channel.
-- @param float g The green channel.
-- @param float b The blue channel.
-- @param float? a The alpha channel.
-- @return Color self The created instance.
function Color.new(r, g, b, a)

    --#debug Assert.isNilOrType(r, "number", "Red channel was not number or nil!")
    --#debug Assert.isNilOrType(g, "number", "Green channel was not number or nil!")
    --#debug Assert.isNilOrType(b, "number", "Blue channel was not number or nil!")
    --#debug Assert.isNilOrType(a, "number", "Alpha channel was not number or nil!")

    -- Create the instance.
    local self = setmetatable({}, Color_mt)

    -- Set the color channels, defaulting to solid black.
    self.r = r or 0
    self.g = g or 0
    self.b = b or 0
    self.a = a or 1

    --#debug Assert.isBetween(self.r, 0, 1, nil, nil, "Red channel was out of range!")
    --#debug Assert.isBetween(self.g, 0, 1, nil, nil, "Green channel was out of range!")
    --#debug Assert.isBetween(self.b, 0, 1, nil, nil, "Blue channel was out of range!")
    --#debug Assert.isBetween(self.a, 0, 1, nil, nil, "Alpha channel was out of range!")

    -- Return the created instance.
    return self
end


---Returns a copy of this color.
-- @return Color copy The copied color.
function Color:copy()
    return Color.new(self.r, self.g, self.b, self.a)
end


---Copies this color's values into the given color.
-- @param Color color The color into which to copy the values.
function Color:copyTo(color)
    color.r, color.g, color.b, color.a = self.r, self.g, self.b, self.a
end


---Attempts to parse the given string as a color. Attempting; in the following order: hex, preset, brand color (if g_vehicleMaterialManager is not nil), packed value, then vector value, then finally nil.
-- @param string inputString The string input to parse.
-- @param boolean? ignoreAlpha If this is true, alpha will not be included in the final color.
-- @return Color color The parsed color, or nil if the string could not be parsed.
function Color.parseFromString(inputString, ignoreAlpha)

    -- If the given input is not a string, do nothing.
    if type(inputString) ~= "string" then
        return nil
    end

    -- If the string starts with a hash '#' character, then parse it as a hex value.
    if string.startsWith(inputString, '#') then
        return Color.fromHex(inputString)
    end
    -- Try to parse the string as a packed value. If it's a valid packed value color, return it.
    local color = Color.fromPackedValue(inputString)
    if color ~= nil then
        if ignoreAlpha then
            color.a = 1
        end
        return color
    end

    -- Try to parse the string as a vector, then the vector as a color. If it's a valid RGBA vector color, return it.
    local vector = string.split(inputString, " ", tonumber)
    if #vector >= 3 then
        if ignoreAlpha then
            return Color.new(vector[1], vector[2], vector[3])
        else
            return Color.new(vector[1], vector[2], vector[3], vector[4])
        end
    end

    -- If there is a brand color manager and it contains a color with the given string as a name, return it.
    if g_vehicleMaterialManager ~= nil then
        color = Color.fromVector(g_vehicleMaterialManager:getMaterialTemplateColorByName(inputString), nil, 3)
        if color ~= nil then
            if ignoreAlpha then
                color.a = 1
            end
            return color
        end
    end

    -- If there is a preset with the given string as a name, return it.
    color = Color.fromPresetName(inputString)
    if color ~= nil then
        if ignoreAlpha then
            color.a = 1
        end
        return color
    end

    -- The input string was not valid, so return nil.
    return nil
end


---Gets the preset from the given name, case insensitive. See Color.PRESETS.
-- @param string presetName The name of the preset to get.
-- @return Color preset The preset with the given name, or nil if none was found.
function Color.fromPresetName(presetName)

    -- If the given name is not a string, do nothing.
    if type(presetName) ~= "string" then
        return nil
    end

    -- Return the preset with the given name in capitals.
    return Color.PRESETS[string.upper(presetName)]
end


---Creates a new color from the given 32-bit packed color.
-- @param integer packedValue The 32-bit integer value from which to unpack the color.
-- @return Color color The created color.
function Color.fromPackedValue(packedValue)

    -- If the given type is a string, turn it into a number.
    if type(packedValue) == "string" then
        packedValue = tonumber(packedValue)
    end

    -- If the given type is not a number, return nil.
    if type(packedValue) ~= "number" then
        return nil
    end

    -- Unpack the individual channels from the packed value and normalise them between 0 and 1.
    local r = bitAND(packedValue, 0x000000ff) / 255
    local g = bitShiftRight(bitAND(packedValue, 0x0000ff00), 8) / 255
    local b = bitShiftRight(bitAND(packedValue, 0x00ff0000 ), 16) / 255
    local a = bitShiftRight(bitAND(packedValue, 0xff000000 ), 24) / 255

    -- Return the unpacked color.
    return Color.new(r, g, b, a)
end


---Creates a 32-bit packed integer value from this color.
-- @return integer packedValue The 32-bit integer packed value.
function Color:toPackedValue()

    -- Pack each channel into the value and return it.
    local packedValue = math.ceil(self.r * 255)
    packedValue = bitOR(packedValue, bitShiftLeft(math.ceil(self.g * 255), 8))
    packedValue = bitOR(packedValue, bitShiftLeft(math.ceil(self.b * 255), 16))
    packedValue = bitOR(packedValue, bitShiftLeft(math.ceil(self.a * 255), 24))
    return packedValue
end


---Creates a color from the given hex code, with or without the preceeding '#' character.
-- @param string hexString The hex string to turn into a color.
-- @return Color color The created color.
function Color.fromHex(hexString)

    -- If the given value is not a string, do nothing.
    if type(hexString) ~= "string" then
        return nil
    end

    -- If the given value is a string and begins with '#' as many color codes do, remove it.
    if type(hexString) == "string" and string.startsWith(hexString, '#') then
        hexString = string.sub(hexString, 2)
    end

    -- Read the hex string has a hex value. If it failed to parse, return nil.
    local packedValue = tonumber(hexString, 16)
    if packedValue == nil then
        return nil
    end

    -- Create the color from a packed value.
    return Color.fromPackedValue(packedValue)
end


---Converts this color into a hex code, with or without the preceeding '#' character based on the given includeHash parameter.
-- @param boolean includeHash If this evaluates to true, the given hex code will start with a '#' character. Otherwise it will be a plain hex value.
-- @return string hexString The calculated hex string representing the color.
function Color:toHex(includeHash)

    local packedValue = self:toPackedValue()
    return string.format("%s%x", (includeHash and '#' or ""), packedValue)
end


---Creates a color from the given array-styled vector. Where each numeric index is a channel from 0 to 1.
-- @param table vector The vector to create the color from.
-- @param integer? minLength The optional minimum length. If the given vector has fewer elements than this length, nil will be returned. If no minimum length is given, no check will be made.
-- @param integer? maxLength The optional maximum length. All elements in the given vector past this count will be ignored and set to a default value.
-- @return Color color The created color.
function Color.fromVector(vector, minLength, maxLength)

    -- Check the validity of the given vector. If it is invalid, return nil.
    if type(vector) ~= "table" or (minLength ~= nil and #vector < minLength) then
        return nil
    end

    -- Default the max length to the count of the vector.
    maxLength = maxLength or #vector

    -- Return the color.
    return Color.new(1 <= maxLength and vector[1] or 0, 2 <= maxLength and vector[2] or 0, 3 <= maxLength and vector[3] or 0, 4 <= maxLength and vector[4] or 1)
end


---Unpacks this color into its seperate rgba channels from 0 to 1.
-- @return float r The red value.
-- @return float g The green value.
-- @return float b The blue value.
-- @return float a The alpha value.
function Color:unpack()
    return self.r, self.g, self.b, self.a
end


---Unpacks this color into its separate rgb channels from 0 to 1.
-- @return float r The red value.
-- @return float g The green value.
-- @return float b The blue value.
function Color:unpack3()
    return self.r, self.g, self.b
end


---Returns this color as a vector3 (rgb).
-- @return table vector3 The color as a vector3 (rgb).
function Color:toVector3()
    return { self.r, self.g, self.b }
end


---Returns this color as a vector4 (rgba).
-- @return table vector4 The color as a vector4 (rgba).
function Color:toVector4()
    return { self.r, self.g, self.b, self.a }
end


---Creates a new color from the given RGBA values from 0 to 255.
-- @param integer r The red value. Defaults to 0.
-- @param integer g The green value. Defaults to 0.
-- @param integer b The blue value. Defaults to 0.
-- @param integer? a The alpha value. Defaults to 255.
-- @return Color color The created color.
function Color.fromRGBA(r, g, b, a)
    return Color.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255, (a or 255) / 255)
end


---Unpacks this color into its seperate rgba channels from 0 to 255.
-- @return integer r The red value.
-- @return integer g The green value.
-- @return integer b The blue value.
-- @return integer a The alpha value.
function Color:unpackRGBA()
    return math.ceil(self.r * 255), math.ceil(self.g * 255), math.ceil(self.b * 255), math.ceil(self.a * 255)
end


---Creates a new color from the RGBA values from 0 to 255 in the given vector. See Color.fromRGBA(r, g, b, a)
-- @param table vector The vector color, where each element is a number ranging from 0 to 255.
-- @param integer? minLength The optional minimum length. If the given vector has fewer elements than this length, nil will be returned. If no minimum length is given, no check will be made.
-- @param integer? maxLength The optional maximum length. All elements in the given vector past this count will be ignored and set to a default value.
-- @return Color color The created color.
function Color.fromVectorRGBA(vector, minLength, maxLength)

    -- Check the validity of the given vector. If it is invalid, return nil.
    if type(vector) ~= "table" or (minLength ~= nil and #vector < minLength) then
        return nil
    end

    -- Default the max length to the count of the vector.
    maxLength = maxLength or #vector

    -- Return the color from RGBA.
    return Color.fromRGBA(1 <= maxLength and vector[1] or 0, 2 <= maxLength and vector[2] or 0, 3 <= maxLength and vector[3] or 0, 4 <= maxLength and vector[4] or 255)
end


---Creates an RGB color array from the color, where each channel is between 0 and 255.
-- @return table vectorRGB The RGB vector.
function Color:toVectorRGB()
    return { math.ceil(self.r * 255), math.ceil(self.g * 255), math.ceil(self.b * 255) }
end


---Creates an RGBA color array from the color, where each channel is between 0 and 255.
-- @return table vectorRGBA The RGBA vector.
function Color:toVectorRGBA()
    return { math.ceil(self.r * 255), math.ceil(self.g * 255), math.ceil(self.b * 255), math.ceil(self.a * 255) }
end


---Blends the two colors together, returning the result.
-- @param Color first The first color value.
-- @param Color second The second color value.
-- @param float alpha The blend amount, where 0 is equal to the first color, and 1 is equal to the second color.
-- @return Color blendedColor The resulting color.
function Color.blend(first, second, alpha)
    --#debug Assert.isClass(first, Color, "Given first color was not a Color type!")
    --#debug Assert.isClass(second, Color, "Given second color was not a Color type!")
    --#debug Assert.isType(alpha, "number", "Given alpha was not a number!")
    return Color.new(MathUtil.lerp(first.r, second.r, alpha), MathUtil.lerp(first.g, second.g, alpha), MathUtil.lerp(first.b, second.b, alpha), MathUtil.lerp(first.a, second.a, alpha))
end


---Returns the swizzled vector from the color using the given key.
-- @param string key The key to swizzle from. Should be a string between 1 and 4 characters in length.
-- @return table swizzledVector The swizzled vector from the given key, or nil if the key included an invalid character.
function Color:swizzle(key)

    -- Ensure the key is valid and of valid length.
    if type(key) ~= "string" then
        return nil
    end
    local swizzleLength = string.len(key)
    if swizzleLength > 4 or swizzleLength <= 0 then
        return nil
    end

    -- Go over each character in the given string.
    local swizzleVector = {}
    for i = 1, swizzleLength do

        -- Get the color with the given character. Return nil if it was nil.
        local swizzleValue = rawget(self, string.sub(key, i, i))
        if swizzleValue == nil then
            return nil
        end

        -- Add the value to the swizzle vector.
        swizzleVector[i] = swizzleValue
    end

    -- Return the created vector.
    return swizzleVector
end


---Writes the given color to the network stream with a 10 bit precision
-- @param integer streamId The stream to write to
-- @param float r red value
-- @param float g green value
-- @param float b blue value
function Color.writeStreamRGB(streamId, r, g, b)
    streamWriteUIntN(streamId, math.clamp(r, 0, 1) * 1023, 10)
    streamWriteUIntN(streamId, math.clamp(g, 0, 1) * 1023, 10)
    streamWriteUIntN(streamId, math.clamp(b, 0, 1) * 1023, 10)
end
