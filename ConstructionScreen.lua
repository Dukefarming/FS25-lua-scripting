













---
local ConstructionScreen_mt = Class(ConstructionScreen, ScreenElement)















---Constructor
-- @param table target
-- @param table custom_mt
-- @return ConstructionScreen self instance
function ConstructionScreen.new(target, custom_mt)
    local self = ScreenElement.new(target, custom_mt or ConstructionScreen_mt)

    self.isMouseMode = true

    self.camera = GuiTopDownCamera.new()
    self.cursor = GuiTopDownCursor.new()
    self.sound = ConstructionSound.new()

    self.brush = nil

    self.items = {}
    self.clonedElements = {}
    self.menuEvents = {}
    self.brushEvents = {}
    self.configEvents = {}
    self.marqueeBoxes = {}

    self.detailsCache = {}
    self.detailsTemplates = {}

    self.configItemCache = {}
    self.configItemCacheLarge = {}

    return self
end




























































---Callback on open
function ConstructionScreen:onOpen()
    ConstructionScreen:superClass().onOpen(self)

    -- Used for a basic undo feature
    g_currentMission.lastConstructionScreenOpenTime = g_time

    g_inputBinding:setContext(ConstructionScreen.INPUT_CONTEXT)

    local viewPortStartX = self.menuBox.absPosition[1] + self.menuBox.absSize[1]
    self.viewPortStartX = viewPortStartX

    self.camera:setTerrainRootNode(g_terrainNode)
    self.camera:setEdgeScrollingOffset(viewPortStartX, 0, 1, 1)

    self.camera:activate()
    self.cursor:activate()

    self.originalSafeFrameOffsetX = g_safeFrameOffsetX
    g_safeFrameOffsetX = viewPortStartX + g_safeFrameOffsetX

    -- Initial brush is always the selector
    if self.selectorBrush == nil then
        local class = g_constructionBrushTypeManager:getClassObjectByTypeName("select")
        self.selectorBrush = class.new(nil, self.cursor)
    end
    self:setBrush(self.selectorBrush, true)

    if self.destructBrush == nil then
        local class = g_constructionBrushTypeManager:getClassObjectByTypeName("destruct")
        self.destructBrush = class.new(nil, self.cursor)
    end
    self.destructMode = false

    -- We need to know when mouse/gamepad changes
    self.isMouseMode = g_inputBinding.lastInputMode == GS_INPUT_HELP_MODE_KEYBOARD
    g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)

    self:rebuildData()

    if self.currentCategory == nil then
        self:setCurrentCategory(1, 1)
    end

    self:updateMenuState()

    FocusManager:setFocus(self.itemList)

    self.originalInputHelpVisibility = g_currentMission.hud.inputHelp:getVisible()
    g_currentMission.hud:setInputHelpVisible(true, true)

    g_messageCenter:subscribe(MessageType.SLOT_USAGE_CHANGED, self.onSlotUsageChanged, self)

    if g_isDevelopmentVersion then
        -- disable edge scrolling when game loses focus -- TODO: enable for non-dev PC platform after some testing?
        g_messageCenter:subscribe(MessageType.APP_WINDOW_FOCUS_CHANGED, self.onAppWindowFocusChanged, self)
    end

    if g_localPlayer ~= nil then
        self.wasFirstPerson = g_localPlayer:getCurrentVehicle() == nil and g_localPlayer.camera.isFirstPerson
        if self.wasFirstPerson then
            g_localPlayer.graphicsComponent:setModelVisibility(true)
        end
    end
end


---Callback on close
-- @param table element
function ConstructionScreen:onClose(element)
    if g_localPlayer ~= nil then
        if self.wasFirstPerson then
            g_localPlayer.graphicsComponent:setModelVisibility(false)
            self.wasFirstPerson = nil
        end
    end

    g_messageCenter:unsubscribeAll(self)

    g_currentMission.hud:setInputHelpVisible(self.originalInputHelpVisibility)

    -- Reset so it is known it is currently not open
    g_currentMission.lastConstructionScreenOpenTime = -1

    -- This will deactivate the selector brush
    self:setBrush(nil, false)

    g_safeFrameOffsetX = self.originalSafeFrameOffsetX

    self.camera:setEdgeScrollingOffset(0, 0, 1, 1)

    self.cursor:deactivate()
    self.camera:deactivate()

    self:removeMenuActionEvents()
    g_inputBinding:revertContext()

    ConstructionScreen:superClass().onClose(self)
end









































































































































































































































































































































