
















---
local ConsumableActivatable_mt = Class(ConsumableActivatable)


---
function ConsumableActivatable.new(vehicle)
    local self = setmetatable({}, ConsumableActivatable_mt)

    self.vehicle = vehicle

    self.activateText = ""

    return self
end


---
function ConsumableActivatable:getIsActivatable()
    if self.vehicle:getIsActiveForInput(true) then
        local spec = self.vehicle.spec_consumable
        for i, type in ipairs(spec.types) do
            if type.consumingFillLevel == 0 then
                return true
            end
        end
    end

    return false
end


---
function ConsumableActivatable:run()
    local spec = self.vehicle.spec_consumable
    for typeIndex, type in ipairs(spec.types) do
        if type.consumingFillLevel == 0 then
            self.optionsTypeName = type.typeName
            self.options, self.optionToVariationIndex = g_consumableManager:getConsumableVariationsByType(type.typeName)

            local function callback(index)
                if index ~= nil then
                    local variationIndex = self.optionToVariationIndex[index]
                    if variationIndex ~= nil then
                        ConsumableRefillEvent.sendEvent(self.vehicle, typeIndex, variationIndex)
                    end
                end
            end

            OptionDialog.show(callback, g_i18n:getText("ui_consumableSelectType"), g_i18n:getText(ConsumableActivatable.TYPE_TEXTS[type.typeName]), self.options)
        end
    end
end


---
function ConsumableActivatable:updateActivateText()
    local spec = self.vehicle.spec_consumable
    for i, type in ipairs(spec.types) do
        if type.consumingFillLevel == 0 then
            self.activateText = g_i18n:getText(ConsumableActivatable.TYPE_TEXTS[type.typeName])
        end
    end
end
