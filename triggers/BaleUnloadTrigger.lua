











---
local BaleUnloadTrigger_mt = Class(BaleUnloadTrigger, UnloadTrigger)






---
function BaleUnloadTrigger.registerXMLPaths(schema, basePath)
    UnloadTrigger.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. "#triggerNode", "Trigger node")
    schema:register(XMLValueType.FLOAT, basePath .. "#deleteLitersPerSecond", "Delete liters per second", 4000)
    FillTypeManager.registerConfigXMLFilltypes(schema, basePath)
end


---Creates a new instance of the class
-- @param boolean isServer true if we are server
-- @param boolean isClient true if we are client
-- @param table? customMt meta table
-- @return table self returns the instance
function BaleUnloadTrigger.new(isServer, isClient, customMt)
    local self = UnloadTrigger.new(isServer, isClient, customMt or BaleUnloadTrigger_mt)

    self.triggerNode = nil
    self.balesInTrigger = {}

    return self
end


---Loads elements of the class
-- @param table components components
-- @param table xmlFile xml file object
-- @param string xmlNode xml key
-- @param table target target object
-- @param table i3dMappings i3dMappings
-- @return boolean success success
function BaleUnloadTrigger:load(components, xmlFile, xmlNode, target, extraAttributes, i3dMappings)
    if not BaleUnloadTrigger:superClass().load(self, components, xmlFile, xmlNode, target, extraAttributes, i3dMappings) then
        return false
    end

    self.triggerNode = xmlFile:getValue(xmlNode .. "#triggerNode", nil, components, i3dMappings)
    if self.triggerNode == nil then
        Logging.xmlError(xmlFile, "Bale trigger '%s' not specified", xmlNode .. "#triggerNode")
        return false
    end

    if not CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.DYNAMIC_OBJECT) then
        Logging.xmlError(xmlFile, "Bale trigger '%s' does not have Bit '%d' (%s) set", xmlNode .. "#triggerNode", CollisionFlag.getBit(CollisionFlag.DYNAMIC_OBJECT), "TRIGGER_DYNAMIC_OBJECT")
        return false
    end

    if Platform.gameplay.automaticBaleDrop then
        if not CollisionFlag.getHasMaskFlagSet(self.triggerNode, CollisionFlag.VEHICLE) then
            Logging.xmlError(xmlFile, "Bale trigger '%s' does not have Bit '%d' (%s) set, which is required for automatic bale loader unloading", xmlNode .. "#triggerNode", CollisionFlag.getBit(CollisionFlag.VEHICLE), "TRIGGER_VEHICLE")
            return false
        end
    end

    addTrigger(self.triggerNode, "baleTriggerCallback", self)

    self.deleteLitersPerMS = xmlFile:getValue(xmlNode .. "#deleteLitersPerSecond", 4000) / 1000

    return true
end


---Delete instance
function BaleUnloadTrigger:delete()
    if self.triggerNode ~= nil and self.triggerNode ~= 0 then
        removeTrigger(self.triggerNode)
        self.triggerNode = 0
    end
    self.balesInTrigger = nil

    BaleUnloadTrigger:superClass().delete(self)
end


















---Update method
-- @param float dt delta time
function BaleUnloadTrigger:update(dt)
    BaleUnloadTrigger:superClass().update(self, dt)
    if self.isServer then
        for index, bale in ipairs(self.balesInTrigger) do
            if bale ~= nil and bale.nodeId ~= 0 then
                if bale:getCanBeSold() then  -- keep currently mounted bales in list, so they are handled once free
                    if bale.dynamicMountType == MountableObject.MOUNT_TYPE_NONE then
                        local fillType = bale:getFillType()
                        local fillLevel = bale:getFillLevel()
                        local fillInfo = nil

                        local delta = bale:getFillLevel()
                        if self.deleteLitersPerMS ~= nil then
                            delta = self.deleteLitersPerMS * dt
                        end

                        if delta > 0 then
                            local baleOwnerFarmId = bale:getOwnerFarmId()
                            delta = self:addFillUnitFillLevel(baleOwnerFarmId, 1, delta, fillType, ToolType.BALE, fillInfo)
                            bale:setFillLevel(fillLevel - delta)
                            local newFillLevel = bale:getFillLevel()
                            if newFillLevel < 0.01 then
                                if fillType == FillType.COTTON then
                                    local total, _ = g_farmManager:updateFarmStats(baleOwnerFarmId, "soldCottonBales", 1)
                                    if total ~= nil then
                                        g_achievementManager:tryUnlock("CottonBales", total)
                                    end
                                end

                                bale:delete()
                                table.remove(self.balesInTrigger, index)
                                break
                            end
                        end
                    end
                end
            else
                table.remove(self.balesInTrigger, index)
            end
        end

        if #self.balesInTrigger > 0 then
            self:raiseActive()
        end
    end
end


---Callback method for the bale trigger
-- @param integer triggerId
-- @param integer otherId
-- @param boolean onEnter
-- @param boolean onLeave
-- @param boolean onStay
-- @param integer otherShapeId
function BaleUnloadTrigger:baleTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    if self.isEnabled then
        local mission = g_currentMission
        local object = mission:getNodeObject(otherId)
        if object ~= nil then
            if object:isa(Bale) then
                if onEnter then
                    if self:getIsBaleSupportedByUnloadTrigger(object) then
                        self:raiseActive()
                        table.addElement(self.balesInTrigger, object)
                    end
                elseif onLeave then
                    for index, bale in ipairs(self.balesInTrigger) do
                        if bale == object then
                            table.remove(self.balesInTrigger, index)
                            break
                        end
                    end
                end
            else
                if object:isa(Vehicle) and SpecializationUtil.hasSpecialization(BaleLoader, object.specializations) then
                    if onEnter then
                        object:addBaleUnloadTrigger(self)
                    elseif onLeave then
                        object:removeBaleUnloadTrigger(self)
                    end
                end
            end
        end
    end
end
