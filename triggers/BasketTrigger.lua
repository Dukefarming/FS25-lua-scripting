








---Class for basket triggers
local BasketTrigger_mt = Class(BasketTrigger)


---On create basket trigger
-- @param integer id id of trigger node
function BasketTrigger:onCreate(id)
    local trigger = BasketTrigger.new()
    if trigger:load(id) then
        g_currentMission:addNonUpdateable(trigger)
    else
        trigger:delete()
    end
end


---Creating basket trigger object
-- @param table? customMt custom metatable (optional)
-- @return table instance instance of basket trigger object
function BasketTrigger.new(customMt)
    local self = setmetatable({}, customMt or BasketTrigger_mt)

    self.triggerId = 0
    self.nodeId = 0

    return self
end


---Load basket trigger
-- @param integer nodeId id of node
-- @return boolean success success
function BasketTrigger:load(nodeId)
    self.nodeId = nodeId

    self.triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "triggerIndex"))
    if self.triggerId == nil then
        self.triggerId = nodeId
    end
    addTrigger(self.triggerId, "triggerCallback", self)

    self.triggerObjects = {}

    self.isEnabled = true

    return true
end


---Delete basket trigger
function BasketTrigger:delete()
    removeTrigger(self.triggerId)
end


---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherId id of actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
function BasketTrigger:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    if self.isEnabled then

        if onEnter then
            local object = g_currentMission:getNodeObject(otherActorId)
            if object.thrownFromPosition ~= nil then
                self.triggerObjects[otherActorId] = true
            end

        elseif onLeave then
            if self.triggerObjects[otherActorId] then
                self.triggerObjects[otherActorId] = false

                -- local object = g_currentMission:getNodeObject(otherActorId)
                -- local x,y,z = worldToLocal(self.triggerId, object.thrownFromPosition[1],object.thrownFromPosition[2],object.thrownFromPosition[3])
                -- local dist = MathUtil.vector3Length(x,y,z)
            end
        end
    end
end
