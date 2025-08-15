GST_Summary = {}

-- Helper function to get item ID from link
local function GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    local itemID = itemLink:match("|Hitem:(%d+):")
    return itemID and tonumber(itemID) or nil
end

-- Helper function to extract enchant ID from item link
local function GetEnchantIDFromLink(itemLink)
    if not itemLink then return nil end
    local enchantID = itemLink:match("|Hitem:%d+:(%d+):")
    if enchantID and enchantID ~= "0" then
        return tonumber(enchantID)
    end
    return nil
end

-- Helper function to get gear popularity for a specific slot and item
local function GetGearPopularity(specId, slotType, itemID, bracket)
    local gearDbs = {
        ["pve"] = usageDbPvE,
        ["2v2"] = usageDb2v2,
        ["3v3"] = usageDb3v3
    }
    
    local db = gearDbs[bracket]
    if not db then return nil end
    
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
    
    for key, data in pairs(db) do
        if type(key) == "string" and string.find(key, keyPrefix, 1, true) == 1 then
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
        frame:SetSize(400, 620)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        
        -- Set up the backdrop
        frame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.9)
        frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
        
        -- Add title
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOPLEFT", 8, -8)
        frame.title:SetText("Gear & Enchant Summary")
        
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
        dropdown:SetPoint("TOPLEFT", SummaryFrame.title, "TOPRIGHT", 20, -2)
        SummaryFrame.bracketDropdown = dropdown

        dropdown.initialize = function(self)
            local info = UIDropDownMenu_CreateInfo()
            local brackets = {"pve", "2v2", "3v3"}
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
    
    -- Define slot positions to mimic character panel (2 columns + weapons below)
    local slotPositions = {
        -- Left column
        [1] = {x = 40, y = -70},   -- HEAD
        [2] = {x = 40, y = -125},  -- NECK
        [3] = {x = 40, y = -180},  -- SHOULDER
        [15] = {x = 40, y = -235}, -- BACK
        [5] = {x = 40, y = -290},  -- CHEST
        [6] = {x = 40, y = -345},  -- WAIST
        [7] = {x = 40, y = -400},  -- LEGS
        [8] = {x = 40, y = -455},  -- FEET
        
        -- Right column
        [9] = {x = 220, y = -70},  -- WRIST
        [10] = {x = 220, y = -125}, -- HANDS
        [11] = {x = 220, y = -180}, -- FINGER_1
        [12] = {x = 220, y = -235}, -- FINGER_2
        [13] = {x = 220, y = -290}, -- TRINKET_1
        [14] = {x = 220, y = -345}, -- TRINKET_2
        
        -- Weapons below (centered)
        [16] = {x = 40, y = -520},  -- MAIN_HAND
        [17] = {x = 220, y = -520}  -- OFF_HAND
    }
    
    -- Slot names for display
    local slotNames = {
        [1] = "HEAD", [2] = "NECK", [3] = "SHOULDER", [5] = "CHEST",
        [6] = "WAIST", [7] = "LEGS", [8] = "FEET", [9] = "WRIST",
        [10] = "HANDS", [11] = "RING1", [12] = "RING2", [13] = "TRINKET1",
        [14] = "TRINKET2", [15] = "BACK", [16] = "MAIN", [17] = "OFF"
    }
    
    -- Map inventory slots to enchant slot types
    local slotTypeMapping = {
        [1] = "HEAD", [2] = "NECK", [3] = "SHOULDER", [5] = "CHEST",
        [6] = "WAIST", [7] = "LEGS", [8] = "FEET", [9] = "WRIST",
        [10] = "HANDS", [11] = "FINGER_1", [12] = "FINGER_2", 
        [13] = "TRINKET_1", [14] = "TRINKET_2", [15] = "BACK", 
        [16] = "MAIN_HAND", [17] = "OFF_HAND"
    }
    
    -- Create slot frames
    for slotID, position in pairs(slotPositions) do
        local slotFrame = CreateFrame("Frame", nil, SummaryFrame, "BackdropTemplate")
        slotFrame:SetSize(120, 70)
        slotFrame:SetPoint("TOPLEFT", SummaryFrame, "TOPLEFT", position.x, position.y)
        slotFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        slotFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        slotFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        -- Get item info for this slot
        local itemLink = GetInventoryItemLink("player", slotID)
        local itemTexture = GetInventoryItemTexture("player", slotID)
        local gearPercent, enchantPercent = nil, nil
        local hasItem = itemLink ~= nil
        
        if hasItem then
            local itemID = GetItemIDFromLink(itemLink)
            local enchantID = GetEnchantIDFromLink(itemLink)
            local slotType = slotTypeMapping[slotID]
            
            -- Get gear popularity
            if itemID then
                local gearInfo = GetGearPopularity(currentSpecID, slotType, itemID, selectedBracket)
                if gearInfo then
                    gearPercent = gearInfo.percent
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
        label:SetText(slotNames[slotID] or "")
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
                gearText:SetTextColor(0.2, 1, 0.2, 1) -- Green
            elseif gearPercent >= 20 then
                gearText:SetTextColor(1, 1, 0.2, 1) -- Yellow
            else
                gearText:SetTextColor(1, 0.6, 0.2, 1) -- Orange
            end
        end
        
        -- Create enchant percentage text
        if enchantPercent then
            local enchantText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            enchantText:SetPoint("CENTER", slotFrame, "CENTER", 0, -10)
            enchantText:SetText(string.format("E:%.0f%%", enchantPercent))
            enchantText:SetJustifyH("CENTER")
            
            -- Color based on popularity
            if enchantPercent >= 50 then
                enchantText:SetTextColor(0.2, 1, 0.2, 1) -- Green
            elseif enchantPercent >= 20 then
                enchantText:SetTextColor(1, 1, 0.2, 1) -- Yellow
            else
                enchantText:SetTextColor(1, 0.6, 0.2, 1) -- Orange
            end
        elseif hasItem then
            -- Show "No Enchant" if item exists but no enchant
            local noEnchantText = slotFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noEnchantText:SetPoint("CENTER", slotFrame, "CENTER", 0, -10)
            noEnchantText:SetText("E:--")
            noEnchantText:SetTextColor(0.8, 0.2, 0.2, 1) -- Red
            noEnchantText:SetJustifyH("CENTER")
        end
        
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
