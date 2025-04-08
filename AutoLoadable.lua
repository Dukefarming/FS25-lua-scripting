













---
function AutoLoadable.prerequisitesPresent(specializations)
    return true
end


---
function AutoLoadable.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadIsSupported", AutoLoadable.getAutoLoadIsSupported)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadIsAllowed", AutoLoadable.getAutoLoadIsAllowed)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadBoundingBox", AutoLoadable.getAutoLoadBoundingBox)
    SpecializationUtil.registerFunction(vehicleType, "getAutoLoadSize", AutoLoadable.getAutoLoadSize)
    SpecializationUtil.registerFunction(vehicleType, "autoLoad", AutoLoadable.autoLoad)
end


---
function AutoLoadable.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", AutoLoadable)
end


---
function AutoLoadable:onLoad(savegame)
    if self.isServer then
        local spec = self.spec_autoLoadable

        spec.isSupported = true
    end
end


---
function AutoLoadable:getAutoLoadIsSupported()
    local spec = self.spec_autoLoadable
    return spec.isSupported
end


---
function AutoLoadable:getAutoLoadIsAllowed()
    return true
end


---
function AutoLoadable:getAutoLoadSize()
    local size = self.size
    local sizeX = size.width
    local sizeY = size.height
    local sizeZ = size.length

    return sizeX, sizeY, sizeZ
end


---
function AutoLoadable:getAutoLoadBoundingBox()
    local size = self.size
    local x, y, z = localToWorld(self.rootNode, size.widthOffset, size.heightOffset, size.lengthOffset)
    local dirX, dirY, dirZ = localDirectionToWorld(self.rootNode, 0, 0, 1)
    local upX, upY, upZ = localDirectionToWorld(self.rootNode, 0, 1, 0)
    local extendX = size.width * 0.5
    local extendY = size.height * 0.5
    local extendZ = size.length * 0.5

    return x, y, z, dirX, dirY, dirZ, upX, upY, upZ, extendX, extendY, extendZ
end


---
function AutoLoadable:autoLoad(autoLoader, node, posX, posZ, sizeX, sizeZ)
    local size = self.size
    local mountPosX = posX + size.widthOffset + size.width*0.5
    local mountPosY = size.heightOffset
    local mountPosZ = posZ + size.lengthOffset + size.height*0.5
    local mountRotX = 0
    local mountRotY = 0
    local mountRotZ = 0

    self:mountKinematic(autoLoader, node, mountPosX, mountPosY, mountPosZ, mountRotX, mountRotY, mountRotZ)

    return true
end
