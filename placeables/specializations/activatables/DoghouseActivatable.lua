








---
local DoghouseActivatable_mt = Class(DoghouseActivatable)


---
function DoghouseActivatable.new(doghousePlaceable)
    local self = setmetatable({}, DoghouseActivatable_mt)

    self.doghousePlaceable = doghousePlaceable
    self.activateText = g_i18n:getText("action_doghouseFillbowl")

    return self
end


---
function DoghouseActivatable:run()
    self.doghousePlaceable:setFoodBowlState(true)
end


---
function DoghouseActivatable:draw()
    local dog = self.doghousePlaceable:getDog()
    local name = ""
    if dog ~= nil then
        name = dog.name
    end

    g_currentMission:showFillDogBowlContext(name)
end


---
function DoghouseActivatable:activate()
    g_currentMission:addDrawable(self)
end


---
function DoghouseActivatable:deactivate()
    g_currentMission:removeDrawable(self)
end
