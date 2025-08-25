GST_BracketUtils = {}

-- Helper function to get class name from class ID
function GST_BracketUtils.GetClassNameFromID(classID)
    local classNames = {
        [1] = "warrior",
        [2] = "paladin",
        [3] = "hunter",
        [4] = "rogue",
        [5] = "priest",
        [6] = "deathknight",
        [7] = "shaman",
        [8] = "mage",
        [9] = "warlock",
        [10] = "monk",
        [11] = "druid",
        [12] = "demonhunter",
        [13] = "evoker"
    }
    return classNames[classID]
end

-- Helper function to get spec name from spec ID
function GST_BracketUtils.GetSpecNameFromID(specID)
    local specNames = {
        -- Warrior
        [71] = "arms",
        [72] = "fury",
        [73] = "protection",
        -- Paladin
        [65] = "holy",
        [66] = "protection",
        [70] = "retribution",
        -- Hunter
        [253] = "beastmastery",
        [254] = "marksmanship",
        [255] = "survival",
        -- Rogue
        [259] = "assassination",
        [260] = "outlaw",
        [261] = "subtlety",
        -- Priest
        [256] = "discipline",
        [257] = "holy",
        [258] = "shadow",
        -- Death Knight
        [250] = "blood",
        [251] = "frost",
        [252] = "unholy",
        -- Shaman
        [262] = "elemental",
        [263] = "enhancement",
        [264] = "restoration",
        -- Mage
        [62] = "arcane",
        [63] = "fire",
        [64] = "frost",
        -- Warlock
        [265] = "affliction",
        [266] = "demonology",
        [267] = "destruction",
        -- Monk
        [268] = "brewmaster",
        [269] = "windwalker",
        [270] = "mistweaver",
        -- Druid
        [102] = "balance",
        [103] = "feral",
        [104] = "guardian",
        [105] = "restoration",
        -- Demon Hunter
        [577] = "havoc",
        [581] = "vengeance",
        -- Evoker
        [1467] = "devastation",
        [1468] = "preservation",
        [1473] = "augmentation"
    }
    return specNames[specID]
end

-- Helper function to get available brackets for current class/spec
function GST_BracketUtils.GetAvailableBrackets(currentClassID, currentSpecID)
    local availableBrackets = {}

    -- Always include the standard brackets
    table.insert(availableBrackets, "pve")
    table.insert(availableBrackets, "2v2")
    table.insert(availableBrackets, "3v3")

    -- Add class-specific shuffle brackets if they exist
    if GSTBracketNames then
        local className = GST_BracketUtils.GetClassNameFromID(currentClassID)
        local specName = GST_BracketUtils.GetSpecNameFromID(currentSpecID)

        if className and specName then
            local shuffleBracket = "shuffle_" .. className .. "_" .. specName
            for _, bracket in ipairs(GSTBracketNames) do
                if bracket == shuffleBracket then
                    table.insert(availableBrackets, shuffleBracket)
                    break
                end
            end
        end
    end

    return availableBrackets
end

-- Helper function to get gear rank for a specific item
function GST_BracketUtils.GetGearRank(slotID, currentSpecID, selectedBracket, itemID, statsShort)
    if not GSTSlotGearDb or not itemID then return nil end

    -- Use the indexed lookup to get matching items
    local slotItems = SlotGearIndexes.LookupBySlotSpecBracket(slotID, currentSpecID, selectedBracket)

    -- Sort by rank
    table.sort(slotItems, function(a, b) return a.rank < b.rank end)

    -- Find matching item
    for _, item in ipairs(slotItems) do
        if item.itemId == itemID then
            local statsMatch = statsShort and item.statsShort and statsShort == item.statsShort
            if not item.statsShort or item.statsShort == "" or statsMatch then
                return item.rank
            end
        end
    end

    return nil
end

-- Helper function to get enchant rank for a specific enchant
function GST_BracketUtils.GetEnchantRank(currentSpecID, slotType, selectedBracket, enchantID)
    if not GSTEnchantsDb or not enchantID then return nil end

    -- Use the indexed lookup to get matching enchants
    local enchants = EnchantsIndexes.LookupBySpecSlotBracket(currentSpecID, slotType, selectedBracket)

    -- Sort by rank
    table.sort(enchants, function(a, b) return a.rank < b.rank end)

    -- Find matching enchant
    for _, enchant in ipairs(enchants) do
        if enchant.enchantId == enchantID then
            return enchant.rank
        end
    end

    return nil
end
