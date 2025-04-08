









---Lightweight HUD UI element.
-- 
-- Wraps an Overlay instance to display and provides a transform hierarchy of child HUDElement instances.
local HUDElement_mt = Class(HUDElement)


---Create a new HUD element.
-- @param table subClass Subclass metatable for inheritance
-- @param table overlay Wrapped Overlay instance
-- @param table? parentHudElement [optional] Parent HUD element of the newly created HUD element
-- @return table HUDElement instance
function HUDElement.new(overlay, parentHudElement, customMt)
    local self = setmetatable({}, customMt or HUDElement_mt)

    self.overlay = overlay
    self.children = {}

    self.pivotX = 0
    self.pivotY = 0
    self.defaultPivotX = 0
    self.defaultPivotY = 0

    -- animation
    self.animation = TweenSequence.NO_SEQUENCE

    self.parent = nil
    if parentHudElement then
        parentHudElement:addChild(self)
    end

    return self
end


---Delete this HUD element and all its children.
-- This will also delete the overlay and thus release its engine handle.
function HUDElement:delete()
    if self.overlay ~= nil then
        self.overlay:delete()
        self.overlay = nil
    end

    if self.parent ~= nil then
        self.parent:removeChild(self)
    end

    self.parent = nil

    for k, v in pairs(self.children) do
        v.parent = nil -- saves the call to removeChild() on delete(), see above
        v:delete()
        self.children[k] = nil
    end
end


---Add a child HUD element to this element.
-- @param table childHudElement HUDElement instance which is added as a child.
function HUDElement:addChild(childHudElement)
--#debug     if childHudElement.isa == nil or not childHudElement:isa(HUDElement) then
--#debug         Logging.error("Trying to add a child to %s which is not of type 'HUDElement' but '%s'", ClassUtil.getClassNameByObject(self), ClassUtil.getClassNameByObject(childHudElement) or type(childHudElement))
--#debug         printCallstack()
--#debug         return
--#debug     end

    if childHudElement.parent == self then
        return
    end

    if childHudElement.parent ~= nil then
        childHudElement.parent:removeChild(childHudElement)
    end

    table.insert(self.children, childHudElement)
    childHudElement.parent = self
end


---Remove a child HUD element from this element.
-- @param table childHudElement HUDElement instance which is removed as a child.
function HUDElement:removeChild(childHudElement)
    if childHudElement.parent == self then
        for i, child in ipairs(self.children) do
            if child == childHudElement then
                child.parent = nil
                table.remove(self.children, i)
                return
            end
        end
    end
end


---Set a HUD element's absolute screen space position.
-- If the element has any children, they will be moved with this element.
function HUDElement:setPosition(x, y)
    local prevX, prevY = self:getPosition()

    -- substitute omitted parameters with current values to mirror Overlay behavior:
    x = x or prevX
    y = y or prevY

    self.overlay:setPosition(x, y)

    if #self.children > 0 then -- move children with self
        local moveX, moveY = x - prevX, y - prevY

        for _, child in pairs(self.children) do
            local childX, childY = child:getPosition()

            child:setPosition(childX + moveX, childY + moveY)
        end
    end
end


---Set this HUD element's rotation.
-- Does not affect children. If no center position is given, the element's pivot values are used (default to 0)
-- @param float rotation Rotation in radians
-- @param float? centerX [optional] Rotation pivot X position offset from overlay position in screen space
-- @param float? centerY [optional] Rotation pivot Y position offset from overlay position in screen space
function HUDElement:setRotation(rotation, centerX, centerY)
    self.overlay:setRotation(rotation, centerX or self.pivotX, centerY or self.pivotY)
end


---Set this HUD element's rotation pivot point.
-- @param float pivotX Pivot x position offset from element position in screen space
-- @param float pivotY Pivot y position offset from element position in screen space
function HUDElement:setRotationPivot(pivotX, pivotY)
    self.pivotX, self.pivotY = pivotX or self.defaultPivotX, pivotY or self.defaultPivotY
    self.defaultPivotX, self.defaultPivotY = pivotX or self.defaultPivotX, pivotY or self.defaultPivotY
end


---Get this HUD element's rotation pivot point.
-- @return float Pivot x position offset from element position in screen space
-- @return float Pivot y position offset from element position in screen space
function HUDElement:getRotationPivot()
    return self.pivotX, self.pivotY
end


---Get this HUD element's position.
-- @return float X position in screen space
-- @return float Y position in screen space
function HUDElement:getPosition()
    return self.overlay:getPosition()
end


---Set this HUD element's scale.
-- This will move and scale children proportionally.
-- @param float scaleWidth Width scale factor
-- @param float scaleHeight Height scale factor
function HUDElement:setScale(scaleWidth, scaleHeight)
    local prevSelfX, prevSelfY = self:getPosition()
    local prevScaleWidth, prevScaleHeight = self:getScale()
    self.overlay:setScale(scaleWidth, scaleHeight)
    local selfX, selfY = self:getPosition()

    if #self.children > 0 then
        local changeFactorX, changeFactorY = scaleWidth / prevScaleWidth, scaleHeight / prevScaleHeight

        for _, child in pairs(self.children) do
            local childScaleWidth, childScaleHeight = child:getScale()

            local childPrevX, childPrevY = child:getPosition()
            local offX = childPrevX - prevSelfX
            local offY = childPrevY - prevSelfY
            local posX = selfX + offX * changeFactorX
            local posY = selfY + offY * changeFactorY

            child:setPosition(posX, posY)
            child:setScale(childScaleWidth * changeFactorX, childScaleHeight * changeFactorY)
        end
    end

    self.pivotX = self.defaultPivotX * scaleWidth
    self.pivotY = self.defaultPivotY * scaleHeight
