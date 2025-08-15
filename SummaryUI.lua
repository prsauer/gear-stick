GST_Summary = {}

-- Helper function to get gear popularity for a specific slot and item
local function GetGearPopularity(specId, slotType, itemID, bracket)
    local gearDbs = {
        ["pve"] = usageDbPvE,
        ["2v2"] = usageDb2v2,
        ["3v3"] = usageDb3v3
    }

    local db = gearDbs[bracket]
    if not db then
        print("DEBUG GetGearPopularity: No database for bracket", bracket)
        return nil
    end

    -- Try to find the gear in the database
    -- First check if there's a direct itemID match (for BIS items)
    local simpleKey = tostring(itemID)
    if db[simpleKey] then
        return {
            percent = db[simpleKey][1],
            isBis = db[simpleKey][2],
            bisName = db[simpleKey][3]
        }
    end

    -- If no direct match, try to find the most popular version with stats
    -- Look for keys that start with specId + itemID + "-"
    local keyPrefix = specId .. itemID .. "-"
    local bestMatch = nil
    local highestPercent = 0
    local foundKeys = {}

    for key, data in pairs(db) do
        if type(key) == "string" and string.find(key, keyPrefix, 1, true) == 1 then
            table.insert(foundKeys, key .. " (" .. data[1] .. "%)")
            if data[1] > highestPercent then
                highestPercent = data[1]
                bestMatch = {
                    percent = data[1],
                    isBis = data[2],
                    bisName = data[3]
                }
            end
        end
    end

    return bestMatch
end

-- Helper function to check if any enchant data exists for a slot
local function HasEnchantDataForSlot(specId, slotType, bracket)
    if not GSTEnchantsDb then return false end

    for _, enchant in ipairs(GSTEnchantsDb) do
        if enchant.specId == specId and
            enchant.slotType == slotType and
            enchant.bracket == bracket then
            return true
        end
    end
    return false
end

-- Helper function to get enchant popularity
local function GetEnchantPopularity(specId, slotType, enchantID, bracket)
    if not GSTEnchantsDb or not enchantID then return nil end

    for _, enchant in ipairs(GSTEnchantsDb) do
        if enchant.specId == specId and
            enchant.slotType == slotType and
            enchant.enchantId == enchantID and
            enchant.bracket == bracket then
            return {
                rank = enchant.rank,
                percent = enchant.percent,
                name = enchant.enchantName
            }
        end
    end
    return nil
end

