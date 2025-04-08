











---Stores the data for motor configurations
local VehicleConfigurationItemMotor_mt = Class(VehicleConfigurationItemMotor, VehicleConfigurationItem)


---
function VehicleConfigurationItemMotor.new(configName, customMt)
    local self = VehicleConfigurationItemMotor:superClass().new(configName, VehicleConfigurationItemMotor_mt)

    return self
end


---
function VehicleConfigurationItemMotor:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
    if not VehicleConfigurationItemMotor:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
        return false
    end

    self.power = xmlFile:getValue(configKey .. "#hp")
    self.maxSpeed = xmlFile:getValue(configKey .. "#maxSpeed")
    self.consumerConfigurationIndex = xmlFile:getValue(configKey .. "#consumerConfigurationIndex")

    return true
end


---
function VehicleConfigurationItemMotor.registerXMLPaths(schema, rootPath, configPath)
    VehicleConfigurationItemMotor:superClass().registerXMLPaths(schema, rootPath, configPath)

    schema:register(XMLValueType.FLOAT, configPath .. "#hp", "Horse power to be shown in the shop")
    schema:register(XMLValueType.FLOAT, configPath .. "#maxSpeed", "Max. speed to be shown in the shop")
    schema:register(XMLValueType.INT, configPath .. "#consumerConfigurationIndex", "Index of consumer configuration to be used")
end
