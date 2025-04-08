















---Event server to all clients reporting a error from the object storage (only shown for players in range of placeable)
local PlaceableObjectStorageErrorEvent_mt = Class(PlaceableObjectStorageErrorEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function PlaceableObjectStorageErrorEvent.emptyNew()
    return Event.new(PlaceableObjectStorageErrorEvent_mt)
end


---Create new instance of event
-- @param table object object
-- @param integer errorId index of error message
function PlaceableObjectStorageErrorEvent.new(placeable, errorId)
    local self = PlaceableObjectStorageErrorEvent.emptyNew()
    self.placeable = placeable
    self.errorId = errorId
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableObjectStorageErrorEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.errorId = streamReadUIntN(streamId, PlaceableObjectStorageErrorEvent.SEND_NUM_BITS)
    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function PlaceableObjectStorageErrorEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteUIntN(streamId, self.errorId, PlaceableObjectStorageErrorEvent.SEND_NUM_BITS)
end


---Run action on receiving side
-- @param integer connection connection
function PlaceableObjectStorageErrorEvent:run(connection)
    if self.placeable ~= nil and self.placeable:getIsSynchronized() then
        if g_currentMission:getFarmId() == self.placeable:getOwnerFarmId() then
            local x1, _, z1 = g_currentMission:getClientPosition()
            local x2, _, z2 = getWorldTranslation(self.placeable.rootNode)
            local distance = MathUtil.vector2Length(x1 - x2, z1 - z2)
            if distance < PlaceableObjectStorageErrorEvent.SHOW_WARNING_DISTANCE then
                if self.errorId == PlaceableObjectStorageErrorEvent.ERROR_NOT_ENOUGH_SPACE then
                    g_currentMission:showBlinkingWarning(g_i18n:getText("warning_objectStorageNotEnoughSpace"), 2500)
                elseif self.errorId == PlaceableObjectStorageErrorEvent.ERROR_STORAGE_IS_FULL then
                    g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_objectStorageIsFull"), self.placeable:getName()), 2500)
                elseif self.errorId == PlaceableObjectStorageErrorEvent.ERROR_SLOT_LIMIT_REACHED_BALES then
                    g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyBales"), 2500)
                elseif self.errorId == PlaceableObjectStorageErrorEvent.ERROR_SLOT_LIMIT_REACHED_PALLETS then
                    g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyPallets"), 2500)
                elseif self.errorId == PlaceableObjectStorageErrorEvent.ERROR_OBJECT_NOT_SUPPORTED then
                    g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_objectStorageObjectNotSupported"), self.placeable:getName()), 3500)
                elseif self.errorId == PlaceableObjectStorageErrorEvent.ERROR_MAX_AMOUNT_FOR_OBJECT_REACHED then
                    g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_objectStorageMaxAmountForObjectReached"), self.placeable:getName()), 3500)
                end
            end
        end
    end
end
