




























---Vehicle Steering Slider for Mobile Version
local GameInfoDisplayMobile_mt = Class(GameInfoDisplayMobile, HUDDisplayElement)




---Creates a new GameInfoDisplayMobile instance.
-- @param string hudAtlasPath Path to the HUD texture atlas.
function GameInfoDisplayMobile.new(hud, hudAtlasPath, moneyUnit, controlHudAtlasPath)
    local backgroundOverlay = GameInfoDisplayMobile.createBackground()
    local self = GameInfoDisplayMobile:superClass().new(backgroundOverlay, nil, GameInfoDisplayMobile_mt)

    self.hud = hud
    self.uiScale = 1.0
    self.hudAtlasPath = hudAtlasPath
    self.controlHudAtlasPath = controlHudAtlasPath
    self.moneyUnit = moneyUnit

    self.vehicle = nil
    self.isRideable = false

    self.buttons = {}
    self.textElements = {}

    self:createMenuButton()
    self:createShopButton()
    self:createMapButton()
    self:createHelpButton()

    self:createWeatherElement()
    self:createMoneyElement()
    self:createFuelFitnessElement()

    g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)

    return self
end


---
function GameInfoDisplayMobile:setVehicle(vehicle)
    self.vehicle = vehicle

    if vehicle ~= nil then
        self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)
    else
        self.isRideable = false
    end

    self.fuelFitnessElement:setVisible(vehicle ~= nil)
end





































































































































































































































































































































---
function GameInfoDisplayMobile:onOpenShop()
    if g_sleepManager:getIsSleeping() then
        return
    end
    g_currentMission:onToggleStore()
end


---
function GameInfoDisplayMobile:onOpenMap()
    if g_sleepManager:getIsSleeping() then
        return
    end
    g_currentMission:onToggleMap()
end


---
function GameInfoDisplayMobile:onOpenMenu()
    if g_sleepManager:getIsSleeping() then
        return
    end
    g_currentMission:onToggleMenu()
end


---
function GameInfoDisplayMobile:onOpenHelp()
    if g_sleepManager:getIsSleeping() then
        return
    end
    g_currentMission:onToggleHelp()
end


---Set the money unit for displaying the account balance.
-- @param integer moneyUnit Money unit ID, any of [GS_MONEY_EURO | GS_MONEY_POUND | GS_MONEY_DOLLAR]. Invalid values are substituted by GS_MONEY_DOLLAR.
function GameInfoDisplayMobile:setMoneyUnit(moneyUnit)
    if moneyUnit ~= GS_MONEY_EURO and moneyUnit ~= GS_MONEY_POUND and moneyUnit ~= GS_MONEY_DOLLAR then
        moneyUnit = GS_MONEY_DOLLAR
    end

    self.moneyUnit = moneyUnit
end


---Set the mission information reference for base information display.
-- @param table missionInfo MissionInfo reference, do not change
function GameInfoDisplayMobile:setMissionInfo(missionInfo)
    self.missionInfo = missionInfo
end


---Set the environment reference to use for weather information display.
-- @param table environment Environment reference, do not change
function GameInfoDisplayMobile:setEnvironment(environment)
    self.environment = environment
end


---Set visibility of the money display.
function GameInfoDisplayMobile:setMoneyVisible(isVisible)
end


---Set visibility of time display.
function GameInfoDisplayMobile:setTimeVisible(isVisible)
end


---Set visibility of temperature display.
function GameInfoDisplayMobile:setTemperatureVisible(isVisible)
end


---Set visibility of weather display.
function GameInfoDisplayMobile:setWeatherVisible(isVisible)
end





---Set visibility of tutorial progress display.
function GameInfoDisplayMobile:setTutorialVisible(isVisible)
end


---Set the current tutorial progress values.
-- @param float progress Progress expressed as a number between 0 and 1
function GameInfoDisplayMobile:setTutorialProgress(progress)
end

























---
function GameInfoDisplayMobile:draw()
    for _, drawFuncs in ipairs(self.textElements) do
        drawFuncs()
    end

    GameInfoDisplayMobile:superClass().draw(self)
end






































---Set this element's scale.
function GameInfoDisplayMobile:setScale(uiScale)
    GameInfoDisplayMobile:superClass().setScale(self, uiScale, uiScale)

    local currentVisibility = self:getVisible()
    self:setVisible(true, false)

    self.uiScale = uiScale
    local posX, posY, width, height = GameInfoDisplayMobile.getBackgroundPositionAndSize(uiScale)
    self:setPosition(posX, posY)

    self:setDimension(width, height)
    self:storeOriginalPosition()

    self:setVisible(currentVisibility, false)

    local refPosX = posX + width
    local refPosY = posY + height

    self:updateButtonPosition(self.shopButton, refPosX, refPosY)
    self:updateButtonPosition(self.menuButton, refPosX, refPosY)
    self:updateButtonPosition(self.mapButton, refPosX, refPosY)
    self:updateButtonPosition(self.helpButton, refPosX, refPosY)

    local buttonHighlight = self.helpHighlightElement
    posX = refPosX + buttonHighlight.offsetX*self.uiScale
    buttonHighlight:setPosition(posX, nil)
end






---Get the position of the background element, which provides this element's absolute position.
-- @param scale Current UI scale
-- @param float width Scaled background width in pixels
-- @return float X position in screen space
-- @return float Y position in screen space
function GameInfoDisplayMobile.getBackgroundPositionAndSize(scale)
    local offX, offY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.BACKGROUND))
    local _, sizeY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BACKGROUND))

    offX = offX*scale

    local leftInset, rightInset, _, _ = getSafeFrameInsets()

    leftInset = math.max(leftInset, offX)
    rightInset = math.max(rightInset, offX)

    local sizeX = 1 - leftInset - rightInset

    local posX = leftInset
    local posY = 1 + offY*scale - sizeY*scale

    return posX, posY, sizeX, sizeY
end






---Create an empty background overlay as a base frame for this element.
function GameInfoDisplayMobile.createBackground()
    local posX, posY, width, height = GameInfoDisplayMobile.getBackgroundPositionAndSize(1)
    local overlay = Overlay.new(nil, posX, posY, width, height)
--     overlay.debugEnabled = true
    return overlay
end
