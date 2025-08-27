-- Talent Loadout Decoder and utilities
GST_DiffUtils = {}

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

-- Get talent details for a specific choice within a choice node
function TalentDecoder:GetChoiceTalentDetails(nodeID, choiceIndex, configID)
    if not C_Traits or not configID then
        return nil
    end

    local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
    if not nodeInfo or not nodeInfo.entryIDs then
        return nil
    end

    -- Choice index is 0-based, but Lua arrays are 1-based
    local entryID = nodeInfo.entryIDs[choiceIndex + 1]
    if not entryID then
        return nil
    end

    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if not entryInfo or not entryInfo.definitionID then
        return nil
    end

    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
    if not definitionInfo then
        return nil
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

    return {
        nodeID = nodeID,
        entryID = entryID,
        spellID = spellID,
        spellName = spellName,
        spellIcon = spellIcon,
        maxRanks = entryInfo.maxRanks or 1,
        choiceIndex = choiceIndex
    }
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

        -- Get configID for choice node lookups
        local configID = nil
        if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
            configID = C_ClassTalents.GetActiveConfigID()
        end

        -- Add talent details to node info (handle choice nodes)
        for _, nodeInfo in ipairs(results.nodeSelections) do
            if nodeInfo.nodeID then
                -- For choice nodes, we need to get the specific choice entry
                if nodeInfo.choiceIndex ~= nil and configID then
                    -- Get choice-specific talent info
                    local choiceTalentInfo = self:GetChoiceTalentDetails(nodeInfo.nodeID, nodeInfo.choiceIndex, configID)
                    if choiceTalentInfo then
                        nodeInfo.talentInfo = choiceTalentInfo
                    end
                elseif talentDetails[nodeInfo.nodeID] then
                    -- Regular node, use cached talent details
                    nodeInfo.talentInfo = talentDetails[nodeInfo.nodeID]
                end
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

-- Validate and decode loadout string with error handling
function GST_DiffUtils.ValidateAndDecode(str)
    if not str or str == "" or string.len(str) < 10 or not string.match(str, "^[A-Za-z0-9+/]*=*$") then
        return nil, "Loadout string invalid"
    end

    local success, result, error = pcall(TalentDecoder.DecodeLoadout, TalentDecoder, str)
    if success and result then
        return result, error
    else
        return nil, "Loadout string invalid"
    end
end

-- Export the TalentDecoder for backward compatibility if needed
GST_DiffUtils.TalentDecoder = TalentDecoder
