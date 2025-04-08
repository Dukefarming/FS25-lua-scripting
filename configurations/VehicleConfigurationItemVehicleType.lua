











---Stores the data of a single vehicle type configuration
local VehicleConfigurationItemVehicleType_mt = Class(VehicleConfigurationItemVehicleType, VehicleConfigurationItem)


---
function VehicleConfigurationItemVehicleType.new(configName, customMt)
    local self = VehicleConfigurationItemVehicleType:superClass().new(configName, VehicleConfigurationItemVehicleType_mt)

    return self
end


---
function VehicleConfigurationItemVehicleType:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
    if not VehicleConfigurationItemVehicleType:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
        return false
    end

    self.vehicleType = xmlFile:getValue(configKey .. "#vehicleType")

    return true
end


---
function VehicleConfigurationItemVehicleType.registerXMLPaths(schema, rootPath, configPath)
    VehicleConfigurationItemVehicleType:superClass().registerXMLPaths(schema, rootPath, configPath)

    schema:register(XMLValueType.STRING, configPath .. "#vehicleType", "Vehicle type to be used")
end
