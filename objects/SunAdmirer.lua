






---Class for objects which are visible when the sun is out
local SunAdmirer_mt = Class(SunAdmirer)


---Creating sun admirer object
-- @param integer id ID of the node
function SunAdmirer:onCreate(id)
    g_currentMission:addNonUpdateable(SunAdmirer.new(id))
end


---Creating nightlight object
-- @param integer name ID of the node
-- @return table instance Instance of object
function SunAdmirer.new(id)
    local self = setmetatable({}, SunAdmirer_mt)

    self.id = id
    self.switchCollision = Utils.getNoNil(getUserAttribute(id, "switchCollision"), false)

    if self.switchCollision then
        self.collisionMask = getCollisionFilterMask(id)
    end

    self:setVisibility(true)

    g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.onWeatherChanged, self)

    return self
end


---Remove Object from WeatherChangeListeners
function SunAdmirer:delete()
    g_messageCenter:unsubscribeAll(self)
end










---Change visibility of sun object
function SunAdmirer:onWeatherChanged()
    if g_currentMission ~= nil and g_currentMission.environment ~= nil then
        self:setVisibility(g_currentMission.environment.isSunOn and not g_currentMission.environment.weather:getIsRaining())
    end
end
