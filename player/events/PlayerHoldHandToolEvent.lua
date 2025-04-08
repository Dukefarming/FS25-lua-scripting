








---
local PlayerHoldHandToolEvent_mt = Class(PlayerHoldHandToolEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlayerHoldHandToolEvent.emptyNew()
    local self = Event.new(PlayerHoldHandToolEvent_mt, NetworkNode.CHANNEL_MAIN)
    return self
end


---
function PlayerHoldHandToolEvent.new(player, handToolId, isHolding)
    local self = PlayerHoldHandToolEvent.emptyNew()

    self.player = player
    self.handToolId = handToolId

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlayerHoldHandToolEvent:readStream(streamId, connection)

    self.player = NetworkUtil.readNodeObject(streamId)
    if streamReadBool(streamId) then
        self.handToolId = NetworkUtil.readNodeObjectId(streamId)
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlayerHoldHandToolEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.player)
    if streamWriteBool(streamId, self.handToolId ~= nil) then
        NetworkUtil.writeNodeObjectId(streamId, self.handToolId)
    end
end


---Run action on receiving side
-- @param integer connection connection
function PlayerHoldHandToolEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end

    if self.player ~= nil then
        if self.handToolId ~= nil then
            local handTool = NetworkUtil.getObject(self.handToolId)
            if handTool ~= nil and handTool:getIsSynchronized() then
                self.player:setCurrentHandTool(handTool, true)
            end
        else
            self.player:setCurrentHandTool(nil, true)
        end
    end
end


---Broadcast event from server to all clients, if called on client call function on server and broadcast it to all clients
-- @param table player player
-- @param integer handToolId handTool object id
-- @param boolean noEventSend no event send
function PlayerHoldHandToolEvent.sendEvent(player, handToolId, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PlayerHoldHandToolEvent.new(player, handToolId))
        else
            g_client:getServerConnection():sendEvent(PlayerHoldHandToolEvent.new(player, handToolId))
        end
    end
end
