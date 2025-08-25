GST_Summary = {}

-- Helper function to get gear popularity for a specific slot and item
local function GetGearPopularity(specId, slotType, itemID, bracket, slotID, equippedStatsShort)
    -- Use the slot-based database for more accurate matching
    if GSTSlotGearDb and itemID then
        local bestMatch = nil

        for _, item in ipairs(GSTSlotGearDb) do
            if item.slotId == slotID and
                item.specId == specId and
                item.bracket == bracket and
                item.itemId == itemID then
                -- Check if stats match (for items with stat variants)
                if equippedStatsShort and item.statsShort then
                    if equippedStatsShort == item.statsShort then
                        -- Exact stats match
                        return {
                            percent = item.percent,
                            isBis = item.rank == 1,
                            bisName = item.itemName
                        }
                    end
                elseif not item.statsShort or item.statsShort == "" then
                    -- No stats variants, direct match
                    if not bestMatch or item.percent > bestMatch.percent then
                        bestMatch = {
                            percent = item.percent,
                            isBis = item.rank == 1,
                            bisName = item.itemName
                        }
                    end
                end
            end
        end

        if bestMatch then
            return bestMatch
        end
    end

    -- Fallback to old database method
    local gearDbs = {
        ["pve"] = usageDbPvE,
        ["2v2"] = usageDb2v2,
        ["3v3"] = usageDb3v3
    }

    local db = gearDbs[bracket]
    if not db then return nil end

    local simpleKey = tostring(itemID)
    if db[simpleKey] then
        return {
            percent = db[simpleKey][1],
            isBis = db[simpleKey][2] == 1,
            bisName = db[simpleKey][3]
        }
    end

    return nil
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

-- Helper function to get profile count for a spec and bracket
local function GetProfileCount(specId, bracket)
    -- Handle solo shuffle brackets
    if bracket:match("^shuffle_") then
        -- Get class and spec names for the shuffle database lookup
        local _, _, currentClassID = UnitClass("player")
        local className = GST_BracketUtils.GetClassNameFromID(currentClassID)
        local specName = GST_BracketUtils.GetSpecNameFromID(specId)

        if className and specName then
            local shuffleDbName = "usageDbshuffle_" .. className .. "_" .. specName
            local shuffleDb = _G[shuffleDbName]

            if shuffleDb then
                local profileCountKey = specId .. "_profileCount"
                return shuffleDb[profileCountKey]
            end
        end
        return nil
    end

    -- Handle standard brackets (pve, 2v2, 3v3)
    local gearDbs = {
        ["pve"] = usageDbPvE,
        ["2v2"] = usageDb2v2,
        ["3v3"] = usageDb3v3
    }

    local db = gearDbs[bracket]
    if not db then return nil end

    local profileCountKey = specId .. "_profileCount"
    return db[profileCountKey]
end



