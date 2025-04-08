



---
local PlaceablePreplacedInfoEvent_mt = Class(PlaceablePreplacedInfoEvent, Event)




---
function PlaceablePreplacedInfoEvent.emptyNew()
    local self = Event.new(PlaceablePreplacedInfoEvent_mt)
    return self
end


---
function PlaceablePreplacedInfoEvent.new()
    local self = PlaceablePreplacedInfoEvent.emptyNew()

    return self
end


---
function PlaceablePreplacedInfoEvent:readStream(streamId, connection)
    g_currentMission.placeableSystem:readStreamPreplacedInfo(streamId, connection)
end


---
function PlaceablePreplacedInfoEvent:writeStream(streamId, connection)
    g_currentMission.placeableSystem:writeStreamPreplacedInfo(streamId, connection)
end
