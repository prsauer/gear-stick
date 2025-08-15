GST_Enchants = {}

local function ListEnchants()
    -- Create the main frame if it doesn't exist
    if not EnchantListFrame then
        local frame = CreateFrame("Frame", "EnchantListFrame", UIParent, "BackdropTemplate")
        frame:SetSize(800, 600)
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
            local brackets = {"pve", "2v2", "3v3"}
            for _, bracket in ipairs(brackets) do
                info.text = string.upper(bracket)
                info.value = bracket
                info.func = function(self)
                    UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                    UIDropDownMenu_SetText(dropdown, string.upper(self.value))
                    ListEnchants() -- Refresh the list
                end
                info.checked = (bracket == UIDropDownMenu_GetSelectedValue(dropdown))
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    -- Set the initial bracket selection if not already set
    if not UIDropDownMenu_GetSelectedValue(EnchantListFrame.bracketDropdown) then
        UIDropDownMenu_SetSelectedValue(EnchantListFrame.bracketDropdown, "pve")
        UIDropDownMenu_SetText(EnchantListFrame.bracketDropdown, "PVE")
    end
    UIDropDownMenu_SetWidth(EnchantListFrame.bracketDropdown, 80)
    UIDropDownMenu_JustifyText(EnchantListFrame.bracketDropdown, "LEFT")

    -- Clear existing content
    for _, child in pairs({EnchantListFrame.content:GetChildren()}) do
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
        
        -- Create slot header
        local slotHeaderFrame = CreateFrame("Frame", nil, EnchantListFrame.content)
        slotHeaderFrame:SetSize(720, 25)
        slotHeaderFrame:SetPoint("TOPLEFT", EnchantListFrame.content, "TOPLEFT", 0, -yOffset)
        
        -- Add slot header background
        slotHeaderFrame.bg = slotHeaderFrame:CreateTexture(nil, "BACKGROUND")
        slotHeaderFrame.bg:SetAllPoints()
        slotHeaderFrame.bg:SetColorTexture(0.2, 0.4, 0.8, 0.8)
        
        -- Add slot name text
        slotHeaderFrame.text = slotHeaderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slotHeaderFrame.text:SetPoint("LEFT", slotHeaderFrame, "LEFT", 10, 0)
        slotHeaderFrame.text:SetText(slotType)
        slotHeaderFrame.text:SetTextColor(1, 1, 1, 1)
        
        yOffset = yOffset + 30
        
        -- Add enchant entries
        for _, enchant in ipairs(enchantList) do
            local enchantFrame = CreateFrame("Frame", nil, EnchantListFrame.content)
            enchantFrame:SetSize(680, 22)
            enchantFrame:SetPoint("TOPLEFT", EnchantListFrame.content, "TOPLEFT", 20, -yOffset)
            
            -- Add rank text
            local rankText = enchantFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rankText:SetPoint("LEFT", enchantFrame, "LEFT", 5, 0)
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
                percentText:SetTextColor(1, 1, 0.2, 1) -- Yellow
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
            nameText:SetWidth(500)
            nameText:SetJustifyH("LEFT")
            
            -- Add enchant ID for reference (smaller text)
            local idText = enchantFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            idText:SetPoint("RIGHT", enchantFrame, "RIGHT", -5, 0)
            idText:SetText(string.format("(ID: %d)", enchant.enchantId or 0))
            idText:SetTextColor(0.5, 0.5, 0.5, 1)
            
            yOffset = yOffset + 25
        end
        
        yOffset = yOffset + 10 -- Extra space between slots
    end
    
    -- Adjust content height based on number of entries
    EnchantListFrame.content:SetHeight(math.max(yOffset, 50))
    
    -- Show the frame
    EnchantListFrame:Show()
end

function GST_Enchants.SlashCmd(arg1)
    ListEnchants()
end
