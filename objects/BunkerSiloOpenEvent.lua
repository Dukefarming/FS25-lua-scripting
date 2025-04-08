



---Event for bunker silo open
local BunkerSiloOpenEvent_mt = Class(BunkerSiloOpenEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BunkerSiloOpenEvent.emptyNew()
    local self = Event.new(BunkerSiloOpenEvent_mt)
    return self
end


---Create new instance of event
-- @param table bunkerSilo bunkerSilo
-- @param float x x opening position
-- @param float y y opening position
-- @param float z z opening position
-- @return table instance instance of event
function BunkerSiloOpenEvent.new(bunkerSilo, x,y,z)
    local self = BunkerSiloOpenEvent.emptyNew()
    self.bunkerSilo = bunkerSilo
    self.x = x
    self.y = y
    self.z = z
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BunkerSiloOpenEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.bunkerSilo = NetworkUtil.readNodeObject(streamId)
        self.x = streamReadFloat32(streamId)
        self.y = streamReadFloat32(streamId)
        self.z = streamReadFloat32(streamId)
    end
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BunkerSiloOpenEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.bunkerSilo)
        streamWriteFloat32(streamId, self.x)
        streamWriteFloat32(streamId, self.y)
        streamWriteFloat32(streamId, self.z)
    end
end


---Run action on receiving side
-- @param integer connection connection
function BunkerSiloOpenEvent:run(connection)
    if not connection:getIsServer() then
        self.bunkerSilo:openSilo(self.x, self.y, self.z)
    end
end
