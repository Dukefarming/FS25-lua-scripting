





























---Display
-- HUD input help display.
-- 
-- Displays controls and further information for the current input context.
local InputHelpDisplay_mt = Class(InputHelpDisplay, HUDDisplay)


---Create a new instance of InputHelpDisplay.
function InputHelpDisplay.new()
    local self = InputHelpDisplay:superClass().new(InputHelpDisplay_mt)

    self.vehicle = nil -- currently controlled vehicle
    self.extraHelpTexts = {}
    self.helpExtensions = {}
    self.infoExtensions = {}
    self.skipActions = {}

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.lineBg = g_overlayManager:createOverlay("gui.shortcutBox1", 0, 0, 0, 0)
    self.lineBg:setColor(r, g, b, a)

    self.lineBgLeft = g_overlayManager:createOverlay("gui.shortcutBox1_left", 0, 0, 0, 0)
    self.lineBgLeft:setColor(r, g, b, a)
    self.lineBgScale = g_overlayManager:createOverlay("gui.shortcutBox1_middle", 0, 0, 0, 0)
    self.lineBgScale:setColor(r, g, b, a)
    self.lineBgRight = g_overlayManager:createOverlay("gui.shortcutBox1_right", 0, 0, 0, 0)
    self.lineBgRight:setColor(r, g, b, a)

    self.comboBg = g_overlayManager:createOverlay("gui.shortcutBox2", 0, 0, 0, 0)
    self.comboBg:setColor(r, g, b, a)

    self.comboText = utf8ToUpper(g_i18n:getText("ui_controlsAdvanced"))
    self.controlGroupText = utf8ToUpper(g_i18n:getText("ui_controlsControlGroup"))

    self.glyphButtonOverlay = GlyphButtonOverlay.new()
    self.glyphButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.80)

    self.keyButtonOverlay = ButtonOverlay.new()
    self.keyButtonOverlay:setColor(nil, nil, nil, nil, 0, 0, 0, 0.80)

    self.separatorHorizontal = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorHorizontal:setColor(1, 1, 1, 0.25)
    self.separatorVertical = g_overlayManager:createOverlay(g_plainColorSliceId, 0, 0, 0, 0)
    self.separatorVertical:setColor(1, 1, 1, 0.25)

    local inputDisplayManager = g_inputDisplayManager
    self.mouseComboOverlays = {}
    for _, combo in ipairs(InputBinding.ORDERED_MOUSE_COMBOS) do
        local actionName = combo.controls
        local helpElement = inputDisplayManager:getControllerSymbolOverlays(actionName, "", "", false)
        local overlays = {}
        for _, button in ipairs(helpElement.buttons) do
            table.insert(overlays, button)
        end
        table.insert(self.mouseComboOverlays, {actionName=actionName, overlays=overlays, mask=combo.mask})
    end

    self:updateGamepadComboButtons()

    self.vehicle = nil -- currently controlled vehicle
    self.vehicleSchemaOverlays = {} -- schema name -> overlay
    self.iconSizeX, self.iconSizeY = 0, 0 -- schema overlay icon size
    self.maxSchemaWidth = 0 -- maximum width of vehicle configuration schema

    g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.updateGamepadComboButtons, self)

    return self
end


---
function InputHelpDisplay:delete()
    self.lineBg:delete()
    self.lineBgLeft:delete()
    self.lineBgScale:delete()
    self.lineBgRight:delete()
    self.comboBg:delete()
    self.glyphButtonOverlay:delete()
    self.keyButtonOverlay:delete()
    self.separatorHorizontal:delete()
    self.separatorVertical:delete()

    for k, v in pairs(self.vehicleSchemaOverlays) do
        v:delete()
        self.vehicleSchemaOverlays[k] = nil
    end

    g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)

    InputHelpDisplay:superClass().delete(self)
end


