









---Input glyph display element.
-- 
-- Displays a key or button glyph for an input.
local InputGlyphElement_mt = Class(InputGlyphElement, HUDElement)









---Create a new instance of InputGlyphElement.
-- @param table inputDisplayManager InputDisplayManager reference
-- @param float baseWidth Default width of this element in screen space
-- @param float baseHeight Default height of this element in screen space
function InputGlyphElement.new(inputDisplayManager, baseWidth, baseHeight, customMt)
    local backgroundOverlay = Overlay.new(nil, 0, 0, baseWidth, baseHeight)
    local self = InputGlyphElement:superClass().new(backgroundOverlay, nil, customMt or InputGlyphElement_mt)

    self.inputDisplayManager = inputDisplayManager
    self.plusOverlay = inputDisplayManager:getPlusOverlay()
    self.orOverlay = inputDisplayManager:getOrOverlay()
    self.keyboardOverlay = ButtonOverlay.new()
    self.keyboardOverlay:setColor(1, 1, 1, 1, 0, 0, 0, 0.80)

    self.actionNames = {}
    self.actionText = nil -- optional action text to display next to the glyph
    self.displayText = nil -- lower or upper cased version of actionText for rendering
    self.actionTextSize = InputGlyphElement.DEFAULT_TEXT_SIZE
    self.inputHelpElement = nil

    self.buttonOverlays = {} -- action name -> overlays
    self.hasButtonOverlays = false
    self.separators = {} -- {i=InputHelpElement.SEPARATOR}
    self.keyNames = {} -- action name -> key names
    self.hasKeyNames = false
    self.isLeftAligned = false

    self.color = {1, 1, 1, 1} -- RGBA array
    self.buttonColor = {1, 1, 1, 1} -- RGBA array
    self.overlayCopies = {} -- contains overlay copies which need to be deleted

    self.baseWidth, self.baseHeight = baseWidth, baseHeight

    self.glyphOffsetX = 0
    self.textOffsetX = 0
    self.iconSizeX, self.iconSizeY = baseWidth, baseHeight
    self.plusIconSizeX, self.plusIconSizeY = baseWidth * 0.5, baseHeight * 0.5
    self.orIconSizeX, self.orIconSizeY = baseWidth * 0.5, baseHeight * 0.5

    self.alignX, self.alignY = 1, 1
    self.alignmentOffsetX, self.alignmentOffsetY = 0, 0
    self.lowerCase = false
    self.upperCase = false
    self.bold = false

    self:setScale(1, 1)

    g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.onInputDevicesChanged, self)

    return self
end


---Delete this element and release its resources.
function InputGlyphElement:delete()
    self.keyboardOverlay:delete()
    g_messageCenter:unsubscribeAll(self)

    InputGlyphElement:superClass().delete(self)
end






---Set the scale of this element.
-- @param float widthScale Width scale factor
-- @param float heightScale Height scale factor
function InputGlyphElement:setScale(widthScale, heightScale)
    InputGlyphElement:superClass().setScale(self, widthScale, heightScale)

    self.glyphOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.GLYPH_OFFSET_X)
    self.textOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.TEXT_OFFSET_X)

    self.iconSizeX, self.iconSizeY = self.baseWidth * widthScale, self.baseHeight * heightScale
    self.plusIconSizeX, self.plusIconSizeY = self.iconSizeX * 0.5, self.iconSizeY * 0.5
    self.orIconSizeX, self.orIconSizeY = self.iconSizeX * 0.5, self.iconSizeY * 0.5
end


---Set the glyph text to be displayed in all upper case or not.
-- This resets the lower case setting if upper case is enabled.
function InputGlyphElement:setUpperCase(enableUpperCase)
    self.upperCase = enableUpperCase
    self.lowerCase = self.lowerCase and not enableUpperCase
    self:updateDisplayText()
end


---Set the glyph text to be displayed in all lower case or not.
-- This resets the upper case setting if lower case is enabled.
function InputGlyphElement:setLowerCase(enableLowerCase)
    self.lowerCase = enableLowerCase
    self.upperCase = self.upperCase and not enableLowerCase
    self:updateDisplayText()
end


---Set the glyph text to be displayed in bold print or not.
function InputGlyphElement:setBold(isBold)
    self.bold = isBold
end


---Set the button frame color for the keyboard glyphs.
-- @param table color Color as an RGBA array
function InputGlyphElement:setKeyboardGlyphColor(color, bgColor)
    local r, g, b, a, bgR, bgG, bgB, bgA
    self.color = color

    if color ~= nil then
        r, g, b, a = color[1], color[2], color[3], color[4]
    end
    if bgColor ~= nil then
        bgR, bgG, bgB, bgA = bgColor[1], bgColor[2], bgColor[3], bgColor[4]
    end

    self.keyboardOverlay:setColor(r, g, b, a, bgR, bgG, bgB, bgA)
end


