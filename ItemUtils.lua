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

-- Edits table in place with secondary stats from a line of text
function GST_ItemUtils.ParseLineAndWriteSecondariesTable(text, tbl)
    if (text ~= nil and string.sub(text, 1, 1) == "+") then
        -- Extract stat value and type
        local value, statType = nil, nil

        if string.find(text, "%+.*Critical Strike") then
            local captured = string.match(text, "%+(%d+,?%d*) Critical Strike")
            value = tonumber((string.gsub(captured, ",", "")))
            statType = "CRIT_RATING"
        elseif string.find(text, "%+.*Haste") then
            local captured = string.match(text, "%+([0-9,.]*) Haste")
            value = tonumber((string.gsub(captured, ",", "")))
            statType = "HASTE_RATING"
        elseif string.find(text, "%+.*Mastery") then
            local captured = string.match(text, "%+([0-9,.]*) Mastery")
            value = tonumber((string.gsub(captured, ",", "")))
            statType = "MASTERY_RATING"
        elseif string.find(text, "%+.*Versatility") then
            local captured = string.match(text, "%+(%d+,?%d*) Versatility")
            value = tonumber((string.gsub(captured, ",", "")))
            statType = "VERSATILITY"
        end

        if value and statType then
            table.insert(tbl, { value = value, type = statType })
        end
    end
    return tbl
end

-- Concats a table of secondary stats into a slug
function GST_ItemUtils.ReduceSecondariesTableToSlug(tbl)
    -- Sort by value (highest first)
    table.sort(tbl, function(a, b) return a.value > b.value end)
    -- debug(tbl)

    -- Build result string
    local rval = ""
    for i, stat in ipairs(tbl) do
        if i > 1 then
            rval = rval .. "-"
        end
        rval = rval .. stat.type
    end

    return rval
end

-- Extract secondary stats from item link using modern APIs
function GST_ItemUtils.GetItemStatsShort(itemLink)
    if not itemLink then return "" end

    local itemID = GST_ItemUtils.GetItemIDFromLink(itemLink)
    if not itemID then return "" end

    GST_TimerStart("GetItemStatsShort.GetItemStats")

    -- Try modern API first: C_Item.GetItemStats
    if C_Item and C_Item.GetItemStats then
        local stats = C_Item.GetItemStats(itemLink)
        GST_DebugTable(stats)
        if stats then
            local secondaryStats = {}

            -- Extract secondary stats from the stats table
            for statType, value in pairs(stats) do
                if statType == "ITEM_MOD_CRIT_RATING_SHORT" or statType == "CRIT_RATING" then
                    table.insert(secondaryStats, { value = value, type = "CRIT_RATING" })
                elseif statType == "ITEM_MOD_HASTE_RATING_SHORT" or statType == "HASTE_RATING" then
                    table.insert(secondaryStats, { value = value, type = "HASTE_RATING" })
                elseif statType == "ITEM_MOD_MASTERY_RATING_SHORT" or statType == "MASTERY_RATING" then
                    table.insert(secondaryStats, { value = value, type = "MASTERY_RATING" })
                elseif statType == "ITEM_MOD_VERSATILITY" or statType == "VERSATILITY" then
                    table.insert(secondaryStats, { value = value, type = "VERSATILITY" })
                end
            end

            GST_TimerStop("GetItemStatsShort.GetItemStats")

            if #secondaryStats > 0 then
                GST_TimerStart("GetItemStatsShort.ReduceSecondariesTableToSlug")
                local slug = GST_ItemUtils.ReduceSecondariesTableToSlug(secondaryStats)
                GST_TimerStop("GetItemStatsShort.ReduceSecondariesTableToSlug")
                return slug
            end
        end
    end
    print("Error looking up item stats for " .. itemLink)
    return nil
end

-- Get complete item info for a slot
function GST_ItemUtils.GetSlotItemInfo(slotID)
    GST_TimerStart("GetInventoryItemLink")
    local itemLink = GetInventoryItemLink("player", slotID)
    GST_TimerStop("GetInventoryItemLink")
    if not itemLink then return nil end

    -- Get stats from item tooltip
    GST_TimerStart("GetItemStatsShort")
    local statsShort = GST_ItemUtils.GetItemStatsShort(itemLink)
    GST_TimerStop("GetItemStatsShort")
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
