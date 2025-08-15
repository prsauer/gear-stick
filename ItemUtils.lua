-- ItemUtils.lua - Shared utility functions for item detection and manipulation
GST_ItemUtils = {}

-- Helper function to get item ID from link
function GST_ItemUtils.GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    local itemID = itemLink:match("|Hitem:(%d+):")
    return itemID and tonumber(itemID) or nil
end

-- Helper function to extract enchant ID from item link
function GST_ItemUtils.GetEnchantIDFromLink(itemLink)
    if not itemLink then return nil end
    local enchantID = itemLink:match("|Hitem:%d+:(%d+):")
    if enchantID and enchantID ~= "0" then
        return tonumber(enchantID)
    end
    return nil
end

-- Standard slot mapping for inventory slots
GST_ItemUtils.SLOT_MAPPING = {
    ["HEAD"] = 1,
    ["NECK"] = 2,
    ["SHOULDER"] = 3,
    ["CHEST"] = 5,
    ["WAIST"] = 6,
    ["LEGS"] = 7,
    ["FEET"] = 8,
    ["WRIST"] = 9,
    ["HANDS"] = 10,
    ["FINGER_1"] = 11,
    ["FINGER_2"] = 12,
    ["TRINKET_1"] = 13,
    ["TRINKET_2"] = 14,
    ["BACK"] = 15,
    ["MAIN_HAND"] = 16,
    ["OFF_HAND"] = 17
}

-- Reverse mapping from slot ID to slot name
GST_ItemUtils.SLOT_NAMES = {
    [1] = "HEAD",
    [2] = "NECK",
    [3] = "SHOULDER",
    [5] = "CHEST",
    [6] = "WAIST",
    [7] = "LEGS",
    [8] = "FEET",
    [9] = "WRIST",
    [10] = "HANDS",
    [11] = "FINGER_1",
    [12] = "FINGER_2",
    [13] = "TRINKET_1",
    [14] = "TRINKET_2",
    [15] = "BACK",
    [16] = "MAIN_HAND",
    [17] = "OFF_HAND"
}

-- Check if player has an item equipped in a specific slot
function GST_ItemUtils.HasItemInSlot(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    return itemLink ~= nil
end

-- Check if player has an item equipped in a specific slot by name
function GST_ItemUtils.HasItemInSlotByName(slotName)
    local slotID = GST_ItemUtils.SLOT_MAPPING[slotName]
    if not slotID then return false end
    return GST_ItemUtils.HasItemInSlot(slotID)
end

-- Extract secondary stats from item link tooltip
function GST_ItemUtils.GetItemStatsShort(itemLink)
    if not itemLink then return "" end
    
    -- Create a temporary tooltip to read item stats
    local tooltip = CreateFrame("GameTooltip", "GST_TempTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)
    
    local stats = {}
    
    -- Parse tooltip for secondary stats
    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                if text:find("%+.*Critical Strike") then
                    table.insert(stats, "Crit")
                elseif text:find("%+.*Versatility") then
                    table.insert(stats, "Vers")
                elseif text:find("%+.*Haste") then
                    table.insert(stats, "Haste")
                elseif text:find("%+.*Mastery") then
                    table.insert(stats, "Mast")
                end
            end
        end
    end
    
    tooltip:Hide()
    return table.concat(stats, "/")
end

-- Get complete item info for a slot
function GST_ItemUtils.GetSlotItemInfo(slotID)
    local itemLink = GetInventoryItemLink("player", slotID)
    if not itemLink then return nil end

    -- Get stats from item tooltip  
    local statsShort = GST_ItemUtils.GetItemStatsShort(itemLink)
    
    return {
        link = itemLink,
        itemID = GST_ItemUtils.GetItemIDFromLink(itemLink),
        enchantID = GST_ItemUtils.GetEnchantIDFromLink(itemLink),
        texture = GetInventoryItemTexture("player", slotID),
        slotID = slotID,
        slotName = GST_ItemUtils.SLOT_NAMES[slotID],
        statsShort = statsShort
    }
end

-- Check if player has any enchant in a specific slot (handles rings/trinkets)
function GST_ItemUtils.HasEnchantInSlot(slotType)
    local slotId = GST_ItemUtils.SLOT_MAPPING[slotType]
    if slotId then
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            local enchantID = GST_ItemUtils.GetEnchantIDFromLink(itemLink)
            if enchantID then
                return true, enchantID
            end
        end

        -- Special handling for rings (check both finger slots)
        if slotType == "FINGER_1" or slotType == "FINGER_2" then
            for ringSlot = 11, 12 do
                local ringLink = GetInventoryItemLink("player", ringSlot)
                if ringLink then
                    local enchantID = GST_ItemUtils.GetEnchantIDFromLink(ringLink)
                    if enchantID then
                        return true, enchantID
                    end
                end
            end
        end

        -- Special handling for trinkets (check both trinket slots)
        if slotType == "TRINKET_1" or slotType == "TRINKET_2" then
            for trinketSlot = 13, 14 do
                local trinketLink = GetInventoryItemLink("player", trinketSlot)
                if trinketLink then
                    local enchantID = GST_ItemUtils.GetEnchantIDFromLink(trinketLink)
                    if enchantID then
                        return true, enchantID
                    end
                end
            end
        end
    end

    return false, nil
end

-- Get all equipped items
function GST_ItemUtils.GetAllEquippedItems()
    local items = {}
    for slotID = 1, 17 do
        local itemInfo = GST_ItemUtils.GetSlotItemInfo(slotID)
        if itemInfo then
            items[slotID] = itemInfo
        end
    end
    return items
end
