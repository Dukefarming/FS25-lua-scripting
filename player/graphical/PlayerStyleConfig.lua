









---Represents a single config for a player style (face, beard, top, etc.).
local PlayerStyleConfig_mt = Class(PlayerStyleConfig)


















---Includes any items enabled for the current selection.
-- @param integer index The index of the item.
-- @return boolean include True if the item should be included; otherwise false.
function PlayerStyleConfig:ENABLED_GETTER_FILTER(index)
    return not self.playerStyle.disabledOptionsForSelection[self.name]
end


---Includes any non-hidden items.
-- @param integer index The index of the item.
-- @param PlayerStyleItem gear The item to compare with.
-- @return boolean include True if the item should be included; otherwise false.
function PlayerStyleConfig:NOT_HIDDEN_GETTER_FILTER(index, gear)
    return not gear.hidden
end


---Includes any non-hat hair styles.
-- @param integer index The index of the item.
-- @param PlayerStyleItem hair The item to compare with.
-- @return boolean include True if the item should be included; otherwise false.
function PlayerStyleConfig:NOT_FOR_HAT_GETTER_FILTER(index, hair)
    return not hair.forHat
end


---Includes any selected items.
-- @param integer index The index of the item.
-- @return boolean include True if the item should be included; otherwise false.
function PlayerStyleConfig:SELECTED_GETTER_FILTER(index)
    return self.selectedItemIndex == index
end


---Includes any item when a onepiece is not selected.
-- @param integer index The index of the item.
-- @return boolean include True if the item should be included; otherwise false.
function PlayerStyleConfig:NO_ONEPIECE_GETTER_FILTER(index)
    return self.playerStyle.configs.onepiece.selectedItemIndex == 0
end


---Includes any beards that fit with the current face.
-- @param integer index The index of the item.
-- @param PlayerStyleItem beard The beard to compare with.
-- @return boolean include True if the item should be included; otherwise false.
function PlayerStyleConfig:BEARD_FACE_GETTER_FILTER(index, beard)
    return beard.faceName == nil or (self.playerStyle.configs.face:getSelectedItem() ~= nil and beard.faceName == self.playerStyle.configs.face:getSelectedItem().name)
end




































































































































































---Gets the index of the item with the given name.
-- @param string itemName The name of the item whose index should be found.
-- @return integer index The index of the found item, or nil if the item is nil or does not exist in this config.
function PlayerStyleConfig:getItemNameIndex(itemName)

    --#debug Assert.isNilOrType(itemName, "string", "Item name should be a string or nil!")

    -- If the name is nil or whitespace, do nothing as it has no associated index.
    if string.isNilOrWhitespace(itemName) then
        return nil
    end

    -- Get the item from its name. If it is nil then return nil.
    local item = self.itemsByName[itemName]
    if item == nil then
        return nil
    end

    -- Get the index from the item.
    return self:getItemIndex(item)
end


---Gets the index of the given item.
-- @param PlayerStyleItem item The item whose index should be found.
-- @return integer index The index of the found item, or nil if the item is nil or does not exist in this config.
function PlayerStyleConfig:getItemIndex(item)

    -- If the item is nil, return nil as it has no index.
    if item == nil then
        return nil
    end

    --#debug Assert.isClass(item, PlayerStyleItem, "Cannot get non-item from list of items!")

    -- Special case for item at index 0 (empty item), as it does not get picked up by ipairs() and pairs() does not guarentee order.
    if item == self.items[0] then
        return 0
    end

    -- Return the index of the item in the collection. This will be nil if the item is not found.
    return table.find(self.items, item)
end


---Gets the currently selected item.
-- @return PlayerStyleItem item The currently selected item.
function PlayerStyleConfig:getSelectedItem()
    return self.items[self.selectedItemIndex]
end
