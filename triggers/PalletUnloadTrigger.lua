












---
local PalletUnloadTrigger_mt = Class(PalletUnloadTrigger, UnloadTrigger)






---
function PalletUnloadTrigger.registerXMLPaths(schema, basePath)
    UnloadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.BOOL, basePath .. "#autoUnload", "Auto unload pallets", true)
    schema:register(XMLValueType.BOOL, basePath .. "#autoUnloadStrapped", "Auto unload pallets that are fasten with tension belts", false)
end


---Creates a new instance of the class
-- @param boolean isServer true if we are server
-- @param boolean isClient true if we are client
-- @param table? customMt meta table
-- @return table self returns the instance
function PalletUnloadTrigger.new(isServer, isClient, customMt)
    local self = UnloadTrigger.new(isServer, isClient, customMt or PalletUnloadTrigger_mt)

    self.triggerNode = nil

    self.activatable = PalletUnloadTriggerActivatable.new(self)
    self.isPlayerInRange = false
    self.isEnabled = true

    self.palletsInRange = {}
    self.vehiclesInRange = {}
    self.autoUnload = true
    self.autoUnloadStrapped = false

    return self
end


---Loads elements of the class
-- @param table components components
-- @param table xmlFile xml file object
-- @param string xmlNode xml key
-- @param table target target object
-- @param table i3dMappings i3dMappings
-- @return boolean success success
function PalletUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
    if not PalletUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
        return false
    end

    local triggerNodeKey = xmlNode .. "#triggerNode"
    self.triggerNode = xmlFile:getValue(triggerNodeKey, nil, components, i3dMappings)
    if self.triggerNode == nil then
        Logging.xmlError(xmlFile, "Pallet trigger %q not specified!", triggerNodeKey)
        return false
    end

    local colMask = getCollisionFilterMask(self.triggerNode)
    if bitAND(CollisionFlag.VEHICLE, colMask) == 0 then
        Logging.xmlError(xmlFile, "Invalid collision mask for pallet trigger '%s'. %s needs to be set!", triggerNodeKey, CollisionFlag.getBitAndName(CollisionFlag.VEHICLE))
        return false
    end

    addTrigger(self.triggerNode, "palletTriggerCallback", self)


    self.autoUnload = xmlFile:getValue(xmlNode .. "#autoUnload", self.autoUnload)
    self.autoUnloadStrapped = xmlFile:getValue(xmlNode .. "#autoUnloadStrapped", self.autoUnloadStrapped)

    return true
end


---Delete instance
function PalletUnloadTrigger:delete()
    if self.triggerNode ~= nil and self.triggerNode ~= 0 then
        removeTrigger(self.triggerNode)
        self.triggerNode = 0
    end

    self.palletsInRange = {}
    self.vehiclesInRange = {}

    PalletUnloadTrigger:superClass().delete(self)
end























































































---Callback method for the wood trigger
-- @param integer triggerId
-- @param integer otherId
-- @param boolean onEnter
-- @param boolean onLeave
-- @param boolean onStay
-- @param integer otherShapeId
function PalletUnloadTrigger:palletTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    if otherId ~= 0 then
        local mission = g_currentMission
        local object = mission:getNodeObject(otherId)
        if object ~= nil then
            if object.isPallet and object.getFillUnits ~= nil then
                if onEnter then
                    local fillUnits = object:getFillUnits()
                    for fillUnitIndex, _ in pairs(fillUnits) do
                        local fillTypeIndex = object:getFillUnitFillType(fillUnitIndex)
                        if fillTypeIndex ~= FillType.UNKNOWN and self:getIsFillTypeSupported(fillTypeIndex) then
                            if object:getFillUnitFillLevel(fillUnitIndex) > 0 then
                                table.addElement(self.palletsInRange, object)
                                object:addDeleteListener(self, "onObjectDeleted")
                            end
                        end
                    end

                    if self.autoUnload then
                        if self.isServer then
                            self:unloadPallets()
                        end
                    end
                else
                    table.removeElement(self.palletsInRange, object)
                    object:removeDeleteListener(self, "onObjectDeleted")
                end
            end
        end

        if not self.autoUnload then
            if object ~= nil then
                if object:isa(Vehicle) then
                    if onEnter then
                        if self.vehiclesInRange[object] == nil then
                            self.vehiclesInRange[object] = 0
                            object:addDeleteListener(self, "onObjectDeleted")
                        end
                        self.vehiclesInRange[object] = self.vehiclesInRange[object] + 1
                    else
                        if self.vehiclesInRange[object] ~= nil then
                            self.vehiclesInRange[object] = self.vehiclesInRange[object] - 1
                            if self.vehiclesInRange[object] == 0 then
                                self.vehiclesInRange[object] = nil
                                object:removeDeleteListener(self, "onObjectDeleted")
                            end
                        end
                    end
                end
            elseif g_localPlayer ~= nil and otherId == g_localPlayer.rootNode then
                if onEnter then
                    self.isPlayerInRange = true
                else
                    self.isPlayerInRange = false
                end
            end
        end

        self:updateActivatableObject()
    end
end
