



---Event for washing stations
local WashingStationEvent_mt = Class(WashingStationEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function WashingStationEvent.emptyNew()
    local self = Event.new(WashingStationEvent_mt)
    return self
end


---Create new instance of event
-- @param table washingStation washingStation
-- @return table instance instance of event
function WashingStationEvent.new(washingStation)
    local self = WashingStationEvent.emptyNew()
    self.washingStation = washingStation
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WashingStationEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.washingStation = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function WashingStationEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.washingStation)
    end
end


---Run action on receiving side
-- @param integer connection connection
function WashingStationEvent:run(connection)
    if not connection:getIsServer() then
        local userId = g_currentMission.userManager:getUserIdByConnection(connection)
        if userId ~= nil then
            local farm = g_farmManager:getFarmByUserId(userId)
            if farm ~= nil then
                self.washingStation:startWashing(farm.farmId)
            end
        end
    end
end
