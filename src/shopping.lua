local addon_name, SL = ...
local M = {}

M.ShoppingList = {
    
}

M.create_entry = function(item_id, item_name, item_link, item_texture, required)
    M.ShoppingList[item_id] = {
        ID       = item_id,
        Name     = item_name,
        Link     = item_link,
        Texture  = item_texture,
        Required = required,
        Obtained = 0
    }
end

local replicate_string = function(str, n)
    local result = ""
    for i = 1, n do
        result = result .. str
    end
    return result
end

local get_keys = function(t)
    local keys = {}
    for k, _ in pairs(t) do
        keys[k] = 0
    end
    return keys
end

local create_item_data = function(item_id, enchant_id, gem_id1, gem_id2,
        gem_id3, gem_id4, suffix_id, unique_id, link_level, spec_id, upgrade_id,
        instance_difficulty_id, num_bonus_ids, bonus_id1, bonus_id2,
        upgrade_value, item_name)
    return {
        ItemID               = item_id or 0,
        EnchantID            = enchant_id or 0,
        GemID1               = gem_id1 or 0,
        GemID2               = gem_id2 or 0,
        GemID3               = gem_id3 or 0,
        GemID4               = gem_id4 or 0,
        SuffixID             = suffix_id or 0,
        UniqueID             = unique_id or 0,
        LinkLevel            = link_level or 0,
        SpecID               = spec_id or 0,
        UpgradeID            = upgrade_id or 0,
        InstanceDifficultyID = instance_difficulty_id or 0,
        NumBonusIDs          = num_bonus_ids or 0,
        BonusID1             = bonus_id1 or 0,
        BonusID2             = bonus_id2 or 0,
        UpgradeValue         = upgrade_value or 0,
        Name                 = item_name
    }
end

local disect_item_link = function(item_link)
    local item_pattern =
        "|c........|Hitem" ..
        replicate_string(":(%d*)", 16) ..
        "|h%[([^%]]+)%]|h"
    return create_item_data(select(3, item_link:find(item_pattern)))
end

local reset_list = function()
    for item_id, item in pairs(M.ShoppingList) do
        item.Obtained = 0
    end
end

M.update_list = function()
    local item_counts = get_keys(M.ShoppingList)
    for bag_id = 0, 4 do
        local slot_count = GetContainerNumSlots(bag_id)
        if slot_count then
            for slot_id = 1, slot_count do
                local texture, item_count, _, _, _, _, item_link =
                    GetContainerItemInfo(bag_id, slot_id)
                if texture then
                    local item = disect_item_link(item_link)
                    if item_counts[item.ItemID] then
                        item_counts[item.ItemID] = item_counts[item.ItemID] +
                            item_count
                    end
                end
            end
        end
    end
    for item_id, item in pairs(M.ShoppingList) do
        if item.Obtained ~= item_counts[item_id] then
            M.ShoppingList[item.ID].Obtained = item_counts[item_id]
            M.show_item(item)
        end
    end
end

M.add_entry = function(input)
    if not input then
        return SL.Error "You must specify a number followed by the item name."
    end
    local space_index = input:find(" ")
    if not space_index then
        return SL.Error "You must specify a number followed by the item name."
    end
    local required = tonumber(input:sub(1, space_index - 1))
    if not required then
        return SL.Error "You must specify the number of the item you need."
    end
    local item         = input:sub(space_index + 1)
    local item_info    = { GetItemInfo(item) }
    local item_name    = item_info[1]
    local item_link    = item_info[2]
    local item_texture = item_info[10]
    if not item_link then
        return SL.Error "Can't find the specified item."
    end
    local item_id      = disect_item_link(item_link).ItemID
    if item_id == 0 then
        return SL.Error "Could not get the item ID of the specified item."
    end
    M.create_entry(item_id, item_name, item_link, item_texture, required)
    SL.Print("Added %dx%s to your shopping list.", required, item_link)
    M.update_list()
end

M.show_item = function(item)
    local got_em = item.Obtained >= item.Required
    SL.Print("%s%s: %d/%d", item.Link, got_em and "|cFF11FF33" or "",
        item.Obtained, item.Required)
end

M.show_list = function()
    local empty = true
    for item_id, item in pairs(M.ShoppingList) do
        empty = false
        M.show_item(item)
    end
    if empty then
        SL.Print "Your shopping list is empty."
    end
end

M.clear_list = function()
    M.ShoppingList = {}
    SL.Print "Shopping list cleared."
end

M.remove_entry = function(item_name)
    for item_id, item in pairs(M.ShoppingList) do
        if item.Name == item_name then
            local item_link = item.Link
            M.ShoppingList[item_id] = nil
            SL.Print("%s has been removed from your shopping list.", item_link)
            return true
        end
    end
    return false
end

SL.Command.MainCommand = M.show_list

SL.Command.add_cmd("add", M.add_entry, [[
/sl add
> "/sl add <number> <item name>" adds the specified number of the specified item to your shopping list.
]], true)

SL.Command.add_cmd("show", M.show_list, [[
/sl show
> "/sl show" shows your shopping list in the chat window.
]])

SL.Command.add_cmd("clear", M.clear_list, [[
/sl clear
> "/sl clear" clears your shopping list.
]])

SL.Command.add_cmd("remove", M.remove_entry, [[
/sl remove
> "/sl remove <item name>" removes the specified item from your shopping list.
]])

SL.Shopping = M
