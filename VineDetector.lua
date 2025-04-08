












---
function VineDetector.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("VineDetector")
    schema:register(XMLValueType.NODE_INDEX, "vehicle.vineDetector.raycast#node", "Raycast node")
    schema:register(XMLValueType.FLOAT, "vehicle.vineDetector.raycast#maxDistance", "Max raycast distance", 1)
    schema:setXMLSpecializationType()
end


---
function VineDetector.prerequisitesPresent(specializations)
    return true
end


---
function VineDetector.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "raycastCallbackVineDetection", VineDetector.raycastCallbackVineDetection)
    SpecializationUtil.registerFunction(vehicleType, "finishedVineDetection", VineDetector.finishedVineDetection)
    SpecializationUtil.registerFunction(vehicleType, "clearCurrentVinePlaceable", VineDetector.clearCurrentVinePlaceable)
    SpecializationUtil.registerFunction(vehicleType, "cancelVineDetection", VineDetector.cancelVineDetection)
    SpecializationUtil.registerFunction(vehicleType, "getIsValidVinePlaceable", VineDetector.getIsValidVinePlaceable)
    SpecializationUtil.registerFunction(vehicleType, "handleVinePlaceable", VineDetector.handleVinePlaceable)
    SpecializationUtil.registerFunction(vehicleType, "getCanStartVineDetection", VineDetector.getCanStartVineDetection)
    SpecializationUtil.registerFunction(vehicleType, "getFirstVineHitPosition", VineDetector.getFirstVineHitPosition)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentVineHitPosition", VineDetector.getCurrentVineHitPosition)
    SpecializationUtil.registerFunction(vehicleType, "getCurrentVineHitDistance", VineDetector.getCurrentVineHitDistance)
end


---
function VineDetector.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", VineDetector)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", VineDetector)

end


---
function VineDetector:onLoad(savegame)
    local spec = self.spec_vineDetector

    spec.raycast = {}
    spec.raycast.node = self.xmlFile:getValue("vehicle.vineDetector.raycast#node", nil, self.components, self.i3dMappings)
    if spec.raycast.node == nil then
        Logging.xmlWarning(self.xmlFile, "Missing vine detector raycast node")
    end
    spec.raycast.maxDistance = self.xmlFile:getValue("vehicle.vineDetector.raycast#maxDistance", 1)
    spec.raycast.vineNode = nil
    spec.raycast.isRaycasting = false
    spec.raycast.firstHitPosition = {0, 0, 0}
    spec.raycast.currentHitPosition = {0, 0, 0}
    spec.raycast.currentHitDistance = 0
    spec.raycast.currentNode = nil
    spec.isVineDetectionActive = false
end


---Called on update
-- @param float dt time since last call in ms
-- @param boolean isActiveForInput true if vehicle is active for input
-- @param boolean isSelected true if vehicle is selected
function VineDetector:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    local spec = self.spec_vineDetector
    if self.isServer and spec.raycast.node ~= nil then
        if self:getCanStartVineDetection() then
            spec.isVineDetectionActive = true
            if not spec.raycast.isRaycasting then
                spec.raycast.isRaycasting = true

                local x, y, z = getWorldTranslation(spec.raycast.node)
                local dx, dy, dz = localDirectionToWorld(spec.raycast.node, 0, -1, 0)
                raycastAllAsync(x,y,z, dx,dy,dz, spec.raycast.maxDistance, "raycastCallbackVineDetection", self, CollisionFlag.STATIC_OBJECT)  -- TODO: verify if this mask is sufficient
            end
        else
            if spec.isVineDetectionActive then
                self:clearCurrentVinePlaceable()
                self:finishedVineDetection()
                spec.isVineDetectionActive = false
            end
        end
    end
end
