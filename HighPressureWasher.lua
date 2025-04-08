












---
function HighPressureWasher.prerequisitesPresent(specializations)
    return true
end


---
function HighPressureWasher.initSpecialization()
    local schema = Vehicle.xmlSchema
    schema:setXMLSpecializationType("HighPressureWasher")

    AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.highPressureWasher.animationNodes")
    EffectManager.registerEffectXMLPaths(schema, "vehicle.highPressureWasher.effects")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.highPressureWasher.sounds", "start(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.highPressureWasher.sounds", "stop(?)")
    SoundManager.registerSampleXMLPaths(schema, "vehicle.highPressureWasher.sounds", "work(?)")

    schema:setXMLSpecializationType()
end


---
function HighPressureWasher.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", HighPressureWasher)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", HighPressureWasher)
    SpecializationUtil.registerEventListener(vehicleType, "onHandToolStoredInHolder", HighPressureWasher)
    SpecializationUtil.registerEventListener(vehicleType, "onHandToolTakenFromHolder", HighPressureWasher)
end


---Called on loading
-- @param table savegame savegame
function HighPressureWasher:onLoad(savegame)
    local spec = self.spec_highPressureWasher

    if self.isClient then
        spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.highPressureWasher.animationNodes", self.components, self, self.i3dMappings)
        spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.highPressureWasher.effects", self.components, self, self.i3dMappings)

        spec.samples = {}
        spec.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.stop  = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
        spec.samples.work  = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.highPressureWasher.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
    end

    if not self.isClient then
        SpecializationUtil.removeEventListener(self, "onDelete", HighPressureWasher)
        SpecializationUtil.removeEventListener(self, "onUpdate", HighPressureWasher)
    end
end


---Called on deleting
function HighPressureWasher:onDelete()
    local spec = self.spec_highPressureWasher
    if self.isClient then
        g_soundManager:deleteSamples(spec.samples)
        g_animationManager:deleteAnimations(spec.animationNodes)
        g_effectManager:deleteEffects(spec.effects)
    end
end
