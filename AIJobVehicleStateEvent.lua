




---Event for ai start
local AIJobVehicleStateEvent_mt = Class(AIJobVehicleStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIJobVehicleStateEvent.emptyNew()
    local self = Event.new(AIJobVehicleStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean isActive is active
function AIJobVehicleStateEvent.new(vehicle, job, helperIndex, startedFarmId)
    local self = AIJobVehicleStateEvent.emptyNew()

    self.vehicle = vehicle
    self.job = job
    self.helperIndex = helperIndex
    self.startedFarmId = startedFarmId

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIJobVehicleStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    if streamReadBool(streamId) then
        local jobId = streamReadInt32(streamId)
        self.job = g_currentMission.aiSystem:getJobById(jobId)
        self.startedFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        self.helperIndex = streamReadUInt8(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIJobVehicleStateEvent:writeStream(streamId, connection)
    assert(not connection:getIsServer(), "AIJobVehicleStateEvent is a server to client event only")
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    if streamWriteBool(streamId, self.job ~= nil) then
        streamWriteInt32(streamId, self.job.jobId)
        streamWriteUIntN(streamId, self.startedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        streamWriteUInt8(streamId, self.helperIndex)
    end
end


---Run action on receiving side
-- @param integer connection connection
function AIJobVehicleStateEvent:run(connection)
    if self.vehicle ~= nil then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            if self.job ~= nil then
                self.vehicle:aiJobStarted(self.job, self.helperIndex, self.startedFarmId)
            else
                self.vehicle:aiJobFinished()
            end
        end
    end
end