---Register required action events for the camera.
function ConstructionScreen:registerBrushActionEvents()
    local _, eventId

    local brush = self.brush
    if brush == nil then
        return
    end

    self.brushEvents = {}

    -- We need primary button also to select objects without brush
    if brush.supportsPrimaryButton then
        if brush.supportsPrimaryDragging then
            _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimaryDrag, true, true, true, true)
            table.insert(self.brushEvents, eventId)

            self.primaryBrushEvent = eventId
        else
            _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)
            table.insert(self.brushEvents, eventId)

            self.primaryBrushEvent = eventId
        end

        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
    end

    if brush.supportsSecondaryButton then
        if brush.supportsSecondaryDragging then
            _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondaryDrag, true, true, true, true)
            table.insert(self.brushEvents, eventId)

            self.secondaryBrushEvent = eventId
        else
            _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SECONDARY, self, self.onButtonSecondary, false, true, false, true)
            table.insert(self.brushEvents, eventId)

            self.secondaryBrushEvent = eventId
        end

        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_HIGH)
    end

    if brush.supportsTertiaryButton then
        _, self.tertiaryBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_TERTIARY, self, self.onButtonTertiary, false, true, false, true)
        g_inputBinding:setActionEventTextPriority(self.tertiaryBrushEvent, GS_PRIO_HIGH)
        table.insert(self.brushEvents, self.tertiaryBrushEvent)
    end

    if brush.supportsFourthButton then
        _, self.fourthBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_FOURTH, self, self.onButtonFourth, false, true, false, true)
        g_inputBinding:setActionEventTextPriority(self.fourthBrushEvent, GS_PRIO_HIGH)
        table.insert(self.brushEvents, self.fourthBrushEvent)
    end

    if brush.placeableHasConfigs then
        _, self.showConfigsEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_SHOW_CONFIGS, self, self.onShowConfigs, false, true, false, true)
        g_inputBinding:setActionEventText(self.showConfigsEvent, g_i18n:getText("input_CONSTRUCTION_SHOW_CONFIGS"))
        g_inputBinding:setActionEventTextPriority(self.showConfigsEvent, GS_PRIO_HIGH)
        table.insert(self.brushEvents, self.showConfigsEvent)
    end

    -- Action axis: trigger on down. They are step-based axis or continuous, defined by the brush.

    if brush.supportsPrimaryAxis then
        _, self.primaryBrushAxisEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_PRIMARY, self, self.onAxisPrimary, false, not brush.primaryAxisIsContinuous, brush.primaryAxisIsContinuous, true)
        g_inputBinding:setActionEventTextPriority(self.primaryBrushAxisEvent, GS_PRIO_HIGH)
        table.insert(self.brushEvents, self.primaryBrushAxisEvent)
    end

    if brush.supportsSecondaryAxis then
        _, self.secondaryBrushAxisEvent = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_ACTION_SECONDARY, self, self.onAxisSecondary, false, not brush.secondaryAxisIsContinuous, brush.secondaryAxisIsContinuous, true)
        g_inputBinding:setActionEventTextPriority(self.secondaryBrushAxisEvent, GS_PRIO_HIGH)
        table.insert(self.brushEvents, self.secondaryBrushAxisEvent)
    end

    if brush.supportsSnapping then
        _, self.snappingBrushEvent = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_SNAPPING, self, self.onButtonSnapping, false, true, false, true)
        g_inputBinding:setActionEventTextPriority(self.snappingBrushEvent, GS_PRIO_HIGH)
        table.insert(self.brushEvents, self.snappingBrushEvent)
    end
end


































































---Remove action events registered on this screen.
function ConstructionScreen:removeBrushActionEvents()
    for _, event in ipairs(self.brushEvents) do
        g_inputBinding:removeActionEvent(event)
    end

    self.primaryBrushEvent = nil
    self.secondaryBrushEvent = nil
    self.tertiaryBrushEvent = nil
    self.fourthBrushEvent = nil
    self.primaryBrushAxisEvent = nil
    self.secondaryBrushAxisEvent = nil
    self.snappingBrushEvent = nil
    self.showConfigsEvent = nil
end









































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































---Creates a table that contains all different layout items. Section headers are excluded and saved separately.
-- These cells are later cloned to form the completed layout
function ConstructionScreen:buildCellDatabase()
    self.detailsTemplates = {}

    for i = #self.attributesLayout.elements, 1, -1 do
        local element = self.attributesLayout.elements[i]
        local name = element.name

        self.detailsTemplates[name] = element:clone()
        self.detailsCache[name] = {}
    end
end


---Get a cell with given type name. If there are cells with the correct name in the cellCache, we use those, otherwise a new one is created
-- @param string name Name of the cell
-- @return table A cell instance with the requested name
function ConstructionScreen:dequeueDetailsCell(name)
    if self.detailsTemplates[name] == nil then
        return nil
    end

    local cell

    local cache = self.detailsCache[name]
    if #cache > 0 then
        cell = cache[#cache]
        cache[#cache] = nil
    else
        cell = self.detailsTemplates[name]:clone(self)
    end

    self.attributesLayout:addElement(cell)

    return cell
end


---Release a cell to the cache after resetting it
-- @param table cell The cell to be added to the cache
function ConstructionScreen:queueDetailsCell(cell)
    local cache = self.detailsCache[cell.name]
    cache[#cache + 1] = cell

    self.attributesLayout:removeElement(cell)

    cell:unlinkElement()
end
