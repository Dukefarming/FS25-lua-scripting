




---Event for ai start
local AIFieldWorkerStateEvent_mt = Class(AIFieldWorkerStateEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function AIFieldWorkerStateEvent.emptyNew()
    local self = Event.new(AIFieldWorkerStateEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param boolean isActive is active
function AIFieldWorkerStateEvent.new(vehicle, isActive)
    local self = AIFieldWorkerStateEvent.emptyNew()

    self.vehicle = vehicle
    self.isActive = isActive

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIFieldWorkerStateEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.isActive = streamReadBool(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function AIFieldWorkerStateEvent:writeStream(streamId, connection)
    assert(not connection:getIsServer(), "AIFieldWorkerStateEvent is a server to client event only")
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.isActive)
end


---Run action on receiving side
-- @param integer connection connection
function AIFieldWorkerStateEvent:run(connection)
    if self.vehicle ~= nil then
        if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
            if self.isActive then
                self.vehicle:startFieldWorker()
            else
                self.vehicle:stopFieldWorker()
            end
        end
    end
end
