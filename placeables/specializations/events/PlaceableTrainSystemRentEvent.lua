




---Event for ai start
local PlaceableTrainSystemRentEvent_mt = Class(PlaceableTrainSystemRentEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableTrainSystemRentEvent.emptyNew()
    local self = Event.new(PlaceableTrainSystemRentEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
-- @param integer reason reason
-- @param boolean isStarted is started
-- @param integer helper helper id
function PlaceableTrainSystemRentEvent.new(object, isRented, farmId, splinePosition)
    local self = PlaceableTrainSystemRentEvent.emptyNew()
    self.object = object
    self.isRented = isRented
    self.farmId = farmId
    self.splinePosition = splinePosition
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableTrainSystemRentEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    self.isRented = streamReadBool(streamId)

    if self.isRented then
        self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
        self.splinePosition = streamReadFloat32(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableTrainSystemRentEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    if streamWriteBool(streamId, self.isRented) then
        streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
        streamWriteFloat32(streamId, self.splinePosition)
    end
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableTrainSystemRentEvent:run(connection)
    local farmId, splinePosition
    if self.isRented then
        farmId = self.farmId
        splinePosition = self.splinePosition
    end

    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.isRented then
            self.object:rentRailroad(farmId, splinePosition, true)
        else
            self.object:returnRailroad(true)
        end
    end

    if not connection:getIsServer() then
        g_server:broadcastEvent(PlaceableTrainSystemRentEvent.new(self.object, self.isRented, self.farmId, self.splinePosition), nil, connection, self.object)
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table vehicle vehicle
-- @param boolean isSwathActive is straw enabled
-- @param boolean noEventSend no event send
function PlaceableTrainSystemRentEvent.sendEvent(object, isRented, farmId, splinePosition, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlaceableTrainSystemRentEvent.new(object, isRented, farmId, splinePosition), nil, nil, object)
        else
            g_client:getServerConnection():sendEvent(PlaceableTrainSystemRentEvent.new(object, isRented, farmId, splinePosition))
        end
    end
end
