









---Info box with key-value layout for mobile version
local InfoDisplayKeyValueBoxMobile_mt = Class(InfoDisplayKeyValueBoxMobile, InfoDisplayBox)


---
function InfoDisplayKeyValueBoxMobile.new(infoDisplay, uiScale)
    local self = InfoDisplayBox.new(infoDisplay, uiScale, InfoDisplayKeyValueBoxMobile_mt)

    self.displayComponents = {}

    self.cachedLines = {}
    self.activeLines = {}

    self.posYOffset = 160 * g_pixelSizeY * (g_screenHeight / g_referenceScreenHeight)

    return self
end






---
function InfoDisplayKeyValueBoxMobile:canDraw()
    return self.doShowNextFrame
end


---Get this HUD extension's display height.
-- @return float Display height in screen space
function InfoDisplayKeyValueBoxMobile:getDisplayHeight()
    return 2 * self.listMarginHeight + #self.activeLines * self.rowHeight + self.labelTextOffsetY
end


---
function InfoDisplayKeyValueBoxMobile:draw(posX, posY)
    local _, rightInset = getSafeFrameInsets()
    posX = posX - rightInset
    local rightX = posX
    local leftX = posX - self.boxWidth
    local y = posY + self.posYOffset

    local height = 2 * self.listMarginHeight + #self.activeLines * self.rowHeight
    drawFilledRectRound(leftX, y, self.boxWidth, height, self.uiScale, 0, 0, 0, 0.75)

    -- Displayitems
    y = y + self.listMarginHeight
    leftX = leftX + self.leftTextOffsetX + self.listMarginWidth
    rightX = rightX - self.rightTextOffsetX - self.listMarginWidth

    local textAreaX = self.boxWidth - self.leftTextOffsetX - self.listMarginWidth - self.rightTextOffsetX - self.listMarginWidth

    for i = #self.activeLines, 1, -1 do
        local line = self.activeLines[i]

        setTextBold(true)
        if line.accentuate then
            setTextColor(unpack(line.accentuateColor or InfoDisplayKeyValueBoxMobile.COLOR.TEXT_HIGHLIGHT))
        else
            setTextColor(1, 1, 1, 1)
        end

        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(leftX, y + self.leftTextOffsetY, self.rowTextSize, line.key)

        setTextAlignment(RenderText.ALIGN_RIGHT)
        local maxWidth = textAreaX - 0.025 * self.boxWidth - getTextWidth(self.rowTextSize, line.key)
        setTextBold(false)

        local text = Utils.limitTextToWidth(line.value, self.rowTextSize, maxWidth, false, "...")
        renderText(rightX, y + self.rightTextOffsetY, self.rowTextSize, text)

        if line.accentuate then
            setTextColor(unpack(InfoDisplayKeyValueBoxMobile.COLOR.TEXT_DEFAULT))
        end

        y = y + self.rowHeight
    end

    setTextAlignment(RenderText.ALIGN_LEFT)

    self.doShowNextFrame = false
end






---
function InfoDisplayKeyValueBoxMobile:clear()
    for i = #self.activeLines, 1, -1 do
        self.cachedLines[#self.cachedLines + 1] = self.activeLines[i]
        self.activeLines[i] = nil
    end
end


---
function InfoDisplayKeyValueBoxMobile:setTitle(title)
end


---
function InfoDisplayKeyValueBoxMobile:textSizeToFit(baseSize, text, maxWidth, minSize)
    local size = baseSize
    if minSize == nil then
        minSize = baseSize / 2
    end

    setTextWrapWidth(maxWidth)
    local lengthWithNoLineLimit = getTextLength(size, text, 99999)

    while getTextLength(size, text, 1) < lengthWithNoLineLimit do
        size = size - baseSize * 0.05

        -- Limit size. Cut off any extra text
        if size <= minSize then
            -- Undo
            size = size + baseSize * 0.05

            break
        end
    end

    setTextWrapWidth(0)

    return size
end


---
function InfoDisplayKeyValueBoxMobile:addLine(key, value, accentuate, accentuateColor)
    local line
    local cached = self.cachedLines
    local numCached = #cached
    if numCached > 0 then
        line = self.cachedLines[numCached]
        self.cachedLines[numCached] = nil
    else
        line = {}
    end

    line.key = key
    line.value = value or ""
    line.accentuate = accentuate
    line.accentuateColor = accentuateColor

    self.activeLines[#self.activeLines + 1] = line
end


---
function InfoDisplayKeyValueBoxMobile:showNextFrame()
    self.doShowNextFrame = true
end






---
function InfoDisplayKeyValueBoxMobile:setScale(uiScale)
    self.uiScale = uiScale
    self:storeScaledValues()
end


---
function InfoDisplayKeyValueBoxMobile:storeScaledValues()
    local scale = self.uiScale

    local function normalize(x, y)
        return x * scale * g_aspectScaleX / g_referenceScreenWidth, y * scale * g_aspectScaleY / g_referenceScreenHeight
    end

    self.boxWidth = normalize(500, 0)

    local _
    _, self.rowTextSize = normalize(0, HUDElement.TEXT_SIZE.DEFAULT_TEXT_MOBILE)

    self.labelTextOffsetX, self.labelTextOffsetY = normalize(0, 3)
    self.leftTextOffsetX, self.leftTextOffsetY = normalize(0, 6)
    self.rightTextOffsetX, self.rightTextOffsetY = normalize(0, 6)

    self.rowWidth, self.rowHeight = normalize(450, 40)
    self.listMarginWidth, self.listMarginHeight = normalize(25, 15)
end
