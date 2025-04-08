









---Info box
local InfoDisplayBox_mt = Class(InfoDisplayBox)


---
function InfoDisplayBox.new(infoDisplay, uiScale, customMt)
    local self = setmetatable({}, customMt or InfoDisplayBox_mt)

    self.infoDisplay = infoDisplay
    self.uiScale = uiScale

    return self
end


---
function InfoDisplayBox:delete()
end


---
function InfoDisplayBox:setScale(uiScale)
    self.uiScale = uiScale
    self:storeScaledValues()
end


---
function InfoDisplayBox:storeScaledValues()
end


---
function InfoDisplayBox:canDraw()
    return true
end


---
function InfoDisplayBox:draw(posX, posY)
    return posX, posY
end
