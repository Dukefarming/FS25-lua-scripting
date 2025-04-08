















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function VehicleSettings.prerequisitesPresent(specializations)
    return true
end


---
function VehicleSettings.initSpecialization()
end


---
function VehicleSettings.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "registerVehicleSetting", VehicleSettings.registerVehicleSetting)
    SpecializationUtil.registerFunction(vehicleType, "setVehicleSettingState", VehicleSettings.setVehicleSettingState)
    SpecializationUtil.registerFunction(vehicleType, "forceVehicleSettingsUpdate", VehicleSettings.forceVehicleSettingsUpdate)
end


---
function VehicleSettings.registerEvents(vehicleType)
    SpecializationUtil.registerEvent(vehicleType, "onVehicleSettingChanged")
end


---
function VehicleSettings.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", VehicleSettings)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", VehicleSettings)
    SpecializationUtil.registerEventListener(vehicleType, "onStateChange", VehicleSettings)
    SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", VehicleSettings)
end


---Called on loading
-- @param table savegame savegame
function VehicleSettings:onPreLoad(savegame)
    local spec = self.spec_vehicleSettings

    spec.isDirty = false
    spec.settings = {}

    if self.isServer then
        SpecializationUtil.removeEventListener(self, "onUpdateTick", VehicleSettings)
    end
end


---Called on updateTick
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function VehicleSettings:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_vehicleSettings
    if spec.isDirty then
        local hasDirtyValue = false
        for i=1, #spec.settings do
            if spec.settings[i].isDirty then
                hasDirtyValue = true
                break
            end
        end

        if hasDirtyValue then
            if g_server == nil and g_client ~= nil then
                g_client:getServerConnection():sendEvent(VehicleSettingsChangeEvent.new(self, spec.settings))
            end
        end

        spec.isDirty = false
    end
end


---Registers a game settings for this vehicle
-- @param string gameSettingId id of game setting
-- @param boolean isBool settings is only a boolean
function VehicleSettings:registerVehicleSetting(gameSettingId, isBool)
    local spec = self.spec_vehicleSettings

    local setting = {}
    setting.index = #spec.settings + 1
    setting.gameSettingId = gameSettingId
    setting.isBool = isBool
    setting.callback = function(_, state)
        if self:getIsActiveForInput(true, true) then
            self:setVehicleSettingState(setting.index, state)
        end
    end

    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[gameSettingId], setting.callback, self)

    table.insert(spec.settings, setting)
end


---Force update of vehicle settings -> current settings will be send from client to server
function VehicleSettings:forceVehicleSettingsUpdate()
    local spec = self.spec_vehicleSettings
    for i=1, #spec.settings do
        local setting = spec.settings[i]
        self:setVehicleSettingState(setting.index, g_gameSettings:getValue(setting.gameSettingId), true)
    end
end


---Set state of vehicle setting by index
-- @param integer settingIndex index of setting
-- @param any state state
-- @param boolean noEventSend no event will be send if true
function VehicleSettings:setVehicleSettingState(settingIndex, state, noEventSend)
    local spec = self.spec_vehicleSettings
    local setting = spec.settings[settingIndex]
    if setting ~= nil then
        if noEventSend == nil or noEventSend == false then
            if g_server == nil and g_client ~= nil then
                g_client:getServerConnection():sendEvent(VehicleSettingsChangeEvent.new(self, spec.settings))
            end
        end

        setting.state = state
        setting.isDirty = true
        spec.isDirty = true

        SpecializationUtil.raiseEvent(self, "onVehicleSettingChanged", setting.gameSettingId, state)
    end
end


---Called if vehicle state changes
function VehicleSettings:onStateChange(state, vehicle, isControlling)
    if isControlling then
        if state == VehicleStateChange.ENTER_VEHICLE then
            self:forceVehicleSettingsUpdate()
        end
    end
end
