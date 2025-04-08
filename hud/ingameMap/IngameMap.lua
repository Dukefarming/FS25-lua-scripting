









---In-game map display element.
-- 
-- This class is used to display the game map both in the HUD as well as in the in-game menu.
local IngameMap_mt = Class(IngameMap, HUDElement)

























---Create a new instance of IngameMap.
-- @param table? customMt custom meta table
-- @return table self IngameMap instance
function IngameMap.new(customMt)
    local self = IngameMap:superClass().new(nil, nil, customMt or IngameMap_mt)
    self.overlay = self:createBackground()

    self.uiScale = 1.0

    self.isVisible = true
    self.clipHotspots = false

    self.fullScreenLayout = IngameMapLayoutFullscreen.new()
    self.layouts = {
        IngameMapLayoutNone.new(),
        IngameMapLayoutCircle.new(),
        IngameMapLayoutSquare.new(),
        IngameMapLayoutSquareLarge.new(),
        self.fullScreenLayout,
    }
    self.state = 1
    self.numToggleStates = 4
    self.layout = self.layouts[self.state]

    self.mapOverlay = Overlay.new(nil, 0, 0, 1, 1) -- null-object, obsoletes defensive checks
    self.mapElement = HUDElement.new(self.mapOverlay) -- null-object

    self:createComponents()
    for _, layout in ipairs(self.layouts) do
        layout:createComponents(self)
    end

    local function setDefaultValue(filter, category)
        filter[category] = not Utils.isBitSet(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_FILTER), category)
    end

    self.filter = {}
    setDefaultValue(self.filter, MapHotspot.CATEGORY_FIELD)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_ANIMAL)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_MISSION)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_TOUR)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_STEERABLE)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_COMBINE)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_TRAILER)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_TOOL)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_UNLOADING)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_LOADING)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_PRODUCTION)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_OTHER)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_SHOP)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_AI)
    setDefaultValue(self.filter, MapHotspot.CATEGORY_PLAYER)

    self.currentFilter = self.filter

    self:setWorldSize(2048, 2048)

    self.hotspots = {}
    self.selectedHotspot = nil

    self.mapExtensionOffsetX = 0.25
    self.mapExtensionOffsetZ = 0.25
    self.mapExtensionScaleFactor = 0.5

    self.allowToggle = true

    self.hotspotsDirty = true
    self.hotspotsRegular = {}
    self.hotspotsRenderLast = {}
    self.hotspotsPersistent = {}
    self.hotspotsPersistentRenderLast = {}
    self.hotspotsPostUpdate = {}

    self.topDownCamera = nil -- set by screen views which use a top down view, used for map position update

    return self
end


---Delete this element and all of its components.
function IngameMap:delete()
    g_inputBinding:removeActionEventsByTarget(self)

    self.mapElement:delete()
    self:setSelectedHotspot(nil)

    for _, layout in ipairs(self.layouts) do
        layout:delete()
    end

    IngameMap:superClass().delete(self)
end






---Set full-screen mode (for map overview) without affecting the mini-map state.
function IngameMap:setFullscreen(isFullscreen)
    if self.isFullscreen == isFullscreen then
        return
    end

    self.isFullscreen = isFullscreen

    local newLayout = self.layouts[self.state]
    if isFullscreen then
        newLayout = self.fullScreenLayout
    end

    self:setLayout(newLayout)
end



















---
function IngameMap:toggleSize(state, force)
--#profile     RemoteProfiler.zoneBeginN("IngameMap_toggleSize")

    if state ~= nil then
        self.state = math.max(math.min(state, self.numToggleStates), 1)
    else
        self.state = (self.state % self.numToggleStates) + 1
    end
    g_gameSettings:setValue("ingameMapState", self.state)

    self:setLayout(self.layouts[self.state])

--#profile     RemoteProfiler.zoneEnd()
end

























---
function IngameMap:resetSettings()
    if self.overlay == nil then
        return -- instance has been deleted, ignore reset
    end

    -- self:setScale(self.uiScale) -- resets scaled values

    -- local baseX, baseY = self:getBackgroundPosition()
    -- self:setPosition(baseX + self.mapOffsetX, baseY + self.mapOffsetY)
    -- self:setSize(self.mapWidth, self.mapHeight)

    self:setSelectedHotspot(nil)
end


















---
function IngameMap:setAllowToggle(isAllowed)
    self.allowToggle = isAllowed
end

















---
function IngameMap:loadMap(filename, worldSizeX, worldSizeZ, fieldColor, grassFieldColor)
    self.mapElement:delete() -- will also delete the wrapped Overlay

    self:setWorldSize(worldSizeX, worldSizeZ)

    self.mapOverlay = Overlay.new(filename, 0, 0, 1, 1)

    self.mapElement = HUDElement.new(self.mapOverlay)
    self:addChild(self.mapElement)

    self:setScale(self.uiScale)
end










---
function IngameMap:setWorldSize(worldSizeX, worldSizeZ)
    self.worldSizeX = worldSizeX
    self.worldSizeZ = worldSizeZ
    self.worldCenterOffsetX = self.worldSizeX * 0.5
    self.worldCenterOffsetZ = self.worldSizeZ * 0.5

    for _, layout in ipairs(self.layouts) do
        layout:setWorldSize(worldSizeX, worldSizeZ)
    end
end









---
function IngameMap:addMapHotspot(mapHotspot)
    table.addElement(self.hotspots, mapHotspot)

    self:sortHotspots()

    self:resetHotspotSorting()

    mapHotspot:addRenderStateChangedListener(self)

    return mapHotspot