local function ShowSummary()
    -- Create the main frame if it doesn't exist
    if not SummaryFrame then
        local frame = CreateFrame("Frame", "SummaryFrame", UIParent, "BackdropTemplate")
        frame:SetSize(400, 580)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")

        -- Set up the backdrop
        frame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.9)
        frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

        -- Add title
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOPLEFT", 8, -8)
        frame.title:SetText("Gearstick Summary")

        -- Add Enchants button
        local enchantsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        enchantsButton:SetSize(80, 22)
        enchantsButton:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
        enchantsButton:SetText("Enchants")
        enchantsButton:SetScript("OnClick", function()
            if GST_Enchants and GST_Enchants.SlashCmd then
                GST_Enchants.SlashCmd()
            end
        end)

        -- Add close button
        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

        -- Make the frame movable
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        -- Make the frame closeable with escape
        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                self:Hide()
            end
        end)
        frame:EnableKeyboard(true)
        frame:SetPropagateKeyboardInput(true)

        -- Add to UISpecialFrames to make it close with escape
        tinsert(UISpecialFrames, "SummaryFrame")

        SummaryFrame = frame
    end

    -- Get current spec info
    local currentSpec = GetSpecialization()
    local currentSpecID = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or nil
    local _, _, currentClassID = UnitClass("player")

    if not currentSpecID then
        print("No specialization selected")
        return
    end

    -- Create bracket dropdown if it doesn't exist
    if not SummaryFrame.bracketDropdown then
        local dropdown = CreateFrame("Frame", "GSTSummaryBracketDropdown", SummaryFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", SummaryFrame.title, "BOTTOMLEFT", 90, -10)
        SummaryFrame.bracketDropdown = dropdown

        dropdown.initialize = function(self)
            local info = UIDropDownMenu_CreateInfo()
            local brackets = { "pve", "2v2", "3v3" }
            for _, bracket in ipairs(brackets) do
                info.text = string.upper(bracket)
                info.value = bracket
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    UIDropDownMenu_SetText(dropdown, string.upper(self.value))
                    ShowSummary() -- Refresh the display
                end
                info.checked = (bracket == UIDropDownMenu_GetSelectedValue(dropdown))
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    -- Set default bracket if not set
    if not UIDropDownMenu_GetSelectedValue(SummaryFrame.bracketDropdown) then
        UIDropDownMenu_SetSelectedValue(SummaryFrame.bracketDropdown, "2v2")
        UIDropDownMenu_SetText(SummaryFrame.bracketDropdown, "2V2")
    end
    UIDropDownMenu_SetWidth(SummaryFrame.bracketDropdown, 80)
    UIDropDownMenu_JustifyText(SummaryFrame.bracketDropdown, "LEFT")

    local selectedBracket = UIDropDownMenu_GetSelectedValue(SummaryFrame.bracketDropdown)

    -- Clear existing slot frames
    if SummaryFrame.slotFrames then
        for _, slotFrame in pairs(SummaryFrame.slotFrames) do
            slotFrame:Hide()
            slotFrame:SetParent(nil)
        end
    end
    SummaryFrame.slotFrames = {}

    -- Define slot positions to mimic character panel (2 columns + trinkets + weapons)
    local slotPositions = {
        -- Left column: HEAD, NECK, SHOULDER, BACK, CHEST, WRIST
        [1] = { x = 40, y = -70 },   -- HEAD
        [2] = { x = 40, y = -125 },  -- NECK
        [3] = { x = 40, y = -180 },  -- SHOULDER
        [15] = { x = 40, y = -235 }, -- BACK
        [5] = { x = 40, y = -290 },  -- CHEST
        [9] = { x = 40, y = -345 },  -- WRIST

        -- Right column: HANDS, WAIST, LEGS, FEET, RING1, RING2
        [10] = { x = 220, y = -70 },  -- HANDS
        [6] = { x = 220, y = -125 },  -- WAIST
        [7] = { x = 220, y = -180 },  -- LEGS
        [8] = { x = 220, y = -235 },  -- FEET
        [11] = { x = 220, y = -290 }, -- FINGER_1
        [12] = { x = 220, y = -345 }, -- FINGER_2

        -- Trinkets row (between columns and weapons)
        [13] = { x = 40, y = -410 },  -- TRINKET_1
        [14] = { x = 220, y = -410 }, -- TRINKET_2

        -- Weapons below (centered)
        [16] = { x = 40, y = -475 }, -- MAIN_HAND
        [17] = { x = 220, y = -475 } -- OFF_HAND
    }



    -- Use shared slot mapping from ItemUtils

    -- Create slot frames
    for slotID, position in pairs(slotPositions) do
        local slotFrame = CreateFrame("Frame", nil, SummaryFrame, "BackdropTemplate")
        slotFrame:SetSize(120, 70)
        slotFrame:SetPoint("TOPLEFT", SummaryFrame, "TOPLEFT", position.x, position.y)
        slotFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        slotFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        slotFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        -- Get item info for this slot using utility functions
        local itemInfo = GST_ItemUtils.GetSlotItemInfo(slotID)
        local hasItem = itemInfo ~= nil
        local itemLink = itemInfo and itemInfo.link
        local itemID = itemInfo and itemInfo.itemID
        local enchantID = itemInfo and itemInfo.enchantID
        local slotType = itemInfo and itemInfo.slotName
        local gearPercent, enchantPercent = nil, nil

        if hasItem then
            -- Get gear popularity
            if itemID then
                local gearInfo = GetGearPopularity(currentSpecID, slotType, itemID, selectedBracket)
                if gearInfo then
                    gearPercent = gearInfo.percent
                else
                    -- Item not found in database = 0% popularity
                    gearPercent = 0
                end
            end

            -- Get enchant popularity
            if enchantID and slotType then
                local enchantInfo = GetEnchantPopularity(currentSpecID, slotType, enchantID, selectedBracket)
                if enchantInfo then
                    enchantPercent = enchantInfo.percent
                end
            end
        end

        -- Create slot label
        local label = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOP", slotFrame, "TOP", 0, -2)
        label:SetText(GST_ItemUtils.SLOT_NAMES[slotID] or "")
        label:SetTextColor(1, 1, 1, 1)
        label:SetJustifyH("CENTER")



        -- Create gear percentage text
        if gearPercent then
            local gearText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            gearText:SetPoint("CENTER", slotFrame, "CENTER", 0, 5)
            gearText:SetText(string.format("G:%.0f%%", gearPercent))
            gearText:SetJustifyH("CENTER")

            -- Color based on popularity
            if gearPercent >= 50 then
                gearText:SetTextColor(0.2, 1, 0.2, 1)   -- Green
            elseif gearPercent >= 20 then
                gearText:SetTextColor(1, 1, 0.2, 1)     -- Yellow
            elseif gearPercent > 0 then
                gearText:SetTextColor(1, 0.6, 0.2, 1)   -- Orange
            else
                gearText:SetTextColor(0.8, 0.2, 0.2, 1) -- Red for 0%
            end
        end

        -- Only show enchant indicators if enchant data exists for this slot
        local hasEnchantData = slotType and HasEnchantDataForSlot(currentSpecID, slotType, selectedBracket)

        if hasEnchantData then
            if enchantPercent then
                local enchantText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                enchantText:SetPoint("CENTER", slotFrame, "CENTER", 0, -10)
                enchantText:SetText(string.format("E:%.0f%%", enchantPercent))
                enchantText:SetJustifyH("CENTER")

                -- Color based on popularity
                if enchantPercent >= 50 then
                    enchantText:SetTextColor(0.2, 1, 0.2, 1) -- Green
                elseif enchantPercent >= 20 then
                    enchantText:SetTextColor(1, 1, 0.2, 1)   -- Yellow
                else
                    enchantText:SetTextColor(1, 0.6, 0.2, 1) -- Orange
                end
            elseif hasItem then
                -- Show "Missing Enchant" only if item exists but no enchant AND enchant data exists for this slot
                local noEnchantText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noEnchantText:SetPoint("CENTER", slotFrame, "CENTER", 0, -10)
                noEnchantText:SetText("E: MISSING")
                noEnchantText:SetTextColor(0.8, 0.2, 0.2, 1) -- Red
                noEnchantText:SetJustifyH("CENTER")
            end
        end

        -- Add tooltip functionality for all slots
        slotFrame:EnableMouse(true)
        slotFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()

            local slotName = GST_ItemUtils.SLOT_NAMES[slotID] or "UNKNOWN"
            GameTooltip:AddLine(slotName .. " Distribution", 1, 1, 1)
            GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer

            -- Get fresh item data for tooltip
            local tooltipItemInfo = GST_ItemUtils.GetSlotItemInfo(slotID)
            local tooltipHasItem = tooltipItemInfo ~= nil
            local tooltipItemID = tooltipItemInfo and tooltipItemInfo.itemID

            -- Show gear distribution using new slot-based database
            if GSTSlotGearDb then
                GameTooltip:AddLine("Top Gear Choices:", 0.2, 1, 0.2)

                -- Find items for this slot from the new database
                local slotItems = {}
                for _, item in ipairs(GSTSlotGearDb) do
                    if item.slotId == slotID and
                        item.specId == currentSpecID and
                        item.bracket == selectedBracket then
                        table.insert(slotItems, item)
                    end
                end

                -- Sort by rank (should already be sorted, but just in case)
                table.sort(slotItems, function(a, b) return a.rank < b.rank end)

                -- Show top 5 items
                for i = 1, math.min(5, #slotItems) do
                    local item = slotItems[i]

                    -- Enhanced matching: compare both item ID and stats
                    local itemMatches = tooltipItemID and tooltipItemID == item.itemId
                    local statsMatch = tooltipItemInfo and tooltipItemInfo.statsShort and
                        tooltipItemInfo.statsShort == item.statsShort
                    local isEquipped = itemMatches and (not item.statsShort or item.statsShort == "" or statsMatch)

                    local color = isEquipped and "|cFF00FF00" or "|cFFFFFFFF"
                    local bisText = item.isBis and " (BiS)" or ""

                    local statsDisplay = item.statsShort and item.statsShort ~= "" and (" (" .. item.statsShort .. ")") or
                        ""
                    GameTooltip:AddLine(
                        string.format("%s%.1f%% - %s%s%s", color, item.percent, item.itemName, statsDisplay, bisText), 1,
                        1, 1)
                end

                if #slotItems == 0 then
                    GameTooltip:AddLine("No gear data for this slot", 0.8, 0.8, 0.8)
                end
            else
                GameTooltip:AddLine("Slot gear database not loaded", 0.8, 0.8, 0.8)
            end



            -- Show enchant distribution
            local tooltipSlotType = tooltipItemInfo and tooltipItemInfo.slotName
            local tooltipEnchantID = tooltipItemInfo and tooltipItemInfo.enchantID
            if tooltipSlotType and GSTEnchantsDb then
                local enchants = {}
                for _, enchant in ipairs(GSTEnchantsDb) do
                    if enchant.specId == currentSpecID and
                        enchant.slotType == tooltipSlotType and
                        enchant.bracket == selectedBracket then
                        table.insert(enchants, enchant)
                    end
                end

                -- Only show enchant section if there are enchants to display
                if #enchants > 0 then
                    GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
                    GameTooltip:AddLine("Top Enchant Choices:", 0.2, 0.8, 1)

                    -- Sort by rank and show top 5
                    table.sort(enchants, function(a, b) return a.rank < b.rank end)

                    local playerEnchantID = tooltipEnchantID
                    for i = 1, math.min(5, #enchants) do
                        local ench = enchants[i]
                        local color = (playerEnchantID and playerEnchantID == ench.enchantId) and "|cFF00FF00" or
                            "|cFFFFFFFF"
                        GameTooltip:AddLine(
                            string.format("%s#%d (%.1f%%) - %s", color, ench.rank, ench.percent, ench.enchantName), 1, 1,
                            1)
                    end
                end
            end

            GameTooltip:Show()
        end)

        slotFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        table.insert(SummaryFrame.slotFrames, slotFrame)
    end

    -- Add legend
    if not SummaryFrame.legend then
        local legend = SummaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        legend:SetPoint("BOTTOM", SummaryFrame, "BOTTOM", 0, 8)
        legend:SetText("G: Gear popularity | E: Enchant popularity")
        legend:SetTextColor(0.7, 0.7, 0.7, 1)
        SummaryFrame.legend = legend
    end

    SummaryFrame:Show()
end

function GST_Summary.SlashCmd(arg1)
    ShowSummary()
end