-- Helper function to check if a slot is "healthy"
local function IsSlotHealthy(slotID, specID, selectedBracket)
    local itemInfo = GST_ItemUtils.GetSlotItemInfo(slotID)
    if not itemInfo then
        return false -- No item = not healthy
    end

    local itemID = itemInfo.itemID
    local enchantID = itemInfo.enchantID
    local slotType = itemInfo.slotName

    -- Check if equipped item is rank 1 or rank 2 in distribution
    local isTopPick = false
    local isRank2Pick = false
    local rank2Percent = 0

    if GSTSlotGearDb and itemID then
        -- Find the top 2 items for this slot/spec/bracket
        local topItems = SlotGearIndexes.LookupBySlotSpecBracket(slotID, specID, selectedBracket)

        -- Sort by rank
        table.sort(topItems, function(a, b) return a.rank < b.rank end)

        -- Check if our equipped item matches rank 1
        if #topItems >= 1 then
            local topItem = topItems[1]
            if topItem.itemId == itemID then
                -- For items with stats variants, also check if stats match
                if topItem.statsShort and itemInfo.statsShort then
                    isTopPick = (topItem.statsShort == itemInfo.statsShort)
                else
                    isTopPick = true
                end
            end
        end

        -- Check if our equipped item matches rank 2
        if #topItems >= 2 and not isTopPick then
            local rank2Item = topItems[2]
            if rank2Item.itemId == itemID then
                -- For items with stats variants, also check if stats match
                if rank2Item.statsShort and itemInfo.statsShort then
                    isRank2Pick = (rank2Item.statsShort == itemInfo.statsShort)
                    rank2Percent = rank2Item.percent
                else
                    isRank2Pick = true
                    rank2Percent = rank2Item.percent
                end
            end
        end
    end

    -- Check if gear meets the rank/usage criteria
    local gearIsHealthy = false
    if isTopPick then
        gearIsHealthy = true
    elseif isRank2Pick then
        gearIsHealthy = (rank2Percent >= 30)
    else
        -- If not a top pick, check the old >50% rule
        local gearInfo = GetGearPopularity(specID, slotType, itemID, selectedBracket, slotID,
            itemInfo and itemInfo.statsShort)
        local gearPercent = gearInfo and gearInfo.percent or 0
        gearIsHealthy = (gearPercent > 50)
    end

    -- If gear doesn't meet criteria, slot is unhealthy
    if not gearIsHealthy then
        return false
    end

    -- Check enchant criteria
    local hasEnchantData = slotType and HasEnchantDataForSlot(specID, slotType, selectedBracket)

    if not hasEnchantData then
        -- No enchant data exists for this slot, so unenchanted is fine
        return true
    end

    if not enchantID then
        -- Slot has enchant data but no enchant = not healthy
        return false
    end

    -- Check enchant popularity (must be >50% OR be the #1 enchant choice)
    local isTopEnchant = false
    if GSTEnchantsDb then
        -- Find the top enchant for this slot/spec/bracket
        local topEnchant = nil
        for _, enchant in ipairs(GSTEnchantsDb) do
            if enchant.specId == specID and
                enchant.slotType == slotType and
                enchant.bracket == selectedBracket then
                if not topEnchant or enchant.rank < topEnchant.rank then
                    topEnchant = enchant
                end
            end
        end

        if topEnchant and topEnchant.enchantId == enchantID then
            isTopEnchant = true
        end
    end

    if not isTopEnchant then
        local enchantInfo = GetEnchantPopularity(specID, slotType, enchantID, selectedBracket)
        local enchantPercent = enchantInfo and enchantInfo.percent or 0
        return enchantPercent > 50
    end

    return true
end

local function ShowSummary()
    -- Create the main frame if it doesn't exist
    if not SummaryFrame then
        local frame = CreateFrame("Frame", "SummaryFrame", UIParent, "BackdropTemplate")
        frame:SetSize(214, 620)
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

        -- Create control container for dynamic layout
        local controlContainer = CreateFrame("Frame", nil, frame)
        controlContainer:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)
        controlContainer:SetSize(190, 130) -- Increased height for spec dropdown
        frame.controlContainer = controlContainer

        -- Add Enchants button
        local enchantsButton = CreateFrame("Button", nil, controlContainer, "UIPanelButtonTemplate")
        enchantsButton:SetSize(80, 24)
        enchantsButton:SetPoint("TOPLEFT", controlContainer, "TOPLEFT", 0, 0)
        enchantsButton:SetText("Enchants")
        enchantsButton:SetScript("OnClick", function()
            if GST_Enchants and GST_Enchants.SlashCmd then
                GST_Enchants.SlashCmd()
                SummaryFrame:Hide() -- Close the summary panel
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

    -- Create spec dropdown if it doesn't exist
    if not SummaryFrame.specDropdown then
        local dropdown = CreateFrame("Frame", "GSTSummarySpecDropdown", SummaryFrame.controlContainer,
            "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", SummaryFrame.controlContainer, "TOPLEFT", 0, -30)
        SummaryFrame.specDropdown = dropdown

        dropdown.initialize = function(self)
            local info = UIDropDownMenu_CreateInfo()
            local specs = {}

            -- Get all specs for current class
            for i = 1, GetNumSpecializationsForClassID(currentClassID) do
                local specID, specName = GetSpecializationInfoForClassID(currentClassID, i)
                if specID and specName then
                    table.insert(specs, { id = specID, name = specName })
                end
            end

            for _, spec in ipairs(specs) do
                info.text = spec.name
                info.value = spec.id
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    UIDropDownMenu_SetText(dropdown, self.text)
                    ShowSummary() -- Refresh the display
                end
                info.checked = (spec.id == UIDropDownMenu_GetSelectedValue(dropdown))
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    -- Set default spec if not set (use current spec)
    if not UIDropDownMenu_GetSelectedValue(SummaryFrame.specDropdown) then
        UIDropDownMenu_SetSelectedValue(SummaryFrame.specDropdown, currentSpecID)
        local _, specName = GetSpecializationInfoForClassID(currentClassID, currentSpec)
        UIDropDownMenu_SetText(SummaryFrame.specDropdown, specName)
    else
        -- Ensure the text is set for the currently selected value
        local selectedValue = UIDropDownMenu_GetSelectedValue(SummaryFrame.specDropdown)
        if selectedValue then
            for i = 1, GetNumSpecializationsForClassID(currentClassID) do
                local specID, specName = GetSpecializationInfoForClassID(currentClassID, i)
                if specID == selectedValue then
                    UIDropDownMenu_SetText(SummaryFrame.specDropdown, specName)
                    break
                end
            end
        end
    end
    UIDropDownMenu_JustifyText(SummaryFrame.specDropdown, "LEFT")

    -- Get selected spec ID
    local selectedSpecID = UIDropDownMenu_GetSelectedValue(SummaryFrame.specDropdown)

    -- Create bracket dropdown if it doesn't exist
    if not SummaryFrame.bracketDropdown then
        local dropdown = CreateFrame("Frame", "GSTSummaryBracketDropdown", SummaryFrame.controlContainer,
            "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", SummaryFrame.controlContainer, "TOPLEFT", 0, -60)
        SummaryFrame.bracketDropdown = dropdown

        dropdown.initialize = function(self)
            local info = UIDropDownMenu_CreateInfo()
            local brackets = { "pve", "2v2", "3v3" }

            -- Add class-specific shuffle brackets if they exist
            if GSTBracketNames then
                local _, _, currentClassID = UnitClass("player")
                local selectedSpecID = UIDropDownMenu_GetSelectedValue(SummaryFrame.specDropdown)

                if currentClassID and selectedSpecID then
                    local className = GST_BracketUtils.GetClassNameFromID(currentClassID)
                    local specName = GST_BracketUtils.GetSpecNameFromID(selectedSpecID)

                    if className and specName then
                        local shuffleBracket = "shuffle_" .. className .. "_" .. specName
                        for _, bracket in ipairs(GSTBracketNames) do
                            if bracket == shuffleBracket then
                                table.insert(brackets, bracket)
                                break
                            end
                        end
                    end
                end
            end

            for _, bracket in ipairs(brackets) do
                -- Display "Solo Shuffle" for shuffle brackets, otherwise use the bracket name
                local displayText = bracket:match("^shuffle_") and "Solo Shuffle" or string.upper(bracket)
                info.text = displayText
                info.value = bracket
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    UIDropDownMenu_SetText(dropdown, displayText)
                    ShowSummary() -- Refresh the display
                end
                info.checked = (bracket == UIDropDownMenu_GetSelectedValue(dropdown))
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    -- Check if current bracket selection is valid for the selected spec
    local currentBracket = UIDropDownMenu_GetSelectedValue(SummaryFrame.bracketDropdown)
    local validBrackets = { "pve", "2v2", "3v3" }
    local hasSoloShuffle = false

    -- Add class-specific shuffle brackets if they exist for the current spec
    if GSTBracketNames then
        local _, _, currentClassID = UnitClass("player")
        if currentClassID and selectedSpecID then
            local className = GST_BracketUtils.GetClassNameFromID(currentClassID)
            local specName = GST_BracketUtils.GetSpecNameFromID(selectedSpecID)

            if className and specName then
                local shuffleBracket = "shuffle_" .. className .. "_" .. specName
                for _, bracket in ipairs(GSTBracketNames) do
                    if bracket == shuffleBracket then
                        table.insert(validBrackets, bracket)
                        hasSoloShuffle = true
                        break
                    end
                end
            end
        end
    end

    -- Check if current bracket is still valid
    local bracketIsValid = false
    for _, validBracket in ipairs(validBrackets) do
        if validBracket == currentBracket then
            bracketIsValid = true
            break
        end
    end

    -- Set bracket selection based on UX preferences
    if not currentBracket or not bracketIsValid then
        local newBracket = "2v2" -- Default fallback

        -- If user was on solo shuffle and new spec has solo shuffle, try to maintain that
        if currentBracket and currentBracket:match("^shuffle_") and hasSoloShuffle then
            -- Find the solo shuffle bracket for the new spec
            for _, validBracket in ipairs(validBrackets) do
                if validBracket:match("^shuffle_") then
                    newBracket = validBracket
                    break
                end
            end
        end

        UIDropDownMenu_SetSelectedValue(SummaryFrame.bracketDropdown, newBracket)
        local displayText = newBracket:match("^shuffle_") and "Solo Shuffle" or string.upper(newBracket)
        UIDropDownMenu_SetText(SummaryFrame.bracketDropdown, displayText)
    end
    UIDropDownMenu_JustifyText(SummaryFrame.bracketDropdown, "LEFT")

    -- Create "Hide healthy slots" checkbox if it doesn't exist
    if not SummaryFrame.hideHealthyCheckbox then
        local checkbox = CreateFrame("CheckButton", nil, SummaryFrame.controlContainer, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", SummaryFrame.controlContainer, "TOPLEFT", 0, -95)
        checkbox:SetSize(20, 20)
        checkbox:SetChecked(false) -- Default to unchecked

        -- Add label
        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText("Hide healthy slots")
        label:SetTextColor(1, 1, 1, 1)

        -- Set up click handler to refresh display
        checkbox:SetScript("OnClick", function()
            ShowSummary() -- Refresh the display
        end)

        SummaryFrame.hideHealthyCheckbox = checkbox
    end

    -- Create "Show rank instead of %" checkbox if it doesn't exist
    if not SummaryFrame.showRankCheckbox then
        local checkbox = CreateFrame("CheckButton", nil, SummaryFrame.controlContainer, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", SummaryFrame.controlContainer, "TOPLEFT", 0, -120)
        checkbox:SetSize(20, 20)
        checkbox:SetChecked(false) -- Default to unchecked

        -- Add label
        local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
        label:SetText("Show rank instead of %")
        label:SetTextColor(1, 1, 1, 1)

        -- Set up click handler to refresh display
        checkbox:SetScript("OnClick", function()
            ShowSummary() -- Refresh the display
        end)

        SummaryFrame.showRankCheckbox = checkbox
    end

    local selectedBracket = UIDropDownMenu_GetSelectedValue(SummaryFrame.bracketDropdown)
    local hideHealthy = SummaryFrame.hideHealthyCheckbox:GetChecked()
    local showRank = SummaryFrame.showRankCheckbox:GetChecked()

    -- Clear existing slot frames
    if SummaryFrame.slotFrames then
        for _, slotFrame in pairs(SummaryFrame.slotFrames) do
            slotFrame:Hide()
            slotFrame:SetParent(nil)
        end
    end
    SummaryFrame.slotFrames = {}

    -- Define slot order and layout configuration
    local slotOrder = {
        -- Left column: HEAD, NECK, SHOULDER, BACK, CHEST, WRIST
        { 1,  2, 3, 15, 5,  9 },  -- Left column slots
        -- Right column: HANDS, WAIST, LEGS, FEET, RING1, RING2
        { 10, 6, 7, 8,  11, 12 }, -- Right column slots
        -- Bottom row: TRINKET_1, TRINKET_2
        { 13, 14 },               -- Trinkets row
        -- Weapons row: MAIN_HAND, OFF_HAND
        { 16, 17 }                -- Weapons row
    }

    -- Layout configuration
    local layout = {
        startY = -172,      -- Starting Y position (adjusted for spec dropdown + additional checkbox + 4px margin)
        slotHeight = 48,    -- Height of each slot frame (matches icon size)
        slotSpacing = 8,    -- Spacing between slots (increased for better visual separation)
        columnWidth = 94,   -- Width of each slot (4px wider)
        leftColumnX = 8,    -- X position for left column (8px margin)
        rightColumnX = 112, -- X position for right column (8px + 94px + 10px gap)
        rowSpacing = 15     -- Extra spacing between different row types (increased)
    }



    -- Use shared slot mapping from ItemUtils

    -- Create slot frames with dynamic flow layout
    local currentY = { layout.startY, layout.startY } -- Track Y position for left and right columns

    for rowIndex, rowSlots in ipairs(slotOrder) do
        local visibleSlotsInRow = {}

        -- First pass: determine which slots in this row should be visible
        for _, slotID in ipairs(rowSlots) do
            local isHealthy = IsSlotHealthy(slotID, selectedSpecID, selectedBracket)
            if not (hideHealthy and isHealthy) then
                table.insert(visibleSlotsInRow, slotID)
            end
        end

        -- Second pass: position the visible slots
        for index, slotID in ipairs(visibleSlotsInRow) do
            local slotFrame = CreateFrame("Frame", nil, SummaryFrame, "BackdropTemplate")
            slotFrame:SetSize(layout.columnWidth, layout.slotHeight)

            -- Calculate position based on row type and visible slot index
            local xPos, yPos

            if rowIndex <= 2 then
                -- Column-based layout for equipment slots (rows 1-2)
                local columnIndex = ((rowIndex - 1) % 2) + 1
                xPos = (columnIndex == 1) and layout.leftColumnX or layout.rightColumnX
                yPos = currentY[columnIndex]
                currentY[columnIndex] = currentY[columnIndex] - layout.slotHeight - layout.slotSpacing
            else
                -- Horizontal layout for trinkets and weapons (rows 3-4)
                local slotsPerRow = #visibleSlotsInRow
                local totalWidth = slotsPerRow * layout.columnWidth + (slotsPerRow - 1) * layout.slotSpacing
                local startX = (214 - totalWidth) / 2 -- Center horizontally in the 214px wide frame

                xPos = startX + (index - 1) * (layout.columnWidth + layout.slotSpacing)
                yPos = math.min(currentY[1], currentY[2]) - layout.rowSpacing

                -- Update both column Y positions for the next row
                if index == #visibleSlotsInRow then
                    currentY[1] = yPos - layout.slotHeight - layout.rowSpacing
                    currentY[2] = yPos - layout.slotHeight - layout.rowSpacing
                end
            end

            slotFrame:SetPoint("TOPLEFT", SummaryFrame, "TOPLEFT", xPos, yPos)
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
                    local gearInfo = GetGearPopularity(selectedSpecID, slotType, itemID, selectedBracket, slotID,
                        itemInfo and itemInfo.statsShort)
                    if gearInfo then
                        gearPercent = gearInfo.percent
                    else
                        -- Item not found in database = 0% popularity
                        gearPercent = 0
                    end
                end

                -- Get enchant popularity
                if enchantID and slotType then
                    local enchantInfo = GetEnchantPopularity(selectedSpecID, slotType, enchantID, selectedBracket)
                    if enchantInfo then
                        enchantPercent = enchantInfo.percent
                    end
                end
            end

            -- Create item icon with border (sized to fit slot frame)
            local iconFrame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
            iconFrame:SetSize(48, 48)
            iconFrame:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 0, 0)
            iconFrame:SetBackdrop({
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            iconFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

            local icon = iconFrame:CreateTexture(nil, "ARTWORK")
            icon:SetSize(46, 46)
            icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)

            if itemInfo and itemInfo.texture then
                icon:SetTexture(itemInfo.texture)
                iconFrame:SetBackdropBorderColor(0.8, 0.8, 0.8, 1) -- Brighter border for equipped items
            else
                -- Use a default empty slot icon
                icon:SetTexture("Interface\\Buttons\\UI-EmptySlot")
                icon:SetAlpha(0.5)                                   -- Make empty slots more transparent
                iconFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5) -- Dimmer border for empty slots
            end

            -- Add item tooltip functionality to the icon (same as gear slot)
            iconFrame:EnableMouse(true)
            iconFrame:SetScript("OnEnter", function(self)
                if itemInfo and itemInfo.link then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(itemInfo.link)
                    GameTooltip:Show()
                elseif GST_ItemUtils.SLOT_NAMES[slotID] then
                    -- Show empty slot tooltip
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:ClearLines()
                    GameTooltip:AddLine(GST_ItemUtils.SLOT_NAMES[slotID], 1, 1, 1)
                    GameTooltip:AddLine("Empty slot", 0.8, 0.8, 0.8)
                    GameTooltip:Show()
                end
            end)

            iconFrame:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            -- Slot name removed - icon and tooltip provide sufficient identification



            -- Create gear percentage/rank text (top-aligned to avoid icon)
            if gearPercent then
                local gearText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                gearText:SetPoint("TOPRIGHT", slotFrame, "TOPRIGHT", -5, -10)

                local displayValue
                local displayColor

                if showRank then
                    -- Show rank instead of percentage
                    local gearRank = GST_BracketUtils.GetGearRank(slotID, selectedSpecID, selectedBracket, itemID,
                        itemInfo and itemInfo.statsShort)
                    if gearRank then
                        displayValue = string.format("#%d", gearRank)
                        -- Color based on rank (lower is better)
                        if gearRank == 1 then
                            displayColor = { 0.2, 1, 0.2, 1 }   -- Green for #1
                        elseif gearRank <= 3 then
                            displayColor = { 1, 1, 0.2, 1 }     -- Yellow for #2-3
                        elseif gearRank <= 5 then
                            displayColor = { 1, 0.6, 0.2, 1 }   -- Orange for #4-5
                        else
                            displayColor = { 0.8, 0.2, 0.2, 1 } -- Red for #6+
                        end
                    else
                        displayValue = "??"
                        displayColor = { 0.8, 0.2, 0.2, 1 } -- Red for no data
                    end
                else
                    -- Show percentage
                    displayValue = string.format("%.0f%%", gearPercent)
                    -- Color based on popularity
                    if gearPercent >= 50 then
                        displayColor = { 0.2, 1, 0.2, 1 }   -- Green
                    elseif gearPercent >= 20 then
                        displayColor = { 1, 1, 0.2, 1 }     -- Yellow
                    elseif gearPercent > 0 then
                        displayColor = { 1, 0.6, 0.2, 1 }   -- Orange
                    else
                        displayColor = { 0.8, 0.2, 0.2, 1 } -- Red for 0%
                    end
                end

                gearText:SetText(displayValue)
                gearText:SetJustifyH("RIGHT")
                gearText:SetTextColor(unpack(displayColor))
            end

            -- Only show enchant indicators if enchant data exists for this slot
            local hasEnchantData = slotType and HasEnchantDataForSlot(selectedSpecID, slotType, selectedBracket)

            if hasEnchantData then
                if enchantPercent then
                    local enchantText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    enchantText:SetPoint("TOPRIGHT", slotFrame, "TOPRIGHT", -5, -30)

                    local displayValue
                    local displayColor

                    if showRank then
                        -- Show rank instead of percentage
                        local enchantRank = GST_BracketUtils.GetEnchantRank(selectedSpecID, slotType, selectedBracket,
                            enchantID)
                        if enchantRank then
                            displayValue = string.format("#%d", enchantRank)
                            -- Color based on rank (lower is better)
                            if enchantRank == 1 then
                                displayColor = { 0.2, 1, 0.2, 1 }   -- Green for #1
                            elseif enchantRank <= 3 then
                                displayColor = { 1, 1, 0.2, 1 }     -- Yellow for #2-3
                            elseif enchantRank <= 5 then
                                displayColor = { 1, 0.6, 0.2, 1 }   -- Orange for #4-5
                            else
                                displayColor = { 0.8, 0.2, 0.2, 1 } -- Red for #6+
                            end
                        else
                            displayValue = "??"
                            displayColor = { 0.8, 0.2, 0.2, 1 } -- Red for no data
                        end
                    else
                        -- Show percentage
                        displayValue = string.format("%.0f%%", enchantPercent)
                        -- Color based on popularity
                        if enchantPercent >= 50 then
                            displayColor = { 0.2, 1, 0.2, 1 } -- Green
                        elseif enchantPercent >= 20 then
                            displayColor = { 1, 1, 0.2, 1 }   -- Yellow
                        else
                            displayColor = { 1, 0.6, 0.2, 1 } -- Orange
                        end
                    end

                    enchantText:SetText(displayValue)
                    enchantText:SetJustifyH("RIGHT")
                    enchantText:SetTextColor(unpack(displayColor))
                elseif hasItem then
                    -- Show "Missing Enchant" only if item exists but no enchant AND enchant data exists for this slot
                    local noEnchantText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    noEnchantText:SetPoint("TOPRIGHT", slotFrame, "TOPRIGHT", -5, -30)

                    if showRank then
                        noEnchantText:SetText("??")
                    else
                        noEnchantText:SetText("0%")
                    end
                    noEnchantText:SetTextColor(0.8, 0.2, 0.2, 1) -- Red
                    noEnchantText:SetJustifyH("RIGHT")
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
                    GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
                    GameTooltip:AddLine("Top Gear Choices:", 0.2, 1, 0.2)

                    -- Find items for this slot from the new database
                    local slotItems = SlotGearIndexes.LookupBySlotSpecBracket(slotID, selectedSpecID, selectedBracket)

                    -- Sort by rank
                    table.sort(slotItems, function(a, b) return a.rank < b.rank end)

                    -- Check if player's equipped item matches any item in the distribution
                    local playerItemMatchesDistribution = false
                    if tooltipHasItem and tooltipItemID then
                        for _, item in ipairs(slotItems) do
                            local itemMatches = tooltipItemID == item.itemId
                            local statsMatch = tooltipItemInfo and tooltipItemInfo.statsShort and
                                item.statsShort and tooltipItemInfo.statsShort == item.statsShort
                            if itemMatches and (not item.statsShort or item.statsShort == "" or statsMatch) then
                                playerItemMatchesDistribution = true
                                break
                            end
                        end
                    end

                    -- Show top 5 items
                    for i = 1, math.min(5, #slotItems) do
                        local item = slotItems[i]

                        -- Enhanced matching: compare both item ID and stats
                        local itemMatches = tooltipItemID and tooltipItemID == item.itemId
                        local statsMatch = tooltipItemInfo and tooltipItemInfo.statsShort and
                            item.statsShort and tooltipItemInfo.statsShort == item.statsShort
                        local isEquipped = itemMatches and (not item.statsShort or item.statsShort == "" or statsMatch)

                        local color = isEquipped and "|cFF00FF00" or "|cFFFFFFFF"
                        local bisText = item.rank == 1 and " (BiS)" or ""

                        local statsDisplay = item.statsShort and item.statsShort ~= "" and
                            (" (" .. item.statsShortPretty .. ")") or
                            ""
                        GameTooltip:AddLine(
                            string.format("%s%.1f%% - %s%s%s", color, item.percent, item.itemName, statsDisplay, bisText),
                            1,
                            1, 1)
                    end

                    -- Show player's equipped item only if it doesn't match any item in the distribution
                    if tooltipHasItem and not playerItemMatchesDistribution then
                        GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer
                        local statsDisplay = tooltipItemInfo.statsShort and tooltipItemInfo.statsShort ~= "" and
                            tooltipItemInfo.statsShortPretty and (" (" .. tooltipItemInfo.statsShortPretty .. ")") or ""
                        GameTooltip:AddLine("You: " .. tooltipItemInfo.link .. statsDisplay, 1, 1, 0) -- Yellow color for equipped item
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
                        if enchant.specId == selectedSpecID and
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
                                string.format("%s%.1f%% - %s", color, ench.percent, ench.enchantName), 1,
                                1,
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
    end

    -- Automatically resize frame to fit content
    local finalY = math.min(currentY[1], currentY[2])
    local contentHeight = math.abs(finalY) + 80         -- Add padding for legend and controls
    local newFrameHeight = math.max(contentHeight, 300) -- Minimum height
    SummaryFrame:SetHeight(newFrameHeight)

    if not SummaryFrame.profileCount then
        local profileCount = SummaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        profileCount:SetPoint("BOTTOM", SummaryFrame, "BOTTOM", 0, 8)
        profileCount:SetTextColor(0.7, 0.7, 0.7, 1)
        SummaryFrame.profileCount = profileCount
    end

    -- Update profile count text (clear first to prevent overlap)
    if SummaryFrame.profileCount then
        SummaryFrame.profileCount:SetText("") -- Clear existing text first
        local profileCount = GetProfileCount(selectedSpecID, selectedBracket)
        if profileCount then
            SummaryFrame.profileCount:SetText(string.format("%d profiles considered", profileCount))
        else
            SummaryFrame.profileCount:SetText("Profile count unavailable")
        end
    end

    SummaryFrame:Show()
end

function GST_Summary.SlashCmd(arg1)
    ShowSummary()
end

function GST_Summary.RefreshIfVisible()
    if SummaryFrame and SummaryFrame:IsShown() then
        ShowSummary()
    end
end
