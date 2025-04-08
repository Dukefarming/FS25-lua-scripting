



---Base class for a drive strategy
-- 
-- Copyright (C) GIANTS Software GmbH, Confidential, All Rights Reserved.
local AIDriveStrategy_mt = Class(AIDriveStrategy)


---
function AIDriveStrategy.new(reconstructionData, customMt)
    local self = setmetatable({}, customMt or AIDriveStrategy_mt)

    return self
end


---
function AIDriveStrategy:delete()
end


---
function AIDriveStrategy:setAIVehicle(vehicle)
    self.vehicle = vehicle
end


---
function AIDriveStrategy:update(dt)
end


---
function AIDriveStrategy:getDriveData(dt, vX,vY,vZ)
    return nil, nil, nil, nil, nil
end


---
function AIDriveStrategy:updateDriving(dt)
end


---
function AIDriveStrategy:debugPrint(text, ...)
    if VehicleDebug.state == VehicleDebug.DEBUG_AI then
        print(string.format("AI DEBUG: %s", string.format(text, ...)))
    end
end
