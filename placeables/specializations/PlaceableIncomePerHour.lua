














---Checks if all prerequisite specializations are loaded
-- @param table specializations specializations
-- @return boolean hasPrerequisite true if all prerequisite specializations are loaded
function PlaceableIncomePerHour.prerequisitesPresent(specializations)
    return true
end


---
function PlaceableIncomePerHour.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "getIncomePerHour", PlaceableIncomePerHour.getIncomePerHour)
end


---
function PlaceableIncomePerHour.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableIncomePerHour.getNeedHourChanged)
end


---
function PlaceableIncomePerHour.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableIncomePerHour)
    SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableIncomePerHour)
end


---
function PlaceableIncomePerHour.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("IncomePerHour")

    schema:register(XMLValueType.FLOAT, basePath .. ".incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(?)#incomePerHour", "Income per hour")
    schema:register(XMLValueType.FLOAT, basePath .. ".incomePerHour", "Income per hour")
    schema:setXMLSpecializationType()
end


---
function PlaceableIncomePerHour.initSpecialization()
    g_storeManager:addSpecType("incomePerHour", "shopListAttributeIconIncomePerHour", PlaceableIncomePerHour.loadSpecValueIncomePerHour, PlaceableIncomePerHour.getSpecValueIncomePerHour, StoreSpecies.PLACEABLE)
    g_placeableConfigurationManager:addConfigurationType("incomePerHour", g_i18n:getText("configuration_incomePerHour"), "incomePerHour", PlaceableConfigurationItem)
end


---Called on loading
-- @param table savegame savegame
function PlaceableIncomePerHour:onLoad(savegame)
    local spec = self.spec_incomePerHour
    local xmlFile = self.xmlFile

    local configurationId = self.configurations["incomePerHour"] or 1
    local configKey = string.format("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(%d)#incomePerHour", configurationId - 1)

    spec.incomePerHour = xmlFile:getValue(configKey) or xmlFile:getValue("placeable.incomePerHour", 0)
    spec.incomePerHourFactor = 1
end


---
function PlaceableIncomePerHour:getNeedHourChanged(superFunc)
    return true
end


---Called if hour changed
function PlaceableIncomePerHour:onHourChanged()
    if self.isServer then
        local ownerFarmId = self:getOwnerFarmId()
        if ownerFarmId ~= FarmlandManager.NO_OWNER_FARM_ID then
            local environment = g_currentMission.environment
            local incomePerHour = self:getIncomePerHour() * environment.timeAdjustment

            if incomePerHour ~= 0 then
                g_currentMission:addMoney(incomePerHour, ownerFarmId, MoneyType.PROPERTY_INCOME, true)
            end
        end
    end
end


---
function PlaceableIncomePerHour:getIncomePerHour()
    local spec = self.spec_incomePerHour
    return spec.incomePerHour
end


---Loads capacity spec value
-- @param integer xmlFile id of xml object
-- @param string customEnvironment custom environment
-- @return table capacityAndUnit capacity and unit
function PlaceableIncomePerHour.loadSpecValueIncomePerHour(xmlFile, customEnvironment, baseDir)
    local incomePerHour = xmlFile:getValue("placeable.incomePerHour.incomePerHourConfigurations.incomePerHourConfiguration(0)#incomePerHour", xmlFile:getValue("placeable.incomePerHour", 0))

    local windTurbineIncomePerHour = xmlFile:getValue("placeable.windTurbine#incomePerHour", 0)

    local solarPanelsDefaultConfigIncomePerHour = xmlFile:getValue("placeable.solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(0)#incomePerHour", 0)

    if incomePerHour == 0 and windTurbineIncomePerHour == 0 and solarPanelsDefaultConfigIncomePerHour == 0 then
        return nil
    end

    return {incomePerHour, windTurbineIncomePerHour + solarPanelsDefaultConfigIncomePerHour}  -- store fixed and variable incomes separately
end


---Returns value of income per hour
-- @param table storeItem store item
-- @param table realItem real item
-- @return integer incomePerHour income per hour
function PlaceableIncomePerHour.getSpecValueIncomePerHour(storeItem, realItem)
    if storeItem.specs.incomePerHour == nil then
        return nil
    end

    local fixedIncome, variableIncome = unpack(storeItem.specs.incomePerHour)

    fixedIncome = fixedIncome * 24 -- 24 hours in an un-adjusted month

    if variableIncome ~= 0 then
        variableIncome = variableIncome * 24
        local maxTotalIncome = fixedIncome + variableIncome

        -- display income range
        return string.format("%s - %s / %s", g_i18n:formatMoney(fixedIncome, nil, false), g_i18n:formatMoney(maxTotalIncome), g_i18n:getText("ui_month"))
    end

    -- display just fixed income
    return string.format("%s / %s", g_i18n:formatMoney(fixedIncome), g_i18n:getText("ui_month"))
end
