








---Class for help icons
local HelpIcons_mt = Class(HelpIcons)


---Creating help icons
-- @param integer id node id
function HelpIcons:onCreate(id)
    local helpIcons = HelpIcons.new(id)
    g_currentMission:addNonUpdateable(helpIcons)
    g_currentMission.helpIconsBase = helpIcons
end


---Creating help icons
-- @param integer name node id
-- @return table instance Instance of object
function HelpIcons.new(name)
    local self = setmetatable({}, HelpIcons_mt)

    self.me = name
    local num = getNumOfChildren(self.me)

    self.helpIcons = {}
    for i = 0, num - 1 do
        local helpIconTriggerId = getChildAt(self.me, i)
        local helpIconId = getChildAt(helpIconTriggerId, 0)
        local helpIconCustomNumber = Utils.getNoNil(getUserAttribute(helpIconTriggerId, "customNumber"), 0)
        addTrigger(helpIconTriggerId, "triggerCallback", self)
        local helpIcon = {helpIconTriggerId = helpIconTriggerId, helpIconId = helpIconId, helpIconCustomNumber = helpIconCustomNumber}
        table.insert(self.helpIcons, helpIcon)
    end
    self.visible = true

    return self
end


---Deleting help icons
function HelpIcons:delete()
    for _, helpIcon in pairs(self.helpIcons) do
        removeTrigger(helpIcon.helpIconTriggerId)
    end
end










---Trigger callback
-- @param integer triggerId id of trigger
-- @param integer otherId id of actor
-- @param boolean onEnter on enter
-- @param boolean onLeave on leave
-- @param boolean onStay on stay
function HelpIcons:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)

    if not onEnter then
        return
    end

    -- Get the local player. If they do not exist, do nothing.
    local localPlayer = g_localPlayer
    if localPlayer == nil then
        return
    end

    -- If the player is not in a vehicle but the other entity id isn't their root node, do nothing.
    if not localPlayer:getIsInVehicle() and otherId ~= localPlayer.rootNode then
        return
    end

    -- Get the player's vehicle. If they are not in a vehicle, or if the vehicle does not match the collided object, do nothing.
    local playerVehicle = localPlayer:getCurrentVehicle()
    if playerVehicle == nil or playerVehicle ~= g_currentMission.nodeToObject[otherId] then
        return
    end

    local missionInfo = g_currentMission.missionInfo
    for i, helpIcon in ipairs(self.helpIcons) do -- order is important for savegame

        if helpIcon.helpIconTriggerId ~= triggerId or not getVisibility(helpIcon.helpIconId) then
            continue
        end

        setVisibility(helpIcon.helpIconId, false)
        setCollisionFilterMask(helpIcon.helpIconTriggerId, 0)

        -- update help icon string
        missionInfo.foundHelpIcons = ""
        for _, helpIcon in ipairs(self.helpIcons) do
            if getVisibility(helpIcon.helpIconId) then
                missionInfo.foundHelpIcons = missionInfo.foundHelpIcons .. "0"
            else
                missionInfo.foundHelpIcons = missionInfo.foundHelpIcons .. "1"
            end
        end

        local messageNumber = helpIcon.helpIconCustomNumber
        if messageNumber == 0 then
            messageNumber = i
        end
        g_currentMission.inGameMessage:showMessage(g_i18n:getText("helpIcon_title" .. messageNumber), g_i18n:getText("helpIcon_text" .. messageNumber), 0)
    end
end


---Show help icons
-- @param boolean visible visible
-- @param boolean clearIconStates clear icon states
function HelpIcons:showHelpIcons(visible, clearIconStates)
    self.visible = visible

    local oldStates = g_currentMission.missionInfo.foundHelpIcons

    for i, helpIcon in ipairs(self.helpIcons) do
        local isVisible = visible
        if clearIconStates == nil or not clearIconStates then
            isVisible = isVisible and string.sub(oldStates, i, i) == "0"
        end

        setVisibility(helpIcon.helpIconId, isVisible)
        if isVisible then
            setCollisionFilterMask(helpIcon.helpIconTriggerId, 3145728)
        else
            setCollisionFilterMask(helpIcon.helpIconTriggerId, 0)
        end
    end

end


---Delete help icon
-- @param integer i id of help icon
function HelpIcons:deleteHelpIcon(i)
    if self.helpIcons[i] ~= nil then
        setVisibility(self.helpIcons[i].helpIconId, false)
        setCollisionFilterMask(self.helpIcons[i].helpIconTriggerId, 0)
    end
end
