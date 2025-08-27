GST_DiffUI = {}

local DiffFrame = nil

local function CreateDiffUI()
    if DiffFrame then
        return DiffFrame
    end

    -- Create the main frame
    local frame = CreateFrame("Frame", "GSTDiffFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1000, 900)
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
    frame.title:SetText("Diff")

    -- Add close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Create scroll frame for talent information
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 50)

    -- Create content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(960, 100) -- Wider for two columns
    scrollFrame:SetScrollChild(content)

    -- Create input boxes for loadout codes
    local input1 = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    input1:SetSize(450, 25)
    input1:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    input1:SetText("CsbBV7//nP39x/JJympTqouKSAAAAAAAAAAAAzMzMMmNzYmBzwYMTDzMZMWmZmZGzYmlZAzMjNmZWmZeAYAGsBLjRjtBkZCwGG")
    input1:SetAutoFocus(false)
    input1:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local input2 = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    input2:SetSize(450, 25)
    input2:SetPoint("TOPLEFT", content, "TOPLEFT", 500, -10)
    input2:SetText("CsbBV7//nP39x/JJympTqouKSAAAAAAAAAAAgxMzMwsZGzMYGGDTDzMZ2GLzMzMjZMzyMgZmZ2YmZZMDMwYwGsMGN2GQmJAbYA")
    input2:SetAutoFocus(false)
    input2:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Function to refresh the diff when input changes
    local function RefreshDiff()
        -- Clear existing content (except input boxes)
        local children = { content:GetChildren() }
        for _, child in pairs(children) do
            if child and child ~= input1 and child ~= input2 then
                child:Hide()
                child:SetParent(nil)
            end
        end

        local loadoutString = input1:GetText() or ""
        local loadout2String = input2:GetText() or ""

        -- Validate and decode loadout strings using DiffUtils
        local decodedData1, errorMsg1 = GST_DiffUtils.ValidateAndDecode(loadoutString)
        local decodedData2, errorMsg2 = GST_DiffUtils.ValidateAndDecode(loadout2String)

        -- Call RenderColumns after it's defined
        if RenderColumns then
            RenderColumns(decodedData1, errorMsg1, decodedData2, errorMsg2)
        end
    end

    -- Function to render both columns
    local function RenderColumns(decodedData1, errorMsg1, decodedData2, errorMsg2)
        -- Create column separator line
        local separatorLine = content:CreateTexture(nil, "ARTWORK")
        separatorLine:SetSize(2, 800)
        separatorLine:SetPoint("TOPLEFT", content, "TOPLEFT", 480, -45)
        separatorLine:SetColorTexture(0.5, 0.5, 0.5, 1)

        local function RenderLoadoutColumn(decodedData, errorMsg, xOffset, columnTitle)
            local yOffset = -45 -- Start below the input boxes

            -- Column title
            local titleText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            titleText:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 10, yOffset)
            titleText:SetText(columnTitle)
            titleText:SetTextColor(1, 1, 0, 1)
            yOffset = yOffset - 25

            if errorMsg then
                local errorText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                errorText:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 10, yOffset)
                errorText:SetText(errorMsg)
                errorText:SetTextColor(1, 0, 0, 1)
                return
            end

            if not decodedData then return end

            -- Show specialization
            local specName = "Unknown Specialization"
            if decodedData.specID and GetSpecializationInfoByID then
                local id, name = GetSpecializationInfoByID(decodedData.specID)
                if name then specName = name end
            end

            local specText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            specText:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 10, yOffset)
            specText:SetText("Specialization: " .. specName)
            specText:SetTextColor(0.8, 0.8, 1, 1)
            yOffset = yOffset - 30

            -- Show selected nodes
            if decodedData.nodeSelections and #decodedData.nodeSelections > 0 then
                for i, nodeInfo in ipairs(decodedData.nodeSelections) do
                    -- Create icon if available
                    if nodeInfo.talentInfo and nodeInfo.talentInfo.spellIcon then
                        local iconButton = CreateFrame("Button", nil, content)
                        iconButton:SetSize(32, 32)
                        iconButton:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 20, yOffset + 2)

                        local iconTexture = iconButton:CreateTexture(nil, "ARTWORK")
                        iconTexture:SetAllPoints(iconButton)
                        iconTexture:SetTexture(nodeInfo.talentInfo.spellIcon)

                        -- Add tooltip
                        if nodeInfo.talentInfo.spellID then
                            iconButton:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                GameTooltip:SetSpellByID(nodeInfo.talentInfo.spellID)
                                GameTooltip:Show()
                            end)
                            iconButton:SetScript("OnLeave", function(self)
                                GameTooltip:Hide()
                            end)
                        end
                    end

                    -- Create text
                    local nodeText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nodeText:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 60, yOffset)

                    local nodeDesc = ""
                    if nodeInfo.talentInfo and nodeInfo.talentInfo.spellName then
                        nodeDesc = nodeInfo.talentInfo.spellName

                        -- Add rank information
                        if nodeInfo.talentInfo.maxRanks and nodeInfo.talentInfo.maxRanks > 1 then
                            local currentRanks = nodeInfo.ranks or nodeInfo.talentInfo.maxRanks
                            nodeDesc = nodeDesc .. " " .. currentRanks .. "/" .. nodeInfo.talentInfo.maxRanks
                        end
                    else
                        nodeDesc = "Unknown Talent"
                    end

                    nodeText:SetText(nodeDesc)
                    nodeText:SetTextColor(0.9, 0.9, 0.9, 1)
                    yOffset = yOffset - 36
                end
            end

            return yOffset
        end

        -- Render both columns
        local yOffset1 = RenderLoadoutColumn(decodedData1, errorMsg1, 0, "Loadout 1")
        local yOffset2 = RenderLoadoutColumn(decodedData2, errorMsg2, 490, "Loadout 2")

        -- Adjust content height based on the taller column
        local maxHeight = math.abs(math.min(yOffset1 or 0, yOffset2 or 0)) + 50
        content:SetHeight(maxHeight)
    end

    -- Add refresh on text change (now that RenderColumns is defined)
    local refreshTimer = nil
    local function DelayedRefresh()
        if refreshTimer then
            refreshTimer:Cancel()
        end
        refreshTimer = C_Timer.NewTimer(0.3, function()
            RefreshDiff()
            refreshTimer = nil
        end)
    end

    input1:SetScript("OnTextChanged", function(self, userInput)
        if userInput then DelayedRefresh() end
    end)
    input2:SetScript("OnTextChanged", function(self, userInput)
        if userInput then DelayedRefresh() end
    end)

    -- Also refresh on Enter/Escape for immediate feedback
    input1:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        RefreshDiff()
    end)
    input2:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        RefreshDiff()
    end)

    -- Get initial loadout strings and decode
    local loadoutString = input1:GetText()
    local loadout2String = input2:GetText()
    local decodedData1, errorMsg1 = GST_DiffUtils.ValidateAndDecode(loadoutString)
    local decodedData2, errorMsg2 = GST_DiffUtils.ValidateAndDecode(loadout2String)

    -- Initial render
    RenderColumns(decodedData1, errorMsg1, decodedData2, errorMsg2)

    -- Store frame reference
    DiffFrame = frame

    -- Show the frame
    frame:Show()
end

function GST_DiffUI.ShowDiff()
    CreateDiffUI()
end

function GST_DiffUI.SlashCmd(arg1)
    GST_DiffUI.ShowDiff()
end

function GST_DiffUI.RefreshIfVisible()
    if DiffFrame and DiffFrame:IsShown() then
        -- Nothing to refresh for this static display
    end
end
