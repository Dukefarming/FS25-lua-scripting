













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function AIVehicleObstacle.prerequisitesPresent(specializations)
    return true
end





















---
function AIVehicleObstacle.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIVehicleObstacle)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIVehicleObstacle)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIVehicleObstacle)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AIVehicleObstacle)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIVehicleObstacle)
end
