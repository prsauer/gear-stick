GST_Enchants = {}



-- Helper function to extract enchant ID from item link
local function GetEnchantIDFromLink(itemLink)
    if not itemLink then return nil end

    -- Item link format: |cffffffff|Hitem:itemID:enchantID:gemID1:gemID2:gemID3:gemID4:suffixID:uniqueID:linkLevel:reforgeID:upgradeTypeID:instanceDifficultyID:numBonusIDs:bonusID1:bonusID2:...|h[name]|h|r
    -- We want to extract the enchantID (second number after itemID)
    local enchantID = itemLink:match("|Hitem:%d+:(%d+):")
    if enchantID and enchantID ~= "0" then
        return tonumber(enchantID)
    end
    return nil
end

-- Helper function to check if player has any enchant in a specific slot
local function HasEnchantInSlot(slotType)
    local slotMapping = {
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

    local slotId = slotMapping[slotType]
    if slotId then
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            local itemEnchantID = GetEnchantIDFromLink(itemLink)
            if itemEnchantID then
                return true
            end
        end

        -- Special handling for rings (check both finger slots)
        if slotType == "FINGER_1" or slotType == "FINGER_2" then
            for ringSlot = 11, 12 do
                local ringLink = GetInventoryItemLink("player", ringSlot)
                if ringLink then
                    local ringEnchantID = GetEnchantIDFromLink(ringLink)
                    if ringEnchantID then
                        return true
                    end
                end
            end
        end

        -- Special handling for trinkets (check both trinket slots)
        if slotType == "TRINKET_1" or slotType == "TRINKET_2" then
            for trinketSlot = 13, 14 do
                local trinketLink = GetInventoryItemLink("player", trinketSlot)
                if trinketLink then
                    local trinketEnchantID = GetEnchantIDFromLink(trinketLink)
                    if trinketEnchantID then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function ListEnchants()
    -- Create the main frame if it doesn't exist
    if not EnchantListFrame then
        local frame = CreateFrame("Frame", "EnchantListFrame", UIParent, "BackdropTemplate")
        frame:SetSize(800, 650)
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
        frame.title:SetText("Popular Enchantments")

        -- Create the scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 8, -60)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 28)

        -- Create the content frame
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(740, 50)
        scrollFrame:SetScrollChild(content)
        frame.content = content

        -- Add help text at bottom
        local helpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        helpText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
        helpText:SetText("Shows the most popular enchantments for your spec by bracket and slot")
        helpText:SetTextColor(0.5, 0.5, 0.5, 1)

        -- Add Summary button
        local summaryButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        summaryButton:SetSize(80, 24)
        summaryButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -8)
        summaryButton:SetText("Summary")
        summaryButton:SetScript("OnClick", function()
            if GST_Summary and GST_Summary.SlashCmd then
                GST_Summary.SlashCmd()
                frame:Hide() -- Close the enchants panel
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
        tinsert(UISpecialFrames, "EnchantListFrame")

        EnchantListFrame = frame
    end

    -- Get current spec and class info
    local currentSpec = GetSpecialization()
    local currentSpecID = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or nil
    local _, _, currentClassID = UnitClass("player")

    if not currentSpecID then
        print("No specialization selected")
        return
    end

    -- Create the spec dropdown if it doesn't exist
    if not EnchantListFrame.specDropdown then
        local dropdown = CreateFrame("Frame", "GSTEnchantSpecDropdown", EnchantListFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", EnchantListFrame.title, "TOPRIGHT", 20, -2)
        EnchantListFrame.specDropdown = dropdown

        -- Initialize the dropdown
        dropdown.initialize = function(self)
            local info = UIDropDownMenu_CreateInfo()
            -- Get all specs for current class
            for i = 1, GetNumSpecializationsForClassID(currentClassID) do
                local specID, specName = GetSpecializationInfoForClassID(currentClassID, i)
                info.text = specName
                info.value = specID
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    UIDropDownMenu_SetText(dropdown, specName)
                    ListEnchants() -- Refresh the list
                end
                info.checked = (specID == UIDropDownMenu_GetSelectedValue(dropdown))
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    -- Set the initial selected value if not already set
    if not UIDropDownMenu_GetSelectedValue(EnchantListFrame.specDropdown) then
        UIDropDownMenu_SetSelectedValue(EnchantListFrame.specDropdown, currentSpecID)
        -- Get the spec name and set it
        local _, specName = GetSpecializationInfoForClassID(currentClassID, currentSpec)
        UIDropDownMenu_SetText(EnchantListFrame.specDropdown, specName)
    end
    UIDropDownMenu_SetWidth(EnchantListFrame.specDropdown, 120)
    UIDropDownMenu_JustifyText(EnchantListFrame.specDropdown, "LEFT")

    -- Create the bracket dropdown if it doesn't exist
    if not EnchantListFrame.bracketDropdown then
        local dropdown = CreateFrame("Frame", "GSTEnchantBracketDropdown", EnchantListFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", EnchantListFrame.specDropdown, "TOPRIGHT", 0, 0)
        EnchantListFrame.bracketDropdown = dropdown

        -- Initialize the dropdown
        dropdown.initialize = function(self)
            local info = UIDropDownMenu_CreateInfo()
            local availableBrackets = GST_BracketUtils.GetAvailableBrackets(currentClassID,
                UIDropDownMenu_GetSelectedValue(EnchantListFrame.specDropdown) or currentSpecID)

            for _, bracket in ipairs(availableBrackets) do
                -- Display "Solo Shuffle" for shuffle brackets, otherwise use the bracket name
                local displayText = bracket:match("^shuffle_") and "Solo Shuffle" or string.upper(bracket)
                info.text = displayText
                info.value = bracket
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    UIDropDownMenu_SetText(dropdown, displayText)
                    ListEnchants() -- Refresh the list
                end
                info.checked = (bracket == UIDropDownMenu_GetSelectedValue(dropdown))
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    -- Set the initial bracket selection if not already set
    if not UIDropDownMenu_GetSelectedValue(EnchantListFrame.bracketDropdown) then
        UIDropDownMenu_SetSelectedValue(EnchantListFrame.bracketDropdown, "2v2")
        UIDropDownMenu_SetText(EnchantListFrame.bracketDropdown, "2V2")
    end
    UIDropDownMenu_SetWidth(EnchantListFrame.bracketDropdown, 80)
    UIDropDownMenu_JustifyText(EnchantListFrame.bracketDropdown, "LEFT")

    -- Clear existing content
    for _, child in pairs({ EnchantListFrame.content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Filter enchants for current class, selected spec, and selected bracket
    local selectedSpecID = UIDropDownMenu_GetSelectedValue(EnchantListFrame.specDropdown)
    local selectedBracket = UIDropDownMenu_GetSelectedValue(EnchantListFrame.bracketDropdown)
    local slotEnchants = {}

    for _, enchant in ipairs(GSTEnchantsDb) do
        if enchant.specId == selectedSpecID and enchant.bracket == selectedBracket then
            local slotType = enchant.slotType or "Unknown"

            if not slotEnchants[slotType] then
                slotEnchants[slotType] = {}
            end
            table.insert(slotEnchants[slotType], enchant)
        end
    end

    -- Sort slots alphabetically
    local sortedSlots = {}
    for slotType in pairs(slotEnchants) do
        table.insert(sortedSlots, slotType)
    end
    table.sort(sortedSlots)

    -- Create headers and data for each slot
    local yOffset = 0
    for _, slotType in ipairs(sortedSlots) do
        local enchantList = slotEnchants[slotType]

        -- Sort enchants by rank
        table.sort(enchantList, function(a, b)
            return (a.rank or 0) < (b.rank or 0)
        end)

        -- Check if player has any enchant in this slot and find its rank/percentage
        local hasAnyEnchant = HasEnchantInSlot(slotType)
        local playerEnchantInfo = nil

        if hasAnyEnchant then
            -- Find which enchant the player has and its rank/percentage
            for _, enchant in ipairs(enchantList) do
                local playerHasThisEnchant = false

                if slotType == "FINGER_1" or slotType == "FINGER_2" then
                    -- For rings, check both finger slots
                    for ringSlot = 11, 12 do
                        local ringLink = GetInventoryItemLink("player", ringSlot)
                        if ringLink then
                            local ringEnchantID = GetEnchantIDFromLink(ringLink)
                            if ringEnchantID and ringEnchantID == enchant.enchantId then
                                playerHasThisEnchant = true
                                break
                            end
                        end
                    end
                elseif slotType == "TRINKET_1" or slotType == "TRINKET_2" then
                    -- For trinkets, check both trinket slots
                    for trinketSlot = 13, 14 do
                        local trinketLink = GetInventoryItemLink("player", trinketSlot)
                        if trinketLink then
                            local trinketEnchantID = GetEnchantIDFromLink(trinketLink)
                            if trinketEnchantID and trinketEnchantID == enchant.enchantId then
                                playerHasThisEnchant = true
                                break
                            end
                        end
                    end
                else
                    -- For all other slots, check the specific slot
                    local slotMapping = {
                        ["HEAD"] = 1,
                        ["NECK"] = 2,
                        ["SHOULDER"] = 3,
                        ["CHEST"] = 5,
                        ["WAIST"] = 6,
                        ["LEGS"] = 7,
                        ["FEET"] = 8,
                        ["WRIST"] = 9,
                        ["HANDS"] = 10,
                        ["BACK"] = 15,
                        ["MAIN_HAND"] = 16,
                        ["OFF_HAND"] = 17
                    }
                    local slotId = slotMapping[slotType]
                    if slotId then
                        local itemLink = GetInventoryItemLink("player", slotId)
                        if itemLink then
                            local itemEnchantID = GetEnchantIDFromLink(itemLink)
                            if itemEnchantID and itemEnchantID == enchant.enchantId then
                                playerHasThisEnchant = true
                            end
                        end
                    end
                end

                if playerHasThisEnchant then
                    playerEnchantInfo = {
                        rank = enchant.rank or 0,
                        percent = enchant.percent or 0
                    }
                    break
                end
            end
        end

        -- Create slot header
        local slotHeaderFrame = CreateFrame("Frame", nil, EnchantListFrame.content)
        slotHeaderFrame:SetSize(720, 20)
        slotHeaderFrame:SetPoint("TOPLEFT", EnchantListFrame.content, "TOPLEFT", 0, -yOffset)

        -- Add slot header background - color based on enchant status
        slotHeaderFrame.bg = slotHeaderFrame:CreateTexture(nil, "BACKGROUND")
        slotHeaderFrame.bg:SetAllPoints()
        if hasAnyEnchant then
            slotHeaderFrame.bg:SetColorTexture(0.2, 0.4, 0.8, 0.8) -- Normal blue
        else
            slotHeaderFrame.bg:SetColorTexture(0.8, 0.2, 0.2, 0.8) -- Warning red
        end

        -- Add warning icon and slot name text
        slotHeaderFrame.text = slotHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        slotHeaderFrame.text:SetPoint("LEFT", slotHeaderFrame, "LEFT", 8, 0)

        local slotText = slotType
        if not hasAnyEnchant then
            slotText = "WARNING " .. slotType .. " NO ENCHANT"
        elseif playerEnchantInfo then
            slotText = slotType ..
                " (#" .. playerEnchantInfo.rank .. " - " .. string.format("%.1f", playerEnchantInfo.percent) .. "%)"
        end
        slotHeaderFrame.text:SetText(slotText)
        slotHeaderFrame.text:SetTextColor(1, 1, 1, 1)

        yOffset = yOffset + 25

        -- Add enchant entries
        for _, enchant in ipairs(enchantList) do
            local enchantFrame = CreateFrame("Frame", nil, EnchantListFrame.content)
            enchantFrame:SetSize(680, 18)
            enchantFrame:SetPoint("TOPLEFT", EnchantListFrame.content, "TOPLEFT", 20, -yOffset)

            -- Check if player has this enchant on appropriate slot
            local hasEnchant = false
            local slotId = nil

            -- Map slot types to inventory slot IDs
            local slotMapping = {
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

            -- Check for this specific enchant in the appropriate slot(s)
            if slotType == "FINGER_1" or slotType == "FINGER_2" then
                -- For rings, check both finger slots
                for ringSlot = 11, 12 do
                    local ringLink = GetInventoryItemLink("player", ringSlot)
                    if ringLink then
                        local ringEnchantID = GetEnchantIDFromLink(ringLink)
                        if ringEnchantID and ringEnchantID == enchant.enchantId then
                            hasEnchant = true
                            break
                        end
                    end
                end
            elseif slotType == "TRINKET_1" or slotType == "TRINKET_2" then
                -- For trinkets, check both trinket slots
                for trinketSlot = 13, 14 do
                    local trinketLink = GetInventoryItemLink("player", trinketSlot)
                    if trinketLink then
                        local trinketEnchantID = GetEnchantIDFromLink(trinketLink)
                        if trinketEnchantID and trinketEnchantID == enchant.enchantId then
                            hasEnchant = true
                            break
                        end
                    end
                end
            else
                -- For all other slots, check the specific slot
                slotId = slotMapping[slotType]
                if slotId then
                    local itemLink = GetInventoryItemLink("player", slotId)
                    if itemLink then
                        local itemEnchantID = GetEnchantIDFromLink(itemLink)
                        if itemEnchantID and itemEnchantID == enchant.enchantId then
                            hasEnchant = true
                        end
                    end
                end
            end

            -- Add checkmark if player has this enchant
            local checkText = enchantFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            checkText:SetPoint("LEFT", enchantFrame, "LEFT", 5, 0)
            if hasEnchant then
                checkText:SetText("OK")
                checkText:SetTextColor(0.2, 1, 0.2, 1) -- Green checkmark
            else
                checkText:SetText("")
            end
            checkText:SetWidth(18)

            -- Add rank text
            local rankText = enchantFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rankText:SetPoint("LEFT", checkText, "RIGHT", 5, 0)
            rankText:SetText(string.format("#%d", enchant.rank or 0))
            rankText:SetTextColor(0.8, 0.8, 0.8, 1)
            rankText:SetWidth(30)
            rankText:SetJustifyH("RIGHT")

            -- Add percentage text
            local percentText = enchantFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            percentText:SetPoint("LEFT", rankText, "RIGHT", 10, 0)
            local percentValue = enchant.percent or 0
            percentText:SetText(string.format("%.1f%%", percentValue))

            -- Color based on percentage
            if percentValue >= 50 then
                percentText:SetTextColor(0.2, 1, 0.2, 1) -- Green
            elseif percentValue >= 20 then
                percentText:SetTextColor(1, 1, 0.2, 1)   -- Yellow
            else
                percentText:SetTextColor(1, 0.6, 0.2, 1) -- Orange
            end
            percentText:SetWidth(50)
            percentText:SetJustifyH("RIGHT")

            -- Add enchant name text
            local nameText = enchantFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameText:SetPoint("LEFT", percentText, "RIGHT", 15, 0)
            nameText:SetText(enchant.enchantName or "Unknown Enchant")
            nameText:SetTextColor(0.9, 0.9, 1, 1)
            nameText:SetWidth(480)
            nameText:SetJustifyH("LEFT")

            -- Add enchant ID for reference (smaller text)
            local idText = enchantFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            idText:SetPoint("RIGHT", enchantFrame, "RIGHT", -5, 0)
            idText:SetText(string.format("(ID: %d)", enchant.enchantId or 0))
            idText:SetTextColor(0.5, 0.5, 0.5, 1)

            yOffset = yOffset + 20
        end

        yOffset = yOffset + 5 -- Extra space between slots
    end

    -- Adjust content height based on number of entries
    EnchantListFrame.content:SetHeight(math.max(yOffset, 50))

    -- Show the frame
    EnchantListFrame:Show()
end

function GST_Enchants.SlashCmd(arg1)
    ListEnchants()
end
