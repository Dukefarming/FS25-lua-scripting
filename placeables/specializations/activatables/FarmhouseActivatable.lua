









---
local FarmhouseActivatable_mt = Class(FarmhouseActivatable)


---
function FarmhouseActivatable.new(placeable)
    local self = setmetatable({}, FarmhouseActivatable_mt)

    self.placeable = placeable
    self.activateText = g_i18n:getText("ui_inGameSleep")

    return self
end


---
function FarmhouseActivatable:getIsActivatable()
    return self.placeable:getIsAllowedToSleep(g_currentMission:getFarmId()) and not g_sleepManager.isSleeping
end


---
function FarmhouseActivatable:run()
    g_sleepManager:showDialog()
end
