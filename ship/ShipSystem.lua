








---
local ShipSystem_mt = Class(ShipSystem)


---
function ShipSystem.new(customMt)
    local self = setmetatable({}, customMt or ShipSystem_mt)

    self.splines = {}
    self.crossingNodes = {}

    return self
end
