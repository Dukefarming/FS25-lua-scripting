








---
local RollercoasterActivatable_mt = Class(RollercoasterActivatable)


---
-- @param table rollercoaster rollercoaster instance
function RollercoasterActivatable.new(rollercoaster)
    local self = setmetatable({}, RollercoasterActivatable_mt)

    self.rollercoaster = rollercoaster
    self.activateText = g_i18n:getText("action_rideRollercoaster")

    return self
end


---
function RollercoasterActivatable:getIsActivatable()
    return self.rollercoaster:getCanEnter()
end


---
function RollercoasterActivatable:run()
    if self.rollercoaster:getCanEnter() then
        local seatIndex = self.rollercoaster:getFreeSeatIndex()

        if seatIndex ~= nil then
            g_client:getServerConnection():sendEvent(RollercoasterPassengerEnterRequestEvent.new(self.rollercoaster, g_localPlayer))
        end
    end
end
