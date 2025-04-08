










---
local WashingStation_mt = Class(WashingStation, Object)




---
function WashingStation.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".trigger#node", "Vehicle trigger node")
    schema:register(XMLValueType.FLOAT, basePath .. "#washDuration", "Wash duration")
    schema:register(XMLValueType.INT, basePath .. "#pricePerWash", "Price per wash")
    SoundManager.registerSampleXMLPaths(schema,  basePath .. ".sounds", "active")
    EffectManager.registerEffectXMLPaths(schema, basePath .. ".effects")
end

























































































































































































































---
local WashingStationActivatable_mt = Class(WashingStationActivatable)


---
function WashingStationActivatable.new(washingStation, triggerNode)
    local self = setmetatable({}, WashingStationActivatable_mt)

    self.washingStation = washingStation
    self.triggerNode = triggerNode
    self.activateText = g_i18n:getText("action_startWashing")

    return self
end


---
function WashingStationActivatable:getIsActivatable()
    return g_currentMission.accessHandler:canFarmAccess(g_currentMission:getFarmId(), self.washingStation)
end


---
function WashingStationActivatable:run()
    g_client:getServerConnection():sendEvent(WashingStationEvent.new(self.washingStation))
end


---
function WashingStationActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.triggerNode)
    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end