end


---Get this HUD element's scale.
-- @return Width scale factor
-- @return Height scale factor
function HUDElement:getScale()
    return self.overlay:getScale()
end


---Set this HUD element's positional alignment.
-- See Overlay:setAlignment for positioning logic.
-- @param integer vertical Vertical alignment value [Overlay.ALIGN_VERTICAL_BOTTOM  | Overlay.ALIGN_VERTICAL_MIDDLE | Overlay.ALIGN_VERTICAL_TOP]
-- @param integer horizontal Horizontal alignment value [Overlay.ALIGN_HORIZONTAL_LEFT | Overlay.ALIGN_HORIZONTAL_CENTER | Overlay.ALIGN_HORIZONTAL_RIGHT]
function HUDElement:setAlignment(vertical, horizontal)
    self.overlay:setAlignment(vertical, horizontal)
end


---Set this HUD element's visibility.
function HUDElement:setVisible(isVisible)
    if self.overlay ~= nil then
        self.overlay.visible = isVisible
    end
end


---Get this HUD element's visibility.
function HUDElement:getVisible()
    return self.overlay.visible
end


---Get this HUD element's color.
-- @return float Red value
-- @return float Green value
-- @return float Blue value
-- @return float Alpha value
function HUDElement:getColor()
    return self.overlay.r, self.overlay.g, self.overlay.b, self.overlay.a
end


---Get this HUD element's color alpha value.
-- @return float Alpha value
function HUDElement:getAlpha()
    return self.overlay.a
end


---Get this HUD element's width in screen space.
function HUDElement:getWidth()
    return self.overlay.width
end


---Get this HUD element's height in screen space.
function HUDElement:getHeight()
    return self.overlay.height
end


---Set this HUD element's width and height.
-- Either value can be omitted (== nil) for no change.
function HUDElement:setDimension(width, height)
    self.overlay:setDimension(width, height)
end


---Get this HUD element's width and height.
-- @return float width
-- @return float height
function HUDElement:getDimension()
    return self.overlay.width, self.overlay.height
end


---Reset this HUD element's dimensions to their default values.
-- Resets width, height, scale and pivot.
function HUDElement:resetDimensions()
    self.overlay:resetDimensions()
    self.pivotX = self.defaultPivotX
    self.pivotY = self.defaultPivotY
end


---Set this HUD element overlay's color.
-- Children are unaffected.
function HUDElement:setColor(r, g, b, a)
    self.overlay:setColor(r, g, b, a)
end


---Set this HUD element overlay's color alpha value only.
function HUDElement:setAlpha(alpha)
    self.overlay:setColor(nil, nil, nil, alpha)
end


---Set this HUD element overlay's image file.
function HUDElement:setImage(imageFilename)
    self.overlay:setImage(imageFilename)
end


---Set this HUD element overlay's UV coordinates.
function HUDElement:setUVs(uvs)
    self.overlay:setUVs(uvs)
end


---Set this HUD element overlay's slice id.
function HUDElement:setSliceId(sliceId)
    self.overlay:setSliceId(sliceId)
end


---Update this HUD element's state.
function HUDElement:update(dt)
    if not self.animation:getFinished() then
        self.animation:update(dt)
    end
end


---Draw this HUD element and all of its children in order of addition.
function HUDElement:draw(clipX1, clipY1, clipX2, clipY2)
    if self.overlay.visible then
        self.overlay:render(clipX1, clipY1, clipX2, clipY2)

        for _, child in ipairs(self.children) do
            child:draw(clipX1, clipY1, clipX2, clipY2)
        end
    end
end






---Convert a vector from pixel values into scaled screen space values.
-- @param table vector2D Array of two pixel values
function HUDElement:scalePixelToScreenVector(vector2D)
    --#debug assertWithCallstack(vector2D ~= nil)
    return vector2D[1] * self.overlay.scaleWidth * g_aspectScaleX / g_referenceScreenWidth,
        vector2D[2] * self.overlay.scaleHeight * g_aspectScaleY / g_referenceScreenHeight
end







---Convert a vertical pixel value into scaled screen space value.
-- @param float height Vertical pixel value
function HUDElement:scalePixelToScreenHeight(height)
    return height * self.overlay.scaleHeight * g_aspectScaleY / g_referenceScreenHeight
end


---Convert a horizontal pixel value into scaled screen space value.
-- @param float width Horizontal pixel value
function HUDElement:scalePixelToScreenWidth(width)
    return width * self.overlay.scaleWidth * g_aspectScaleX / g_referenceScreenWidth
end


---Convert a texture space pivot to an element-local pivot.
-- @param table uvPivot Array of two pixel pivot coordinates in texture space
-- @param table uvs Array of UV coordinates as {x, y, width, height}
function HUDElement:normalizeUVPivot(uvPivot, size, uvs)
    return self:scalePixelToScreenWidth(uvPivot[1] * size[1] / uvs[3]),
        self:scalePixelToScreenHeight(uvPivot[2] * size[2] / uvs[4])
end
