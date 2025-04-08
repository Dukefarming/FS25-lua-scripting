










---
local YarderTowerSetTargetEvent_mt = Class(YarderTowerSetTargetEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function YarderTowerSetTargetEvent.emptyNew()
    local self = Event.new(YarderTowerSetTargetEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param table playerStyle info
-- @return table instance instance of event
function YarderTowerSetTargetEvent.new(object, state, x, y, z)
    local self = YarderTowerSetTargetEvent.emptyNew()
    self.object = object
    self.state = state
    self.x = x
    self.y = y
    self.z = z

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function YarderTowerSetTargetEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.state = streamReadBool(streamId)
    if self.state then
        self.x = streamReadFloat32(streamId)
        self.y = streamReadFloat32(streamId)
        self.z = streamReadFloat32(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function YarderTowerSetTargetEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    if streamWriteBool(streamId, self.state) then
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
    end
end


---Run action on receiving side
-- @param integer connection connection
function YarderTowerSetTargetEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.object)
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        local spec = self.object.spec_yarderTower
        if self.x ~= nil then
            spec.mainRope.isValid = true
            spec.mainRope.target[1], spec.mainRope.target[2], spec.mainRope.target[3] = self.x, self.y, self.z
        end
        self.object:setYarderTargetActive(self.state, true)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean state state
-- @param boolean noEventSend no event send
function YarderTowerSetTargetEvent.sendEvent(vehicle, state, x, y, z, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(YarderTowerSetTargetEvent.new(vehicle, state, x, y, z), nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(YarderTowerSetTargetEvent.new(vehicle, state, x, y, z))
        end
    end
end
