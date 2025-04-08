








---Player farm setting answer event.
-- 
-- Triggered in response to PlayerSetFarmEvent.
local PlayerSetFarmAnswerEvent_mt = Class(PlayerSetFarmAnswerEvent, Event)












---Create an empty instance
-- @return table instance Instance of object
function PlayerSetFarmAnswerEvent.emptyNew()
    local self = Event.new(PlayerSetFarmAnswerEvent_mt)
    return self
end


---Create an instance of PlayerSetFarmAnswerEvent.
-- @param integer answerState
-- @param integer farmId Farm ID
-- @param string? password Password used for PlayerSetFarmEvent
-- @return table instance Instance of PlayerSetFarmAnswerEvent
function PlayerSetFarmAnswerEvent.new(answerState, farmId, password)
    local self = PlayerSetFarmAnswerEvent.emptyNew()

    self.answerState = answerState
    self.farmId = farmId
    self.password = password

    return self
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetFarmAnswerEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.answerState, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

    local passwordCorrect = self.answerState == PlayerSetFarmAnswerEvent.STATE.OK
    local passwordSet = self.password ~= nil
    if streamWriteBool(streamId, passwordCorrect and passwordSet) then
        streamWriteString(streamId, self.password)
    end
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function PlayerSetFarmAnswerEvent:readStream(streamId, connection)
    self.answerState = streamReadUIntN(streamId, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

    if streamReadBool(streamId) then
        self.password = streamReadString(streamId)
    end

    self:run(connection)
end


---Run event
-- @param table connection connection information
function PlayerSetFarmAnswerEvent:run(connection)
    if not connection:getIsServer() then -- server side, should not happen
        Logging.devWarning("PlayerSetFarmAnswerEvent is a server to client only event")
    else -- client side
        if self.answerState == PlayerSetFarmAnswerEvent.STATE.OK then
            g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId, self.password)
        elseif self.answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
            g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId)
        end
    end
end
