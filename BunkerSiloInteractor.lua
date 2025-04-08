













---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function BunkerSiloInteractor.prerequisitesPresent(specializations)
    return true
end


---
function BunkerSiloInteractor.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setBunkerSiloInteractorCallback", BunkerSiloInteractor.setBunkerSiloInteractorCallback)
    SpecializationUtil.registerFunction(vehicleType, "notifiyBunkerSilo",               BunkerSiloInteractor.notifiyBunkerSilo)
end


---
function BunkerSiloInteractor.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BunkerSiloInteractor)
end


---
function BunkerSiloInteractor:onLoad(savegame)
    local spec = self.spec_bunkerSiloInteractor

    spec.callback = nil
    spec.callbackTarget = nil
end


---Set fill level changed callback (e.g. by bunker silo)
-- @param function callback callback
-- @param table callbackTarget callback target
function BunkerSiloInteractor:setBunkerSiloInteractorCallback(callback, callbackTarget)
    local spec = self.spec_bunkerSiloInteractor
    spec.callback = callback
    spec.callbackTarget = callbackTarget
end


---
function BunkerSiloInteractor:notifiyBunkerSilo(changedFillLevel, fillType, x, y, z)
    local spec = self.spec_bunkerSiloInteractor
    if spec.callback ~= nil then
        spec.callback(spec.callbackTarget, self, changedFillLevel, fillType, x, y, z)
    end
end
