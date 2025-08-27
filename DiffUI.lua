GST_DiffUI = {}

local DiffFrame = nil

-- Talent Loadout Decoder based on Blizzard's implementation
local TalentDecoder = {}

-- Base64 conversion tables (from Blizzard's ExportUtil)
local function MakeBase64ConversionTable()
    local base64ConversionTable = {}
    base64ConversionTable[0] = 'A'
    for num = 1, 25 do
        table.insert(base64ConversionTable, string.char(65 + num))
    end
    for num = 0, 25 do
        table.insert(base64ConversionTable, string.char(97 + num))
    end
    for num = 0, 9 do
        table.insert(base64ConversionTable, tostring(num))
    end
    table.insert(base64ConversionTable, '+')
    table.insert(base64ConversionTable, '/')
    return base64ConversionTable
end

local Base64CharToNumberConversionTable = tInvert(MakeBase64ConversionTable())
local BitsPerChar = 6

-- Convert base64 string to data values
local function ConvertFromBase64(exportString)
    local dataValues = {}
    for i = 1, #exportString do
        local char = string.sub(exportString, i, i)
        local value = Base64CharToNumberConversionTable[char]
        if value then
            table.insert(dataValues, value)
        end
    end
    return dataValues
end

-- Import data stream to extract bit values
local ImportDataStream = {}
ImportDataStream.__index = ImportDataStream

function ImportDataStream:new(exportString)
    local obj = {}
    setmetatable(obj, ImportDataStream)
    obj.dataValues = ConvertFromBase64(exportString)
    obj.currentIndex = 1
    obj.currentExtractedBits = 0
    obj.currentRemainingValue = obj.dataValues[1] or 0
    return obj
end

function ImportDataStream:ExtractValue(bitWidth)
    if self.currentIndex > #self.dataValues then
        return nil
    end

    local value = 0
    local bitsNeeded = bitWidth
    local extractedBits = 0

    while bitsNeeded > 0 do
        local remainingBits = BitsPerChar - self.currentExtractedBits
        local bitsToExtract = math.min(remainingBits, bitsNeeded)
        self.currentExtractedBits = self.currentExtractedBits + bitsToExtract

        local maxStorableValue = bit.lshift(1, bitsToExtract)
        local remainder = self.currentRemainingValue % maxStorableValue
        self.currentRemainingValue = bit.rshift(self.currentRemainingValue, bitsToExtract)

        value = value + bit.lshift(remainder, extractedBits)
        extractedBits = extractedBits + bitsToExtract
        bitsNeeded = bitsNeeded - bitsToExtract

        if bitsToExtract < remainingBits then
            break
        elseif bitsToExtract >= remainingBits then
            self.currentIndex = self.currentIndex + 1
            self.currentExtractedBits = 0
            self.currentRemainingValue = self.dataValues[self.currentIndex] or 0
        end
    end

    return value
end

function ImportDataStream:GetNumberOfBits()
    return BitsPerChar * #self.dataValues
end

-- Get all tree node IDs for mapping indices to actual node IDs
function TalentDecoder:GetTreeNodeIDs(specID)
    local allNodeIDs = {}

    if not C_Traits or not C_ClassTalents then
        return allNodeIDs
    end

    -- Get the tree ID for this specific spec (based on other addon patterns)
    if C_ClassTalents.GetTraitTreeForSpec then
        local treeID = C_ClassTalents.GetTraitTreeForSpec(specID)
        if treeID and C_Traits.GetTreeNodes then
            local nodes = C_Traits.GetTreeNodes(treeID)
            if nodes then
                for _, nodeID in ipairs(nodes) do
                    table.insert(allNodeIDs, nodeID)
                end
            end
        end
    end

    return allNodeIDs
end

-- Get talent details from node IDs (spell IDs, icons, etc)
function TalentDecoder:GetTalentDetails(nodeIDs)
    local talentDetails = {}
    local debugInfo = {}

    if not C_Traits then
        debugInfo.error = "C_Traits not available"
        return talentDetails, debugInfo
    end

    if not C_ClassTalents then
        debugInfo.error = "C_ClassTalents not available"
        return talentDetails, debugInfo
    end

    local configID = nil
    if C_ClassTalents.GetActiveConfigID then
        configID = C_ClassTalents.GetActiveConfigID()
    end

    debugInfo.configID = configID

    if not configID then
        debugInfo.error = "No configID available"
        return talentDetails, debugInfo
    end

    debugInfo.nodeIDsToProcess = #nodeIDs
    debugInfo.processedNodes = 0

    for _, nodeID in ipairs(nodeIDs) do
        if C_Traits.GetNodeInfo then
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            debugInfo.processedNodes = debugInfo.processedNodes + 1

            if nodeInfo and nodeInfo.entryIDs then
                -- Get the first entry (there may be multiple for choice nodes)
                local entryID = nodeInfo.entryIDs[1]
                if entryID and C_Traits.GetEntryInfo then
                    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                    if entryInfo and entryInfo.definitionID then
                        -- Use GetDefinitionInfo to get the actual talent details
                        local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                        if definitionInfo then
                            -- Debug: show what fields actually exist
                            local debugFields = {}
                            for k, v in pairs(definitionInfo) do
                                table.insert(debugFields, k .. "=" .. tostring(v))
                            end

                            -- Extract spell ID from definition info
                            local spellID = definitionInfo.spellID or definitionInfo.overriddenSpellID
                            local spellName = nil
                            local spellIcon = nil

                            -- Get spell info if we have a spell ID
                            if spellID and C_Spell and C_Spell.GetSpellInfo then
                                local spellInfo = C_Spell.GetSpellInfo(spellID)
                                if spellInfo then
                                    spellName = spellInfo.name
                                    spellIcon = spellInfo.iconID
                                end
                            end

                            talentDetails[nodeID] = {
                                nodeID = nodeID,
                                entryID = entryID,
                                definitionID = entryInfo.definitionID,
                                spellID = spellID,
                                spellName = spellName,
                                spellIcon = spellIcon,
                                maxRanks = entryInfo.maxRanks,
                                rawDefinitionInfo = definitionInfo,
                                debugFields = table.concat(debugFields, ", ")
                            }
                        end
                    end
                end
            end
        end
    end

    debugInfo.talentDetailsFound = 0
    for _ in pairs(talentDetails) do
        debugInfo.talentDetailsFound = debugInfo.talentDetailsFound + 1
    end

    return talentDetails, debugInfo
end

-- Decode talent loadout string
function TalentDecoder:DecodeLoadout(loadoutString)
    local importStream = ImportDataStream:new(loadoutString)

    -- Read header
    local bitWidthHeaderVersion = 8
    local bitWidthSpecID = 16
    local headerBitWidth = bitWidthHeaderVersion + bitWidthSpecID + 128

    local importStreamTotalBits = importStream:GetNumberOfBits()
    if importStreamTotalBits < headerBitWidth then
        return nil, "Invalid loadout string: too short"
    end

    local serializationVersion = importStream:ExtractValue(bitWidthHeaderVersion)
    local specID = importStream:ExtractValue(bitWidthSpecID)

    -- Read tree hash (128 bits / 8 = 16 bytes)
    local treeHash = {}
    for i = 1, 16 do
        treeHash[i] = importStream:ExtractValue(8)
    end

    local results = {
        serializationVersion = serializationVersion,
        specID = specID,
        treeHash = treeHash,
        nodeSelections = {},
        debugInfo = {
            totalBits = importStreamTotalBits,
            bitsAfterHeader = importStreamTotalBits - headerBitWidth,
            currentIndex = importStream.currentIndex,
            currentExtractedBits = importStream.currentExtractedBits,
            dataValuesLength = #importStream.dataValues
        }
    }

    -- Get tree node IDs for mapping
    local allNodeIDs = self:GetTreeNodeIDs(results.specID)
    results.debugInfo.totalAvailableNodes = #allNodeIDs

    -- Try to read node selections with better error handling and debug info
    local nodeCount = 0
    local maxNodes = math.min(200, #allNodeIDs > 0 and #allNodeIDs or 200)
    local bitsRead = headerBitWidth
    local selectedNodeIDs = {}

    while importStream.currentIndex <= #importStream.dataValues and nodeCount < maxNodes do
        -- Check if we have enough bits left for at least one more bit
        local remainingBits = importStreamTotalBits - bitsRead
        if remainingBits < 1 then
            break
        end

        local isNodeSelected = importStream:ExtractValue(1)
        bitsRead = bitsRead + 1

        if isNodeSelected == nil then
            -- End of stream
            break
        end

        if isNodeSelected == 1 then
            local actualNodeID = nil
            if #allNodeIDs > nodeCount then
                actualNodeID = allNodeIDs[nodeCount + 1] -- Lua is 1-indexed
                table.insert(selectedNodeIDs, actualNodeID)
            end

            local nodeInfo = {
                selected = true,
                nodeIndex = nodeCount,
                nodeID = actualNodeID,
                granted = false,
                purchased = false
            }

            -- Read if node is purchased (vs granted)
            if remainingBits >= 2 then
                local isNodePurchased = importStream:ExtractValue(1)
                bitsRead = bitsRead + 1

                if isNodePurchased == 1 then
                    nodeInfo.purchased = true

                    -- Read if partially ranked
                    if remainingBits >= 3 then
                        local isPartiallyRanked = importStream:ExtractValue(1)
                        bitsRead = bitsRead + 1

                        if isPartiallyRanked == 1 then
                            -- Read rank count (6 bits)
                            if remainingBits >= 9 then
                                nodeInfo.ranks = importStream:ExtractValue(6)
                                bitsRead = bitsRead + 6
                            end
                        end

                        -- Read if choice node
                        if remainingBits >= 4 then
                            local isChoiceNode = importStream:ExtractValue(1)
                            bitsRead = bitsRead + 1

                            if isChoiceNode == 1 then
                                -- Read choice index (2 bits)
                                if remainingBits >= 6 then
                                    nodeInfo.choiceIndex = importStream:ExtractValue(2)
                                    bitsRead = bitsRead + 2
                                end
                            end
                        end
                    end
                else
                    -- Node is granted (automatic), not purchased
                    nodeInfo.granted = true
                end
            end

            table.insert(results.nodeSelections, nodeInfo)
        end

        nodeCount = nodeCount + 1
    end

    -- Get talent details for selected nodes
    if #selectedNodeIDs > 0 then
        local talentDetails, talentDebugInfo = self:GetTalentDetails(selectedNodeIDs)
        results.talentDetails = talentDetails
        results.debugInfo.talentLookup = talentDebugInfo

        -- Add talent details to node info
        for _, nodeInfo in ipairs(results.nodeSelections) do
            if nodeInfo.nodeID and talentDetails[nodeInfo.nodeID] then
                nodeInfo.talentInfo = talentDetails[nodeInfo.nodeID]
            end
        end
    end

    -- Add final debug info
    results.debugInfo.nodesProcessed = nodeCount
    results.debugInfo.finalBitsRead = bitsRead
    results.debugInfo.finalCurrentIndex = importStream.currentIndex
    results.debugInfo.selectedNodesFound = #results.nodeSelections

    return results, nil
end

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

    -- Create scroll frame for talent information
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 50)

    -- Create content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(560, 100)
    scrollFrame:SetScrollChild(content)

    -- Decode the talent loadout
    local loadoutString =
    "CsbBV7//nP39x/JJympTqouKSAAAAAAAAAAAAzMzMMmNzYmBzwYMTDzMZMWmZmZGzYmlZAzMjNmZWmZeAYAGsBLjRjtBkZCwGG"
    local decodedData, errorMsg = TalentDecoder:DecodeLoadout(loadoutString)

    -- Force some debug output to console
    print("=== DIFF UI DEBUG ===")
    print("decodedData type:", type(decodedData))
    if decodedData then
        print("specID:", decodedData.specID)
        print("nodeSelections count:", decodedData.nodeSelections and #decodedData.nodeSelections or "nil")
        print("debugInfo exists:", decodedData.debugInfo and "yes" or "no")
    end
    print("errorMsg:", errorMsg or "none")
    print("===================")

    local yOffset = 0

    if errorMsg then
        -- Show error message
        local errorText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
        errorText:SetText("Error: " .. errorMsg)
        errorText:SetTextColor(1, 0, 0, 1)
        yOffset = yOffset - 20
    elseif decodedData then
        -- Show loadout info
        local headerText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
        headerText:SetText("Talent Loadout Decoded")
        headerText:SetTextColor(1, 1, 0, 1)
        yOffset = yOffset - 25

        -- Show spec info with name instead of ID
        local specText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        specText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)

        local specName = "Unknown Specialization"
        if decodedData.specID and GetSpecializationInfoByID then
            local id, name, description, icon, role, primaryStat = GetSpecializationInfoByID(decodedData.specID)
            if name then
                specName = name
            end
        end

        specText:SetText("Specialization: " .. specName)
        specText:SetTextColor(0.8, 0.8, 1, 1)
        yOffset = yOffset - 25



        -- Show selected nodes
        if decodedData.nodeSelections and #decodedData.nodeSelections > 0 then
            local nodesHeaderText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nodesHeaderText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
            nodesHeaderText:SetText("Selected Nodes (" .. #decodedData.nodeSelections .. "):")
            nodesHeaderText:SetTextColor(1, 1, 1, 1)
            yOffset = yOffset - 20

            for i, nodeInfo in ipairs(decodedData.nodeSelections) do
                -- Create icon texture if we have spell icon info
                local iconTexture = nil
                if nodeInfo.talentInfo and nodeInfo.talentInfo.spellIcon then
                    -- Create a button to hold the icon so we can add tooltip functionality
                    local iconButton = CreateFrame("Button", nil, content)
                    iconButton:SetSize(32, 32)
                    iconButton:SetPoint("TOPLEFT", content, "TOPLEFT", 20, yOffset + 2)

                    -- Add the icon texture to the button
                    iconTexture = iconButton:CreateTexture(nil, "ARTWORK")
                    iconTexture:SetAllPoints(iconButton)
                    iconTexture:SetTexture(nodeInfo.talentInfo.spellIcon)

                    -- Add spell tooltip on hover
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

                local nodeText = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                local textXOffset = iconTexture and 60 or 20 -- Offset text if icon is present (32px icon + 28px spacing)
                nodeText:SetPoint("TOPLEFT", content, "TOPLEFT", textXOffset, yOffset)

                local nodeDesc = ""

                -- Show just spell name and ranks
                if nodeInfo.talentInfo and nodeInfo.talentInfo.spellName then
                    nodeDesc = nodeInfo.talentInfo.spellName

                    -- Add rank information in "x/y" format
                    if nodeInfo.talentInfo.maxRanks and nodeInfo.talentInfo.maxRanks > 1 then
                        local currentRanks
                        if nodeInfo.ranks then
                            -- Partially ranked - use the stored rank count
                            currentRanks = nodeInfo.ranks
                        else
                            -- Fully ranked (isPartiallyRanked was 0) - use max ranks
                            currentRanks = nodeInfo.talentInfo.maxRanks
                        end
                        nodeDesc = nodeDesc .. " " .. currentRanks .. "/" .. nodeInfo.talentInfo.maxRanks
                    end
                else
                    -- Fallback if no spell name
                    nodeDesc = "Unknown Talent"
                end

                nodeText:SetText(nodeDesc)
                nodeText:SetTextColor(0.9, 0.9, 0.9, 1)
                yOffset = yOffset - 36 -- Increased spacing for 32px icons
            end
        else
            local noNodesText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noNodesText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, yOffset)
            noNodesText:SetText("No talent nodes found in loadout")
            noNodesText:SetTextColor(0.7, 0.7, 0.7, 1)
            yOffset = yOffset - 20
        end

        -- Update content height
        content:SetHeight(math.abs(yOffset) + 20)
    end

    -- Store the content frame for future updates
    frame.content = content

    -- Add Summary button
    local summaryButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    summaryButton:SetSize(80, 24)
    summaryButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -8)
    summaryButton:SetText("Summary")
    summaryButton:SetScript("OnClick", function()
        if GST_Summary and GST_Summary.SlashCmd then
            GST_Summary.SlashCmd()
            frame:Hide() -- Close the diff panel
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

    DiffFrame = frame
    return frame
end

function GST_DiffUI.ShowDiff()
    local frame = CreateDiffUI()
    frame:Show()
end

function GST_DiffUI.SlashCmd(arg1)
    GST_DiffUI.ShowDiff()
end

function GST_DiffUI.RefreshIfVisible()
    if DiffFrame and DiffFrame:IsShown() then
        -- Nothing to refresh for this static display
    end
end
