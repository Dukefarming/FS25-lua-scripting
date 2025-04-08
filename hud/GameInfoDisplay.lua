

























---
local GameInfoDisplay_mt = Class(GameInfoDisplay, HUDDisplay)


---Create a new instance of GameInfoDisplay.
function GameInfoDisplay.new()
    local self = GameInfoDisplay:superClass().new(GameInfoDisplay_mt)

    local activeColor = HUD.COLOR.ACTIVE

    local r, g, b, a = 0, 0, 0, 0.80
    self.moneyBgRight = g_overlayManager:createOverlay("gui.gameInfo_right", 0, 0, 0, 0)
    self.moneyBgRight:setColor(r, g, b, a)
    self.moneyBgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
    self.moneyBgScale:setColor(r, g, b, a)

    r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    self.infoBgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
    self.infoBgScale:setColor(r, g, b, a)
    self.infoBgLeft = g_overlayManager:createOverlay("gui.gameInfo_left", 0, 0, 0, 0)
    self.infoBgLeft:setColor(r, g, b, a)

    self.calendarIcon = g_overlayManager:createOverlay("gui.icon_calendar", 0, 0, 0, 0)
    self.calendarIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])

    self.weatherIcon = g_overlayManager:createOverlay("gui.icon_weather_sun", 0, 0, 0, 0)
    self.weatherIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.weatherNextIcon = g_overlayManager:createOverlay("gui.icon_weather_sun", 0, 0, 0, 0)
    self.weatherNextIcon:setColor(1, 1, 1, 0.2)

    self.clockIcon = g_overlayManager:createOverlay("gui.icon_clock", 0, 0, 0, 0)
    self.clockIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.clockHandHour = g_overlayManager:createOverlay("gui.clockhand_hour", 0, 0, 0, 0)
    self.clockHandHour:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
    self.clockHandMinute = g_overlayManager:createOverlay("gui.clockhand_minute", 0, 0, 0, 0)
    self.clockHandMinute:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])

    self.fastForwardIcon = g_overlayManager:createOverlay("gui.fastforward", 0, 0, 0, 0)
    self.fastForwardIcon:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])

    self.fastForwardArrowIcon = g_overlayManager:createOverlay("gui.fastforward_arrow", 0, 0, 0, 0)
    self.fastForwardArrowIcon:setColor(0, 0, 0, 1)

    self.weatherSliceIds = {}
    self.weatherSliceIds[WeatherType.SUN] = "gui.icon_weather_sun"
    self.weatherSliceIds[WeatherType.PARTIALLY_CLOUDY] = "gui.icon_weather_partiallyCloudy"
    self.weatherSliceIds[WeatherType.CLOUDY] = "gui.icon_weather_cloudy"
    self.weatherSliceIds[WeatherType.RAIN] = "gui.icon_weather_rain"
    self.weatherSliceIds[WeatherType.SNOW] = "gui.icon_weather_snow"
    self.weatherSliceIds[WeatherType.HAIL] = "gui.icon_weather_hail"
    self.weatherSliceIds[WeatherType.TWISTER] = "gui.icon_weather_twister"
    self.weatherSliceIds[WeatherType.THUNDER] = "gui.icon_weather_thunder"

    return self
end



















