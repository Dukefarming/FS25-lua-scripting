








---
local Timer_mt = Class(Timer)


---
function Timer.new(duration)
    local self = setmetatable({}, Timer_mt)

    self.duration = duration
    self.callback = nil
    self.isRunning = false
    self.timeLeft = duration

    return self
end


---
function Timer:delete()
    self:reset()
end


---
function Timer:reset()
    g_currentMission:removeUpdateable(self)
    self.isRunning = false
end


---Start the timer.
function Timer:start(noReset)
    if self.duration == nil then
        Logging.error("Timer duration not set")
        printCallstack()
        return
    end

    self.isRunning = true
    if noReset == nil or not noReset then
        self.timeLeft = self.duration
    end

    g_currentMission:addUpdateable(self)
end


---
function Timer:startIfNotRunning()
    if not self.isRunning then
        self:start()
    end
end


---Stop the timer
function Timer:stop()
    g_currentMission:removeUpdateable(self)
    self.isRunning = false
end


---
function Timer:finish()
    g_currentMission:removeUpdateable(self)
    self.timeLeft = 0
    self.isRunning = false
    if self.callback ~= nil then
        self.callback(self)
    end
end


---Get whether the timer is running
function Timer:getIsRunning()
    return self.isRunning
end


---Set the callback to be called when the timer finishes
function Timer:setFinishCallback(callback)
    self.callback = callback
    return self
end


---Get the time that has passed since the timer started, in milliseconds
function Timer:getTimePassed()
    return self.duration - self.timeLeft
end












---
function Timer:update(dt)
    if self.isRunning then
        local scale = 1
        if self.scaleFunc ~= nil then
            scale = self.scaleFunc()
        end
        self.timeLeft = self.timeLeft - dt*scale

        if self.timeLeft <= 0 then
            self:finish()
        end
    end
end






---Create a one-shot timer for duration. This effectively is an async operation calling the callback after givent timeout.
function Timer.createOneshot(duration, callback, scaleFunc)
    local timer = Timer.new(duration)
    timer:setFinishCallback(function()
        timer:delete()
        return callback()
    end)
    timer:setScaleFunction(scaleFunc)
    timer:start()

    return timer
end


---Get the duration of the timer
function Timer:getDuration()
    return self.duration
end


---Set the duration of the timer. Will take affect with the next start
function Timer:setDuration(duration)
    self.duration = duration
    return self
end


---
function Timer:writeUpdateStream(streamId)
    streamWriteInt32(streamId, self.timeLeft)
end


---
function Timer:readUpdateStream(streamId)
    self.timeLeft = streamReadInt32(streamId)
end
