








---
local HandsPickUpFailedEvent_mt = Class(HandsPickUpFailedEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function HandsPickUpFailedEvent.emptyNew()
    local self = Event.new(HandsPickUpFailedEvent_mt)

    return self
end


---
function HandsPickUpFailedEvent.new(hands)
    local self = HandsPickUpFailedEvent.emptyNew()

    self.hands = hands

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function HandsPickUpFailedEvent:readStream(streamId, connection)

    self.hands = NetworkUtil.readNodeObject(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function HandsPickUpFailedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.hands)
end


---Run action on receiving side
-- @param integer connection connection
function HandsPickUpFailedEvent:run(connection)
    assert(connection:getIsServer(), "HandsPickUpFailedEvent is a server to client only event")

    if self.hands ~= nil and self.hands:getIsSynchronized() then
        self.hands:pickupFailed()
    end
end
