




























































































































---
function AIDischargeable:getDischargeNodeAutomaticDischarge(superFunc, dischargeNode)
    -- disable automatic discharging since we control it on our own when we reach the unloading point
    if Platform.gameplay.automaticDischarge and self:getIsAIActive() then
        return false
    end

    return superFunc(self, dischargeNode)
end


---
function AIDischargeable:onDischargeStateChanged(state)
    local spec = self.spec_aiDischargeable
    if spec.currentDischargeNode ~= nil and spec.isAIDischargeRunning and state == Dischargeable.DISCHARGE_STATE_OFF then
        self:stoppedAIDischarge()
    end
end