---Store scaled positioning, size and offset values.
function InputHelpDisplay:storeScaledValues()
    self:setPosition(g_hudAnchorLeft, g_hudAnchorTop)

    local lineWidth, lineHeight = self:scalePixelValuesToScreenVector(330, 25)
    self.lineBg:setDimension(lineWidth, lineHeight)

    self.helpAnchorOffsetX, self.helpAnchorOffsetY = self:scalePixelValuesToScreenVector(340, -25)

    local partWidth = self:scalePixelToScreenWidth(6)
    self.lineBgLeft:setDimension(partWidth, lineHeight)
    self.lineBgScale:setDimension(0, lineHeight)
    self.lineBgRight:setDimension(partWidth, lineHeight)

    local comboWidth, comboHeight = self:scalePixelValuesToScreenVector(330, 50)
    self.comboBg:setDimension(comboWidth, comboHeight)

    self.lineOffsetY = self:scalePixelToScreenHeight(5)
    self.textSize = self:scalePixelToScreenHeight(12)

    self.textOffsetX, self.textOffsetY = self:scalePixelValuesToScreenVector(14, 8)
    self.comboTextOffsetX, self.comboTextOffsetY = self:scalePixelValuesToScreenVector(14, 32)

    self.comboSeparatorOffsetX, self.comboSeparatorOffsetY = self:scalePixelValuesToScreenVector(0, 24)
    self.comboIconWidth, self.comboIconHeight = self:scalePixelValuesToScreenVector(24, 24)

    self.separatorHorizontal:setDimension(lineWidth, g_pixelSizeY)

    local verticalSeparatorHeight = self:scalePixelToScreenHeight(24)
    self.separatorVertical:setDimension(g_pixelSizeX, verticalSeparatorHeight)

    self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
    self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))

    self.schemaOffsetX, self.schemaOffsetY = self:scalePixelValuesToScreenVector(14, 2)

    self.iconSizeX, self.iconSizeY = self:scalePixelValuesToScreenVector(26, 26)
    self.maxSchemaWidth = self:scalePixelToScreenWidth(180)

    for _, overlay in pairs(self.vehicleSchemaOverlays) do
        overlay:resetDimensions()

        local pixelSize = {overlay.defaultWidth, overlay.defaultHeight}
        local width, height = self:scalePixelToScreenVector(pixelSize)
        overlay:setDimension(width, height)
    end
end


