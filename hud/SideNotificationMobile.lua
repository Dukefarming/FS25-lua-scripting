





















---HUD side notification element for mobile version
-- 
-- Custom sub class of side notification with different uv's and text size
local SideNotificationMobile_mt = Class(SideNotificationMobile, SideNotification)


---Create a new SideNotificationMobile.
-- @return table SideNotificationMobile instance
function SideNotificationMobile.new()
    local self = SideNotificationMobile:superClass().new(SideNotificationMobile_mt)

    self.uiScale = 1
    self.r, self.g, self.b, self.a = unpack(SideNotificationMobile.COLOR.BACKGROUND)

    self:applyValues(self.uiScale)

    return self
end




































































---Get this element's base background position.
-- @param float uiScale Current UI scale factor
function SideNotificationMobile.getBackgroundPosition(uiScale)
    local offX, offY = getNormalizedScreenValues(unpack(SideNotificationMobile.POSITION.SELF))
    return 1 + offX * uiScale, 1 + offY * uiScale -- top right corner plus offset
end


---Create the background overlay.
function SideNotificationMobile:createBackground()
    local posX, posY = SideNotificationMobile.getBackgroundPosition(1)
    local width, height = getNormalizedScreenValues(unpack(SideNotificationMobile.SIZE.SELF))

    local overlay = Overlay.new(nil, posX - width, posY - height, width, height)
    return overlay
end
