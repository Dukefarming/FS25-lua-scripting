






---This pre-simulates a particle system so it doesn't start at zero when the game begins
local SimParticleSystem_mt = Class(SimParticleSystem)


---Creating SimParticleSystem
-- @param integer id node id
function SimParticleSystem:onCreate(id)
    g_currentMission:addNonUpdateable(SimParticleSystem.new(id))
end


---Creating SimParticleSystem
-- @param integer name node id
-- @return table instance Instance of object
function SimParticleSystem.new(name)
    local self = setmetatable({}, SimParticleSystem_mt)
    self.id = name

    local particleSystem = nil

    if getHasClassId(self.id, ClassIds.SHAPE) then
        local geometry = getGeometry(self.id)
        if geometry ~= 0 then
            if getHasClassId(geometry, ClassIds.PRECIPITATION) then
                particleSystem = geometry
            end
        end
    end

    if particleSystem ~= nil then
        local lifespan = getParticleSystemLifespan(particleSystem)
        addParticleSystemSimulationTime(particleSystem, lifespan)
    end

    return self
end
