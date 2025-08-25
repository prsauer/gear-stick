-- SlotGear Index Functions
-- Builds an index for the GSTSlotGearDb database for fast lookups

local SlotGearIndexes = {}

-- Global index table that gets built once
GSTSlotGearIndex = nil

-- Build an index table that maps concatenated keys (slotId_specId_bracket) to arrays of database indexes
function SlotGearIndexes.BuildIndex()
    local index = {}

    -- Iterate through the entire database
    for i = 1, #GSTSlotGearDb do
        local entry = GSTSlotGearDb[i]
        local slotId = entry.slotId
        local specId = entry.specId
        local bracket = entry.bracket

        -- Create the concatenated key
        local key = slotId .. "_" .. specId .. "_" .. bracket

        -- Initialize the array for this key if it doesn't exist
        if not index[key] then
            index[key] = {}
        end

        -- Add the current database index to the array
        table.insert(index[key], i)
    end

    return index
end

-- Lookup function that takes slotId, specId, and bracket and returns an array of matching entries
function SlotGearIndexes.LookupBySlotSpecBracket(slotId, specId, bracket)
    -- Ensure the global index exists
    if not GSTSlotGearIndex then
        GSTSlotGearIndex = SlotGearIndexes.BuildIndex()
    end

    -- Create the concatenated key
    local key = slotId .. "_" .. specId .. "_" .. bracket

    -- Get the array of indexes for this key
    local indexArray = GSTSlotGearIndex[key]

    if not indexArray then
        return {} -- Return empty array if no matches found
    end

    -- Build the result array by looking up each index in the database
    local result = {}
    for _, dbIndex in ipairs(indexArray) do
        table.insert(result, GSTSlotGearDb[dbIndex])
    end

    return result
end

-- Function to initialize the global index (call this once when the addon loads)
function SlotGearIndexes.InitializeIndex()
    if not GSTSlotGearIndex then
        GSTSlotGearIndex = SlotGearIndexes.BuildIndex()
    end
end

-- Example usage:
-- SlotGearIndexes.InitializeIndex() -- Call this once when addon loads
-- local results = SlotGearIndexes.LookupBySlotSpecBracket(1, 250, "pve") -- Get all head slot items for spec 250 in PvE bracket

return SlotGearIndexes
