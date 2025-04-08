

---
local HandsPickUpObjectEvent_mt = Class(HandsPickUpObjectEvent, Event)




---Create an empty instance
-- @return table instance Instance of object
function HandsPickUpObjectEvent.emptyNew()
    local self = Event.new(HandsPickUpObjectEvent_mt)
    return self
end


---Create an instance
-- @param HandTool hands The hands instance.
-- @param table target
-- @return table instance Instance of object
function HandsPickUpObjectEvent.new(hands, target)
    local self = HandsPickUpObjectEvent.emptyNew()

    self.hands = hands
    self.target = target

    return self
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function HandsPickUpObjectEvent:readStream(streamId, connection)

    -- Read the hands.
    self.hands = NetworkUtil.readNodeObject(streamId)
    --#debug Player.debugLog(self.hands:getCarryingPlayer(), Player.DEBUG_DISPLAY_FLAG.NETWORK, "HandsPickUpObjectEvent:readStream")

    -- Read the target distance of the pick up.
    self.target = {}
    self.target.distance = NetworkUtil.readCompressedRange(streamId, 0, HandToolHands.PICKUP_DISTANCE, 10)

    -- Read if the item is a split shape or not.
    local isSplitShape = streamReadBool(streamId)

    if isSplitShape then
        self.target.node = readSplitShapeIdFromStream(streamId)
        if self.target.node == 0 then
            Logging.error("Picked up split shape is not synced!")
            self.target.node = nil
        end
    else

        local nodeObject = NetworkUtil.readNodeObject(streamId)
        if nodeObject ~= nil then
            self.target.node = nodeObject.rootNode or nodeObject.nodeId
        else
            Logging.error("Could not find picked up node object!")
        end
    end

    self:run(connection)
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function HandsPickUpObjectEvent:writeStream(streamId, connection)
    --#debug Player.debugLog(self.hands:getCarryingPlayer(), Player.DEBUG_DISPLAY_FLAG.NETWORK, "HandsPickUpObjectEvent:writeStream")

    -- Only the server can create the joint. The client can only tell the server that they want to pick up an item, then the server's response triggers the actual state change in Hands.
    -- The joint is synched automatically, and only needs to be dealt with on the server.

    -- Write the hands.
    NetworkUtil.writeNodeObject(streamId, self.hands)

    -- Write the distance of the pick up.
    NetworkUtil.writeCompressedRange(streamId, self.target.distance, 0, HandToolHands.PICKUP_DISTANCE, 10)

    -- Write if the held item is a split shape or not.
    local isSplitShape = self.target.node ~= nil and self.target.node ~= 0 and getHasClassId(self.target.node, ClassIds.MESH_SPLIT_SHAPE)
    streamWriteBool(streamId, isSplitShape)

    local nodeObject = g_currentMission:getNodeObject(self.target.node)
    if isSplitShape then
        writeSplitShapeIdToStream(streamId, self.target.node)
    elseif nodeObject ~= nil then
        NetworkUtil.writeNodeObject(streamId, nodeObject)
    else
        Logging.error("Invalid picked up object! Is not a split shape or object! id: %s", tostring(self.target.node))
    end
end


---Run event
-- @param table connection connection information
function HandsPickUpObjectEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.hands)
    end

    if self.hands ~= nil and self.hands:getIsSynchronized() then
        if not self.hands:pickUpTarget(self.target, true) then
            if not connection:getIsServer() then
                connection:sendEvent(HandsPickUpFailedEvent.new(self.hands))
            end
        end
    end
end


---
-- @param HandTool hands The hands instance.
-- @param table target
-- @param boolean? noEventSend
function HandsPickUpObjectEvent.sendEvent(hands, target, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(HandsPickUpObjectEvent.new(hands, target), nil, nil, hands)
        else
            g_client:getServerConnection():sendEvent(HandsPickUpObjectEvent.new(hands, target))
        end
    end
end
