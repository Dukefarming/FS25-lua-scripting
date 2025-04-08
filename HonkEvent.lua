




---Event for honking
local HonkEvent_mt = Class(HonkEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function HonkEvent.emptyNew()
    local self = Event.new(HonkEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param boolean isPlaying honk is playing
function HonkEvent.new(object, isPlaying)
    local self = HonkEvent.emptyNew()
    self.object = object
    self.isPlaying = isPlaying
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function HonkEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isPlaying = streamReadBool(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function HonkEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    streamWriteBool(streamId, self.isPlaying)
end


---Run action on receiving side
-- @param integer connection connection
function HonkEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        self.object:playHonk(self.isPlaying, true)
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(HonkEvent.new(self.object, self.isPlaying), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isPlaying honk is playing
-- @param boolean noEventSend no event send
function HonkEvent.sendEvent(vehicle, isPlaying, noEventSend)
    if vehicle.spec_honk ~= nil and vehicle.spec_honk.isPlaying ~= isPlaying then
        if noEventSend == nil or noEventSend == false then
            if g_server ~= nil then
                g_server:broadcastEvent(HonkEvent.new(vehicle, isPlaying), nil, nil, vehicle)
            else
                g_client:getServerConnection():sendEvent(HonkEvent.new(vehicle, isPlaying))
            end
        end
    end
end
