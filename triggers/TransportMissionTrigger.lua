











---Class for transport mission triggers
local TransportMissionTrigger_mt = Class(TransportMissionTrigger)


---On create mission trigger
-- @param integer id trigger node id
function TransportMissionTrigger:onCreate(id)
    g_currentMission:addNonUpdateable(TransportMissionTrigger.new(id))
end


---Creating mission trigger object
-- @param integer name trigger node id
-- @return table instance instance of object
function TransportMissionTrigger.new(id)
    local self = setmetatable({}, TransportMissionTrigger_mt)

    self.triggerId = id
    self.index = getUserAttribute(self.triggerId, "index")

    addTrigger(id, "triggerCallback", self)

    self.isEnabled = true

    g_missionManager:addTransportMissionTrigger(self)

    -- Hide until needed
    self:setMission(nil)

    return self
end


---Deleting shop trigger
function TransportMissionTrigger:delete()
    removeTrigger(self.triggerId)

    g_missionManager:removeTransportMissionTrigger(self)
end













---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherId id of actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
function TransportMissionTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    if self.isEnabled and self.mission ~= nil then
        if onEnter then
            self.mission:objectEnteredTrigger(self, otherId)
        elseif onLeave then
            self.mission:objectLeftTrigger(self, otherId)
        end
    end
end