end


---
function IngameMap:removeMapHotspot(mapHotspot)
    if mapHotspot ~= nil then
        table.removeElement(self.hotspots, mapHotspot)

        if self.selectedHotspot == mapHotspot then
            self:setSelectedHotspot(nil)
        end

        if g_currentMission ~= nil then
            if g_currentMission.currentMapTargetHotspot == mapHotspot then
                g_currentMission:setMapTargetHotspot(nil)
            end
        end

        mapHotspot:removeRenderStateChangedListener(self)

        self:resetHotspotSorting()
    end
end






---
function IngameMap:setSelectedHotspot(hotspot)
    if self.selectedHotspot ~= nil then
        self.selectedHotspot:setSelected(false)
    end
    self.selectedHotspot = hotspot
    if self.selectedHotspot ~= nil then
        self.selectedHotspot:setSelected(true)
    end
end






























































































































































































































































































































































































---Draw the player's current coordinates as text.
function IngameMap:drawPlayersCoordinates()
    local renderString = string.format("%.1f°, %d, %d", math.deg(-self.playerRotation % (2*math.pi)), self.normalizedPlayerPosX * self.worldSizeX, self.normalizedPlayerPosZ * self.worldSizeZ)

    self.layout:drawCoordinates(renderString)
end


---Draw current latency to server as text.
function IngameMap:drawLatencyToServer()
    local missionDynamicInfo = g_currentMission.missionDynamicInfo
    if g_client ~= nil and g_client.currentLatency ~= nil and missionDynamicInfo.isMultiplayer and missionDynamicInfo.isClient then
        local color
        if g_client.currentLatency <= 50 then
            color = IngameMap.COLOR.LATENCY_GOOD
        elseif g_client.currentLatency < 100 then
            color = IngameMap.COLOR.LATENCY_MEDIUM
        else
            color = IngameMap.COLOR.LATENCY_BAD
        end

        self.layout:drawLatency(string.format("%dms", math.max(g_client.currentLatency, 10)), color)
    end
end







































---Draw a single hotspot on the map.
function IngameMap:drawHotspot(hotspot, smallVersion, scale, doDebug)
    if hotspot == nil then
        return
    end

    local layout = self.layout
    local worldX, worldZ = hotspot:getWorldPosition()
    local rotation = hotspot:getWorldRotation()

    local objectX = (worldX + self.worldCenterOffsetX) / self.worldSizeX * self.mapExtensionScaleFactor + self.mapExtensionOffsetX
    local objectZ = (worldZ + self.worldCenterOffsetZ) / self.worldSizeZ * self.mapExtensionScaleFactor + self.mapExtensionOffsetZ

    if hotspot.scale ~= scale then
        hotspot:setScale(scale)
    end

    local width, height = hotspot:getDimension()
    local x, y, yRot, visible = layout:getMapObjectPosition(objectX, objectZ, width, height, rotation, hotspot:getIsPersistent())

    if not visible then
        return
    end

    -- extra clipping for mobile version
    if self.clipHotspots and self.clipX1 ~= nil then
        if x < self.clipX1 or (x + width) > self.clipX2 or y < self.clipY1 or (y + height) > self.clipY2 then
            return
        end
    end

    hotspot.lastScreenPositionX = x
    hotspot.lastScreenPositionY = y
    hotspot.lastScreenRotation = yRot
    hotspot.lastScreenLayout = layout

    hotspot:render(x, y, yRot, smallVersion)
end






---Set this element's scale.
-- @param float uiScale Current UI scale applied to both width and height of elements
function IngameMap:setScale(uiScale)
    IngameMap:superClass().setScale(self, uiScale, uiScale)
    self.uiScale = uiScale

    self:storeScaledValues(uiScale)
end


---Store scaled positioning, size and offset values.
function IngameMap:storeScaledValues(uiScale)
    for _, layout in ipairs(self.layouts) do
        layout:storeScaledValues(self, uiScale)
    end

    self.helpAnchorOffsetX, self.helpAnchorOffsetY = self:scalePixelValuesToScreenVector(0, 15)
end



















---Get the base position of the entire element.
function IngameMap:getBackgroundPosition()
    return g_safeFrameOffsetX, g_safeFrameOffsetY
end









---Create the empty background overlay.
function IngameMap:createBackground()
    local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.SELF))
    local posX, posY = self:getBackgroundPosition()

    local overlay = g_overlayManager:createOverlay(IngameMap.SLICE_IDS.BACKGROUND_ROUND, posX, posY, width, height)
    overlay:setColor(0,0,0,0.75)

    return overlay
end


---Create required display components.
function IngameMap:createComponents()
    local baseX, baseY = self:getPosition()
    local width, height = self:getWidth(), self:getHeight()

    self:createToggleMapSizeGlyph(baseX, baseY, width, height)
end


---Create the input glyph for map size toggling.
function IngameMap:createToggleMapSizeGlyph(baseX, baseY, baseWidth, baseHeight)
    local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.INPUT_ICON))
    local offX, offY = getNormalizedScreenValues(unpack(IngameMap.POSITION.INPUT_ICON))

    local element = InputGlyphElement.new(g_inputDisplayManager, width, height)
    local posX, posY = baseX + offX, baseY + offY

    element:setPosition(posX, posY)
    element:setKeyboardGlyphColor(IngameMap.COLOR.INPUT_ICON)
    element:setAction(InputAction.TOGGLE_MAP_SIZE)

    self.toggleMapSizeGlyph = element
    self:addChild(element)
end
