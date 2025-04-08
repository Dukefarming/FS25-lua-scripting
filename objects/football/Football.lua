












---
local Football_mt = Class(Football, PhysicsObject)














---Creating football object
-- @param boolean isServer is server
-- @param boolean isClient is client
-- @param table? customMt customMt
-- @return table instance Instance of object
function Football.new(isServer, isClient, customMt)
    local self = PhysicsObject.new(isServer, isClient, customMt or Football_mt)

    self.forcedClipDistance = 200
    registerObjectClassName(self, "Football")

    return self
end



























---Deleting football object
function Football:delete()
    g_soundManager:deleteSamples(self.samples)
    unregisterObjectClassName(self)

    self:removeChildrenFromNodeObject(self.nodeId)

    -- call physics super function as we dont want to delete the ball entity
    PhysicsObject:superClass().delete(self)
end
