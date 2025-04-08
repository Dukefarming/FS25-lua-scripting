

---
local FlashlightToggleLightEvent_mt = Class(FlashlightToggleLightEvent, Event)




---Create an empty instance
-- @return table instance Instance of object
function FlashlightToggleLightEvent.emptyNew()
    local self = Event.new(FlashlightToggleLightEvent_mt)
    return self
end


---Create an instance
-- @param HandTool flashlight Flashlight hand tool instance.
-- @param boolean isActive True if flashlight is on; otherwise false.
-- @return table instance Instance of object
function FlashlightToggleLightEvent.new(flashlight, isActive)
    local self = FlashlightToggleLightEvent.emptyNew()

    self.flashlight = flashlight
    self.isActive = isActive

    return self
end


---Reads network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function FlashlightToggleLightEvent:readStream(streamId, connection)
    self.flashlight = NetworkUtil.readNodeObject(streamId)
    self.isActive = streamReadBool(streamId)
    self:run(connection)
end


---Writes network stream
-- @param integer streamId network stream identification
-- @param table connection connection information
function FlashlightToggleLightEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.flashlight)
    streamWriteBool(streamId, self.isActive)
end


---Run event
-- @param table connection connection information
function FlashlightToggleLightEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection)
    end

    if self.flashlight ~= nil and self.flashlight:getIsSynchronized() then
        self.flashlight:setFlashlightIsActive(self.isActive, true)
    end
end


---
function FlashlightToggleLightEvent.sendEvent(flashlight, isActive, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(FlashlightToggleLightEvent.new(flashlight, isActive))
        else
            g_client:getServerConnection():sendEvent(FlashlightToggleLightEvent.new(flashlight, isActive))
        end
    end
end
