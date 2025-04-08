









---
local AIUserSetting_mt = Class(AIUserSetting)


---
function AIUserSetting.new(customMt)
    local self = setmetatable({}, customMt or AIUserSetting_mt)

    self.unitText = nil
    self.defaultPostFix = nil
    self.isVineyardSetting = false

    return self
end
