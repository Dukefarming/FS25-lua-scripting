






















---
local TopNotification_mt = Class(TopNotification, HUDDisplay)


---Create a new instance of TopNotification.
function TopNotification.new()
    local self = TopNotification:superClass().new(TopNotification_mt)

    self.currentNotification = {title="", text="", info="", icon=nil, duration=0, isValid=false}

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.bgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
    self.bgScale:setColor(r, g, b, a)
    self.bgLeft = g_overlayManager:createOverlay("gui.gameInfo_left", 0, 0, 0, 0)
    self.bgLeft:setColor(r, g, b, a)
    self.bgRight = g_overlayManager:createOverlay("gui.gameInfo_right", 0, 0, 0, 0)
    self.bgRight:setColor(r, g, b, a)

    self.icons = {}

    return self
end












---Store scaled positioning, size and offset values.
function TopNotification:storeScaledValues()
    self:setPosition(0.5, g_hudAnchorTop)

    local bgRightWidth, bgHeight = self:scalePixelValuesToScreenVector(10, 65)
    local bgLeftWidth = self:scalePixelToScreenWidth(10)
    local bgScaleWidth = self:scalePixelToScreenWidth(460)
    self.bgRight:setDimension(bgRightWidth, bgHeight)
    self.bgScale:setDimension(bgScaleWidth, bgHeight)
    self.bgLeft:setDimension(bgLeftWidth, bgHeight)

    self.iconWidth, self.iconHeight = self:scalePixelValuesToScreenVector(80, 40)
    self.iconOffsetX, self.iconOffsetY = self:scalePixelValuesToScreenVector(7, 13)

    self.titleTextSize = self:scalePixelToScreenHeight(17)
    self.titleTextOffsetY = self:scalePixelToScreenHeight(40)
    self.textSize = self:scalePixelToScreenHeight(12)
    self.textOffsetY = self:scalePixelToScreenHeight(24)
    self.infoTextSize = self:scalePixelToScreenHeight(12)
    self.infoTextOffsetY = self:scalePixelToScreenHeight(11)

--     self:setNotification("Classic Radio Network FM", "Artist - Song name or something", "something in transparent yadda yadda", "dataS/menu/hud/radioStations/radio_classic.png", 2000)
end






























































---Set a notification to be displayed in a frame at the top of the screen.
-- If another notification is being displayed, it is immediately replaced by this new one.
-- @param string title Notification title
-- @param string text Notification message text
-- @param string info Additional info text
-- @param string? iconFilename [optional] Filename of the icon
-- @param integer? duration [optional] Display duration in milliseconds. Negative values or nil default to a long-ish standard duration.
function TopNotification:setNotification(title, text, info, iconFilename, duration)
    local icon = self.icons[iconFilename]
    if iconFilename ~= nil and icon == nil then
        icon = Overlay.new(iconFilename, 0, 0, self.iconWidth, self.iconHeight)
        self.icons[iconFilename] = icon
    end

    self.currentNotification.title = utf8ToUpper(title)
    self.currentNotification.text = utf8ToUpper(text)
    self.currentNotification.info = info
    self.currentNotification.icon = icon
    self.currentNotification.duration = duration or TopNotification.DEFAULT_DURATION
    self.currentNotification.isValid = true
end