---Set the color for button glyphs.
-- @param table color Color as an RGBA array
function InputGlyphElement:setButtonGlyphColor(color)
    self.buttonColor = color

    for _, actionName in ipairs(self.actionNames) do
        local buttonOverlays = self.buttonOverlays[actionName]
        if buttonOverlays ~= nil then -- safety-catch to avoid errors for invalid setups (will just not show icon)
            for _, overlay in pairs(buttonOverlays) do
                overlay:setColor(unpack(color))
            end
        end
    end
end






---Set the action whose input glyphs need to be displayed by this element.
-- @param string actionName InputAction name
-- @param string? actionText [optional] Additional action text to display after the glyph
-- @param float? actionTextSize [optional] Additional action text size in screen space
-- @param boolean? noModifiers [optional] If true, will only show the input glyph of the last unmodified input binding axis
function InputGlyphElement:setAction(actionName, actionText, actionTextSize, noModifiers)
    -- use this instance's action names array instead of creating a new one each time this is called
    table.clear(self.actionNames)
    table.insert(self.actionNames, actionName)
    self:setActions(self.actionNames, actionText, actionTextSize, noModifiers)
end


---Set multiple actions whose input glyphs need to be displayed by this element.
-- If exactly two actions are passed in, they will be interpreted as belonging to the same axis and the system tries
-- to resolved the actions to a combined glyph. Otherwise, the glyphs will just be displayed in order of the actions.
-- @param table actionNames InputAction names array
-- @param string? actionText [optional] Additional action text to display after the glyph
-- @param float? actionTextSize [optional] Additional action text size in screen space
-- @param boolean? noModifiers [optional] If true, will only show the input glyph of the last unmodified input binding axis
function InputGlyphElement:setActions(actionNames, actionText, actionTextSize, noModifiers, customBinding)
    self.actionNames = actionNames
    self.actionText = actionText
    self.actionTextSize = actionTextSize or InputGlyphElement.DEFAULT_TEXT_SIZE
    self.noModifiers = noModifiers

    self:updateDisplayText() -- apply lower / upper case if necessary

    local height = self:getHeight()
    local width = 0
    local isDoubleAction = #actionNames == 2

    for i, actionName in ipairs(actionNames) do
        local actionName2 = nil
        if isDoubleAction then
            actionName2 = actionNames[i + 1]
        end

        local helpElement = self.inputDisplayManager:getControllerSymbolOverlays(actionName, actionName2, "", noModifiers, customBinding)
        local buttonOverlays = helpElement.buttons
        self.separators = helpElement.separators

        if self.buttonOverlays[actionName] == nil then
            self.buttonOverlays[actionName] = {}
        else
            for j=1, #self.buttonOverlays[actionName] do
                self.buttonOverlays[actionName][j] = nil
            end
        end
        self.hasButtonOverlays = false

        if #buttonOverlays > 0 then
            for _, overlay in ipairs(buttonOverlays) do
                table.insert(self.buttonOverlays[actionName], overlay)
                self.hasButtonOverlays = true
            end
        end

        if self.keyNames[actionName] == nil then
            self.keyNames[actionName] = {}
        else
            for j=1, #self.keyNames[actionName] do
                self.keyNames[actionName][j] = nil
            end
        end
        self.hasKeyNames = false

        if #helpElement.keys > 0 then
            for _, key in ipairs(helpElement.keys) do
                table.insert(self.keyNames[actionName], key)
                self.hasKeyNames = true
            end
        end

        if isDoubleAction then
            break -- should have resolved everything now
        end
    end

    if self.hasButtonOverlays then
        for _, buttonOverlays in pairs(self.buttonOverlays) do
            for i, _ in ipairs(buttonOverlays) do
                if i > 1 then -- TODO: use separator types to get width
                    width = width + self.plusIconSizeX + self.glyphOffsetX
                end

                width = width + self.iconSizeX + (i < #buttonOverlays and self.glyphOffsetX or 0)
            end
        end
    elseif self.hasKeyNames then
        for _, keyNames in pairs(self.keyNames) do
            for _, key in ipairs(keyNames) do
                local keyWidth = self.keyboardOverlay:getButtonWidth(key, height)
                width = width + keyWidth
            end
        end
    end

    -- adjust this element's size so other elements can correctly offset from this
    self:setDimension(width, height)
end


---Update the display text from the set action text according to current casing settings.
function InputGlyphElement:updateDisplayText()
    if self.actionText ~= nil then
        self.displayText = self.actionText
        if self.upperCase then
            self.displayText = utf8ToUpper(self.actionText)
        elseif self.lowerCase then
            self.displayText = utf8ToLower(self.actionText)
        end
    end
end


---Get the screen space width required by the glyphs used to display input in the current input context.
function InputGlyphElement:getGlyphWidth()
    local width = 0
    if self.hasButtonOverlays then
        for _, actionName in ipairs(self.actionNames) do
            if self.buttonOverlays[actionName] ~= nil then
                for i, _ in ipairs(self.buttonOverlays[actionName]) do
                    if i > 1 and self:getDrawSeparator() then
                        local separatorType = self.separators[i - 1]
                        local separatorWidth = 0
                        if separatorType == InputHelpElement.SEPARATOR.COMBO_INPUT then
                            separatorWidth = self.plusIconSizeX
                        elseif separatorType == InputHelpElement.SEPARATOR.ANY_INPUT then
                            separatorWidth = self.orIconSizeX
                        end

                        width = width + separatorWidth + self.glyphOffsetX
                    end

                    local padding = i < #self.buttonOverlays[actionName] and self.glyphOffsetX or 0
                    width = width + self.iconSizeX + padding
                end
            end
        end
    elseif self.hasKeyNames then
        for _, actionName in ipairs(self.actionNames) do
            local keyNames = self.keyNames[actionName]
            if keyNames ~= nil then
                for i, key in ipairs(keyNames) do
                    local padding = i < #self.keyNames[actionName] and self.glyphOffsetX or 0
                    local keyWidth = self.keyboardOverlay:getButtonWidth(key, self.iconSizeY)
                    width = width + keyWidth + padding
                end
            end
        end
    end

    return width
end










---Draw the input glyph(s).
function InputGlyphElement:draw(clipX1, clipY1, clipX2, clipY2)
    if #self.actionNames == 0 or not self.overlay:getIsVisible() then
        return
    end

    InputGlyphElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)

    local posX, posY = self:getPosition()
    local offsetX, offsetY = self:getPositionOffset()
    local totalGlyphWidth = self:getGlyphWidth()

