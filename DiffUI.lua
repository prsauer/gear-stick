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

    -- Store references to created UI elements for cleanup by column
    local createdElements = {
        column1 = {},
        column2 = {},
        separator = nil
    }

    -- Function to create separator if it doesn't exist
    local function EnsureSeparator()
        if not createdElements.separator then
            local separatorLine = content:CreateTexture(nil, "ARTWORK")
            separatorLine:SetSize(2, 800)
            separatorLine:SetPoint("TOPLEFT", content, "TOPLEFT", 480, -45)
            separatorLine:SetColorTexture(0.5, 0.5, 0.5, 1)
            createdElements.separator = separatorLine
        end
    end

    -- Function to render a single column
    local function RenderColumn(decodedData, errorMsg, xOffset, columnTitle, columnKey)
        EnsureSeparator()   -- Make sure separator exists
        local yOffset = -45 -- Start below the input boxes

        -- Column title
        local titleText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleText:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 10, yOffset)
        titleText:SetText(columnTitle)
        titleText:SetTextColor(1, 1, 0, 1)
        table.insert(createdElements[columnKey], titleText)
        yOffset = yOffset - 25

        if errorMsg then
            local errorText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            errorText:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 10, yOffset)
            errorText:SetText(errorMsg)
            errorText:SetTextColor(1, 0, 0, 1)
            table.insert(createdElements[columnKey], errorText)
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
        table.insert(createdElements[columnKey], specText)
        yOffset = yOffset - 30

        -- Show selected nodes
        if decodedData.nodeSelections and #decodedData.nodeSelections > 0 then
            for i, nodeInfo in ipairs(decodedData.nodeSelections) do
                -- Create icon if available
                if nodeInfo.talentInfo and nodeInfo.talentInfo.spellIcon then
                    local iconButton = CreateFrame("Button", nil, content)
                    iconButton:SetSize(32, 32)
                    iconButton:SetPoint("TOPLEFT", content, "TOPLEFT", xOffset + 20, yOffset + 2)
                    table.insert(createdElements[columnKey], iconButton)

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
                table.insert(createdElements[columnKey], nodeText)

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

    -- Function to compute differences between two loadouts
    local function ComputeDiff()
        local loadoutString1 = input1:GetText() or ""
        local loadoutString2 = input2:GetText() or ""

        local decodedData1, errorMsg1 = GST_DiffUtils.ValidateAndDecode(loadoutString1)
        local decodedData2, errorMsg2 = GST_DiffUtils.ValidateAndDecode(loadoutString2)

        -- Return early if either loadout is invalid
        if errorMsg1 or errorMsg2 or not decodedData1 or not decodedData2 then
            return decodedData1, errorMsg1, decodedData2, errorMsg2
        end

        -- Create sets of selected talents for each loadout (using node ID + choice index for comparison)
        local talents1 = {}
        local talents2 = {}

        if decodedData1.nodeSelections then
            for _, nodeInfo in ipairs(decodedData1.nodeSelections) do
                if nodeInfo.nodeID then
                    -- For choice nodes, include choice index in the key
                    -- For regular nodes, use node ID + ranks
                    local key
                    if nodeInfo.choiceIndex ~= nil then
                        -- Choice node: nodeID_choiceIndex_ranks
                        local ranks = nodeInfo.ranks or (nodeInfo.talentInfo and nodeInfo.talentInfo.maxRanks or 1)
                        key = nodeInfo.nodeID .. "_choice_" .. nodeInfo.choiceIndex .. "_" .. ranks
                    else
                        -- Regular node: nodeID_ranks
                        local ranks = nodeInfo.ranks or (nodeInfo.talentInfo and nodeInfo.talentInfo.maxRanks or 1)
                        key = nodeInfo.nodeID .. "_" .. ranks
                    end
                    talents1[key] = nodeInfo
                end
            end
        end

        if decodedData2.nodeSelections then
            for _, nodeInfo in ipairs(decodedData2.nodeSelections) do
                if nodeInfo.nodeID then
                    -- For choice nodes, include choice index in the key
                    -- For regular nodes, use node ID + ranks
                    local key
                    if nodeInfo.choiceIndex ~= nil then
                        -- Choice node: nodeID_choiceIndex_ranks
                        local ranks = nodeInfo.ranks or (nodeInfo.talentInfo and nodeInfo.talentInfo.maxRanks or 1)
                        key = nodeInfo.nodeID .. "_choice_" .. nodeInfo.choiceIndex .. "_" .. ranks
                    else
                        -- Regular node: nodeID_ranks
                        local ranks = nodeInfo.ranks or (nodeInfo.talentInfo and nodeInfo.talentInfo.maxRanks or 1)
                        key = nodeInfo.nodeID .. "_" .. ranks
                    end
                    talents2[key] = nodeInfo
                end
            end
        end

        -- Create diff data: talents unique to each side
        local diffData1 = {
            specID = decodedData1.specID,
            serializationVersion = decodedData1.serializationVersion,
            nodeSelections = {}
        }
        local diffData2 = {
            specID = decodedData2.specID,
            serializationVersion = decodedData2.serializationVersion,
            nodeSelections = {}
        }

        -- Find talents in loadout 1 that are NOT in loadout 2
        for key, nodeInfo in pairs(talents1) do
            if not talents2[key] then
                table.insert(diffData1.nodeSelections, nodeInfo)
            end
        end

        -- Find talents in loadout 2 that are NOT in loadout 1
        for key, nodeInfo in pairs(talents2) do
            if not talents1[key] then
                table.insert(diffData2.nodeSelections, nodeInfo)
            end
        end

        return diffData1, nil, diffData2, nil
    end

    -- Function to refresh a specific column
    local function RefreshColumn(columnNum)
        local columnKey = "column" .. columnNum

        -- Cleanup elements for this specific column
        for _, element in pairs(createdElements[columnKey]) do
            if element and element.Hide then
                element:Hide()
            end
            if element and element.SetParent then
                element:SetParent(nil)
            end
        end
        -- Clear the tracking table for this column
        createdElements[columnKey] = {}

        -- Get diff data instead of individual loadout data
        local diffData1, errorMsg1, diffData2, errorMsg2 = ComputeDiff()

        local decodedData, errorMsg
        if columnNum == 1 then
            decodedData, errorMsg = diffData1, errorMsg1
        else
            decodedData, errorMsg = diffData2, errorMsg2
        end

        -- Render just this column
        local xOffset = columnNum == 1 and 0 or 490
        local columnTitle = columnNum == 1 and "Only in Loadout 1" or "Only in Loadout 2"
        RenderColumn(decodedData, errorMsg, xOffset, columnTitle, columnKey)
    end

    -- Add refresh on text change (now that RenderColumn is defined)
    local refreshTimer = nil
    local function DelayedRefresh()
        -- Clear any existing timer
        refreshTimer = nil

        -- Create new timer - refresh both columns since diff affects both
        refreshTimer = C_Timer.NewTimer(0.3, function()
            RefreshColumn(1)
            RefreshColumn(2)
            refreshTimer = nil
        end)
    end

    input1:SetScript("OnTextChanged", function(self, userInput)
        if userInput then DelayedRefresh() end
    end)
    input2:SetScript("OnTextChanged", function(self, userInput)
        if userInput then DelayedRefresh() end
    end)

    -- Also refresh on Enter for immediate feedback
    input1:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        RefreshColumn(1)
        RefreshColumn(2)
    end)
    input2:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        RefreshColumn(1)
        RefreshColumn(2)
    end)

    -- Store frame reference
    DiffFrame = frame

    -- Initial render of both columns (after all functions are defined)
    RefreshColumn(1)
    RefreshColumn(2)

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
