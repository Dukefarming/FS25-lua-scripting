









---Class for creating 3d character lines with the alphabetShader
local CharacterLine_mt = Class(CharacterLine)


---
function CharacterLine.new(linkNode, fontMaterial, numCharacters, customMt)
    local self = setmetatable({}, customMt or CharacterLine_mt)

    self.fontMaterial = fontMaterial

    self.rootNode = createTransformGroup("characterLine")
    link(linkNode, self.rootNode)

    self.characters = {}
    for i=1, numCharacters do
        local shape = fontMaterial:getClonedShape(self.rootNode)
        setShapeCastShadowmap(shape, false)
        table.insert(self.characters, shape)
    end

    self.textSize = 1
    self.scaleX = 1
    self.scaleY = 1
    self.textAlignment = RenderText.ALIGN_RIGHT
    self.textVerticalAlignment = RenderText.VERTICAL_ALIGN_BOTTOM
    self.fontThickness = 1
    self.fontThicknessShader = ((self.fontThickness) - 1) / 8 + 1

    self.useNormalMap = true

    self.textColor = nil
    self.hiddenColor = nil
    self.textEmissiveScale = 0
    self.hiddenAlpha = 0

    self:setText("")

    return self
end


---
function CharacterLine:setSizeAndScale(textSize, scaleX, scaleY)
    self.textSize = textSize or self.textSize
    self.scaleX = scaleX or self.scaleX
    self.scaleY = scaleY or self.scaleY
end


---
function CharacterLine:setTextAlignment(textAlignment)
    self.textAlignment = textAlignment or self.textAlignment
end


---
function CharacterLine:setTextVerticalAlignment(textVerticalAlignment)
    self.textVerticalAlignment = textVerticalAlignment or self.textVerticalAlignment
end


---
function CharacterLine:setFontThickness(fontThickness)
    self.fontThickness = fontThickness or self.fontThickness
    self.fontThicknessShader = ((self.fontThickness) - 1) / 8 + 1

    for _, shape in ipairs(self.characters) do
        setShaderParameter(shape, "alphaErosion", 1 - self.fontThicknessShader, 0, 0, 0, false)
    end
end


---
function CharacterLine:setColor(textColor, hiddenColor, textEmissiveScale, hiddenAlpha)
    self.textColor = textColor or self.textColor
    self.hiddenColor = hiddenColor or self.hiddenColor
    self.textEmissiveScale = textEmissiveScale or self.textEmissiveScale
    self.hiddenAlpha = hiddenAlpha or self.hiddenAlpha

    local r, g, b
    if self.textColor ~= nil then
        r, g, b = self.textColor[1], self.textColor[2], self.textColor[3]
    end

    for _, shape in ipairs(self.characters) do
        self.fontMaterial:setFontCharacterColor(shape, r, g, b, 1, self.textEmissiveScale)
    end
end


---
function CharacterLine:setDecalLayer(decalLayer)
    for _, shape in ipairs(self.characters) do
        setShapeDecalLayer(shape, decalLayer or 0)
    end
end


---
function CharacterLine:setCastShadowmap(castShadowmap)
    for _, shape in ipairs(self.characters) do
        setShapeCastShadowmap(shape, castShadowmap)
    end
end


---
function CharacterLine:setUseNormalMap(useNormalMap)
    self.useNormalMap = Utils.getNoNil(useNormalMap, self.useNormalMap)

    for _, shape in ipairs(self.characters) do
        self.fontMaterial:assignFontMaterialToNode(shape, self.useNormalMap)
    end
end


---
function CharacterLine:setText(text)
    local realWidth = 0
    local xPos = 0
    local height = 0
    local textLength = utf8Strlen(text)
    for i, shape in ipairs(self.characters) do
        local targetCharacter
        if i <= textLength then
            targetCharacter = utf8Substr(text, textLength - i, 1)
        else
            targetCharacter = " "
        end

        local characterData = self.fontMaterial:setFontCharacter(shape, targetCharacter, self.textColor, self.hiddenColor)

        local offsetX, offsetY = 0, 0
        local spacingX, spacingY, realSpacingX = self.fontMaterial.spacingX, self.fontMaterial.spacingY, self.fontMaterial.spacingX
        if characterData ~= nil then
            spacingX = characterData.spacingX or spacingX
            spacingY = characterData.spacingY or spacingY
            realSpacingX = characterData.realSpacingX or spacingY
            offsetX, offsetY = characterData.offsetX, characterData.offsetY
        end

        local ratio = (1 - (spacingX * 2)) / (1 - (spacingY * 2))
        local scaleX = (self.textSize * ratio) * self.scaleX
        local scaleY = self.textSize * self.scaleY

        setScale(shape, scaleX, scaleY, 1)

        local charWidth = scaleX + (self.textSize * self.fontMaterial.charToCharSpace) * (spacingX / realSpacingX)
        setTranslation(shape, xPos - charWidth * 0.5 + (charWidth * offsetX), scaleY * 0.5 + (scaleY * offsetY), 0)

        xPos = xPos - charWidth
        height = math.max(height, scaleY)

        if targetCharacter ~= " " and targetCharacter ~= "" then
            realWidth = xPos
        end
    end

    local x, y, z = 0, 0, 0
    if self.textAlignment == RenderText.ALIGN_LEFT then
        x = -realWidth
    elseif self.textAlignment == RenderText.ALIGN_CENTER then
        x = -realWidth * 0.5
    end

    if self.textVerticalAlignment == RenderText.VERTICAL_ALIGN_MIDDLE then
        y = -height * 0.5
    elseif self.textVerticalAlignment == RenderText.VERTICAL_ALIGN_TOP then
        y = -height
    end

    setTranslation(self.rootNode, x, y, z)
end
