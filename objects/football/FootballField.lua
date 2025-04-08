















---
local FootballField_mt = Class(FootballField, Object)






























---Creating football field
-- @param integer id node id
function FootballField.onCreate(_, id)
    local footballField = FootballField.new(g_server ~= nil, g_client ~= nil)
    if footballField:load(id) then
        g_currentMission.onCreateObjectSystem:add(footballField)
        footballField:register(true)
    else
        footballField:delete()
    end
end


---Creating football field object
-- @param boolean isServer is server
-- @param boolean isClient is client
-- @param table customMt customMt
-- @return table instance Instance of object
function FootballField.new(isServer, isClient, customMt)
    local self = Object.new(isServer, isClient, customMt or FootballField_mt)

    registerObjectClassName(self, "FootballField")

    self.i3dMappings = {}
    self.components = {}

    return self
end



















































































































---Deleting football field object
function FootballField:delete()
    if self.football ~= nil then
        self.football:delete()
    end

    if self.goalTriggerBlueNode ~= nil then
        removeTrigger(self.goalTriggerBlueNode)
    end
    if self.goalTriggerRedNode ~= nil then
        removeTrigger(self.goalTriggerRedNode)
    end
    if self.gameAreaNode ~= nil then
        removeTrigger(self.gameAreaNode)
    end
    if self.resetTriggerNode ~= nil then
        removeTrigger(self.resetTriggerNode)
    end
    if self.ballResetTimer ~= nil then
        self.ballResetTimer:reset()
    end

    g_soundManager:deleteSamples(self.samples)

    g_currentMission.activatableObjectsSystem:removeActivatable(self.resetActivatable)

    removeConsoleCommand("gsFootballFieldReload")

    unregisterObjectClassName(self)
    FootballField:superClass().delete(self)
end




















---Called on server side on join
-- @param integer streamId stream ID
-- @param table connection connection
function FootballField:writeStream(streamId, connection)
    FootballField:superClass().writeStream(self, streamId, connection)

    if not connection:getIsServer() then
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.football))
        self.football:writeStream(streamId, connection)
        g_server:registerObjectInStream(connection, self.football)

        streamWriteUInt8(streamId, self.scoreBlue)
        streamWriteUInt8(streamId, self.scoreRed)
    end
end