--     drawPoint(posX, posY, 4*g_pixelSizeX, 4*g_pixelSizeY, 0, 1, 0, 1)

    posX = posX + offsetX
    posY = posY + offsetY

    if not self.isLeftAligned then
        posX = posX + self.overlay.width - totalGlyphWidth
    end

    if self.hasButtonOverlays then
        for _, actionName in ipairs(self.actionNames) do
            if self.buttonOverlays[actionName] ~= nil then
                posX = self:drawControllerButtons(self.buttonOverlays[actionName], posX, posY, clipX1, clipY1, clipX2, clipY2)
            end
        end
    elseif self.hasKeyNames then
        for _, actionName in ipairs(self.actionNames) do
            local keyNames = self.keyNames[actionName]
            if keyNames ~= nil then
                for i, key in ipairs(keyNames) do
                    local padding = i < #keyNames and self.glyphOffsetX or 0
                    posX = posX + self.keyboardOverlay:renderButton(key, posX, posY, self.iconSizeY, true, clipX1, clipY1, clipX2, clipY2) + padding
                end
            end
        end
    end

    if self.actionText ~= nil then
        self:drawActionText(posX, posY, clipX1, clipY1, clipX2, clipY2)
    end
end


---Draw controller button glyphs.
-- @param table Array of controller button glyph overlays
-- @param float posX Initial drawing X position in screen space
-- @param float posY Initial drawing Y position in screen space
-- @return float X position in screen space after the last glyph
function InputGlyphElement:drawControllerButtons(buttonOverlays, posX, posY, clipX1, clipY1, clipX2, clipY2)
--     drawPoint(posX, posY, 2*g_pixelSizeX, 2*g_pixelSizeY, 1, 0, 0, 1)
    local color = self.buttonColor
    for i, overlay in ipairs(buttonOverlays) do
        if i > 1 and self:getDrawSeparator() then
            local separatorType = self.separators[i - 1]
            local separatorOverlay = self.orOverlay
            local separatorWidth = 0
            local separatorHeight = 0
            if separatorType == InputHelpElement.SEPARATOR.COMBO_INPUT then
                separatorOverlay = self.plusOverlay
                separatorWidth, separatorHeight = self.plusIconSizeX, self.plusIconSizeY
            elseif separatorType == InputHelpElement.SEPARATOR.ANY_INPUT then
                separatorWidth, separatorHeight = self.orIconSizeX, self.orIconSizeY
            end

            local overlayPosX = posX
            local overlayPosY = posY + (self.iconSizeY-separatorHeight)*0.5
            separatorOverlay:renderCustom(overlayPosX, overlayPosY, separatorWidth, separatorHeight, color[1], color[2], color[3], color[4], clipX1, clipY1, clipX2, clipY2)

            posX = posX + separatorWidth + self.glyphOffsetX
        end

        local overlayPosX = posX
        local overlayPosY = posY
        overlay:renderCustom(overlayPosX, overlayPosY, self.iconSizeX, self.iconSizeY, color[1], color[2], color[3], color[4], clipX1, clipY1, clipX2, clipY2)

        local padding = i < #buttonOverlays and self.glyphOffsetX or 0
        posX = posX + self.iconSizeX + padding
    end

    return posX
end


---Draw the action text after the input glyphs.
-- @param float posX Drawing X position in screen space
-- @param float posY Drawing Y position in screen space
function InputGlyphElement:drawActionText(posX, posY, clipX1, clipY1, clipX2, clipY2)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(self.bold)
    setTextColor(unpack(self.color))

    if clipX1 ~= nil then
        setTextClipArea(clipX1, clipY1, clipX2, clipY2)
    end

    renderText(posX + self.textOffsetX, posY + self.actionTextSize * 0.5, self.actionTextSize, self.displayText)

    if clipX1 ~= nil then
        setTextClipArea(0, 0, 1, 1)
    end
end
