















---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function BalerStationary.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Baler, specializations)
       and SpecializationUtil.hasSpecialization(BaleWrapper, specializations)
       and SpecializationUtil.hasSpecialization(FoldableSteps, specializations)
end


---Register all events that should be called for this specialization
-- @param table vehicleType vehicle type
function BalerStationary.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BalerStationary)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", BalerStationary)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", BalerStationary)
end
