



---Event for bunker silo close
local BunkerSiloCloseEvent_mt = Class(BunkerSiloCloseEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function BunkerSiloCloseEvent.emptyNew()
    local self = Event.new(BunkerSiloCloseEvent_mt)
    return self
end


---Create new instance of event
-- @param table bunkerSilo bunkerSilo
-- @return table instance instance of event
function BunkerSiloCloseEvent.new(bunkerSilo)
    local self = BunkerSiloCloseEvent.emptyNew()
    self.bunkerSilo = bunkerSilo
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BunkerSiloCloseEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        self.bunkerSilo = NetworkUtil.readNodeObject(streamId)
    end
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function BunkerSiloCloseEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObject(streamId, self.bunkerSilo)
    end
end


---Run action on receiving side
-- @param integer connection connection
function BunkerSiloCloseEvent:run(connection)
    if not connection:getIsServer() then
        self.bunkerSilo:setState(BunkerSilo.STATE_CLOSED)
    end
end