---Draw the input help.
-- Only draws if the element is visible and there are any help elements.
function InputHelpDisplay:draw(offsetX, offsetY)
    local isVisible = self:getVisible()
    local posX, posY = self:getPosition()
    local vehicleControlPosY

    posX = posX + (offsetX or 0)
    posY = posY + (offsetY or 0)

    posY, vehicleControlPosY = self:drawVehicleSchema(posX, posY, not isVisible)

    if not isVisible then
        return
    end

    local inputBinding = g_inputBinding
    local inputDisplayManager = g_inputDisplayManager

    local pressedComboMaskGamepad, pressedComboMaskMouse = inputBinding:getComboCommandPressedMask()
    local useGamepadButtons = GS_IS_CONSOLE_VERSION or (inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD)
    local currentPressedMask = useGamepadButtons and pressedComboMaskGamepad or pressedComboMaskMouse
    local isCombo = currentPressedMask ~= 0

    local comboActionStatus = inputDisplayManager:getComboHelpElements(useGamepadButtons)
    local hasComboCommands = next(comboActionStatus) ~= nil

    local eventHelpElements = inputDisplayManager:getEventHelpElements(currentPressedMask, useGamepadButtons)
    if (eventHelpElements == nil or #eventHelpElements == 0) and not hasComboCommands and isCombo then
        -- just load the base input list without modifier (pressed mask == 0)
        eventHelpElements = inputDisplayManager:getEventHelpElements(0, useGamepadButtons)
    end

    table.sort(self.helpExtensions, function(a, b)
        return a.priority < b.priority
    end)

    table.sort(self.infoExtensions, function(a, b)
        return a.priority < b.priority
    end)

    local helpExtensionTotalHeight = 0
    for i=#self.helpExtensions, 1, -1 do
        local helpExtension = self.helpExtensions[i]

        if helpExtension.setEventHelpElements ~= nil then
            helpExtension:setEventHelpElements(self, eventHelpElements)
        end

        local height = helpExtension:getHeight()
        if height > 0 then
            helpExtensionTotalHeight = helpExtensionTotalHeight + height + self.lineOffsetY
        else
            table.remove(self.helpExtensions, i)
        end
    end

    local infoExtensionTotalHeight = 0
    for i=#self.infoExtensions, 1, -1 do
        local infoExtension = self.infoExtensions[i]

        if infoExtension.setEventHelpElements ~= nil then
            infoExtension:setEventHelpElements(self, eventHelpElements)
        end

        local height = infoExtension:getHeight()
        if height > 0 then
            infoExtensionTotalHeight = infoExtensionTotalHeight + height + self.lineOffsetY
        else
            table.remove(self.infoExtensions, i)
        end
    end

    if hasComboCommands then
        posY = posY - self.comboBg.height
        self.comboBg:renderCustom(posX, posY)

        setTextBold(true)
        setTextAlignment(RenderText.ALIGN_LEFT)
        setTextColor(1, 1, 1, 1)
        renderText(posX + self.comboTextOffsetX, posY + self.comboTextOffsetY, self.textSize, self.comboText)
        self.separatorHorizontal:renderCustom(posX + self.comboSeparatorOffsetX, posY + self.comboSeparatorOffsetY)

        local combos = self.mouseComboOverlays
        local pressedComboMask = pressedComboMaskMouse
        if useGamepadButtons then
            combos = self.gamepadComboOverlays
            pressedComboMask = pressedComboMaskGamepad
        end

        local numCombos = #combos
        local widthPerCombo = self.comboBg.width / numCombos
        local activeColor = HUD.COLOR.ACTIVE
        local iconPosX = posX

        for k, comboInfo in ipairs(combos) do
            if comboActionStatus[comboInfo.actionName] then
                local isPressed = bitAND(pressedComboMask, comboInfo.mask) ~= 0
                local r, g, b, a = 1, 1, 1, 1
                if isPressed then
                    r, g, b, a = activeColor[1], activeColor[2], activeColor[3], activeColor[4]
                end

                local numOverlays = #comboInfo.overlays
                local spaceX = widthPerCombo - self.comboIconWidth*numOverlays
                local spacingX = spaceX / (numOverlays+3)
                local overlayPosX = iconPosX + 2*spacingX
                for _, overlay in ipairs(comboInfo.overlays) do
                    overlay:renderCustom(overlayPosX, posY, self.comboIconWidth, self.comboIconHeight, r, g, b, a)
                    overlayPosX = overlayPosX + spacingX + self.comboIconWidth
                end
            end

            if k < numCombos then
                iconPosX = iconPosX + widthPerCombo
                self.separatorVertical:renderCustom(iconPosX, posY)
            end
        end

        posY = posY - self.lineOffsetY
    end

    local numElements = 0
    if eventHelpElements ~= nil then
        for k, helpElement in ipairs(eventHelpElements) do
            if self.skipActions[helpElement.actionName] == nil then
                if helpElement.actionName == InputAction.SWITCH_IMPLEMENT and vehicleControlPosY ~= nil then
                    local buttons = helpElement.buttons
                    local isComboButtonMapping = helpElement.isComboButtonMapping
                    local keys = helpElement.keys
                    local lineBg = self.lineBg
                    local lineHeight = lineBg.height
                    vehicleControlPosY = vehicleControlPosY - lineHeight
                    if #buttons > 0 then
                        local totalWidth = self.glyphButtonOverlay:getButtonWidth(buttons, isComboButtonMapping, true, lineHeight)
                        local startPosX = posX + lineBg.width - totalWidth
                        self.glyphButtonOverlay:renderButton(buttons, isComboButtonMapping, true, startPosX, vehicleControlPosY, lineHeight)

                    elseif #keys > 0 then
                        local startPosX = posX + lineBg.width
                        for i=#keys, 1, -1 do
                            local key = keys[i]
                            local keyWidth = self.keyButtonOverlay:getButtonWidth(key, lineHeight)
                            local width = keyWidth + g_pixelSizeX
                            startPosX = startPosX - width
                            self.keyButtonOverlay:renderButton(key, startPosX, vehicleControlPosY, lineHeight, true)
                        end
                    end
                else
                    posY = self:drawInputHelpElement(posX, posY, helpElement)
                    posY = posY - self.lineOffsetY
                end

                numElements = numElements + 1

                local maxNumElements = helpElement.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS
                if numElements > maxNumElements then
                    break
                end
            else
                self.skipActions[helpElement.actionName] = nil
            end
        end
    end

    for k, extension in pairs(self.helpExtensions) do
        local maxNumElements = extension.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS
        if numElements < maxNumElements then
            posY = extension:draw(self, posX, posY)
            posY = posY - self.lineOffsetY

            numElements = numElements + 1
        end

        self.helpExtensions[k] = nil
    end

    for k, extension in pairs(self.infoExtensions) do
        local newPosY = extension:draw(self, posX, posY)

        if newPosY ~= posY then
            posY = newPosY - self.lineOffsetY
        end

        self.infoExtensions[k] = nil
    end

    for k, text in pairs(self.extraHelpTexts) do
        posY = self:drawExtraText(posX, posY, text)
        posY = posY - self.lineOffsetY

        self.extraHelpTexts[k] = nil
    end
end
