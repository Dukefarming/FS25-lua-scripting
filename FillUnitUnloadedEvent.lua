




---Event from server to client, telling which pallets have been unloaded
local FillUnitUnloadedEvent_mt = Class(FillUnitUnloadedEvent, Event)




---Create instance of Event class
-- @return table self instance of class event
function FillUnitUnloadedEvent.emptyNew()
    local self = Event.new(FillUnitUnloadedEvent_mt)
    return self
end


---Create new instance of event
-- @param table object object
function FillUnitUnloadedEvent.new(object, pallet, showWarning, result)
    local self = FillUnitUnloadedEvent.emptyNew()
    self.object = object
    self.pallet = pallet
    self.showWarning = showWarning
    self.result = result

    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FillUnitUnloadedEvent:readStream(streamId, connection)
    self.object = NetworkUtil.readNodeObject(streamId)
    if streamReadBool(streamId) then
        self.pallet = NetworkUtil.readNodeObject(streamId)

        local paramsXZ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
        local paramsY = g_currentMission.vehicleYPosHighPrecisionCompressionParams

        self.x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        self.y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
        self.z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
        local x_rot = NetworkUtil.readCompressedAngle(streamId)
        local y_rot = NetworkUtil.readCompressedAngle(streamId)
        local z_rot = NetworkUtil.readCompressedAngle(streamId)

        self.qx, self.qy, self.qz, self.qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)
    else
        self.showWarning = streamReadBool(streamId)

        local result = streamReadUIntN(streamId, 2)
        if result == 2 then
            self.result = true
        elseif result == 1 then
            self.result = false
        end
    end

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function FillUnitUnloadedEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.object)
    if streamWriteBool(streamId, self.pallet ~= nil) then
        NetworkUtil.writeNodeObject(streamId, self.pallet)

        local paramsXZ = g_currentMission.vehicleXZPosHighPrecisionCompressionParams
        local paramsY = g_currentMission.vehicleYPosHighPrecisionCompressionParams

        local component = self.pallet.components[1]
        local x,y,z = getWorldTranslation(component.node)
        local x_rot,y_rot,z_rot = getWorldRotation(component.node)
        NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
        NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
        NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
        NetworkUtil.writeCompressedAngle(streamId, x_rot)
        NetworkUtil.writeCompressedAngle(streamId, y_rot)
        NetworkUtil.writeCompressedAngle(streamId, z_rot)
    else
        streamWriteBool(streamId, self.showWarning == true)

        if self.result ~= nil then
            streamWriteUIntN(streamId, self.result == true and 2 or 1, 2)
        else
            streamWriteUIntN(streamId, 0, 2)
        end
    end
end


---Run action on receiving side
-- @param integer connection connection
function FillUnitUnloadedEvent:run(connection)
    if self.object ~= nil and self.object:getIsSynchronized() then
        if self.pallet ~= nil and self.pallet:getIsSynchronized() then
            if self.pallet.unmount ~= nil then
                self.pallet:unmount()
            end

            self.pallet:setWorldPositionQuaternion(self.x, self.y, self.z, self.qx, self.qy, self.qz, self.qw, 1, true)

            SpecializationUtil.raiseEvent(self.object, "onFillUnitUnloadPallet", self.pallet)
        else
            if self.showWarning then
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("fillUnit_unload_nospace"))
            end

            if self.result ~= nil then
                SpecializationUtil.raiseEvent(self.object, "onFillUnitUnloaded", self.result)
            end
        end
    end
end