---Store scaled positioning, size and offset values.
function GameInfoDisplay:storeScaledValues()
    self:setPosition(g_hudAnchorRight, g_hudAnchorTop)

    self.helpAnchorOffsetY = self:scalePixelToScreenHeight(-80)

    local textSize = 17
    local textOffsetY = 27
    local moneyBgRightWidth, infoBgHeight = self:scalePixelValuesToScreenVector(10, 65)
    self.moneyBgRight:setDimension(moneyBgRightWidth, infoBgHeight)
    self.moneyBgScale:setDimension(0, infoBgHeight)
    self.moneyTextSize = self:scalePixelToScreenHeight(textSize)
    self.moneyTextSpacing = self:scalePixelToScreenWidth(20)
    self.moneyTextOffsetX, self.moneyTextOffsetY = self:scalePixelValuesToScreenVector(-20, textOffsetY)
    self.moneyHelpOffsetX = self:scalePixelToScreenWidth(-60)

    local infoBgLeftWidth = self:scalePixelToScreenWidth(10)
    self.infoBgScale:setDimension(0, infoBgHeight)
    self.infoBgLeft:setDimension(infoBgLeftWidth, infoBgHeight)

    local calendarIconWidth, calendarIconHeight = self:scalePixelValuesToScreenVector(48, 48)
    self.calendarIcon:setDimension(calendarIconWidth, calendarIconHeight)
    self.calendarIconOffsetY = self:scalePixelToScreenHeight(10)
    self.calendarTextSize = self:scalePixelToScreenHeight(textSize)
    self.calendarTextOffsetY = self:scalePixelToScreenHeight(textOffsetY)
    self.calendarHelpOffsetX = self:scalePixelToScreenWidth(-60)

    local weatherIconWidth, weatherIconHeight = self:scalePixelValuesToScreenVector(48, 48)
    self.weatherIcon:setDimension(weatherIconWidth, weatherIconHeight)
    self.weatherIconOffsetY = self:scalePixelToScreenHeight(8)
    local weatherIconNextWidth, weatherIconNextHeight = self:scalePixelValuesToScreenVector(32, 32)
    self.weatherNextIcon:setDimension(weatherIconNextWidth, weatherIconNextHeight)
    self.weatherNextIconOffsetX, self.weatherNextIconOffsetY = self:scalePixelValuesToScreenVector(55, 8)
    self.weatherNextIconSpacing = self:scalePixelToScreenWidth(42)
    self.weatherHelpOffsetX = self:scalePixelToScreenWidth(-60)

    local clockIconWidth, clockIconHeight = self:scalePixelValuesToScreenVector(48, 48)
    self.clockIcon:setDimension(clockIconWidth, clockIconHeight)
    local clockHandHourWidth, clockHandHourHeight = self:scalePixelValuesToScreenVector(2, 8)
    self.clockHandHour:setDimension(clockHandHourWidth, clockHandHourHeight)
    local clockHandMinuteWidth, clockHandMinuteHeight = self:scalePixelValuesToScreenVector(2, 12)
    self.clockHandMinute:setDimension(clockHandMinuteWidth, clockHandMinuteHeight)

    self.clockIconOffsetY = self:scalePixelToScreenHeight(8)
    self.clockTextSize = self:scalePixelToScreenHeight(textSize)
    self.clockTextOffsetY = self:scalePixelToScreenHeight(textOffsetY)
    self.clockHandSmallX, self.clockHandSmallY = self:scalePixelValuesToScreenVector(10, 10)

    local fastForwardWidth, fastForwardHeight = self:scalePixelValuesToScreenVector(23, 14)
    self.fastForwardIcon:setDimension(fastForwardWidth, fastForwardHeight)
    local fastForwardArrowWidth, fastForwardArrowHeight = self:scalePixelValuesToScreenVector(6, 6)
    self.fastForwardArrowIcon:setDimension(fastForwardArrowWidth, fastForwardArrowHeight)
    self.fastForwardOffsetX, self.fastForwardOffsetY = self:scalePixelValuesToScreenVector(10, 26)
    self.fastForwardTextOffsetX, self.fastForwardTextOffsetY = self:scalePixelValuesToScreenVector(5, textOffsetY)
    self.fastForwardTextSize = self:scalePixelToScreenHeight(textSize)
    self.fastForwardArrowOffsetX, self.fastForwardArrowOffsetY = self:scalePixelValuesToScreenVector(9, 4)
    self.fastForwardArrow1OffsetX, self.fastForwardArrow1OffsetY = self:scalePixelValuesToScreenVector(6, 4)
    self.fastForwardArrow2OffsetX, self.fastForwardArrow2OffsetY = self:scalePixelValuesToScreenVector(13, 4)

    self.separatorWidth = self:scalePixelToScreenWidth(2)
    self.separatorHeight = self:scalePixelToScreenHeight(35)
    self.separatorOffsetY = self:scalePixelToScreenHeight(17)

    self.spacing = self:scalePixelToScreenWidth(20)
end
