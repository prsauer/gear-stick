GST_Talents = {}


local function ListTalents()
    -- Create the main frame if it doesn't exist
    if not TalentListFrame then
        local frame = CreateFrame("Frame", "TalentListFrame", UIParent, "BackdropTemplate")
        frame:SetSize(600, 500)
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
        frame.title:SetText("Talent Loadouts")

        -- Create the scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 8, -60) -- Changed from -30 to -60
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 28)

        -- Create the content frame
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(540, 50) -- Made content wider to match new frame size
        scrollFrame:SetScrollChild(content)
        frame.content = content

        -- Add help text at bottom
        local helpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        helpText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 8, 8)
        helpText:SetText("Click any button to highlight the talent code, then press Ctrl+C to copy")
        helpText:SetTextColor(0.5, 0.5, 0.5, 1) -- Gray color

        -- Add Summary button
        local summaryButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        summaryButton:SetSize(80, 24)
        summaryButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -8)
        summaryButton:SetText("Summary")
        summaryButton:SetScript("OnClick", function()
            if GST_Summary and GST_Summary.SlashCmd then
                GST_Summary.SlashCmd()
                frame:Hide() -- Close the talents panel
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
        tinsert(UISpecialFrames, "TalentListFrame")

        TalentListFrame = frame
    end

    -- Get current spec and class info
    local currentSpec = GetSpecialization()
    local currentSpecID = currentSpec and select(1, GetSpecializationInfo(currentSpec)) or nil
    local _, _, currentClassID = UnitClass("player")

    if not currentSpecID then
        print("No specialization selected")
        return
    end

    -- Create the dropdown if it doesn't exist
    if not TalentListFrame.specDropdown then
        local dropdown = CreateFrame("Frame", "GSTSpecDropdown", TalentListFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", TalentListFrame.title, "TOPRIGHT", 20, -2)
        TalentListFrame.specDropdown = dropdown

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
                    ListTalents() -- Refresh the list
                end
                info.checked = (specID == UIDropDownMenu_GetSelectedValue(dropdown))
                UIDropDownMenu_AddButton(info)
            end
        end
    end

    -- Set the initial selected value if not already set
    if not UIDropDownMenu_GetSelectedValue(TalentListFrame.specDropdown) then
        UIDropDownMenu_SetSelectedValue(TalentListFrame.specDropdown, currentSpecID)
        -- Get the spec name and set it
        local _, specName = GetSpecializationInfoForClassID(currentClassID, currentSpec)
        UIDropDownMenu_SetText(TalentListFrame.specDropdown, specName)
    end
    UIDropDownMenu_SetWidth(TalentListFrame.specDropdown, 100)
    UIDropDownMenu_JustifyText(TalentListFrame.specDropdown, "LEFT")

    -- Clear existing content
    for _, child in pairs({ TalentListFrame.content:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Filter loadouts for current class and selected spec, and group by bracket
    local selectedSpecID = UIDropDownMenu_GetSelectedValue(TalentListFrame.specDropdown)
    local bracketLoadouts = {}
    for _, loadout in ipairs(GSTLoadoutsDb) do
        if loadout.classId == currentClassID and loadout.specId == selectedSpecID then
            local bracket = loadout.bracket or "Unknown"
            if not bracketLoadouts[bracket] then
                bracketLoadouts[bracket] = {}
            end
            table.insert(bracketLoadouts[bracket], loadout)
        end
    end

    -- Sort brackets (2v2, 3v3, etc.)
    local sortedBrackets = {}
    for bracket in pairs(bracketLoadouts) do
        table.insert(sortedBrackets, bracket)
    end
    table.sort(sortedBrackets)

    -- Create headers and buttons for each bracket's loadouts
    local yOffset = 0
    for _, bracket in ipairs(sortedBrackets) do
        local loadoutList = bracketLoadouts[bracket]

        -- Create bracket header
        local headerFrame = CreateFrame("Frame", nil, TalentListFrame.content)
        headerFrame:SetSize(520, 25)
        headerFrame:SetPoint("TOPLEFT", TalentListFrame.content, "TOPLEFT", 0, -yOffset)

        -- Add header background
        headerFrame.bg = headerFrame:CreateTexture(nil, "BACKGROUND")
        headerFrame.bg:SetAllPoints()
        headerFrame.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

        -- Add bracket name text
        headerFrame.text = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerFrame.text:SetPoint("LEFT", headerFrame, "LEFT", 10, 0)
        headerFrame.text:SetText(bracket)

        yOffset = yOffset + 30 -- Space after header

        -- Sort loadouts by rank (ascending)
        table.sort(loadoutList, function(a, b)
            return (a.rank or 0) < (b.rank or 0) -- Changed > to < for ascending order
        end)

        -- Create buttons for this bracket's loadouts
        for _, loadout in ipairs(loadoutList) do
            -- Create container frame for button and editbox
            local container = CreateFrame("Frame", nil, TalentListFrame.content)
            container:SetSize(520, 30)
            container:SetPoint("TOPLEFT", TalentListFrame.content, "TOPLEFT", 0, -yOffset)

            -- Create loadout button
            local button = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
            button:SetSize(200, 30)
            button:SetPoint("LEFT", container, "LEFT", 10, 0) -- Indented slightly

            -- Format button text with loadout info
            local buttonText = string.format("#%d %s",
                loadout.rank or 0,
                loadout.name or "Unnamed")
            button:SetText(buttonText)

            -- Create EditBox
            local editBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
            editBox:SetSize(300, 20)
            editBox:SetPoint("LEFT", button, "RIGHT", 10, 0)
            editBox:SetAutoFocus(false)
            editBox:SetText(loadout.code)

            -- Set up the click handler
            button:SetScript("OnClick", function()
                editBox:SetFocus()
                editBox:HighlightText()
            end)

            yOffset = yOffset + 35 -- Space between buttons
        end

        yOffset = yOffset + 5 -- Extra space between brackets
    end

    -- Adjust content height based on number of loadouts
    TalentListFrame.content:SetHeight(math.max(yOffset, 50))

    -- Show the frame
    TalentListFrame:Show()
end

function GST_Talents.SlashCmd(arg1)
    ListTalents()
end

function GST_Talents.RefreshIfVisible()
    if TalentListFrame and TalentListFrame:IsShown() then
        ListTalents()
    end
end
