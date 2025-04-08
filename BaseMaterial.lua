













---
function BaseMaterial.prerequisitesPresent(specializations)
    return true
end


---
function BaseMaterial.initSpecialization()
end


---
function BaseMaterial.registerFunctions(vehicleType)
end


---
function BaseMaterial.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaseMaterial)
end


---
function BaseMaterial:onLoad(savegame)
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baseMaterial") --FS22 to FS25
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baseMaterialConfigurations", "vehicle.designColorConfigurations") --FS22 to FS25
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.designMaterialConfigurations", "vehicle.designColorConfigurations") --FS22 to FS25
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.designMaterial2Configurations", "vehicle.designColorConfigurations") --FS22 to FS25
    XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.designMaterial3Configurations", "vehicle.designColorConfigurations") --FS22 to FS25
end
