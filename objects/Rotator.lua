






---s rotate around a specified axis (default z) with a specified speed
local Rotator_mt = Class(Rotator)


---Creating rotator
-- @param entityId id node id
function Rotator:onCreate(id)
    g_currentMission:addUpdateable(Rotator.new(id))
end


---Creating rotator
-- @param entityId node node id
-- @return table instance Instance of object
function Rotator.new(node)
    local self = setmetatable({}, Rotator_mt)

    self.axisTable = {0, 0, 0}
    self.rotationNode = node
    local rpm = tonumber(getUserAttribute(node, "rpm"))
    if rpm ~= nil then
        self.speed = (rpm * 2 * math.pi) / 60 / 1000  -- rpm to rad/ms
    else
        self.speed = Utils.getNoNil(tonumber(getUserAttribute(node, "speed")), 0.0012)
    end
    local axis = Utils.getNoNil(getUserAttribute(node, "axis"), 3)
    self.axisTable[axis] = 1

    return self
end






---Update
-- @param float dt time since last call in ms
function Rotator:update(dt)
    rotate(self.rotationNode, self.axisTable[1] * self.speed * dt, self.axisTable[2] * self.speed * dt, self.axisTable[3] * self.speed * dt)
end
