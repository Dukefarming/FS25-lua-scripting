










---Special sound manager class for dedicated server that disables all sounds
local ServerSoundManager_mt = Class(ServerSoundManager, SoundManager)


---Creating manager
-- @return table instance instance of object
function ServerSoundManager.new(customMt)
    local self = SoundManager.new(customMt or ServerSoundManager_mt)

    return self
end


---Returns a clone of the sample at the given link node
-- @param table sample sample object
-- @param integer linkNode id of new link node
-- @return table sample sample object
function SoundManager:cloneSample(sample, linkNode, modifierTargetObject)
    local newSample = table.clone(sample)
    newSample.modifiers = table.clone(sample.modifiers)

    if modifierTargetObject ~= nil then
        newSample.modifierTargetObject = modifierTargetObject
    end

    newSample.sourceRandomizations = {}

    self.samples[newSample] = newSample
    table.insert(self.orderedSamples, newSample)

    return newSample
end
