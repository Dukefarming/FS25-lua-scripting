









---
local RollercoasterPassengerEnterRequestEvent_mt = Class(RollercoasterPassengerEnterRequestEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function RollercoasterPassengerEnterRequestEvent.emptyNew()
    local self = Event.new(RollercoasterPassengerEnterRequestEvent_mt)
    return self
end


---Create new instance of event
-- @param table rollercoaster rollercoaster object
-- @param table player player making the enter request
-- @return table instance instance of event
function RollercoasterPassengerEnterRequestEvent.new(rollercoaster, player)
    local self = RollercoasterPassengerEnterRequestEvent.emptyNew()
    self.rollercoaster = rollercoaster
    self.player = player
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RollercoasterPassengerEnterRequestEvent:readStream(streamId, connection)
    self.rollercoaster = NetworkUtil.readNodeObject(streamId)
    self.player = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function RollercoasterPassengerEnterRequestEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.rollercoaster)
    NetworkUtil.writeNodeObject(streamId, self.player)
end


---Run action on receiving side
-- @param integer connection connection
function RollercoasterPassengerEnterRequestEvent:run(connection)
    if self.rollercoaster ~= nil and self.rollercoaster:getIsSynchronized() then
        self.rollercoaster:tryEnterRide(connection, self.player)
    end
end
