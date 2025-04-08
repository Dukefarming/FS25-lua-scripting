




---Event for selling train goods
local PlaceableTrainSystemSellEvent_mt = Class(PlaceableTrainSystemSellEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableTrainSystemSellEvent.emptyNew()
    return Event.new(PlaceableTrainSystemSellEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @return PlaceableTrainSystemSellEvent instance
function PlaceableTrainSystemSellEvent.new(object)
    local self = PlaceableTrainSystemSellEvent.emptyNew()
    self.object = object
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableTrainSystemSellEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableTrainSystemSellEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableTrainSystemSellEvent:run(connection)
    if not connection:getIsServer() then
        if self.object ~= nil and self.object:getIsSynchronized() then
            self.object:sellGoods()
        end
    end
end
